/*
  Copyright (c) 2011-2013, 2018 Ronald de Man

  This file is distributed under the terms of the GNU GPL, version 2.
*/

static uint64_t mask[MAX_PIECES];
int shift[MAX_PIECES];

int piv_sq[24];
uint64_t piv_idx[64];
uint8_t piv_valid[64];
uint64_t sq_mask[64];

/* tri0x40 - triangle mapping for pivot piece (used in LOOP_BLACK_PIECES_PIVOT) */
static uint64_t tri0x40[] = {
  6, 0, 1, 2, 2, 1, 0, 6,
  0, 7, 3, 4, 4, 3, 7, 0,
  1, 3, 8, 5, 5, 8, 3, 1,
  2, 4, 5, 9, 9, 5, 4, 2,
  2, 4, 5, 9, 9, 5, 4, 2,
  1, 3, 8, 5, 5, 8, 3, 1,
  0, 7, 3, 4, 4, 3, 7, 0,
  6, 0, 1, 2, 2, 1, 0, 6
};

#ifdef SMALL
uint64_t diagonal;
int16_t KK_map[64][64];
char mirror[64][64];
#endif

static uint64_t pw_mask, pw_pawnmask;
static uint64_t pw_capt_mask[8];
static uint64_t idx_mask1[8], idx_mask2[8];

void init_tables(void)
{
  set_up_tables();
}

static inline uint64_t MakeMove(uint64_t idx, int k, int sq)
{
  return idx | ((uint64_t)sq << shift[k]);
}

#define PAWN_MASK 0xff000000000000ffULL

// Portable bit_set implementation (replaces GCC inline assembly)
static inline void bit_set_standard(uint64_t* x, uint64_t y)
{
  *x |= (1ULL << y);
}

static inline void bit_set_test_standard(uint64_t* x, uint64_t y, int* v)
{
  *x |= (1ULL << y);
  (*v)++;
}

// Portable PopCount implementation (replaces __builtin_popcountll)
// Uses Hamming weight with parallel bit counting for better performance
static inline int popcount_standard(uint64_t x)
{
  // Parallel bit counting (Hamming weight)
  x = x - ((x >> 1) & 0x5555555555555555ULL);
  x = (x & 0x3333333333333333ULL) + ((x >> 2) & 0x3333333333333333ULL);
  x = (x + (x >> 4)) & 0x0F0F0F0F0F0F0F0FULL;
  return (int)((x * 0x0101010101010101ULL) >> 56);
}

#ifdef USE_POPCNT
// Use compiler intrinsic if available
#ifndef PopCount
#ifdef _MSC_VER
#include <intrin.h>
#define PopCount(x) __popcnt64(x)
#else
#include <x86intrin.h>
#define PopCount(x) __builtin_popcountll(x)
#endif
#endif
#else
#ifndef PopCount
#define PopCount(x) popcount_standard(x)
#endif
#endif

// FILL_OCC64_cheap - Standard C++ version
#define FILL_OCC64_cheap \
  occ = bb = 0; \
  for (i = n - 2, idx2 = (idx ^ pw_mask) >> 6; i >= numpawns; i--, idx2 >>= 6) \
    bit_set_standard(&occ, idx2 & 0x3f); \
  for (; i > 0; i--, idx2 >>= 6) \
    bit_set_standard(&bb, idx2 & 0x3f); \
  bit_set_standard(&bb, piv_sq[idx2]); \
  occ |= bb; \
  if (PopCount(occ) == (uint64_t)(n - 1) && !(bb & PAWN_MASK))

// FILL_OCC64 - Standard C++ version
#define FILL_OCC64 \
  occ = bb = 0; \
  for (i = n - 2, idx2 = (idx ^ pw_mask) >> 6; i >= numpawns; i--, idx2 >>= 6) \
    bit_set_standard(&occ, (p[i] = idx2 & 0x3f)); \
  for (; i > 0; i--, idx2 >>= 6) \
    bit_set_standard(&bb, (p[i] = idx2 & 0x3f)); \
  bit_set_standard(&bb, (p[0] = piv_sq[idx2])); \
  occ |= bb; \
  if (PopCount(occ) == (uint64_t)(n - 1) && !(bb & PAWN_MASK))

