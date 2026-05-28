/*
  Copyright (c) 2011-2013, 2018 Ronald de Man

  This file is distributed under the terms of the GNU GPL, version 2.
*/

/* Loser (giveaway) chess pawnful verifier - uses suicide chess code with loser-specific rules */

/* Loser chess is a subset of suicide chess, so we use the same code */
/* Define GIVEAWAY before including stbverp.c */
#ifndef GIVEAWAY
#define GIVEAWAY
#endif
#include "stbverp.c"
