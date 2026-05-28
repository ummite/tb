/*
  Copyright (c) 2011-2018, 2024, 2025 Ronald de Man

  This file is distributed under the terms of the GNU GPL, version 2.
*/

#ifndef COMPAT_H
#define COMPAT_H

/* Include standard intrinsics replacement */
#include "stdintrin.h"

/* Include stdint.h early for type definitions */
#include <stdint.h>

/* Include stdbool.h early for bool type */
#include <stdbool.h>

/* Compiler detection */
#ifdef _MSC_VER
  #define COMPILER_MSVC 1

  /* Inline function */
  #define __inline__ inline

  /* Aligned array */
  #define __attribute_aligned__(x) __declspec(align(x))

  /* C11 restrict keyword */
  #define __restrict__ __restrict
  /* Provide plain 'restrict' for code using C99 keyword not supported by MSVC */
  #ifndef restrict
  #define restrict __restrict
  #endif

  /* strcasecmp for Windows */
  #include <string.h>
  #define strcasecmp _stricmp
  #define strdup _strdup

  /* Disable C11 atomics - use MSVC intrinsics instead */
  #pragma warning(push)
  #pragma warning(disable: 4117)
  #define __STDC_NO_ATOMICS__ 1
  #pragma warning(pop)

  /* Include intrinsics for atomic operations */
  #include <intrin.h>

  /* Portable atomic compare-and-swap for uint8_t using MSVC intrinsics */
  static inline int atomic_compare_exchange_strong_uint8(uint8_t *ptr, uint8_t *expected, uint8_t desired)
  {
      uint8_t original = *ptr;
      if (original == *expected) {
          uint8_t compare = *expected;
          if (_InterlockedCompareExchange8((char*)ptr, desired, compare) == compare) {
              return 1;
          }
      }
      *expected = original;
      return 0;
  }

  /* Define C11-style atomic operations using MSVC intrinsics */
  #define _Atomic_uint8_t uint8_t
  #define _Atomic(x) x
  #define atomic_compare_exchange_strong(ptr, expected, desired) \
      atomic_compare_exchange_strong_uint8((uint8_t*)(ptr), (uint8_t*)(expected), (uint8_t)(desired))

#else
  /* GCC/Clang */
  #define COMPILER_GCC 1

  /* Inline function */
  #define __inline__ inline

  /* strcasecmp */
  #include <strings.h>

  /* restrict keyword for GCC/Clang */
  #define __restrict__ __restrict__
  /* Ensure plain 'restrict' is available for GCC/Clang builds */
  #ifndef restrict
  #define restrict __restrict__
  #endif

#endif

/* Common defines */
#ifndef MAX
  #define MAX(a, b) ((a) > (b) ? (a) : (b))
#endif

#ifndef MIN
  #define MIN(a, b) ((a) < (b) ? (a) : (b))
#endif

/* Assume macro - defined in defs.h, don't redefine here */

#endif /* COMPAT_H */