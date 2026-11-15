/*
  Standalone self-test for the VirtualTable API (virtual_table.h / virtual_table.c).

  libc + virtual_table.h only. Single threaded (virtual_table.c has no threads).

  Parameters are chosen against the real contract of virtual_table.c:
    page_size          = 1 << page_size_shift = 1 << 20 = 1 MiB
    max_resident_pages = cache_size / page_size = 16 (exactly, so neither the
                         16 minimum nor the 65536 maximum clamp kicks in)
    total_size         = 20 MiB = 20 pages, so sweeping the whole table past 16
                         resident pages forces the tail slot to be recycled
  A full 1 MiB resident cache therefore needs at least 16 MiB, and more than 16
  pages of table to ever see an eviction.

  Backing files are opened by vt_create as snprintf("%s.%s.part%d", path,
  table_name, k) where k is the index after the priority-descending sort, so
  the priority 2 store becomes part0 and the priority 1 store becomes part1.
*/

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stddef.h>

#include "virtual_table.h"

#define VT_SELFTEST_PAGE_SIZE_SHIFT 20
#define VT_SELFTEST_PAGE_SIZE       ((size_t)1 << VT_SELFTEST_PAGE_SIZE_SHIFT)
#define VT_SELFTEST_CACHE_SIZE      ((size_t)16 * VT_SELFTEST_PAGE_SIZE)
#define VT_SELFTEST_TOTAL_SIZE      ((uint64_t)20 * VT_SELFTEST_PAGE_SIZE)
#define VT_SELFTEST_TABLE_NAME      "vtself"
#define VT_SELFTEST_NUM_BACKINGS    2

static const char *vt_selftest_backing_path[VT_SELFTEST_NUM_BACKINGS] = {
    "C:\\Users\\Ummite\\AppData\\Local\\Temp\\vt-self-a",
    "C:\\Users\\Ummite\\AppData\\Local\\Temp\\vt-self-b"
};

static const int vt_selftest_backing_priority[VT_SELFTEST_NUM_BACKINGS] = { 2, 1 };

static uint8_t vt_selftest_value(uint64_t i)
{
    return (uint8_t)(i * 31u + 7u);
}

/* Only called on success: vt_destroy() has already closed the FILE handles, so
   the files can be removed. Both part indexes are tried for each prefix. */
static void vt_selftest_remove_backings(void)
{
    char path[1024];
    int p, k;

    for (p = 0; p < VT_SELFTEST_NUM_BACKINGS; p++) {
        for (k = 0; k < VT_SELFTEST_NUM_BACKINGS; k++) {
            snprintf(path, sizeof(path), "%s.%s.part%d",
                     vt_selftest_backing_path[p], VT_SELFTEST_TABLE_NAME, k);
            remove(path);
        }
    }
}

int main(void)
{
    VTBackingStore backings[VT_SELFTEST_NUM_BACKINGS];
    VTConfig config;
    VirtualTable *vt;
    uint64_t offset;
    uint64_t cross_offset;
    uint16_t expected16;
    uint16_t got16;

    backings[0].path     = vt_selftest_backing_path[0];
    backings[0].type     = VT_BACKING_FILE;
    backings[0].priority = vt_selftest_backing_priority[0];
    backings[0].max_size = 0;

    backings[1].path     = vt_selftest_backing_path[1];
    backings[1].type     = VT_BACKING_FILE;
    backings[1].priority = vt_selftest_backing_priority[1];
    backings[1].max_size = 0;

    config.total_size         = VT_SELFTEST_TOTAL_SIZE;
    config.cache_size         = VT_SELFTEST_CACHE_SIZE;
    config.reserve_gb         = 0;
    config.backings           = backings;
    config.num_backings       = VT_SELFTEST_NUM_BACKINGS;
    config.use_memory_mapping = 0;
    config.enable_prefetch    = 0;
    config.page_size_shift    = VT_SELFTEST_PAGE_SIZE_SHIFT;

    vt = vt_create(&config, VT_SELFTEST_TABLE_NAME);
    if (!vt) {
        printf("VT SELFTEST FAIL create\n");
        return 1;
    }

    /* The prototype never hands out a raw pointer. */
    if (vt_get_raw_pointer_for_testing(vt) != NULL) {
        printf("VT SELFTEST FAIL raw\n");
        vt_destroy(vt);
        return 1;
    }

    /* Byte by byte on purpose: no 20 MiB scratch buffer, and it walks every
       page so the cache has to evict and refill. */
    for (offset = 0; offset < VT_SELFTEST_TOTAL_SIZE; offset++)
        vt_write_u8(vt, offset, vt_selftest_value(offset));

    /* Covers page 0 (hash key 0), cache hits on the still resident pages and
       pages that were evicted and must come back from the backing store. */
    for (offset = 0; offset < VT_SELFTEST_TOTAL_SIZE; offset++) {
        uint8_t expected = vt_selftest_value(offset);
        uint8_t got = vt_read_u8(vt, offset);

        if (got != expected) {
            printf("VT SELFTEST FAIL read offset=%llu got=%u exp=%u\n",
                   (unsigned long long)offset, (unsigned)got, (unsigned)expected);
            vt_destroy(vt);
            return 1;
        }
    }

    /* u16 written across the page 0 / page 1 boundary: two u8 writes, two pages. */
    expected16    = 0xBEEFu;
    cross_offset  = (uint64_t)VT_SELFTEST_PAGE_SIZE - 1u;
    vt_write_u16(vt, cross_offset, expected16);
    got16 = vt_read_u16(vt, cross_offset);
    if (got16 != expected16) {
        printf("VT SELFTEST FAIL cross\n");
        vt_destroy(vt);
        return 1;
    }

    vt_prefetch_range(vt, 0, (uint64_t)2 * VT_SELFTEST_PAGE_SIZE);

    if (vt_flush(vt) != 0) {
        printf("VT SELFTEST FAIL flush\n");
        vt_destroy(vt);
        return 1;
    }

    vt_destroy(vt);

    printf("VT SELFTEST OK\n");

    /* Backing files are kept as-is when a step failed, for inspection. */
    vt_selftest_remove_backings();

    return 0;
}
