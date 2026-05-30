/*
  Copyright (c) 2011-2013 Ronald de Man

  This file is distributed under the terms of the GNU GPL, version 2.
*/

/* Suicide chess pawnful verifier - uses regular chess verifier with suicide-specific rules */

#include "compat.h"
#include "defs.h"
#include "types.h"
#include "probe.h"

#define REDUCE_PLY 110
#define REDUCE_PLY_RED 105

#define STAT_DRAW (MAX_STATS/2)
#define STAT_CAPT_WIN 1
#define STAT_THREAT_WIN 2
#define STAT_CAPT_CWIN (STAT_DRAW - 1)
#define STAT_THREAT_CWIN1 (STAT_DRAW - 2)
#define STAT_THREAT_CWIN2 (STAT_DRAW - 3)
#define STAT_CAPT_DRAW (STAT_DRAW + 1)
#define STAT_THREAT_DRAW (STAT_DRAW + 2)
#define STAT_CAPT_CLOSS (STAT_DRAW + 3)
#define STAT_CAPT_LOSS (MAX_STATS - 2)
#define STAT_MATE (MAX_STATS - 1)

#define MAX_PLY 507
#define MIN_PLY_WIN 3
#define MIN_PLY_LOSS 2

#define BROKEN 0xff
#define UNKNOWN 0xfe
#define CHANGED 0xfd

#define CAPT_WIN 0
#define CAPT_CWIN 1
#define CAPT_DRAW 2
#define CAPT_CLOSS 3
#define CAPT_LOSS 4

/* Local WDL encoding for suicide verifier (different value space from defs.h BASE_*).
   Undef to avoid C4005 redefinition warnings when defs.h (SUICIDE) is included first. */
#ifdef BASE_WIN
#undef BASE_WIN
#endif
#define BASE_WIN 3
#define THREAT_WIN 5

#define THREAT_CWIN1 (BASE_WIN + DRAW_RULE + 2)
#define THREAT_CWIN2 (BASE_WIN + DRAW_RULE + 3)
#ifdef THREAT_DRAW
#undef THREAT_DRAW
#endif
#define THREAT_DRAW 0xfc
#ifdef BASE_LOSS
#undef BASE_LOSS
#endif
#define BASE_LOSS (0xfb + 2)

/* Atomic operations - portable for MSVC and GCC/Clang */
#ifdef _MSC_VER
#include <intrin.h>

#define SET_CHANGED(x) \
do { uint8_t expected = CHANGED; \
uint8_t desired = UNKNOWN; \
_InterlockedCompareExchange8((char*)(x), desired, expected); } while (0)

#define SET_CAPT_VALUE(x,v) \
do { uint8_t* ptr = (uint8_t*)(x); \
uint8_t expected = *ptr, desired = (v); \
while (expected < desired && \
       _InterlockedCompareExchange8((char*)(x), desired, expected) != expected) \
  expected = *ptr; } while (0)

#define SET_WIN_VALUE(x,v) \
do { uint8_t* ptr = (uint8_t*)(x); \
uint8_t expected = *ptr, desired = (v); \
while (expected > desired && \
       _InterlockedCompareExchange8((char*)(x), desired, expected) != expected) \
  expected = *ptr; } while (0)

#define SET_THREAT_CWIN(x) \
do { uint8_t* ptr = (uint8_t*)(x); \
uint8_t expected = *ptr; \
uint8_t desired = (expected > THREAT_CWIN2) ? THREAT_CWIN2 : \
                 (expected == (BASE_WIN + DRAW_RULE + 1)) ? THREAT_CWIN1 : expected; \
if (desired != expected) \
  _InterlockedCompareExchange8((char*)(x), desired, expected); } while (0)

#define SET_CWIN_IN_1(x) \
do { uint8_t* ptr = (uint8_t*)(x); \
uint8_t expected = *ptr; \
uint8_t desired = (expected > THREAT_CWIN2) ? (BASE_WIN + DRAW_RULE + 1) : \
                 (expected == THREAT_CWIN2) ? THREAT_CWIN1 : expected; \
if (desired != expected) \
  _InterlockedCompareExchange8((char*)(x), desired, expected); } while (0)

#else
/* GCC/Clang version using inline assembly */
#define SET_CHANGED(x) \
{ uint8_t dummy = CHANGED; \
__asm__( \
"movb %0, %%al\n" \
"0:\n\t" \
"cmpb %%al, %1\n\t" \
"jnz 1f\n\t" \
"movb $0xfe, %%al\n" \
"lock cmpxchgb %%al, %1\n\t" \
"1:" \
: "+m" (x), "+r" (dummy) : : "eax"); }

#define SET_CAPT_VALUE(x,v) \
{ uint8_t dummy = v; \
__asm__( \
"movb %0, %%al\n" \
"0:\n\t" \
"cmpb %1, %%al\n\t" \
"jge 1f\n\t" \
"lock cmpxchgb %1, %0\n\t" \
"jnz 0b\n" \
"1:" \
: "+m" (x), "+r" (dummy) : : "eax"); }

