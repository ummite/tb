/*
  Windows compatibility headers for GCC/MSVC cross-platform support
*/

#ifndef WINCOMPAT_H
#define WINCOMPAT_H

#include <sys/time.h>

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

  /* inttypes.h macros for MSVC - explicit definitions for compatibility */
  #define PRId64 "I64d"
  #define PRIu64 "I64u"
  #define PRIx64 "I64x"
  #define PRId32 "d"
  #define PRIu32 "u"
  #define PRIx32 "x"

  /* usleep replacement */
  #define usleep(x) Sleep((x) / 1000)

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
  #define PRId64 "d"
  #define PRIu64 "u"
  #define PRIx64 "x"
  #define PRId32 "d"
  #define PRIu32 "u"
  #define PRIx32 "x"

#endif

#endif /* WINCOMPAT_H */