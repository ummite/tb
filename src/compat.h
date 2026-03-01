/*
  Copyright (c) 2011-2018, 2024, 2025 Ronald de Man

  This file is distributed under the terms of the GNU GPL, version 2.
*/

#ifndef COMPAT_H
#define COMPAT_H

/* Include standard intrinsics replacement */
#include "stdintrin.h"

/* Compiler detection */
#ifdef _MSC_VER
  #define COMPILER_MSVC 1

  /* Inline function */
  #define __inline__ __inline

  /* Aligned array */
  #define __attribute_aligned__(x) __declspec(align(x))

  /* C++11 features */
  #define _Bool bool
  #define __restrict__ __restrict

  /* strcasecmp for Windows */
  #include <string.h>
  #define strcasecmp _stricmp
  #define strdup _strdup

#else
  /* GCC/Clang */
  #define COMPILER_GCC 1

  /* Inline function */
  #define __inline__ __inline

  /* strcasecmp */
  #include <strings.h>

  /* C++11 features */
  #define _Bool bool
  #define __restrict__ __restrict__

#endif

/* Common defines */
#ifndef MAX
  #define MAX(a, b) ((a) > (b) ? (a) : (b))
#endif

#ifndef MIN
  #define MIN(a, b) ((a) < (b) ? (a) : (b))
#endif

/* Assume macro for optimization hint - skip for MSVC as stdintrin.h handles it */
#ifndef _MSC_VER
#define assume(x) do { if (!(x)) __builtin_unreachable(); } while (0)
#endif

#endif /* COMPAT_H */