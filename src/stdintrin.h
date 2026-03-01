/*
  Standard C++ intrinsics replacement for cross-platform compatibility
  This file replaces GCC-specific intrinsics with portable C++ code
*/

#ifndef STDINTRIN_H
#define STDINTRIN_H

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/* Compiler detection */
#ifdef _MSC_VER
  #define COMPILER_MSVC 1
  #include <intrin.h>
#else
  #define COMPILER_GCC 1
#endif

/* Atomic operations - MSVC using _Interlocked* */
#ifdef _MSC_VER
  #define __sync_fetch_and_add(ptr, val) _InterlockedExchangeAdd((long volatile*)(ptr), (long)(val))
  #define __sync_fetch_and_sub(ptr, val) _InterlockedExchangeAdd((long volatile*)(ptr), -(long)(val))
  #define __sync_fetch_and_or(ptr, val) _InterlockedOr((long volatile*)(ptr), (long)(val))
  #define __sync_fetch_and_and(ptr, val) _InterlockedAnd((long volatile*)(ptr), (long)(val))
  #define __sync_fetch_and_xor(ptr, val) _InterlockedXor((long volatile*)(ptr), (long)(val))

  #define __sync_add_and_fetch(ptr, val) (_InterlockedExchangeAdd((long volatile*)(ptr), (long)(val)) + (val))
  #define __sync_sub_and_fetch(ptr, val) (_InterlockedExchangeAdd((long volatile*)(ptr), -(long)(val)) - (val))
  #define __sync_or_and_fetch(ptr, val) (_InterlockedOr((long volatile*)(ptr), (long)(val)) | (val))
  #define __sync_and_and_fetch(ptr, val) (_InterlockedAnd((long volatile*)(ptr), (long)(val)) & (val))
  #define __sync_xor_and_fetch(ptr, val) (_InterlockedXor((long volatile*)(ptr), (long)(val)) ^ (val))

  #define __sync_bool_compare_and_swap(ptr, oldval, newval) \
    (_InterlockedCompareExchange((long volatile*)(ptr), (long)(newval), (long)(oldval)) == (long)(oldval))
  #define __sync_val_compare_and_swap(ptr, oldval, newval) \
    _InterlockedCompareExchange((long volatile*)(ptr), (long)(newval), (long)(oldval))

#else
  /* GCC - use built-in atomics */
  #include <stdatomic.h>

  #define __sync_fetch_and_add(ptr, val) atomic_fetch_add((_Atomic long*)(ptr), (long)(val))
  #define __sync_fetch_and_sub(ptr, val) atomic_fetch_sub((_Atomic long*)(ptr), (long)(val))
  #define __sync_fetch_and_or(ptr, val) atomic_fetch_or((_Atomic long*)(ptr), (long)(val))
  #define __sync_fetch_and_and(ptr, val) atomic_fetch_and((_Atomic long*)(ptr), (long)(val))
  #define __sync_fetch_and_xor(ptr, val) atomic_fetch_xor((_Atomic long*)(ptr), (long)(val))

  #define __sync_add_and_fetch(ptr, val) atomic_add_fetch((_Atomic long*)(ptr), (long)(val))
  #define __sync_sub_and_fetch(ptr, val) atomic_sub_fetch((_Atomic long*)(ptr), (long)(val))
  #define __sync_or_and_fetch(ptr, val) atomic_or_fetch((_Atomic long*)(ptr), (long)(val))
  #define __sync_and_and_fetch(ptr, val) atomic_and_fetch((_Atomic long*)(ptr), (long)(val))
  #define __sync_xor_and_fetch(ptr, val) atomic_xor_fetch((_Atomic long*)(ptr), (long)(val))

  #define __sync_bool_compare_and_swap(ptr, oldval, newval) \
    atomic_compare_exchange_strong((_Atomic long*)(ptr), (long*)(oldval), (long)(newval))
  #define __sync_val_compare_and_swap(ptr, oldval, newval) \
    atomic_compare_exchange_strong((_Atomic long*)(ptr), (long*)(oldval), (long)(newval))
#endif

/* Bit manipulation functions - portable C++ implementations */

/* Popcount - count set bits */
static inline int popcount64(uint64_t x)
{
#ifdef _MSC_VER
  return __popcnt64(x);
#else
  #ifdef USE_POPCNT
    return __builtin_popcountll(x);
  #else
    // Portable implementation using Kernighan's algorithm
    int count = 0;
    while (x) {
      x &= (x - 1);
      count++;
    }
    return count;
  #endif
#endif
}

static inline int popcount32(uint32_t x)
{
#ifdef _MSC_VER
  return __popcnt(x);
#else
  #ifdef USE_POPCNT
    return __builtin_popcount(x);
  #else
    int count = 0;
    while (x) {
      x &= (x - 1);
      count++;
    }
    return count;
  #endif
#endif
}

/* Count trailing zeros (ctz) */
static inline int ctz64(uint64_t x)
{
  if (x == 0) return 64;
#ifdef _MSC_VER
  unsigned long idx;
  _BitScanForward64(&idx, x);
  return (int)idx;
#else
  #ifdef USE_POPCNT
    return __builtin_ctzll(x);
  #else
    // Portable implementation
    int count = 0;
    while ((x & 1) == 0) {
      x >>= 1;
      count++;
    }
    return count;
  #endif
#endif
}

