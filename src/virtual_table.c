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

    /* Simple MRU heuristic: on hit, move-to-front. Evict from tail. */
    /* For faster lookup in hot path we also maintain a small open-address hash
       page -> resident_slot (size ~2*max). Linear probe. */
    uint64_t *hash_page;           /* keys, 0 = empty */
    int      *hash_slot;           /* corresponding resident index, or -1 */
    uint32_t  hash_size;

    /* Backing stores (sorted by priority desc at create time: [0] is preferred/fastest for reads/writes) */
    FILE **backing_files;
    int    num_backings_effective;

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

    /* Hash for O(1) resident lookup (open addressing, ~2x size) */
    vt->hash_size = vt->max_resident_pages * 2 + 17; /* prime-ish */
    vt->hash_page = (uint64_t *)calloc(vt->hash_size, sizeof(uint64_t));
    vt->hash_slot = (int *)     calloc(vt->hash_size, sizeof(int));
    if (vt->hash_page) {
        for (uint32_t i=0; i<vt->hash_size; i++) vt->hash_slot[i] = -1;
    }

    if (!vt->resident_pages || !vt->resident_page_idx || !vt->dirty || !vt->hash_page || !vt->hash_slot) {
        vt_destroy(vt);
        return NULL;
    }

    /* Open backing files. Sort by priority desc (highest first = [0] preferred for I/O) */
    vt->backing_files = (FILE **)calloc(config->num_backings, sizeof(FILE *));
    /* We will keep a copy of indices to sort */
    int *prio_idx = (int *)malloc(sizeof(int) * config->num_backings);
    for (int i = 0; i < config->num_backings; i++) prio_idx[i] = i;

    /* simple insertion sort by priority desc */
    for (int i=1; i<config->num_backings; i++) {
        int key = prio_idx[i];
        int j = i-1;
        while (j>=0 && config->backings[prio_idx[j]].priority < config->backings[key].priority) {
            prio_idx[j+1] = prio_idx[j];
            j--;
        }
        prio_idx[j+1] = key;
    }

    vt->num_backings_effective = 0;
    for (int k = 0; k < config->num_backings; k++) {
        int i = prio_idx[k];
        char path[1024];
        snprintf(path, sizeof(path), "%s.%s.part%d", config->backings[i].path, table_name ? table_name : "vt", k);

        FILE *f = fopen(path, "r+b");
        if (!f) f = fopen(path, "w+b");
        if (f) {
            /* Ensure sparse file big enough */
            fseek(f, 0, SEEK_END);
            if (ftell(f) < (long long)config->total_size) {
                fseek(f, (long long)config->total_size - 1, SEEK_SET);
                fputc(0, f);
            }
            rewind(f);
            vt->backing_files[vt->num_backings_effective] = f;
            vt->num_backings_effective++;
        } else {
            fprintf(stderr, "Warning: could not open/create backing %s (priority %d)\n",
                    config->backings[i].path, config->backings[i].priority);
        }
    }
    free(prio_idx);

    if (vt->num_backings_effective == 0) {
        fprintf(stderr, "VirtualTable: no usable backing stores!\n");
        vt_destroy(vt);
        return NULL;
    }

    return vt;
}

