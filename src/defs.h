/*
  Copyright (c) 2011-2018 Ronald de Man

  This file is distributed under the terms of the GNU GPL, version 2.
*/

#ifndef DEFS_H
#define DEFS_H

#include <inttypes.h>

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
#define SUICIDE
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
#define assume(x) do { if (!(x)) __assume(0); } while (0)
#else
#define assume(x) do { if (!(x)) {} } while (0)
#endif

#define PASTER(x,y) x##_##y
#define EVALUATOR(x,y) PASTER(x,y)

#endif
