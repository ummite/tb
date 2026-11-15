/*
  Copyright (c) 2011-2013, 2018, 2025 Ronald de Man

  This file is distributed under the terms of the GNU GPL, version 2.
*/

#include <stdio.h>
#include <stdlib.h>

#include "threads.h"
#include "util.h"

/* Use c11threads library for Windows (MSVC and MinGW) */
#if defined(_WIN32)
#include "wincompat.h"
#include "c11threads_win32.c"
#else
/* POSIX systems (Linux, macOS) - use standard C11 threads */
#include <sys/time.h>
#include <threads.h>
#ifdef __linux__
#include <sched.h>
#endif
#include <unistd.h>
#endif

struct thread_data *thread_data;

typedef struct {
  int needed;
  int called;
  mtx_t mutex;
  cnd_t cond;
} barrier_t;

int barrier_init(barrier_t *barrier, int needed)
{
  barrier->needed = needed;
  barrier->called = 0;
  mtx_init(&barrier->mutex, mtx_plain);
  cnd_init(&barrier->cond);
  return 0;
}

int barrier_destroy(barrier_t *barrier)
{
  mtx_destroy(&barrier->mutex);
  cnd_destroy(&barrier->cond);
  return 0;
}

int barrier_wait(barrier_t *barrier)
{
  mtx_lock(&barrier->mutex);
  barrier->called++;
  if (barrier->called == barrier->needed) {
    barrier->called = 0;
    cnd_broadcast(&barrier->cond);
  } else {
    cnd_wait(&barrier->cond,&barrier->mutex);
  }
  mtx_unlock(&barrier->mutex);
  return 0;
}

static void setaffinity(int i)
{
#ifdef __linux__
  cpu_set_t cpuset;
  CPU_ZERO(&cpuset);
  CPU_SET(i, &cpuset);
  if (sched_setaffinity(0, sizeof(cpuset), &cpuset))
    perror("sched_setaffinity");
#else
  (void)i;
#endif
}

thrd_t *threads;
static barrier_t barrier;

static struct {
  void (*func)(struct thread_data *);
  uint64_t *work;
  int counter;
  int done;
  int total;
} queue;

static char progress_text[160];
static int progress_step;
static int progress_steps;
static struct timeval progress_pass_start;
static long progress_last_print;
static int progress_lines;

static void format_span(long secs, char *buf, size_t cap)
{
  long h, m, s;

  if (secs < 0)
    secs = 0;
  h = secs / 3600;
  m = (secs / 60) % 60;
  s = secs % 60;
  if (h > 0)
    snprintf(buf, cap, "%ld:%02ld:%02ld", h, m, s);
  else
    snprintf(buf, cap, "%ld:%02ld", m, s);
}

void progress_set(int step, int steps, const char *phase)
{
  progress_step = step;
  progress_steps = steps;
  snprintf(progress_text, sizeof(progress_text), "%s", phase ? phase : "");
  if (steps > 0)
    printf("[%d/%d] %s\n", step, steps, progress_text);
  else
    printf("%s\n", progress_text);
  fflush(stdout);
}

static void progress_line(int done, int total, int force)
{
  struct timeval now;
  long elapsed, eta;
  int pct;
  char ebuf[24], tbuf[24];

  gettimeofday(&now, NULL);
  elapsed = (long)now.tv_sec - (long)progress_pass_start.tv_sec;
  if (!force) {
    if (elapsed < 2)
      return;
    if (elapsed == progress_last_print)
      return;
    if (done >= total)
      return;
  } else if (!progress_lines && elapsed < 2) {
    return;
  }
  progress_last_print = elapsed;
  progress_lines = 1;
  pct = (total > 0) ? (int)((100ull * (unsigned)done) / (unsigned)total) : 0;
  format_span(elapsed, ebuf, sizeof(ebuf));
  if (progress_steps > 0)
    printf("[%d/%d] %s  ", progress_step, progress_steps, progress_text);
  else if (progress_text[0])
    printf("%s  ", progress_text);
  else
    printf("pass  ");
  if (done > 0 && done < total) {
    eta = (long)(((double)elapsed * (double)(total - done)) / (double)done);
    format_span(eta, tbuf, sizeof(tbuf));
    printf("%d/%d  %d%%  elapsed %s  ETA %s\n", done, total, pct, ebuf, tbuf);
  } else {
    printf("%d/%d  %d%%  elapsed %s\n", done, total, pct, ebuf);
  }
  fflush(stdout);
}

