/*
  Copyright (c) 2011-2013, 2018, 2024, 2025 Ronald de Man

  This file is distributed under the terms of the GNU GPL, version 2.
*/

#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#ifndef _WIN32
#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <sys/time.h>
#else
#include "wincompat.h"
#endif

#ifdef USE_ZSTD
#ifdef _WIN32
#include <zstd/zstd.h>
#else
#include <zstd.h>
#endif
#else
#include "lz4.h"
#endif

#include "defs.h"
#include "threads.h"
#include "util.h"

FD open_file(const char *name)
{
#ifndef _WIN32
  return open(name, O_RDONLY);
#else
  return CreateFile(name, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING,
      FILE_FLAG_RANDOM_ACCESS, NULL);
#endif
}

void close_file(FD fd)
{
#ifndef _WIN32
  close(fd);
#else
  CloseHandle(fd);
#endif
}

size_t file_size(FD fd)
{
#ifndef _WIN32
  struct stat statbuf;
  fstat(fd, &statbuf);
  return statbuf.st_size;
#else
  DWORD sizeLow, sizeHigh;
  sizeLow = GetFileSize(fd, &sizeHigh);
  return ((uint64_t)sizeHigh << 32) | sizeLow;
#endif
}

void *map_file(FD fd, int shared, map_t *map)
{
#ifndef _WIN32
  *map = file_size(fd);
#ifdef __linux__
  void *data = mmap(NULL, *map, PROT_READ,
      shared ? MAP_SHARED : MAP_PRIVATE | MAP_POPULATE, fd, 0);
#else
  void *data = mmap(NULL, *map, PROT_READ, MAP_SHARED, fd, 0);
#endif
#ifdef MADV_RANDOM
  madvise(data, *map, MADV_RANDOM);
#endif
  if (data == MAP_FAILED) {
    fprintf(stderr, "mmap() failed.\n");
    exit(EXIT_FAILURE);
  }
  return data;

#else
  DWORD sizeLow, sizeHigh;
  sizeLow = GetFileSize(fd, &sizeHigh);
  *map = CreateFileMapping(fd, NULL, PAGE_READONLY, sizeHigh, sizeLow, NULL);
  if (*map == NULL) {
    fprintf(stderr, "CreateFileMapping() failed.\n");
    exit(EXIT_FAILURE);
  }
  return MapViewOfFile(*map, FILE_MAP_READ, 0, 0, 0);

#endif
}

void unmap_file(void *data, map_t map)
{
  if (!data) return;

#ifndef _WIN32
  munmap((void *)data, map);

#else
  UnmapViewOfFile(data);
  CloseHandle(map);

#endif
}

void *alloc_aligned(uint64_t size, uintptr_t alignment)
{
  void *ptr;

#ifndef _WIN32
  posix_memalign(&ptr, alignment, size);
  if (ptr == NULL) {
    fprintf(stderr, "Could not allocate sufficient memory.\n");
    exit(EXIT_FAILURE);
  }

#else
  unsigned char *tmp;
  ptr = malloc(size + alignment - 1);
  if (ptr == NULL) {
    fprintf(stderr, "Could not allocate sufficient memory.\n");
    exit(EXIT_FAILURE);
  }
  tmp = (unsigned char *)ptr + alignment - 1;
  tmp = tmp - (size_t)tmp % alignment;
  ptr = (void *)tmp;

#endif

  return ptr;
}

void *alloc_huge(uint64_t size)
{
  void *ptr;

#ifndef _WIN32

  posix_memalign(&ptr, 2 * 1024 * 1024, size);
  if (ptr == NULL) {
    fprintf(stderr, "Could not allocate sufficient memory.\n");
    exit(EXIT_FAILURE);
  }
#ifdef MADV_HUGEPAGE
  madvise(ptr, size, MADV_HUGEPAGE);
#endif

#else
  /* Windows (VS2026): Safe path for 5-piece completion.
     Large pages temporarily disabled for stability during 5pc generation
     (was causing Access Violations on some pawnful tables with -d).
     Re-enable for 6/7pc once the root cause is fixed. */
  size_t align = 2 * 1024 * 1024;
  unsigned char *tmp;
  ptr = malloc(size + align - 1);
  if (ptr == NULL) {
    fprintf(stderr, "Could not allocate sufficient memory.\n");
    exit(EXIT_FAILURE);
  }
  tmp = (unsigned char *)ptr + align - 1;
  tmp = tmp - (size_t)tmp % align;
  ptr = (void *)tmp;

#endif

  return ptr;
}