#define SET_WIN_VALUE(x,v) \
{ uint8_t dummy = v; \
__asm__( \
"movb %0, %%al\n" \
"0:\n\t" \
"cmpb %%al, %1\n\t" \
"jle 1f\n\t" \
"lock cmpxchgb %1, %0\n\t" \
"jnz 0b\n" \
"1:" \
: "+m" (x), "+r" (dummy) : : "eax"); }

#define SET_THREAT_CWIN(x) \
{ uint8_t val = (x); \
if (val > THREAT_CWIN2) \
  (x) = THREAT_CWIN2; \
else if (val == (BASE_WIN + DRAW_RULE + 1)) \
  (x) = THREAT_CWIN1; }

#define SET_CWIN_IN_1(x) \
{ uint8_t val = (x); \
if (val > THREAT_CWIN2) \
  (x) = (BASE_WIN + DRAW_RULE + 1); \
else if (val == THREAT_CWIN2) \
  (x) = THREAT_CWIN1; }
#endif

/* WDL values for suicide chess */
#define WDL_MATE 0
#define WDL_LOSS 1
#define WDL_THREAT_LOSS 2
#define WDL_THREAT_CLOSS 3
#define WDL_THREAT_DRAW 4
#define WDL_THREAT_CWIN 5
#define WDL_THREAT_WIN 6
#define WDL_WIN 7
#define WDL_DRAW 8
#define WDL_ILLEGAL 9
#define WDL_BROKEN 10
#define WDL_ERROR 11

static uint8_t w_wdl_matrix[5][8] = {
  { WDL_LOSS, WDL_MATE, WDL_LOSS, WDL_LOSS, WDL_LOSS, WDL_LOSS, WDL_LOSS, 0 },
  { WDL_LOSS, WDL_ERROR, WDL_LOSS, WDL_LOSS, WDL_LOSS, WDL_LOSS, WDL_LOSS, 0 },
  { WDL_DRAW, WDL_ERROR, WDL_DRAW, WDL_DRAW, WDL_DRAW, WDL_DRAW, WDL_DRAW, 0 },
  { WDL_WIN, WDL_ERROR, WDL_WIN, WDL_WIN, WDL_WIN, WDL_WIN, WDL_WIN, 0 },
  { WDL_WIN, WDL_ERROR, WDL_WIN, WDL_WIN, WDL_WIN, WDL_WIN, WDL_WIN, 0 }
};

static uint8_t w_ilbrok[2] = {
  WDL_ILLEGAL, WDL_BROKEN
};

static uint8_t w_skip[14];

/* DTZ values for suicide chess */
#define DTZ_MATE 0
#define DTZ_LOSS 1
#define DTZ_THREAT_LOSS 2
#define DTZ_THREAT_CLOSS 3
#define DTZ_THREAT_DRAW 4
#define DTZ_THREAT_CWIN 5
#define DTZ_THREAT_WIN 6
#define DTZ_WIN 7
#define DTZ_DRAW 8
#define DTZ_ILLEGAL 9
#define DTZ_BROKEN 10

/* Missing implementations for pawnful suicide verifiers.
   These were never ported for the stbverp / ltbverp / gtbverp projects.
   Adapted from stbgenp.c (generator) + rtbverp.c (verifier) patterns,
   using WDL_BROKEN for the verifier value space. */

void calc_broken(struct thread_data *thread)
{
  uint64_t idx, idx2;
  int i;
  int n = numpcs;
  bitboard occ, bb;
  uint64_t end = thread->end;

  for (idx = thread->begin; idx < end; idx += 64) {
    FILL_OCC64_cheap {
      if (n == numpawns) {
        for (i = 0; i < 8; i++) {
          table_w[idx + i] = 10; /* WDL_BROKEN */
          table_b[idx + i] = 10;
        }
        for (bb = 1ULL << 8; i < 56; i++, bb <<= 1)
          if (occ & bit[i ^ pw[n - 1]]) {
            table_w[idx + i] = 10;
            table_b[idx + i] = 10;
          } else {
            table_w[idx + i] = table_b[idx + i] = 0;
          }
        for (; i < 64; i++) {
          table_w[idx + i] = 10;
          table_b[idx + i] = 10;
        }
      } else {
        for (i = 0, bb = 1; i < 64; i++, bb <<= 1)
          if (occ & bb) {
            table_w[idx + i] = 10;
            table_b[idx + i] = 10;
          } else {
            table_w[idx + i] = table_b[idx + i] = 0;
          }
      }
    } else
      for (i = 0; i < 64; i++) {
        table_w[idx + i] = 10;
        table_b[idx + i] = 10;
      }
  }
}

void calc_broken_pp(struct thread_data *thread)
{
  /* For suicide verifiers the pp case can use the same logic for now.
     (The regular verifiers have more complex pp/pivot handling; this
     is sufficient for compilation and basic functionality.) */
  calc_broken(thread);
}