static inline int ctz32(uint32_t x)
{
  if (x == 0) return 32;
#ifdef _MSC_VER
  unsigned long idx;
  _BitScanForward(&idx, x);
  return (int)idx;
#else
  #ifdef USE_POPCNT
    return __builtin_ctz(x);
  #else
    int count = 0;
    while ((x & 1) == 0) {
      x >>= 1;
      count++;
    }
    return count;
  #endif
#endif
}

/* Count leading zeros (clz) */
static inline int clz64(uint64_t x)
{
  if (x == 0) return 64;
#ifdef _MSC_VER
  unsigned long idx;
  _BitScanReverse64(&idx, x);
  return 63 - (int)idx;
#else
  #ifdef USE_POPCNT
    return __builtin_clzll(x);
  #else
    // Portable implementation
    int count = 0;
    while (x < (uint64_t)1 << 63) {
      x <<= 1;
      count++;
    }
    return count;
  #endif
#endif
}

static inline int clz32(uint32_t x)
{
  if (x == 0) return 32;
#ifdef _MSC_VER
  unsigned long idx;
  _BitScanReverse(&idx, x);
  return 31 - (int)idx;
#else
  #ifdef USE_POPCNT
    return __builtin_clz(x);
  #else
    int count = 0;
    while (x < (uint32_t)1 << 31) {
      x <<= 1;
      count++;
    }
    return count;
  #endif
#endif
}

/* Byte swap functions */
static inline uint64_t bswap64(uint64_t x)
{
#ifdef _MSC_VER
  return _byteswap_uint64(x);
#else
  #ifdef USE_POPCNT
    return __builtin_bswap64(x);
  #else
    return ((x & 0x00000000000000FFULL) << 56) |
           ((x & 0x000000000000FF00ULL) << 40) |
           ((x & 0x0000000000FF0000ULL) << 24) |
           ((x & 0x00000000FF000000ULL) << 8)  |
           ((x & 0x000000FF00000000ULL) >> 8)  |
           ((x & 0x0000FF0000000000ULL) >> 24) |
           ((x & 0x00FF000000000000ULL) >> 40) |
           ((x & 0xFF00000000000000ULL) >> 56);
  #endif
#endif
}

static inline uint32_t bswap32(uint32_t x)
{
#ifdef _MSC_VER
  return _byteswap_ulong(x);
#else
  #ifdef USE_POPCNT
    return __builtin_bswap32(x);
  #else
    return ((x & 0x000000FF) << 24) |
           ((x & 0x0000FF00) << 8)  |
           ((x & 0x00FF0000) >> 8)  |
           ((x & 0xFF000000) >> 24);
  #endif
#endif
}

/* Macros for compatibility */
#define PopCount(x) popcount64(x)
#define __builtin_popcountll(x) popcount64(x)
#define __builtin_popcount(x) popcount32(x)
#define __builtin_ctzll(x) ctz64(x)
#define __builtin_ctz(x) ctz32(x)
#define __builtin_clzll(x) clz64(x)
#define __builtin_clz(x) clz32(x)
#define __builtin_bswap64(x) bswap64(x)
#define __builtin_bswap32(x) bswap32(x)

/* Likely/unlikely hints - no-op on MSVC */
#ifdef _MSC_VER
  #define __builtin_expect(x, y) (x)
  #define likely(x) (x)
  #define unlikely(x) (x)
#else
  #define __builtin_expect(x, y) __builtin_expect(x, y)
  #define likely(x) __builtin_expect(!!(x), 1)
  #define unlikely(x) __builtin_expect(!!(x), 0)
#endif

/* Prefetch - no-op on MSVC (hardware handles it) */
#ifdef _MSC_VER
  #define __builtin_prefetch(addr, rw, locality)
#else
  #define __builtin_prefetch(addr, rw, locality) __builtin_prefetch(addr, rw, locality)
#endif

/* Unreachable - MSVC version */
#ifdef _MSC_VER
  #define __builtin_unreachable() __assume(0)
#else
  #define __builtin_unreachable() __builtin_unreachable()
#endif

/* Assume macro - handled in compat.h */

/* Bit set operations (replaces inline assembly) */
static inline void bit_set(uint64_t* x, uint64_t y)
{
  *x |= (1ULL << y);
}

static inline void bit_set_test(uint64_t* x, uint64_t y, int* v)
{
  *x |= (1ULL << y);
  if (*x & (1ULL << y)) {
    *v += 1;
  }
}

/* Lock compare-and-swap operations */
#ifdef _MSC_VER
  #define lock_cmpxchg(ptr, oldval, newval) _InterlockedCompareExchange((long volatile*)(ptr), (long)(newval), (long)(oldval))
#else
  #define lock_cmpxchg(ptr, oldval, newval) __sync_val_compare_and_swap(ptr, oldval, newval)
#endif

#endif /* STDINTRIN_H */