/* Create a disk-backed mapping for a huge table when we want to use disk
   instead of physical RAM. The returned pointer can be used exactly like
   a normal malloc'ed buffer (table[idx] = ...).
   On success returns the mapped address, *handle_out receives the mapping object.
   If !use_disk, falls back to alloc_huge (for small cases).
   basename can be used to derive a temp filename (e.g. tablename).
*/
void *alloc_mapped(uint64_t size, int use_disk, const char *basename, void **handle_out)
{
  if (!use_disk || size < (1ULL << 30)) {  /* < 1GB: just use normal */
    *handle_out = NULL;
    return alloc_huge(size);
  }

  char tmpname[128];
  static int tmp_counter = 0;
  if (basename && *basename)
    sprintf(tmpname, "%s.tmp%d.table", basename, tmp_counter++);
  else
    sprintf(tmpname, "syzygy8tmp.%d.table", tmp_counter++);

#ifndef _WIN32
  int fd = open(tmpname, O_RDWR | O_CREAT | O_TRUNC, 0666);
  if (fd < 0) {
    perror("open temp table file");
    fprintf(stderr, "Could not create disk backing for table (%s). Try with more free disk space.\n", tmpname);
    exit(EXIT_FAILURE);
  }
  if (ftruncate(fd, size) != 0) {
    perror("ftruncate for table");
    close(fd);
    unlink(tmpname);
    exit(EXIT_FAILURE);
  }
  void *data = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
  close(fd);
  if (data == MAP_FAILED) {
    fprintf(stderr, "mmap of disk-backed table failed (%s).\n", tmpname);
    unlink(tmpname);
    exit(EXIT_FAILURE);
  }
#ifdef MADV_RANDOM
  madvise(data, size, MADV_RANDOM);  /* generation access is mostly random */
#endif
  *handle_out = (void *)(uintptr_t)size;  /* store size for unmap */
  unlink(tmpname);  /* remove dir entry; mapping keeps data until munmap */
  return data;
#else
  /* Windows: use FILE_FLAG_DELETE_ON_CLOSE so the file disappears when last handle closes */
  HANDLE hfile = CreateFile(tmpname, GENERIC_READ | GENERIC_WRITE,
      0, NULL, CREATE_ALWAYS,
      FILE_ATTRIBUTE_TEMPORARY | FILE_FLAG_DELETE_ON_CLOSE | FILE_FLAG_RANDOM_ACCESS,
      NULL);
  if (hfile == INVALID_HANDLE_VALUE) {
    fprintf(stderr, "CreateFile for disk table failed (need ~50TB free on current drive for 8pc).\n");
    exit(EXIT_FAILURE);
  }
  LARGE_INTEGER li;
  li.QuadPart = size;
  SetFilePointerEx(hfile, li, NULL, FILE_BEGIN);
  if (!SetEndOfFile(hfile)) {
    fprintf(stderr, "SetEndOfFile failed for disk-backed table (you need ~50 TiB free disk space on the current drive for a full 8pc pawnful table like KPPPPPPvK).\n");
    fprintf(stderr, "Run the generator from a directory on your large NAS/drive, or ensure sufficient free space. More CPU time will be used due to disk I/O.\n");
    CloseHandle(hfile);
    exit(EXIT_FAILURE);
  }
  HANDLE hmap = CreateFileMapping(hfile, NULL, PAGE_READWRITE,
      (DWORD)(size >> 32), (DWORD)size, NULL);
  if (!hmap) {
    fprintf(stderr, "CreateFileMapping RW for table failed.\n");
    CloseHandle(hfile);
    exit(EXIT_FAILURE);
  }
  void *data = MapViewOfFile(hmap, FILE_MAP_ALL_ACCESS, 0, 0, 0);
  /* We can close hfile here; the mapping keeps it alive. hmap kept in handle_out */
  CloseHandle(hfile);
  if (!data) {
    fprintf(stderr, "MapViewOfFile failed for disk table.\n");
    CloseHandle(hmap);
    exit(EXIT_FAILURE);
  }
  *handle_out = hmap;
  return data;
#endif
}

void free_mapped(void *ptr, void *handle, int use_disk, const char *basename)
{
  if (!ptr) return;
  if (!use_disk || !handle) {
    /* was normal alloc_huge - we don't free here (the generators free or reuse) */
    return;
  }

#ifndef _WIN32
  size_t sz = (size_t)handle;
  munmap(ptr, sz);
  /* basename not really needed; file will be unlinked by caller or left as .tmp if wanted */
#else
  UnmapViewOfFile(ptr);
  CloseHandle((HANDLE)handle);
  /* With DELETE_ON_CLOSE the file is auto-deleted */
#endif
}

