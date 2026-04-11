/*
  Copyright (c) 2011-2013, 2018, 2025 Ronald de Man

  This file is distributed under the terms of the GNU GPL, version 2.
*/

#ifndef THREADS_H
#define THREADS_H

#include "compat.h"
#include "defs.h"
#include "types.h"

#ifndef _WIN32
#if defined(__STDC_NO_THREADS__) || !__has_include(<threads.h>)
#include "c11threads.h"
#else
#include <threads.h>
#endif
#else
#include "c11threads.h"
#endif

#define LOCK_T mtx_t
#define LOCK_INIT(x) mtx_init(&(x), mtx_plain)
#ifdef _MSC_VER
#define LOCK(x) do { _mm_mfence(); mtx_lock(&(x)); } while (0)
#define UNLOCK(x) do { mtx_unlock(&(x)); _mm_mfence(); } while (0)
#else
#define LOCK(x) do { __sync_synchronize(); mtx_lock(&(x)); } while (0)
#define UNLOCK(x) do { mtx_unlock(&(x)); __sync_synchronize(); } while (0)
#endif

struct thread_data {
#ifdef _WIN32
  __declspec(align(64)) uint64_t begin;
#else
  uint64_t begin;
#endif
  uint64_t end;
  bitboard occ;
  uint64_t *stats;
  int *p;
  int thread;
  int affinity;
};

void init_threads(int pawns);
void run_threaded(void (*func)(struct thread_data *), uint64_t *work,
    int report_time);
void run_single(void (*func)(struct thread_data *), uint64_t *work,
    int report_time);
void fill_work(int n, uint64_t size, uint64_t mask, uint64_t *w);
void fill_work_offset(int n, uint64_t size, uint64_t mask, uint64_t *w,
    uint64_t offset);
uint64_t *alloc_work(int n);
uint64_t *create_work(int n, uint64_t size, uint64_t mask);

void create_compression_threads(void);
void run_compression(void (*func)(int t));

extern int numthreads;
extern int thread_affinity;
extern int total_work;
extern struct thread_data *thread_data;
extern struct timeval start_time, cur_time;

#endif