int total_work;
int numthreads;
int thread_affinity;

int detect_num_cores(void)
{
#ifdef _WIN32
  SYSTEM_INFO si;
  GetSystemInfo(&si);
  if (si.dwNumberOfProcessors < 1)
    return 1;
  return (int)si.dwNumberOfProcessors;
#else
  long n = sysconf(_SC_NPROCESSORS_ONLN);
  if (n < 1)
    return 1;
  return (int)n;
#endif
}

struct timeval start_time, cur_time;

void fill_work(int n, uint64_t size, uint64_t mask, uint64_t *w)
{
  int i;

  w[0] = 0;
  w[n] = size;

  for (i = 1; i < n; i++)
    w[i] = ((((uint64_t)i) * size) / ((uint64_t)n)) & ~mask;
}

void fill_work_offset(int n, uint64_t size, uint64_t mask, uint64_t *w,
    uint64_t offset)
{
  fill_work(n, size, mask, w);
  for (int i = 0; i <= n; i++)
    w[i] += offset;
}

uint64_t *alloc_work(int n)
{
  return (uint64_t *)malloc((n + 1) * sizeof(uint64_t));
}

uint64_t *create_work(int n, uint64_t size, uint64_t mask)
{
  uint64_t *w;

  w = alloc_work(n);
  fill_work(n, size, mask, w);

  return w;
}

int worker(void *arg);

void init_threads(int pawns)
{
  int i;

  assume(numthreads >= 1); // to get rid of some warnings

  thread_data = alloc_aligned(numthreads * sizeof(*thread_data), 64);

  for (i = 0; i < numthreads; i++) {
    thread_data[i].thread = i;
    thread_data[i].affinity = -1;
  }

  if (pawns) {
    uint8_t *p = alloc_aligned(64 * numthreads, 64);
    for (i = 0; i < numthreads; i++)
      thread_data[i].p = (int *)(p + 64 * i);
  }

  threads = malloc(numthreads * sizeof(*threads));
  barrier_init(&barrier, numthreads);

  for (i = 0; i < numthreads - 1; i++) {
    int rc = thrd_create(&threads[i], worker, (void *)&(thread_data[i]));
    if (rc != thrd_success) {
      fprintf(stderr, "ERROR: thrd_create() returned %d\n", rc);
      exit(EXIT_FAILURE);
    }
  }
  threads[numthreads - 1] = thrd_current();

  if (thread_affinity) {
    for (i = 0; i < numthreads; i++)
      thread_data[i].affinity = i;
    setaffinity(thread_data[numthreads - 1].affinity);
  }
}
int worker(void *arg)
{
  struct thread_data *thread = (struct thread_data *)arg;
  int t = thread->thread;
  int w;

  if (t != numthreads - 1) {
    if (thread->affinity >= 0)
      setaffinity(thread->affinity);
  }

  do {
    barrier_wait(&barrier);

    int total = queue.total;

    while (1) {
      w = __sync_fetch_and_add(&queue.counter, 1);
      if (w >= total) break;
      thread->begin = queue.work[w];
      thread->end = queue.work[w + 1];
      queue.func(thread);
      __sync_add_and_fetch(&queue.done, 1);
      if (t == numthreads - 1)
        progress_line(queue.done, total, 0);
    }

    barrier_wait(&barrier);
  } while (t != numthreads - 1);

  return 0;
}