// FILL_OCC_CAPTS - Standard C version
// Usage: FILL_OCC_CAPTS { body }
// The body is the body of the if statement
#define FILL_OCC_CAPTS \
  uint64_t idx2 = idx ^ pw_capt_mask[i]; \
  bitboard bb; \
  occ = bb = 0; \
  for (k = n - 1; k >= numpawns; k--) \
    if (k != i) { \
      bit_set_standard(&occ, (p[k] = idx2 & 0x3f)); \
      idx2 >>= 6; \
    } \
  for (; k > 0; k--) \
    if (k != i) { \
      bit_set_standard(&bb, (p[k] = idx2 & 0x3f)); \
      idx2 >>= 6; \
    } \
  bit_set_standard(&bb, (p[0] = piv_sq[idx2])); \
  occ |= bb; \
  if (PopCount(occ) == (uint64_t)(n - 1) && !(bb & PAWN_MASK))

// FILL_OCC_CAPTS_PIVOT - Standard C version
#define FILL_OCC_CAPTS_PIVOT \
  uint64_t idx2 = idx ^ pw_mask; \
  bitboard bb; \
  occ = bb = 0; \
  for (k = n - 1; k >= numpawns; k--, idx2 >>= 6) \
    bit_set_standard(&occ, (p[k] = idx2 & 0x3f)); \
  for (; k > 0; k--, idx2 >>= 6) \
    bit_set_standard(&bb, (p[k] = idx2 & 0x3f)); \
  occ |= bb; \
  if (PopCount(occ) == (uint64_t)(n - 1) && !(bb & PAWN_MASK))

// Original assembly version (commented out for reference)
#if 0
#define FILL_OCC64_cheap \
  occ = bb = 0; \
  for (i = n - 2, idx2 = (idx ^ pw_mask) >> 6; i >= numpawns; i--, idx2 >>= 6) \
    bit_set(occ, idx2 & 0x3f); \
  for (; i > 0; i--, idx2 >>= 6) \
    bit_set(bb, idx2 & 0x3f); \
  bit_set(bb, piv_sq[idx2]); \
  occ |= bb; \
  if (PopCount(occ) == n - 1 && !(bb & PAWN_MASK))

#define FILL_OCC64 \
  occ = bb = 0; \
  for (i = n - 2, idx2 = (idx ^ pw_mask) >> 6; i >= numpawns; i--, idx2 >>= 6) \
    bit_set(occ, p[i] = idx2 & 0x3f); \
  for (; i > 0; i--, idx2 >>= 6) \
    bit_set(bb, p[i] = idx2 & 0x3f); \
  bit_set(bb, p[0] = piv_sq[idx2]); \
  occ |= bb; \
  if (PopCount(occ) == n - 1 && !(bb & PAWN_MASK))
#endif

// FILL_OCC_PIECES - alias for FILL_OCC64
#define FILL_OCC_PIECES \
  occ = bb = 0; \
  for (i = n - 2, idx2 = (idx ^ pw_mask) >> 6; i >= numpawns; i--, idx2 >>= 6) \
    bit_set_standard(&occ, (p[i] = idx2 & 0x3f)); \
  for (; i > 0; i--, idx2 >>= 6) \
    bit_set_standard(&bb, (p[i] = idx2 & 0x3f)); \
  bit_set_standard(&bb, (p[0] = piv_sq[idx2])); \
  occ |= bb; \
  if (PopCount(occ) == (uint64_t)(n - 1) && !(bb & PAWN_MASK))

// FILL_OCC - for use in BEGIN_ITER_ALL context (simpler version without if condition)
#define FILL_OCC \
  do { \
    uint64_t idx2; \
    bitboard bb; \
    occ = bb = 0; \
    for (i = n - 2, idx2 = (idx ^ pw_mask) >> 6; i >= numpawns; i--, idx2 >>= 6) \
      bit_set_standard(&occ, (p[i] = idx2 & 0x3f)); \
    for (; i > 0; i--, idx2 >>= 6) \
      bit_set_standard(&bb, (p[i] = idx2 & 0x3f)); \
    bit_set_standard(&bb, (p[0] = piv_sq[idx2])); \
    occ |= bb; \
  } while (0)

// FILL_OCC_PAWNS - for filling pawn positions
// Usage: FILL_OCC_PAWNS { body }
#define FILL_OCC_PAWNS \
  do { \
    uint64_t idx2; \
    occ = 0; \
    for (i = numpawns - 1, idx2 = idx >> 6; i >= 0; i--, idx2 >>= 6) \
      bit_set_standard(&occ, (p[i] = idx2 & 0x3f)); \
  } while (0)

