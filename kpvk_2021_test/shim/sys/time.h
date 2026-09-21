/*
  Minimal sys/time.h shim for MSVC (struct timeval + gettimeofday).
  Build shim for the 2018 tbgenp.c experiment (2026-09-14).
*/
#ifndef SHIM_SYS_TIME_H
#define SHIM_SYS_TIME_H

#ifdef __cplusplus
extern "C" {
#endif

struct timeval {
  long tv_sec;
  long tv_usec;
};

int gettimeofday(struct timeval *tv, void *tz);

#ifdef __cplusplus
}
#endif

#endif /* SHIM_SYS_TIME_H */
