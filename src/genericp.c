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
#ifdef _MSC_VER
#include <intrin.h>
#define PopCount(x) __popcnt64(x)
#else
#include <x86intrin.h>
#define PopCount(x) __builtin_popcountll(x)
#endif
#else
#define PopCount(x) popcount_standard(x)
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

// FILL_OCC_CAPTS - Standard C++ version
#define FILL_OCC_CAPTS \
  uint64_t idx2 = idx ^ pw_capt_mask[i]; \
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

// FILL_OCC_CAPTS_PIVOT - Standard C++ version
#define FILL_OCC_CAPTS_PIVOT \
  uint64_t idx2 = idx ^ pw_mask; \
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

#endif // GENERICP_H