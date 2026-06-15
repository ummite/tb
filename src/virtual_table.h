/*
  Virtual Table abstraction for Syzygy 7pc generation.

  Goal:
  - Allow the huge position tables (table_w / table_b) to live primarily on disk / SAN / remote RAM.
  - Provide a large in-RAM cache (using most of the machine's available memory).
  - Support multiple backing stores with different speeds (local fast NVMe + SAN, etc.).
  - Enable range-based prefetching when threads claim work ranges.
  - Later: support checkpointing by flushing dirty ranges.

  This is experimental and aimed at making 7pc generation feasible on machines
  that do not have hundreds of GB of RAM.
*/

#ifndef VIRTUAL_TABLE_H
#define VIRTUAL_TABLE_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct VirtualTable VirtualTable;

/* Backing store types */
typedef enum {
    VT_BACKING_FILE,      /* Regular file (local or SAN) */
    VT_BACKING_RAMDISK    /* RAM disk / remote memory exposed as a file */
} VTBackingType;

/* Description of one backing store */
typedef struct {
    const char *path;           /* Path or UNC path to the backing file/directory */
    VTBackingType type;
    int priority;               /* Higher = faster / preferred (0 = slowest) */
    uint64_t max_size;          /* 0 = unlimited */
} VTBackingStore;

/* Configuration for the Virtual Table */
typedef struct {
    uint64_t total_size;                    /* Size of the virtual table in bytes */
    size_t cache_size;                      /* How much RAM to use for cache (0 = auto: all RAM - reserve_gb) */
    size_t reserve_gb;                      /* When cache_size==0, leave this much RAM for the OS/other things */
    VTBackingStore *backings;               /* Array of backing stores */
    int num_backings;
    int use_memory_mapping;                 /* Try to use mmap / file mapping when possible */
    int enable_prefetch;                    /* Enable automatic prefetching of work ranges */
    int page_size_shift;                    /* log2 of cache page size (default 20 = 1MB) */
} VTConfig;

/* Create / destroy */
VirtualTable *vt_create(const VTConfig *config, const char *table_name /* for filenames */);
void vt_destroy(VirtualTable *vt);

/* Core access (these will be the hot path - should be very fast when cached) */
uint8_t  vt_read_u8 (VirtualTable *vt, uint64_t offset);
void     vt_write_u8(VirtualTable *vt, uint64_t offset, uint8_t value);

/* For 16-bit tables (DTZ wide case) */
uint16_t vt_read_u16 (VirtualTable *vt, uint64_t offset);
void     vt_write_u16(VirtualTable *vt, uint64_t offset, uint16_t value);

/* Notify that a thread is about to work on [begin, end) */
void vt_prefetch_range(VirtualTable *vt, uint64_t begin, uint64_t end);

/* Flush all dirty data to backing stores (for checkpointing) */
int vt_flush(VirtualTable *vt);

/* Statistics */
typedef struct {
    uint64_t cache_hits;
    uint64_t cache_misses;
    uint64_t bytes_read_from_backing;
    uint64_t bytes_written_to_backing;
    uint64_t evictions;
} VTStats;

void vt_get_stats(VirtualTable *vt, VTStats *out);
void vt_reset_stats(VirtualTable *vt);

/* For integration with existing code that expects a raw pointer (temporary / testing only) */
uint8_t *vt_get_raw_pointer_for_testing(VirtualTable *vt); /* May return NULL if not fully in RAM */

/* Note on 8pc usage:
   The generator (tbgenp.c for pawnful 8pc like KPPPPPPvK) will allocate the
   main analysis table (table_w/table_b) via vt_create when numpcs>=8 or
   use_disk is requested. Calls to vt_prefetch_range() will be inserted when
   work ranges are claimed (see run_threaded / pawn slice code).
   Physical RAM is bounded by VTConfig.cache_size; the rest lives on the
   configured backings (fast local + large SAN for capacity = "more disk").
   Multiple machines can share the same backing files for distributed compute
   (each with its own cache), coordinated by pawn-file (0-3) or work ID sharding. */

#ifdef __cplusplus
}
#endif

#endif /* VIRTUAL_TABLE_H */