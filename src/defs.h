/*
  Copyright (c) 2011-2018 Ronald de Man

  This file is distributed under the terms of the GNU GPL, version 2.
*/

#ifndef DEFS_H
#define DEFS_H

/* Include standard types - must come first for all platforms */
#include <stdint.h>

/* Include inttypes.h for format macros (PRId64, PRIu64, etc.) */
/* MSVC includes this via Windows SDK, GCC/Clang via stdint.h chain */
#ifdef _MSC_VER
/* Windows SDK 10.0.17763.0+ includes inttypes.h with proper format macros */
/* Don't define our own - let the SDK handle it */
#else
#include <inttypes.h>
#endif

#if defined(REGULAR) || defined(SHATRANJ)
#define SMALL
#endif

#ifndef SHATRANJ
#define DRAW_RULE (2 * 50)
#else
#define DRAW_RULE (2 * 70)
#endif

#if TBPIECES < 7
#define MAX_STATS 1536
#else
#define MAX_STATS 2560
#endif

#ifndef COMPRESSION_THREADS
#define COMPRESSION_THREADS 1
#endif

#ifndef ZSTD_LEVEL
#define ZSTD_LEVEL 1
#endif

#define MAX_VALS (((MAX_STATS / 2) - DRAW_RULE) / 2)

enum { MAXSYMB = 4095 + 8 };

#define LOOKUP
#define LUBITS 12

// GIVEAWAY is a variation on SUICIDE
#ifdef GIVEAWAY
#ifndef SUICIDE
#define SUICIDE
#endif
#endif

#ifdef SUICIDE
/* Suicide / Giveaway / Loser specific WDL value encodings.
   These are referenced from the SUICIDE branches in the shared pawnful
   files (reducep.c, reducep_tmpl.c, statsp.c, tbgenp.c) when building
   any of the *_p suicide-family projects.  They used to live only inside
   stbgenp.c and were therefore invisible to the shared code on some builds. */
#define STALE_WIN       5
#define THREAT_WIN1     7
#define THREAT_WIN2     8
#define BASE_WIN        7
#define THREAT_CWIN1    (BASE_WIN + DRAW_RULE + 2)
#define THREAT_CWIN2    (BASE_WIN + DRAW_RULE + 3)

#define THREAT_WIN_RED  5
#define BASE_WIN_RED    6
#define THREAT_CWIN_RED 7
#define BASE_CWIN_RED   8

#define PAWN_CLOSS      0xfc
#define PAWN_DRAW       0xfb
#define THREAT_DRAW     0xfa
#define BASE_LOSS       0xf9
#define BASE_LOSS_RED   0xf9
#define BASE_CLOSS_RED  0xf8
#endif

/* likely/unlikely hints - compiler-specific for portability */
#if defined(__GNUC__) || defined(__clang__)
#define likely(x) __builtin_expect(!!(x), 1)
#define unlikely(x) __builtin_expect(!!(x), 0)
#elif defined(_MSC_VER)
/* MSVC: use __predict_true/__predict_false if available, otherwise passthrough */
#define likely(x) (x)
#define unlikely(x) (x)
#else
#define likely(x) (x)
#define unlikely(x) (x)
#endif

/* assume() for compiler optimizations - hints that condition is always true */
#if defined(__GNUC__) || defined(__clang__)
#define assume(x) do { if (!(x)) __builtin_unreachable(); } while (0)
#elif defined(_MSC_VER)
#define assume(x) __assume(x)
#else
#define assume(x) do { if (!(x)) {} } while (0)
#endif

#define PASTER(x,y) x##_##y
#define EVALUATOR(x,y) PASTER(x,y)

#endif