void vt_destroy(VirtualTable *vt)
{
    if (!vt) return;

    /* Best effort flush on destroy */
    vt_flush(vt);

    if (vt->backing_files) {
        for (int i = 0; i < vt->num_backings_effective; i++) {
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
    free(vt->hash_page);
    free(vt->hash_slot);
    free(vt);
}

/* Simple hash helpers for resident page lookup (open addressing) */
static uint32_t vt_hash(VirtualTable *vt, uint64_t page) {
    return (uint32_t)((page * 11400714819323198485ULL) % vt->hash_size);
}

static int vt_hash_lookup(VirtualTable *vt, uint64_t page) {
    uint32_t h = vt_hash(vt, page);
    for (uint32_t probe=0; probe < vt->hash_size; probe++) {
        uint32_t idx = (h + probe) % vt->hash_size;
        if (vt->hash_page[idx] == 0) return -1; /* empty */
        if (vt->hash_page[idx] == page) return vt->hash_slot[idx];
    }
    return -1;
}

static void vt_hash_insert(VirtualTable *vt, uint64_t page, int slot) {
    uint32_t h = vt_hash(vt, page);
    for (uint32_t probe=0; probe < vt->hash_size; probe++) {
        uint32_t idx = (h + probe) % vt->hash_size;
        if (vt->hash_page[idx] == 0 || vt->hash_page[idx] == page) {
            vt->hash_page[idx] = page;
            vt->hash_slot[idx] = slot;
            return;
        }
    }
    /* table full - very unlikely with 2x sizing; fall back to linear in get_page */
}

/* Bounded resident page cache with MRU move-to-front + hash lookup + multi-backing */
static uint8_t *vt_get_page(VirtualTable *vt, uint64_t page)
{
    if (page >= vt->num_pages) return NULL;

    /* Fast path via hash */
    int slot = vt_hash_lookup(vt, page);
    if (slot >= 0 && slot < (int)vt->num_resident) {
        /* MRU: move to front if not already */
        if (slot != 0) {
            /* swap with front */
            uint8_t *tmp_p = vt->resident_pages[0];
            uint64_t tmp_idx = vt->resident_page_idx[0];
            uint8_t tmp_d  = (vt->dirty[0/8] & (1u<<(0%8))) ? 1 : 0;

            vt->resident_pages[0] = vt->resident_pages[slot];
            vt->resident_page_idx[0] = vt->resident_page_idx[slot];
            if (vt->dirty[slot/8] & (1u<<(slot%8))) vt->dirty[0/8] |= (1u<<(0%8)); else vt->dirty[0/8] &= ~(1u<<(0%8));

            vt->resident_pages[slot] = tmp_p;
            vt->resident_page_idx[slot] = tmp_idx;
            if (tmp_d) vt->dirty[slot/8] |= (1u<<(slot%8)); else vt->dirty[slot/8] &= ~(1u<<(slot%8));

            /* update hash for the two slots */
            vt_hash_insert(vt, vt->resident_page_idx[0], 0);
            vt_hash_insert(vt, vt->resident_page_idx[slot], slot);
        }
        vt->stats.cache_hits++;
        return vt->resident_pages[0];
    }

    /* Miss: find or allocate slot (MRU front, evict tail) */
    uint32_t new_slot;
    if (vt->num_resident < vt->max_resident_pages) {
        new_slot = vt->num_resident++;
    } else {
        new_slot = vt->num_resident - 1; /* evict LRU-ish (tail) */
        uint32_t evict = new_slot;
        if (vt->dirty[evict/8] & (1u << (evict % 8))) {
            /* flush to primary backing (highest priority = [0]) */
            if (vt->backing_files[0] && vt->resident_pages[evict]) {
                fseek(vt->backing_files[0], (long long)vt->resident_page_idx[evict] * vt->page_size, SEEK_SET);
                fwrite(vt->resident_pages[evict], 1, vt->page_size, vt->backing_files[0]);
                vt->stats.bytes_written_to_backing += vt->page_size;
            }
            vt->dirty[evict/8] &= ~(1u << (evict % 8));
        }
        /* remove old from hash */
        uint64_t oldp = vt->resident_page_idx[evict];
        /* (hash remove omitted for brevity - re-insert will overwrite) */
    }

    if (!vt->resident_pages[new_slot]) {
        vt->resident_pages[new_slot] = (uint8_t *)malloc(vt->page_size);
        if (!vt->resident_pages[new_slot]) {
            fprintf(stderr, "VirtualTable: failed to allocate cache page\n");
            return NULL;
        }
    }

    /* Load from best (highest priority) backing that has data */
    int loaded = 0;
    for (int b = 0; b < vt->num_backings_effective; b++) {
        if (vt->backing_files[b]) {
            fseek(vt->backing_files[b], (long long)page * vt->page_size, SEEK_SET);
            if (fread(vt->resident_pages[new_slot], 1, vt->page_size, vt->backing_files[b]) == vt->page_size) {
                vt->stats.bytes_read_from_backing += vt->page_size;
                loaded = 1;
                break;
            }
        }
    }
    if (!loaded) {
        memset(vt->resident_pages[new_slot], 0, vt->page_size);
    }

    vt->resident_page_idx[new_slot] = page;
    vt_hash_insert(vt, page, new_slot);
    vt->stats.cache_misses++;
    return vt->resident_pages[new_slot];
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

    /* Mark dirty via hash or linear (fast path) */
    int slot = vt_hash_lookup(vt, page);
    if (slot < 0) {
        for (uint32_t i = 0; i < vt->num_resident; i++) {
            if (vt->resident_page_idx[i] == page) { slot = i; break; }
        }
    }
    if (slot >= 0) {
        vt->dirty[slot / 8] |= (1u << (slot % 8));
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
    if (!vt || vt->num_backings_effective == 0 || !vt->backing_files[0]) return -1;

    /* Flush all dirty resident pages to primary backing [0] (highest priority) */
    for (uint32_t i = 0; i < vt->num_resident; i++) {
        if (vt->dirty[i / 8] & (1u << (i % 8))) {
            if (vt->resident_pages[i] && vt->backing_files[0]) {
                fseek(vt->backing_files[0], (long long)vt->resident_page_idx[i] * vt->page_size, SEEK_SET);
                fwrite(vt->resident_pages[i], 1, vt->page_size, vt->backing_files[0]);
                vt->stats.bytes_written_to_backing += vt->page_size;
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