// FILL_OCC_PAWNS_PIECES - for filling both pawns and pieces (used in atbgenp.c)
// Sets up: occ (all pieces), pawns (pawns only), p[] (all positions)
#define FILL_OCC_PAWNS_PIECES \
  do { \
    uint64_t idx2; \
    bitboard bb; \
    occ = bb = pawns = 0; \
    for (i = n - 2, idx2 = (idx ^ pw_mask) >> 6; i >= numpawns; i--, idx2 >>= 6) { \
      pawns |= bit[idx2 & 0x3f]; \
      bit_set_standard(&occ, (p[i] = idx2 & 0x3f)); \
    } \
    for (; i > 0; i--, idx2 >>= 6) \
      bit_set_standard(&bb, (p[i] = idx2 & 0x3f)); \
    bit_set_standard(&bb, (p[0] = piv_sq[idx2])); \
    occ |= bb; \
  } while (0)

// MARK macros for pawnful positions

// MAKE_IDX2 macro
#define MAKE_IDX2 \
  idx2 = ((idx << 6) & idx_mask1[i]) | (idx & idx_mask2[i])

#define MAKE_IDX2_PIVOT \
  idx2 = idx

#ifdef _MSC_VER
// MSVC doesn't support ##__VA_ARGS__, so we need separate macros
#define MARK_NO_ARG(func) \
static void func(int k, uint8_t *table, uint64_t idx, bitboard occ, int *p)

#define MARK_1_ARG(func, arg1) \
static void func(int k, uint8_t *table, uint64_t idx, bitboard occ, int *p, arg1)

#define MARK_2_ARGS(func, arg1, arg2) \
static void func(int k, uint8_t *table, uint64_t idx, bitboard occ, int *p, arg1, arg2)

