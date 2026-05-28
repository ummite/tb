# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Chess tablebase generator for up to 7 pieces, producing Syzygy-style compressed WDL (win/draw/loss) and DTZ (distance-to-zero) endgame databases. Supports six chess variants: regular, atomic, suicide, giveaway, shatranj, and loser (alias for giveaway). GPL v2. Author: Ronald de Man.

All source is in `src/`. All source files are C, compiled as C11. The project uses the C compiler (not C++) — `.c` files only, no C++ standard library.

## Build

Three build systems. All produce executables in `bin/`.

### Visual Studio (Windows, primary)
```bash
build.bat              # Release, all 21 projects
build.bat debug        # Debug configuration
build.bat clean        # Clean build artifacts
build.bat verify       # Build and verify all executables exist
```
Solution: `tbgen.sln` (21 projects, x64, VS 2022+, toolset v145). `build.bat` auto-discovers MSBuild by scanning VS 2026/2022/Insiders/Community/Professional/Enterprise and BuildTools install paths.

### CMake (Cross-platform)
```bash
cmake -B build -DATTACK_METHOD=BMI2 -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release --target build_all
```
Options: `ATTACK_METHOD` (BMI2|MAGIC|HYPER), `USE_ZSTD` (ON|OFF, default OFF uses LZ4), `MAX_TBPIECES` (3-7, default 7), `COMPRESSION_THREADS_COUNT` (default 6).

### GCC/MinGW (Linux/WSL)
```bash
cd src && make all     # Regular: rtbgen, rtbgenp, rtbver, rtbverp, tbcheck
make atomic            # Atomic: atbgen, atbgenp, atbver, atbverp, tbcheck
make suicide           # Suicide: stbgen, stbgenp, stbver, stbverp, tbcheck
make giveaway          # Giveaway: gtbgen, gtbgenp, gtbver, gtbverp, tbcheck
make shatranj          # Shatranj: jtbgen, jtbgenp, jtbver, jtbverp, tbcheck
make variants          # All variants
make clean             # Clean all variants
```
Variables: `ATTACK_METHOD` (MAGIC default), `USE_COMPRESSION` (LZ4|ZSTD), `TBPIECES` (default 7), `COMPRESSION_THREADS` (default 6), `DEBUG` (0|1), `BUILD_LEVEL` (0-3, s, z; default 3).

**Makefile delegation:** `src/Makefile` sets compiler flags and delegates each executable to a variant-specific Makefile (e.g., `Makefile.regular`), which sets defines/paths and includes `Makefile.general` for common build rules. Objects go to `objsr/` (or `objsa/` etc.), dependencies to `.depsr/`.

### Executable Summary

| Variant | Generator | Pawnful Generator | Verifier | Pawnful Verifier |
|---------|-----------|-------------------|----------|------------------|
| Regular | rtbgen | rtbgenp | rtbver | rtbverp |
| Atomic | atbgen | atbgenp | atbver | atbverp |
| Suicide | stbgen | stbgenp | stbver | stbverp |
| Giveaway | gtbgen | gtbgenp | gtbver | gtbverp |
| Shatranj | jtbgen | jtbgenp | jtbver | jtbverp |
| Loser | ltbgen | ltbgenp | ltbver | ltbverp | (integrated 2026) |

Plus `tbcheck` for checksum verification (shared). Loser chess reuses suicide chess code — `ltbgen.c` defines `GIVEAWAY` then `#include "stbgen.c"`. Same pattern for `ltbgenp.c`, `ltbver.c`, `ltbverp.c`. Now fully supported in Makefile, Visual Studio solution (ltbgen.vcxproj etc), and CMakeLists.txt (loser target + build_all). Use -DLOSER -DGIVEAWAY -DSUICIDE for compilation. Produces ltbgen/ltbver etc. and .ltbw/.ltbz files with LTBPATH magic handling.

## Generate and Verify Tablebases

```bash
# Set path to subtablebases (required for generation)
export RTBPATH=/path/to/tablebases   # Linux
set RTBPATH=C:\path\to\tablebases    # Windows

# Generate single tablebases
rtbgen -t 8 --stats KQRvKR           # Pawnless
rtbgenp -t 8 --stats KRPvKR          # Pawnful

# Verify
tbcheck KQRvKR.rtbw                   # Checksum check only
rtbver --log KQRvKR                   # Full verification

# Bulk operations (Python, runs from cwd)
python src/run.py --generate --min 3 --max 5 --threads 8
python src/run.py --verify --threads 8
```

Key generator options: `-t N` (threads), `--stats` (save stats to `$RTBSTATSDIR`), `--wdl`/`--dtz` (only one file type), `-d` (reduce RAM, **required** for 6-piece on typical machines), `-g` (generate without compressing), `-p` (ply-accurate DTZ), `-A -n N` (auto-generate all N-piece pawnless tables).