void run_threaded(void (*func)(struct thread_data *), uint64_t *work, int report_time)
{
  int secs, usecs;
  struct timeval stop_time;
  uint64_t slice_work[101];
  uint64_t *use = work;
  int local_total = total_work;
  uint64_t span;

  span = work[total_work] - work[0];
  /* One thread keeps total_work at 1 so compression stays unchanged.
     Split that single range here, only for this pass, so ETA can move. */
  if (total_work < 20 && span >= (1ull << 20)) {
    int n = 100;
    int i;
    if (span / 64 < 100)
      n = (int)(span / 64);
    if (n >= 2) {
      slice_work[0] = work[0];
      slice_work[n] = work[total_work];
      for (i = 1; i < n; i++) {
        uint64_t v = (work[0] + ((span * (uint64_t)i) / (uint64_t)n)) & ~0x3full;
        if (v < slice_work[i - 1])
          v = slice_work[i - 1];
        if (v > work[total_work])
          v = work[total_work];
        slice_work[i] = v;
      }
      use = slice_work;
      local_total = n;
    }
  }

  queue.func = func;
  queue.work = use;
  queue.total = local_total;
  queue.counter = 0;
  queue.done = 0;
  progress_lines = 0;
  progress_last_print = -1;
  gettimeofday(&progress_pass_start, NULL);

  worker((void *)&(thread_data[numthreads - 1]));
  progress_line(local_total, local_total, 1);

  gettimeofday(&stop_time, NULL);
  secs = stop_time.tv_sec - cur_time.tv_sec;
  usecs = stop_time.tv_usec - cur_time.tv_usec;
  if (usecs < 0) {
    usecs += 1000000;
    secs--;
  }
  if (report_time)
    printf("time taken = %3d:%02d.%03d\n", secs / 60, secs % 60, usecs/1000);
  cur_time = stop_time;
}

void run_single(void (*func)(struct thread_data *), uint64_t *work, int report_time)
{
  int secs, usecs;
  struct timeval stop_time;
  struct thread_data *thread = &(thread_data[0]);

  thread->begin = work[0];
  thread->end = work[total_work];
  func(thread);

  gettimeofday(&stop_time, NULL);
  secs = stop_time.tv_sec - cur_time.tv_sec;
  usecs = stop_time.tv_usec - cur_time.tv_usec;
  if (usecs < 0) {
    usecs += 1000000;
    secs--;
  }
  if (report_time)
    printf("time taken = %3d:%02d.%03d\n", secs / 60, secs % 60, usecs/1000);
  cur_time = stop_time;
}

static struct thread_data cmprs_data[COMPRESSION_THREADS];
static void (*cmprs_func)(int t);

static thrd_t cmprs_threads[COMPRESSION_THREADS];
static barrier_t cmprs_barrier;

static int cmprs_worker(void *arg)
{
  struct thread_data *thread = arg;
  int t = thread->thread;

  do {
    barrier_wait(&cmprs_barrier);

    cmprs_func(t);

    barrier_wait(&cmprs_barrier);
  } while (t != COMPRESSION_THREADS - 1);

  return 0;
}

void create_compression_threads(void)
{
  for (int i = 0; i < COMPRESSION_THREADS; i++)
    cmprs_data[i].thread = i;

  barrier_init(&cmprs_barrier, COMPRESSION_THREADS);

  for (int i = 0; i < COMPRESSION_THREADS - 1; i++) {
    int rc = thrd_create(&cmprs_threads[i], cmprs_worker, &cmprs_data[i]);
    if (rc != thrd_success) {
      fprintf(stderr, "ERROR: thrd_create() returned %d\n", rc);
      exit(EXIT_FAILURE);
    }
  }
}

void run_compression(void (*func)(int t))
{
  cmprs_func = func;
  cmprs_worker(&cmprs_data[COMPRESSION_THREADS - 1]);
}