// Fallback MARK macro for MSVC - use MARK_1_ARG for single argument
#define MARK(func, arg1) MARK_1_ARG(func, arg1)
#else
#define MARK(func, ...) \
static void func(int k, uint8_t *table, uint64_t idx, bitboard occ, int *p, ##__VA_ARGS__)
#endif

#define MARK_BEGIN_PIVOT \
  int sq; \
  uint64_t idx2; \
  bitboard bb; \
  CHECK_DIAG; \
  bb = PieceMoves(p[0], pt[0], occ); \
  while (bb) { \
    sq = FirstOne(bb); \
    idx2 = MakeMove(idx, 0, sq)

#define MARK_BEGIN \
  int sq; \
  uint64_t idx2; \
  bitboard bb; \
  bb = PieceMoves(p[k], pt[k], occ); \
  while (bb) { \
    sq = FirstOne(bb); \
    idx2 = MakeMove(idx, k, sq)

#define MARK_END \
    ClearFirst(bb); \
  }

// BEGIN_CAPTS macros
#ifndef ATOMIC
#define BEGIN_CAPTS \
  uint64_t idx; \
  bitboard occ; \
  int i = captured_piece; \
  int j, k; \
  int p[MAX_PIECES]; \
  int pt2[MAX_PIECES]; \
  int n = numpcs; \
  uint64_t end = thread->end >> 6; \
  for (k = 0; k < n; k++) \
    pt2[k] = pt[k]; \
  pt2[i] = 0
#else
#define BEGIN_CAPTS \
  uint64_t idx; \
  bitboard occ; \
  int i = captured_piece; \
  int j, k; \
  int p[MAX_PIECES]; \
  int pt2[MAX_PIECES]; \
  int n = numpcs; \
  uint64_t end = thread->end >> 6
#endif

#define BEGIN_CAPTS_NOPROBE \
  uint64_t idx; \
  bitboard occ; \
  int i = captured_piece; \
  int j, k; \
  int p[MAX_PIECES]; \
  int n = numpcs; \
  uint64_t end = thread->end >> 6

#define BEGIN_CAPTS_PIVOT \
  uint64_t idx; \
  bitboard occ; \
  int j, k; \
  int p[MAX_PIECES]; \
  int pt2[MAX_PIECES]; \
  int n = numpcs; \
  uint64_t end = thread->end; \
  for (k = 1; k < n; k++) \
    pt2[k] = pt[k]; \
  pt2[0] = 0

#define BEGIN_CAPTS_PIVOT_NOPROBE \
  uint64_t idx; \
  bitboard occ; \
  int j, k; \
  int p[MAX_PIECES]; \
  int n = numpcs; \
  uint64_t end = thread->end

// LOOP macros
#define LOOP_CAPTS \
  for (idx = thread->begin >> 6; idx < end; idx++)

#define LOOP_CAPTS_PIVOT \
  for (idx = thread->begin; idx < end; idx++)

// BEGIN_ITER_ALL and LOOP_ITER_ALL macros
#define BEGIN_ITER_ALL \
  uint64_t idx; \
  bitboard occ; \
  int i; \
  int n = numpcs; \
  int p[MAX_PIECES]; \
  uint64_t end = thread->end;

#define LOOP_ITER_ALL \
  for (idx = thread->begin; idx < end; idx++)

// LOOP_WHITE_PIECES and LOOP_BLACK_PIECES
#ifndef ATOMIC
#define LOOP_WHITE_PIECES(func, ...) \
  do { \
    uint64_t idx3 = idx2 | ((uint64_t)p[0] << shift[i]); \
    func##_pivot(table_w, idx3 & ~mask[0], occ, p, ##__VA_ARGS__); \
    for (j = 1; white_pcs[j] >= 0; j++) { \
      k = white_pcs[j]; \
      uint64_t idx3 = idx2 | ((uint64_t)p[k] << shift[i]); \
      func(k, table_w, idx3 & ~mask[k], occ, p, ##__VA_ARGS__); \
    } \
  } while (0)
#else
#define LOOP_WHITE_PIECES(func, ...) \
  do { \
    bitboard bits = king_range[p[0]]; \
    for (j = 1; white_pcs[j] >= 0; j++) { \
      k = white_pcs[j]; \
      if (bit[p[k]] & bits) continue; \
      uint64_t idx3 = idx2 | ((uint64_t)p[k] << shift[i]); \
      func(k, table_w, idx3 & ~mask[k], occ, p, ##__VA_ARGS__); \
    } \
  } while (0)
#endif

#ifndef ATOMIC
#define LOOP_BLACK_PIECES(func, ...) \
  do { for (j = 0; black_pcs[j] >= 0; j++) { \
    k = black_pcs[j]; \
    uint64_t idx3 = idx2 | ((uint64_t)p[k] << shift[i]); \
    func(k, table_b, idx3 & ~mask[k], occ, p, ##__VA_ARGS__); \
  } } while (0)
#else
#define LOOP_BLACK_PIECES(func, ...) \
  do { \
    bitboard bits = king_range[p[black_king]]; \
    for (j = 1; black_pcs[j] >= 0; j++) { \
      k = black_pcs[j]; \
      if (bit[p[k]] & bits) continue; \
      uint64_t idx3 = idx2 | ((uint64_t)p[k] << shift[i]); \
      func(k, table_b, idx3 & ~mask[k], occ, p, ##__VA_ARGS__); \
  } } while (0)
#endif

#define CHECK_BLACK_PIECES_PIVOT \
  for (j = 0; black_pcs[j] >= 0; j++) { \
    k = black_pcs[j]; \
    if (!(p[k] & 0x24) && mirror[p[k]] >= 0) break; \
  } \
  if (black_pcs[j] < 0) continue

#ifndef ATOMIC
#define LOOP_BLACK_PIECES_PIVOT(func, ...) \
  do { for (j = 0; black_pcs[j] >= 0; j++) { \
    k = black_pcs[j]; \
    if ((p[k] & 0x24) || mirror[p[k]] < 0) continue; \
    uint64_t idx3 = idx2 | tri0x40[p[k]]; \
    func(k, table_b, idx3 & ~mask[k], occ, p, ##__VA_ARGS__); \
  } } while (0)
#else
#define LOOP_BLACK_PIECES_PIVOT(func, ...) \
  do { \
    bitboard bits = king_range[p[black_king]]; \
    for (j = 1; black_pcs[j] >= 0; j++) { \
      k = black_pcs[j]; \
      if (bit[p[k]] & bits) continue; \
      if ((p[k] & 0x24) || mirror[p[k]] < 0) continue; \
      uint64_t idx3 = idx2 | tri0x40[p[k]]; \
      func(k, table_b, idx3 & ~mask[k], occ, p, ##__VA_ARGS__); \
  } } while (0)
#endif

// BEGIN_ITER and LOOP_ITER macros
#define BEGIN_ITER \
  uint64_t idx, idx2; \
  bitboard occ, bb; \
  int i, j, k; \
  int n = numpcs; \
  int p[MAX_PIECES]; \
  uint64_t end = thread->end

#define LOOP_ITER \
  for (idx = thread->begin; idx < end; idx++)

#ifndef BEGIN_ITER_ALL
#define BEGIN_ITER_ALL \
  uint64_t idx; \
  bitboard occ, bb; \
  int i; \
  int n = numpcs; \
  int p[MAX_PIECES]; \
  uint64_t end = size

#define LOOP_ITER_ALL \
  for (idx = 0; idx < end; idx++)
#endif

// CHECK macros
#define CHECK_WHITE_PIECES \
  for (j = 0; white_pcs[j] >= 0; j++) { \
    k = white_pcs[j]; \
    if (!(p[k] & 0x38)) break; \
  } \
  if (white_pcs[j] < 0) continue

#define CHECK_BLACK_PIECES \
  for (j = 0; black_pcs[j] >= 0; j++) { \
    k = black_pcs[j]; \
    if (!(p[k] & 0x38)) break; \
  } \
  if (black_pcs[j] < 0) continue

#define CHECK_PIECES_PIVOT \
  for (j = 0; black_pcs[j] >= 0; j++) { \
    k = black_pcs[j]; \
    if (!(p[k] & 0x24)) break; \
  } \
  if (black_pcs[j] < 0) continue

// LOOP_PIECES_PIVOT
#ifndef ATOMIC
#define LOOP_PIECES_PIVOT(func, ...) \
  do { for (j = 0; black_pcs[j] >= 0; j++) { \
    k = black_pcs[j]; \
    if ((p[k] & 0x24)) continue; \
    uint64_t idx3 = idx2 | tri0x40[p[k]]; \
    func(k, table_b, idx3 & ~mask[k], occ, p, ##__VA_ARGS__); \
  } } while (0)
#else
#define LOOP_PIECES_PIVOT(func, ...) \
  do { \
    bitboard bits = king_range[p[white_king]]; \
    for (j = 1; black_pcs[j] >= 0; j++) { \
      k = black_pcs[j]; \
      if (bit[p[k]] & bits) continue; \
      if ((p[k] & 0x24)) continue; \
      uint64_t idx3 = idx2 | tri0x40[p[k]]; \
      func(k, table_b, idx3 & ~mask[k], occ, p, ##__VA_ARGS__); \
  } } while (0)
#endif

// RETRO macro
#ifdef _MSC_VER
// MSVC doesn't support ##__VA_ARGS__, so we need separate macros
#define RETRO_NO_ARG(func) \
  for (j = 0; pcs[j] >= 0; j++) { \
    k = pcs[j]; \
    uint64_t idx3 = idx2 | ((uint64_t)p[k] << shift[i]); \
    func(k, table, idx3 & ~mask[k], occ, p); \
  }

#define RETRO_1_ARG(func, arg1) \
  for (j = 0; pcs[j] >= 0; j++) { \
    k = pcs[j]; \
    uint64_t idx3 = idx2 | ((uint64_t)p[k] << shift[i]); \
    func(k, table, idx3 & ~mask[k], occ, p, arg1); \
  }

// Fallback - just use RETRO_NO_ARG for MSVC compatibility
// Code will be updated to use explicit RETRO_NO_ARG/RETRO_1_ARG calls
#define RETRO(func, ...) RETRO_NO_ARG(func)
#else
#define RETRO(func, ...) \
  for (j = 0; pcs[j] >= 0; j++) { \
    k = pcs[j]; \
    uint64_t idx3 = idx2 | ((uint64_t)p[k] << shift[i]); \
    func(k, table, idx3 & ~mask[k], occ, p, ##__VA_ARGS__); \
  }
#endif

// PIVOT function definitions
#ifdef _MSC_VER
#define MARK_PIVOT_NO_ARG(func) \
static void func##_pivot(uint8_t *table, uint64_t idx, bitboard occ, int *p)

#define MARK_PIVOT_1_ARG(func, arg1) \
static void func##_pivot(uint8_t *table, uint64_t idx, bitboard occ, int *p, arg1)

#define MARK_PIVOT(func, arg1) MARK_PIVOT_1_ARG(func, arg1)
#else
#define MARK_PIVOT(func, ...) \
static void func##_pivot(uint8_t *table, uint64_t idx, bitboard occ, int *p, ##__VA_ARGS__)
#endif