/*
  Windows compatibility headers for GCC/MSVC cross-platform support
*/

#ifndef WINCOMPAT_H
#define WINCOMPAT_H

#ifdef _MSC_VER
  /* Microsoft Visual C++ */
  #include <winsock2.h>
  #include <ws2tcpip.h>
  #include <stdint.h>
  #include <stdlib.h>
  #include <string.h>

  /* strcasecmp replacement */
  #define strcasecmp _stricmp
  #define strncasecmp _strnicmp
  #define strdup _strdup

  /* getopt - simple implementation */
  extern char *optarg;
  extern int optind;
  extern int opterr;
  extern int optopt;

  int _getopt(int argc, char *argv[], const char *optstring);
  #define getopt(argc, argv, optstring) _getopt(argc, argv, optstring)

  /* getopt_long implementation for Windows */
  #define required_argument 1
  #define optional_argument 2
  #define no_argument 0

  struct option {
    const char *name;
    int has_arg;
    int *flag;
    int val;
  };

  int getopt_long(int argc, char *argv[], const char *optstring,
                  const struct option *longopts, int *longindex);

  /* inttypes.h macros for MSVC - explicit definitions for compatibility */
  #ifndef PRId64
  #define PRId64 "I64d"
  #define PRIu64 "I64u"
  #define PRIx64 "I64x"
  #define PRId32 "d"
  #define PRIu32 "u"
  #define PRIx32 "x"
  #endif

  /* usleep replacement */
  #define usleep(x) Sleep((x) / 1000)

  /* struct timeval for Windows - guarded against winsock2.h definition */
  #ifndef _SYS_TIME_H
  #ifndef timeval
  struct timeval {
    long tv_sec;
    long tv_usec;
  };
  #endif
  #endif

#else
  /* Unix-like systems (GCC) */
  #include <sys/time.h>
  #include <unistd.h>
  #include <strings.h>
  #include <stdint.h>
  #include <getopt.h>
  #include <inttypes.h>

  /* strcasecmp */
  #define strcasecmp strcasecmp
  #define strdup strdup

  /* inttypes.h macros for GCC */
  #ifndef PRId64
  #define PRId64 "d"
  #define PRIu64 "u"
  #define PRIx64 "x"
  #define PRId32 "d"
  #define PRIu32 "u"
  #define PRIx32 "x"
  #endif

#endif

#endif /* WINCOMPAT_H */