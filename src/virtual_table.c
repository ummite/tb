/*
  Basic implementation skeleton for VirtualTable.

  This is a first working prototype focused on:
  - Large RAM cache
  - Multiple backing stores (local disk + SAN)
  - Range prefetch notification
  - Simple page-based caching

  Not yet optimized. Goal is to get something that compiles and can be tested on 5pc/6pc first.
*/

#include "virtual_table.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <sys/mman.h>
#include <unistd.h>
#include <fcntl.h>
#endif

struct VirtualTable {
    VTConfig config;
    char table_name[256];

    size_t page_size;
    size_t page_mask;
    uint64_t num_pages;

    /* === Bounded cache (critical fix for 7pc) ===
       We no longer allocate a giant dense array of size num_pages.
       Instead we keep only a small number of resident pages in RAM.
       This array size is proportional to cache_size, not to total table size.
    */
    uint32_t max_resident_pages;   /* bounded by cache_size */
    uint32_t num_resident;         /* currently in cache */

    /* Resident pages + their metadata (sparse) */
    uint8_t **resident_pages;      /* [max_resident_pages] */
    uint64_t *resident_page_idx;   /* which global page number is here */
    uint8_t  *dirty;               /* bitfield sized to max_resident_pages */

    /* Backing files (one per backing store for now - simplistic) */
    FILE **backing_files;

    VTStats stats;
};

/* Improved creation with better multi-backing support */
VirtualTable *vt_create(const VTConfig *config, const char *table_name)
{
    if (!config || config->num_backings <= 0) return NULL;

    VirtualTable *vt = (VirtualTable *)calloc(1, sizeof(VirtualTable));
    if (!vt) return NULL;

    strncpy(vt->table_name, table_name ? table_name : "virtual", sizeof(vt->table_name)-1);

    vt->config = *config;
    vt->page_size = (size_t)1 << (config->page_size_shift ? config->page_size_shift : 20); /* 1MB default */
    vt->page_mask = vt->page_size - 1;
    vt->num_pages = (config->total_size + vt->page_size - 1) / vt->page_size;

    /* Bounded cache allocation (key fix) */
    vt->max_resident_pages = (uint32_t)((config->cache_size > 0 ? config->cache_size : (256ULL * 1024 * 1024)) / vt->page_size);
    if (vt->max_resident_pages < 16) vt->max_resident_pages = 16;   /* minimum sanity */
    if (vt->max_resident_pages > 65536) vt->max_resident_pages = 65536; /* cap for prototype */

    vt->resident_pages    = (uint8_t **)calloc(vt->max_resident_pages, sizeof(uint8_t *));
    vt->resident_page_idx = (uint64_t *)calloc(vt->max_resident_pages, sizeof(uint64_t));
    vt->dirty             = (uint8_t *) calloc((vt->max_resident_pages + 7) / 8, 1);
    vt->num_resident      = 0;

    if (!vt->resident_pages || !vt->resident_page_idx || !vt->dirty) {
        vt_destroy(vt);
        return NULL;
    }

    /* Open backing files for each store. We keep them sorted by priority (highest first) */
    vt->backing_files = (FILE **)calloc(config->num_backings, sizeof(FILE *));

    /* For simplicity in prototype we just open all of them.
       Later we can sort by priority and use the fastest for reads, primary for writes. */
    for (int i = 0; i < config->num_backings; i++) {
        char path[1024];
        snprintf(path, sizeof(path), "%s.%s.part%d", config->backings[i].path, table_name, i);

        FILE *f = fopen(path, "r+b");
        if (!f) {
            /* Try to create it */
            f = fopen(path, "w+b");
        }

        if (f) {
            /* Ensure file is big enough (sparse) */
            fseek(f, 0, SEEK_END);
            if (ftell(f) < (long long)config->total_size) {
                fseek(f, (long long)config->total_size - 1, SEEK_SET);
                fputc(0, f);
            }
            rewind(f);
            vt->backing_files[i] = f;
        } else {
            fprintf(stderr, "Warning: could not open/create backing %s\n", path);
        }
    }

    /* Sort backing_files by priority (simple bubble for small number) */
    /* For now we assume the caller already passed them in priority order (fastest first) */

    return vt;
}

void vt_destroy(VirtualTable *vt)
{
    if (!vt) return;

    if (vt->backing_files) {
        for (int i = 0; i < vt->config.num_backings; i++) {
            if (vt->backing_files[i]) fclose(vt->backing_files[i]);
        }
        free(vt->backing_files);
    }

    if (vt->resident_pages) {
        for (uint32_t i = 0; i < vt->max_resident_pages; i++) {
            free(vt->resident_pages[i]);
        }
        free(vt->resident_pages);
    }
    free(vt->resident_page_idx);
    free(vt->dirty);
    free(vt);
}