**Testing 6-piece and 7-piece Syzygy tables**: See `docs/TESTING_SYZYGY_6_7.md` and the scripts `test_syzygy67.bat` / `test_syzygy67.sh`. Full generation is extremely heavy; the recommended path is verification against `checksums/{wdl,dtz}6.txt` + `7.txt` plus probing tests.

Environment variables: `RTBPATH` (subtablebase directory, required), `RTBSTATSDIR` (stats output, default `.`), `RTBWDIR`/`RTBZDIR` (separate WDL/DTZ dirs for verifier with `-d`).

Reference checksums are in `checksums/` (wdl345.txt, wdl6.txt, dtz345.txt, dtz6.txt, dtz7.txt).

## Architecture

### Preprocessor-Based Code Generation

The entire project is built from a small set of base files that `#include` variant-specific and type-specific code at compile time. There are no separate compilation units per variant — a single `tbgen.c` becomes rtbgen, atbgen, stbgen, gtbgen, or jtbgen depending on defines.

**Include chain for `tbgen.c` (pawnless generator):**
```
tbgen.c
  |-- probe.c (inline)
  |-- board.c (inline)
  |-- generics.c     [if SMALL, i.e., REGULAR or SHATRANJ]
  |-- generic.c      [if !SMALL, i.e., ATOMIC/SUICIDE/GIVEAWAY/LOSER]
  |-- rtbgen.c       [if REGULAR]
  |-- stbgen.c       [if SUICIDE (also GIVEAWAY)]
  |-- atbgen.c       [if ATOMIC]
  |-- ltbgen.c       [if LOSER — defines GIVEAWAY, then #includes stbgen.c]
  |-- jtbgen.c       [if SHATRANJ]
  |-- stats.c        [after variant code]
  |-- reduce.c       [after stats]
      |-- reduce_tmpl.c  [with T=u8, then T=u16]
```

**Include chain for `tbgenp.c` (pawnful generator):**
```
tbgenp.c
  |-- genericp.c       [always — pawnful has no SMALL/SMALL2 split]
  |-- rtbgenp.c        [if REGULAR]
  |-- stbgenp.c        [if SUICIDE]
  |-- atbgenp.c        [if ATOMIC]
  |-- ltbgenp.c        [if LOSER — defines GIVEAWAY, then #includes stbgenp.c]
  |-- jtbgenp.c        [if SHATRANJ]
  |-- statsp.c         [after variant code]
  |-- reducep.c        [after stats]
      |-- reducep_tmpl.c [with T=u8, then T=u16]
```

**Include chain for `tbver.c` (pawnless verifier):**
```
tbver.c
  |-- probe.c (inline)
  |-- board.c (inline)
  |-- generic.c        [if !SMALL]
  |-- generics.c       [if SMALL]
  |-- rtbver.c         [if REGULAR]
  |-- stbver.c         [if SUICIDE]
  |-- atbver.c         [if ATOMIC]
  |-- ltbver.c         [if LOSER — defines GIVEAWAY, then #includes stbver.c]
  |-- jtbver.c         [if SHATRANJ]
```

The pawnful verifier (`tbverp.c`) follows the same pattern but includes `genericp.c` instead of `generic.c`/`generics.c`. Verifiers do NOT include stats or reduce — they only load and verify.

**Type templating:** `compress.c` includes `compress_tmpl.c` twice (`T=u8`, then `T=u16`) to generate `compress_u8_*` and `compress_u16_*` function families. Same pattern in `reduce.c` and `permute.c`.

### The Two Orthogonal Dimensions

Code selection depends on two independent axes:

1. **Variant** (REGULAR/ATOMIC/SUICIDE/GIVEAWAY/SHATRANJ/LOSER) — controls chess rules: move generation, mate detection, draw conditions. Selected via `#if/#elif` in `tbgen.c`/`tbver.c`.

2. **Encoding** (SMALL vs non-SMALL) — controls board position indexing. `SMALL` is defined when REGULAR or SHATRANJ is set, enabling king-pair encoding (462 unique KK positions via `KK_map[64][64]`). Non-SMALL (atomic/suicide/giveaway) uses single-king encoding (10 upper-triangle squares for the first piece).

These are independent: the variant flag determines rules, SMALL determines how positions are packed into indices. The `generic.c`/`generics.c` selection and `rtbgen.c`/`atbgen.c`/`stbgen.c`/`jtbgen.c` selection happen in separate `#if` chains.

### Variant Flags, Suffixes, and Magic Numbers