void write_u32(FILE *F, uint32_t v)
{
  fputc(v & 0xff, F);
  fputc((v >> 8) & 0xff, F);
  fputc((v >> 16) & 0xff, F);
  fputc((v >> 24) & 0xff, F);
}

void write_u16(FILE *F, uint16_t v)
{
  fputc(v & 0xff, F);
  fputc((v >> 8) & 0xff, F);
}

void write_u8(FILE *F, uint8_t v)
{
  fputc(v, F);
}

static uint8_t buf[8192];

void write_bits(FILE *F, uint32_t bits, int n)
{
  static int numBytes, numBits;

  if (n > 0) {
    if (numBits) {
      if (numBits >= n) {
	buf[numBytes - 1] |= (bits << (numBits - n));
	numBits -= n;
	n = 0;
      } else {
	buf[numBytes - 1] |= (bits >> (n - numBits));
	n -= numBits;
	numBits = 0;
      }
    }
    while (n >= 8) {
      buf[numBytes++] = bits >> (n - 8);
      n -= 8;
    }
    if (n > 0) {
      buf[numBytes++] = bits << (8 - n);
      numBits = 8 - n;
    }
  } else if (n == 0) {
    numBytes = 0;
    numBits = 0;
  } else if (n < 0) {
    n = -n;
    while (numBytes < n)
      buf[numBytes++] = 0;
    fwrite(buf, 1, n, F);
    numBytes = 0;
    numBits = 0;
  }
}

#define COPYSIZE (10*1024*1024)

static size_t compress_bound;

static LOCK_T cmprs_mutex;

static FILE *cmprs_F;
static void *cmprs_ptr;
static size_t cmprs_size;
static void *cmprs_v;
static size_t cmprs_idx;

struct CompressFrame {
  uint32_t cmprs_chunk;
  uint32_t chunk;
  size_t idx;
  uint8_t data[];
};

#define HEADER_SIZE offsetof(struct CompressFrame, data)

struct CompressState {
  uint8_t *buffer;
  struct CompressFrame *frame;
#ifdef USE_ZSTD
  ZSTD_CCtx *c_ctx;
  ZSTD_DCtx *d_ctx;
#endif
};

static struct CompressState cmprs_state[COMPRESSION_THREADS];

static void init(void)
{
  static int initialised = 0;

  if (!initialised) {
    initialised = 1;
    LOCK_INIT(cmprs_mutex);
#ifdef USE_ZSTD
    compress_bound = ZSTD_compressBound(COPYSIZE);
#else
    compress_bound = LZ4_compressBound(COPYSIZE);
#endif
    for (int i = 0; i < COMPRESSION_THREADS; i++) {
      cmprs_state[i].buffer = malloc(COPYSIZE);
      cmprs_state[i].frame = malloc(HEADER_SIZE + compress_bound);
#ifdef USE_ZSTD
      cmprs_state[i].c_ctx = ZSTD_createCCtx();
      cmprs_state[i].d_ctx = ZSTD_createDCtx();
#endif
    }
    create_compression_threads();
  }
}

static void file_read(void *ptr, size_t size, FILE *F)
{
  if (fread(ptr, 1, size, F) != size) {
    fprintf(stderr, "Error reading data from disk.\n");
    exit(EXIT_FAILURE);
  }
}

static void file_write(void *ptr, size_t size, FILE *F)
{
  if (fwrite(ptr, 1, size, F) != size) {
    fprintf(stderr, "Error writing data to disk.\n");
    exit(EXIT_FAILURE);
  }
}

#ifdef USE_ZSTD

static size_t compress(struct CompressState *state, void *dst, void *src,
    size_t chunk)
{
  return ZSTD_compressCCtx(state->c_ctx, dst, compress_bound, src, chunk,
      ZSTD_LEVEL);
}

static void decompress(struct CompressState *state, void *dst, size_t chunk,
    void *src, size_t compressed)
{
  ZSTD_decompressDCtx(state->d_ctx, dst, chunk, src, compressed);
}

#else

static size_t compress(struct CompressState *state, void *dst, void *src,
    size_t chunk)
{
  (void)state;
  return LZ4_compress(src, dst, chunk);
}

static void decompress(struct CompressState *state, void *dst, size_t chunk,
    void *src, size_t compressed)
{
  (void)state;
  (void)compressed;
  LZ4_uncompress(src, dst, chunk);
}

#endif

void copy_data(FILE *F, FILE *G, uint64_t size)
{
  init();

  uint8_t *buffer = cmprs_state[0].buffer;

  while (size) {
    uint32_t chunk = min(COPYSIZE, size);
    file_read(buffer, chunk, G);
    file_write(buffer, chunk, F);
    size -= chunk;
  }
}