/* Bounded resident page cache lookup (prototype - linear search for simplicity) */
static uint8_t *vt_get_page(VirtualTable *vt, uint64_t page)
{
    if (page >= vt->num_pages) return NULL;

    /* Search if already resident */
    for (uint32_t i = 0; i < vt->num_resident; i++) {
        if (vt->resident_page_idx[i] == page) {
            vt->stats.cache_hits++;
            return vt->resident_pages[i];
        }
    }

    /* Miss: allocate a new resident slot (very naive eviction for prototype) */
    uint32_t slot;
    if (vt->num_resident < vt->max_resident_pages) {
        slot = vt->num_resident++;
    } else {
        /* Prototype eviction: just reuse slot 0 (real LRU/Clock later) */
        slot = 0;
        if (vt->dirty[0 / 8] & (1u << (0 % 8))) {
            /* flush dirty page before reuse */
            if (vt->backing_files[0] && vt->resident_pages[0]) {
                fseek(vt->backing_files[0], (long long)vt->resident_page_idx[0] * vt->page_size, SEEK_SET);
                fwrite(vt->resident_pages[0], 1, vt->page_size, vt->backing_files[0]);
            }
            vt->dirty[0 / 8] &= ~(1u << (0 % 8));
        }
    }

    if (!vt->resident_pages[slot]) {
        vt->resident_pages[slot] = (uint8_t *)malloc(vt->page_size);
        if (!vt->resident_pages[slot]) {
            fprintf(stderr, "VirtualTable: failed to allocate cache page\n");
            return NULL;
        }
    }

    /* Load content */
    if (vt->backing_files[0]) {
        fseek(vt->backing_files[0], (long long)page * vt->page_size, SEEK_SET);
        fread(vt->resident_pages[slot], 1, vt->page_size, vt->backing_files[0]);
        vt->stats.bytes_read_from_backing += vt->page_size;
    } else {
        memset(vt->resident_pages[slot], 0, vt->page_size);
    }

    vt->resident_page_idx[slot] = page;
    vt->stats.cache_misses++;
    return vt->resident_pages[slot];
}

uint8_t vt_read_u8(VirtualTable *vt, uint64_t offset)
{
    uint64_t page = offset / vt->page_size;
    uint64_t off  = offset & vt->page_mask;
    uint8_t *p = vt_get_page(vt, page);
    if (!p) return 0;
    return p[off];
}

void vt_write_u8(VirtualTable *vt, uint64_t offset, uint8_t value)
{
    uint64_t page = offset / vt->page_size;
    uint64_t off  = offset & vt->page_mask;
    uint8_t *p = vt_get_page(vt, page);
    if (!p) return;

    p[off] = value;

    /* Mark the correct resident slot dirty (search for slot - prototype) */
    for (uint32_t i = 0; i < vt->num_resident; i++) {
        if (vt->resident_page_idx[i] == page) {
            vt->dirty[i / 8] |= (1u << (i % 8));
            break;
        }
    }
    vt->stats.bytes_written_to_backing++; /* rough */
}

uint16_t vt_read_u16(VirtualTable *vt, uint64_t offset)
{
    /* Little endian assumption */
    uint16_t lo = vt_read_u8(vt, offset);
    uint16_t hi = vt_read_u8(vt, offset + 1);
    return lo | (hi << 8);
}

void vt_write_u16(VirtualTable *vt, uint64_t offset, uint16_t value)
{
    vt_write_u8(vt, offset,     (uint8_t)(value & 0xFF));
    vt_write_u8(vt, offset + 1, (uint8_t)(value >> 8));
}

void vt_prefetch_range(VirtualTable *vt, uint64_t begin, uint64_t end)
{
    /* For the prototype: just make sure the pages are in cache */
    uint64_t start_page = begin / vt->page_size;
    uint64_t end_page   = (end + vt->page_size - 1) / vt->page_size;

    for (uint64_t p = start_page; p < end_page && p < vt->num_pages; p++) {
        (void)vt_get_page(vt, p);   /* will load if missing */
    }
}

int vt_flush(VirtualTable *vt)
{
    if (!vt || !vt->backing_files[0]) return -1;

    /* Only flush currently resident pages (bounded) */
    for (uint32_t i = 0; i < vt->num_resident; i++) {
        if (vt->dirty[i / 8] & (1u << (i % 8))) {
            if (vt->resident_pages[i] && vt->backing_files[0]) {
                fseek(vt->backing_files[0], (long long)vt->resident_page_idx[i] * vt->page_size, SEEK_SET);
                fwrite(vt->resident_pages[i], 1, vt->page_size, vt->backing_files[0]);
            }
            vt->dirty[i / 8] &= ~(1u << (i % 8));
        }
    }
    fflush(vt->backing_files[0]);
    return 0;
}

void vt_get_stats(VirtualTable *vt, VTStats *out)
{
    if (vt && out) *out = vt->stats;
}

void vt_reset_stats(VirtualTable *vt)
{
    if (vt) memset(&vt->stats, 0, sizeof(vt->stats));
}

uint8_t *vt_get_raw_pointer_for_testing(VirtualTable *vt)
{
    /* Not supported in this basic version */
    return NULL;
}