| Flag | Variant | WDL suffix | DTZ suffix | Path var | WDL magic | DTZ magic |
|------|---------|------------|------------|----------|-----------|-----------|
| REGULAR | Standard chess | .rtbw | .rtbz | RTBPATH | 0x5d23e871 | 0xa50c66d7 |
| ATOMIC | Captures explode | .atbw | .atbz | ATBPATH | 0x49a48d55 | 0xeb5ea991 |
| SUICIDE | Must capture | .stbw | .stbz | STBPATH | 0x1593f67b | 0x23e7cfe4 |
| GIVEAWAY | Must lose pieces | .gtbw | .gtbz | GTBPATH | 0x21bc55bc | 0x501bf5d6 |
| SHATRANJ | Ancient chess | .jtbw | .jtbz | JTBPATH | 0xb4e9b3b7 | 0x87c126fc |
| LOSER | Loser chess | .ltbw | .ltbz | LTBPATH | (uses GIVEAWAY) | (uses GIVEAWAY) |

Note: `GIVEAWAY` implies `SUICIDE` in `defs.h` (`#ifdef GIVEAWAY / #define SUICIDE`). The VS project for giveaway compiles with both `-DGIVEAWAY -DSUICIDE`. The `DRAW_RULE` is 100 plies for REGULAR, 140 for SHATRANJ. Magic numbers and suffixes are defined in `probe.h`.

### WDL Value Encoding

The generator uses a symmetric value scheme around `STAT_DRAW` (512 for 6-piece, 640 for 7-piece):
- Wins are **below** 512: lower value = faster win (WIN_IN_ONE=2)
- Losses are **above** 512: higher value = faster loss (LOSS_IN_ONE=0xf9, MATE=0xfa)
- Special markers: ILLEGAL=0, UNKNOWN=0xfe, BROKEN=0xff, CHANGED=0xfd, CAPT_CLOSS=0xfc
- CAPT_CWIN is defined as `STAT_DRAW - 2` (510 for 6-piece), NOT `WIN_IN_ONE + DRAW_RULE` despite a misleading comment in `rtbgen.c`
- `REDUCE_PLY` is 122 for regular, defines the retrograde search horizon

This encoding is defined in `rtbgen.c` (and variant-specific equivalents), then used by `reduce.c` to map values during compression.

### Compression Architecture

**WDL compression** (`compress.c`): Non-templated, always `u8`. Uses pair-based (digram) Huffman coding. The algorithm:
1. Counts adjacent symbol pair frequencies across the entire table (threaded)
2. Iteratively merges highest-frequency pairs into composite symbols
3. Resolves 4 "don't-care" wildcards to least-cost real values
4. Builds canonical Huffman codes via `create_code()` → `sort_code()`
5. Falls back to package-merge (L=32 length-constrained) if standard Huffman exceeds 32-bit codes

**DTZ compression** (`compress_tmpl.c`): Templated for `u8` (narrow, <256 unique values) and `u16` (wide, >=256). Uses 4-category value mapping (win-short, loss-short, win-long, loss-long) from `struct dtz_map`.

**The `tb_handle` struct** (from `compress.h`) tracks per-table Huffman codes, symbol tables, block sizes, and permutation state. **Gotcha:** `decompress.h` defines a completely different `tb_handle` — the two headers mutually exclude each other via `#ifdef` guards (`#error` if both are defined).

### Core Components

