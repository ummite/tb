#ifndef UTIL_H
#define UTIL_H

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#endif

#ifdef _WIN32
typedef HANDLE map_t;
typedef HANDLE FD;
#define FD_ERR INVALID_HANDLE_VALUE
#define SEP_CHAR ';'

#else
typedef size_t map_t;
typedef int FD;
#define FD_ERR -1
#define SEP_CHAR ':'

#endif

#undef min
#define min(a,b) ((a) < (b) ? (a) : (b))

FD open_file(const char *name);
void close_file(FD fd);

size_t file_size(FD fd);

void *map_file(FD fd, int shared, map_t *map);
void unmap_file(void *data, map_t map);

void *alloc_aligned(uint64_t size, uintptr_t alignment);
void *alloc_huge(uint64_t size);

/* Disk-backed (memory mapped) allocation for huge tables to keep RAM low.
   When use_disk is true, creates a temp file on disk and maps it.
   The caller must call free_mapped_table (or equivalent unmap + unlink) at end.
   handle_out is for the OS mapping handle (map_t on Unix, HANDLE on Win). */
void *alloc_mapped(uint64_t size, int use_disk, const char *basename, void **handle_out);
void free_mapped(void *ptr, void *handle, int use_disk, const char *basename);

void write_u32(FILE *F, uint32_t v);
void write_u16(FILE *F, uint16_t v);
void write_u8(FILE *F, uint8_t v);

void write_bits(FILE *F, uint32_t bits, int n);

void copy_data(FILE *F, FILE *G, uint64_t num);
void write_data(FILE *F, uint8_t *src, uint64_t offset, uint64_t size,
    uint8_t *v);
void read_data_u8(FILE *F, uint8_t *dst, uint64_t size, uint8_t *v);
void read_data_u16(FILE *F, uint16_t *dst, uint64_t size, uint16_t *v);

/* Syzygy material ID validation (canonical orientation + piece order).
   Returns 0 if name is a legal, official-style tablebase ID; non-zero otherwise.
   On failure, prints a reason to stderr. Accepts optional path prefixes
   (uses the basename after the last '/' or '\\'). */
int validate_tablename(const char *name);

#endif
