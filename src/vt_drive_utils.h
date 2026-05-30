/*
  Drive discovery and benchmarking utilities for VirtualTable backing stores.

  Goals:
  - Enumerate local fixed drives (C:, D:, etc.) with free space.
  - Run quick sequential benchmarks to rank drive speed.
  - Query physical RAM (total + available).
  - Help the user choose good locations for swap files (local fast disks + SAN).
*/

#ifndef VT_DRIVE_UTILS_H
#define VT_DRIVE_UTILS_H

#include <stdint.h>
#include <stddef.h>

#ifdef _WIN32
#include <windows.h>
#endif

typedef struct {
    char letter;           /* e.g. 'C', 'D', 'S', 'T' */
    char root[4];          /* "C:\\" etc. */
    uint64_t total_bytes;
    uint64_t free_bytes;
    int is_fixed;          /* 1 if DRIVE_FIXED */
    int is_network;        /* 1 if DRIVE_REMOTE */
} DriveInfo;

typedef struct {
    DriveInfo *drives;
    int count;
} DriveList;

/* RAM info */
typedef struct {
    uint64_t total_physical;
    uint64_t available_physical;
    uint64_t total_virtual;
    uint64_t available_virtual;
} RamInfo;

/* Enumerate all local drives (fixed + remote) */
DriveList *vt_enum_drives(void);
void vt_free_drive_list(DriveList *list);

/* Get current RAM situation */
int vt_get_ram_info(RamInfo *info);

/* Quick sequential benchmark on a drive root.
   Writes and reads 'test_size_bytes' using large buffers.
   Returns approximate MB/s for write and read (0 on failure).
*/
typedef struct {
    double write_mbs;
    double read_mbs;
    int success;
} DriveBenchmark;

DriveBenchmark vt_benchmark_drive(const char *root_path, uint64_t test_size_bytes);

/* Helper: print a nice summary of drives with benchmarks */
void vt_print_drive_summary(const DriveList *drives, const DriveBenchmark *benches);

#endif /* VT_DRIVE_UTILS_H */