/*
  Windows compatibility headers for GCC/MSVC cross-platform support
*/

#ifndef WINCOMPAT_H
#define WINCOMPAT_H

#if defined(_WIN32) || defined(_WIN64)
  /* Windows (MSVC or MinGW) */
  #ifdef _MSC_VER
    /* MSVC-specific headers */
    #include <winsock2.h>
    #include <ws2tcpip.h>
    #include <stdint.h>
  #endif

  #include <stdlib.h>
  #include <string.h>
  #include <inttypes.h>  /* Include Windows SDK inttypes.h first */

  /* strcasecmp replacement */
  #ifndef _MSC_VER
    #define strcasecmp _stricmp
  #endif
  #define strncasecmp _strnicmp
  #define strdup _strdup

  /* getopt - simple implementation for Windows */
  extern char *optarg;
  extern int optind;
  extern int opterr;
  extern int optopt;

  int _getopt(int argc, char *argv[], const char *optstring);
  #define getopt(argc, argv, optstring) _getopt(argc, argv, optstring)

  /* getopt_long implementation for Windows */
  #ifndef required_argument
  #define required_argument 1
  #define optional_argument 2
  #define no_argument 0
  #endif

  #ifndef __HAVE_STRUCT_OPTION
  #define __HAVE_STRUCT_OPTION
  struct option {
    const char *name;
    int has_arg;
    int *flag;
    int val;
  };
  #endif

  int getopt_long(int argc, char *argv[], const char *optstring,
                  const struct option *longopts, int *longindex);

  /* usleep replacement */
  #define usleep(x) Sleep((x) / 1000)

  /* struct timeval is provided by winsock2.h — no redefinition needed */

  /* gettimeofday replacement for Windows */
  static inline int gettimeofday(struct timeval *tv, void *tz)
  {
    FILETIME ft;
    unsigned __int64 tmpres = 0;

    (void)tz;  /* Unused - timezone support not implemented */

    if (NULL != tv) {
      GetSystemTimePreciseAsFileTime(&ft);
      tmpres |= ft.dwHighDateTime;
      tmpres <<= 32;
      tmpres |= ft.dwLowDateTime;

      /* Convert to microseconds (100-nanosecond intervals) */
      tmpres -= 116444736000000000LL;  /* Windows epoch offset */
      tmpres /= 10;  /* Convert to microseconds */

      tv->tv_sec = (long)(tmpres / 1000000UL);
      tv->tv_usec = (long)(tmpres % 1000000UL);
    }

    return 0;
  }

#else
  /* Unix-like systems (GCC/Clang) - use standard headers */
  #include <sys/time.h>
  #include <unistd.h>
  #include <strings.h>
  #include <stdint.h>
  #include <getopt.h>
  #include <inttypes.h>

#endif

#endif /* WINCOMPAT_H */