static void write_data_worker(int t)
{
  struct CompressState *state = &cmprs_state[t];

  FILE *F = cmprs_F;
  uint8_t *src = cmprs_ptr;
  uint8_t *v = cmprs_v;
  while (1) {
    LOCK(cmprs_mutex);
    size_t idx = cmprs_idx;
    uint32_t chunk = min(COPYSIZE, cmprs_size - idx);
    cmprs_idx += chunk;
    UNLOCK(cmprs_mutex);
    if (chunk == 0)
      break;
    uint8_t *buf;
    if (v) {
      for (size_t i = 0; i < chunk; i++)
        state->buffer[i] = v[src[idx + i]];
      buf = state->buffer;
    } else
      buf = src + idx;
    uint32_t cmprs_chunk = compress(state, state->frame->data, buf, chunk);
    state->frame->cmprs_chunk = cmprs_chunk;
    state->frame->chunk = chunk;
    state->frame->idx = idx;
    file_write(state->frame, cmprs_chunk + HEADER_SIZE, F);
  }
}

void write_data(FILE *F, uint8_t *src, uint64_t offset, uint64_t size,
    uint8_t *v)
{
  init();

  cmprs_F = F;
  cmprs_ptr = src;
  cmprs_size = offset + size;
  cmprs_v = v;
  cmprs_idx = offset;
  run_compression(write_data_worker);
}

static void read_data_worker_u8(int t)
{
  struct CompressState *state = &cmprs_state[t];

  FILE *F = cmprs_F;
  uint8_t *dst = cmprs_ptr;
  uint8_t *v = cmprs_v;
  while (1) {
    uint32_t cmprs_chunk;
    LOCK(cmprs_mutex);
    if (cmprs_size == 0) {
      UNLOCK(cmprs_mutex);
      break;
    }
    file_read(&cmprs_chunk, 4, F);
    file_read(&state->frame->chunk, cmprs_chunk + HEADER_SIZE - 4, F);
    uint32_t chunk = state->frame->chunk;
    if (chunk > cmprs_size) {
      fprintf(stderr, "Error in read_data_worker.\n");
      exit(EXIT_FAILURE);
    }
    cmprs_size -= chunk;
    UNLOCK(cmprs_mutex);
    size_t idx = state->frame->idx;
    if (!v)
      decompress(state, dst + idx, chunk, state->frame->data, cmprs_chunk);
    else {
      decompress(state, state->buffer, chunk, state->frame->data, cmprs_chunk);
      for (size_t i = 0; i < chunk; i++)
        dst[idx + i] |= v[state->buffer[i]];
    }
  }
}

void read_data_u8(FILE *F, uint8_t *dst, uint64_t size, uint8_t *v)
{
  init();

  cmprs_F = F;
  cmprs_ptr = dst;
  cmprs_size = size;
  cmprs_v = v;
  run_compression(read_data_worker_u8);
}

static void read_data_worker_u16(int t)
{
  struct CompressState *state = &cmprs_state[t];

  FILE *F = cmprs_F;
  uint16_t *dst = cmprs_ptr;
  uint16_t *v = cmprs_v;
  while (1) {
    uint32_t cmprs_chunk;
    LOCK(cmprs_mutex);
    if (cmprs_size == 0) {
      UNLOCK(cmprs_mutex);
      break;
    }
    file_read(&cmprs_chunk, 4, F);
    file_read(&state->frame->chunk, cmprs_chunk + HEADER_SIZE - 4, F);
    uint32_t chunk = state->frame->chunk;
    if (chunk > cmprs_size) {
      fprintf(stderr, "Error in read_data_worker.\n");
      exit(EXIT_FAILURE);
    }
    cmprs_size -= chunk;
    UNLOCK(cmprs_mutex);
    size_t idx = state->frame->idx;
    decompress(state, state->buffer, chunk, state->frame->data, cmprs_chunk);
    if (!v)
      for (size_t i = 0; i < chunk; i++)
        dst[idx + i] = state->buffer[i];
    else
      for (size_t i = 0; i < chunk; i++)
        dst[idx + i] |= v[state->buffer[i]];
  }
}

// Read 8-bit data into 16-bit array.
void read_data_u16(FILE *F, uint16_t *dst, uint64_t size, uint16_t *v)
{
  init();

  cmprs_F = F;
  cmprs_ptr = dst;
  cmprs_size = size;
  cmprs_v = v;
  run_compression(read_data_worker_u16);
}
