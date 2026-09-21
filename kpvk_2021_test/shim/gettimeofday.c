/*
  gettimeofday() for Windows via GetSystemTimePreciseAsFileTime.
  Build shim for the 2018 tbgenp.c experiment (2026-09-14).
*/
#include "sys/time.h"

#include <stdint.h>
#include <windows.h>

int gettimeofday(struct timeval *tv, void *tz)
{
  FILETIME ft;
  uint64_t ns;
  (void)tz;
  GetSystemTimePreciseAsFileTime(&ft);
  ns = ((uint64_t)ft.dwHighDateTime << 32) | (uint64_t)ft.dwLowDateTime;
  ns -= 116444736000000000ULL; /* 100-ns ticks between 1601-01-01 and 1970-01-01 */
  tv->tv_sec = (long)(ns / 10000000ULL);
  tv->tv_usec = (long)((ns % 10000000ULL) / 10ULL);
  return 0;
}