- **board.c/h** - Board representation, move generation. Bitboards (`u64`). Sliding piece attacks via `magic.c`, `hyper.c`, or `bmi2.c` (selected at compile time). Key inlines: `FirstOne()` (CTZ), `PopCount()`, `PieceRange()` (attack bitboard), `PieceMoves()` (attacks minus occupancy).
- **probe.c/h** - Tablebase probing. Defines `TBEntry`, `TBEntry_piece`, `TBEntry_pawn`, `PairsData`. `TBEntry_piece` has per-side `factor[]`, `pieces[]`, `norm[]`, `order[]` arrays for pawnless indexing. `TBEntry_pawn` has a `file[4]` array of per-file sub-tables (files a-d, by symmetry).
- **reduce.c** / **reducep.c** - Retrograde analysis for pawnless/pawnful. Maps full value range to reduced set after each pass. Includes `reduce_tmpl.c`/`reducep_tmpl.c` with `T=u8` then `T=u16`. Pawnful version has per-save-index tracking (`reduce_cnt` array, `local` parameter).
- **compress.c/h** - Huffman compression. `struct tb_handle` with `HuffCode *c[8]`, `Symbol *symtable[8]`, `blocksize[]`, `idxbits[]`. WDL compression always `u8`, DTZ templated for `u8`/`u16`.
- **permute.c/h** - Permutation indexing, removes transpositions. Templated (`T=u8/u16`) via `permute_tmpl.c`. Uses `EVALUATOR(x,y)` two-level macro for function name generation.
- **util.c/h** - File I/O, memory mapping (`mmap`/`CreateFileMapping`), platform abstraction, checksum verification (CityHash-based, not MD5). Writes little-endian data: `write_u32/u16/u8/bits()`. `alloc_huge()` tries huge pages for large tables.
- **threads.c/h** - C11 thread pool. `wincompat.c` provides MSVC compatibility via `c11threads.h` (wraps Win32 `CRITICAL_SECTION`, `CreateThread`, `TlsAlloc`).
- **stats.c** vs **statsp.c** — Pawnless stats handles diagonal symmetry (positions below diagonal counted with weight 2). Pawnful stats tracks pawn-file sub-tables (4 file positions), has `local` parameter for per-reduction-step tracking, global longest-game FEN strings, and pawn-move-specific counters (`STAT_PAWN_WIN`, `STAT_PAWN_CWIN`, `STAT_PAWN_DRAW`).
- **types.h** - `bitboard` = `uint64_t`, `Move` = `uint16_t`, piece constants PAWN=1..KING=6, WPAWN=1..BKING=14 (black = type | 0x08). Defines `struct dtz_map` with 4-category value mapping arrays.
- **defs.h** - `DRAW_RULE` (100/140), `MAX_VALS`, `SMALL` (defined for REGULAR/SHATRANJ), `likely()`/`unlikely()`/`assume()` compiler hints, `EVALUATOR(x,y)` macro concatenation.
- **probe.h** - Variant-specific magic numbers, file suffixes, and environment variable names. Contains `#error` guard against including both compress.h and decompress.h.

### MSVC Compatibility Layer

The project compiles as C11 on both GCC and MSVC. Key compatibility shims:
- `compat.h` — `__restrict__`, `__inline__`, `strcasecmp`/`strdup` mapping, atomic CAS via `_InterlockedCompareExchange8` on MSVC.
- `wincompat.h/c` — `getopt()`/`getopt_long()` implementation (161 lines), `usleep()`, `gettimeofday()` (via `GetSystemTimePreciseAsFileTime` with epoch offset `116444736000000000LL`).
- `c11threads.h` / `c11threads_win32.c` — Full C11 thread API on Win32: `thrd_t` = thread ID, `mtx_t` = `CRITICAL_SECTION`, `cnd_t` = `SleepConditionVariableCS` (Vista+) or custom semaphore fallback. `call_once` uses `InitOnceExecuteOnce` (Vista+) or `InterlockedCompareExchange`.

### Attack Generation Methods

Selected at compile time via `ATTACK_METHOD`. Three options for bishop/rook/queen attacks:
- **BMI2** - Uses `_pext_u64` intrinsic (fastest, requires BMI2 CPU + `-mbmi2`/`/arch:AVX2`)
- **MAGIC** - Magic number bitboards with precomputed tables (most portable, GCC default)
- **HYPER** - Hyperbola tables (alternative)

Note: `board.h` line 16 has `#if defined(MAGIC) && defined(BMI2) / #undef BMI2` — defining both causes BMI2 to be silently dropped in favor of MAGIC to avoid symbol conflicts.

### Tablebase File Format

Tablebase files are written little-endian with:
1. 4-byte magic number (variant-specific, defined in `probe.h`)
2. Metadata: piece types, symmetry flags, value mappings, block sizes
3. Compressed data blocks with Huffman coding (pair-based digram compression)
4. Embedded CityHash checksum appended at end

`tbcheck` validates the embedded checksum. `checksums/` directory contains reference checksums for all known tablebases.

### Tablebase Naming

`<attacking_material>v<defending_material>`: K=King, Q=Queen, R=Rook, B=Bishop, N=Knight, P=Pawn. Kings always included, not counted in piece total. Total pieces = string length - 1. Example: `KRPvKR` = 4 pieces.

### Key Constants

| Constant | Value | Meaning |
|----------|-------|---------|
| `TBPIECES` | 7 (default) | Max piece count |
| `DRAW_RULE` | 100 (REGULAR) / 140 (SHATRANJ) | 50-move rule ply count |
| `MAX_STATS` | 1536 (<7 pieces) / 2560 (7 pieces) | Stats array size |
| `MAX_VALS` | `(MAX_STATS/2 - DRAW_RULE) / 2` | Max compressed values (~298 for 6-piece) |
| `MAXSYMB` | 4103 | Max Huffman symbols |
| `HUGEPAGESIZE` | 2 MiB | Huge page allocation granularity |
| `STAT_DRAW` | `MAX_STATS/2` | Center of WDL value encoding (512/640) |
| `REDUCE_PLY` | 122 (REGULAR) | Retrograde search horizon |
