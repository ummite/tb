# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a chess tablebase generator for up to 7 pieces, producing Syzygy-style endgame databases. The generator creates compressed WDL (win/draw/loss) and DTZ (distance-to-zero) files used by chess engines for optimal endgame play.

## Build and Run

### Prerequisites
- GCC/MinGW with C11 support
- ZSTD library and headers (or LZ4 as alternative)
- 16GB+ RAM for 6-piece tables, ~1TB for 7-piece tables

### Build Commands
```bash
cd src
make all          # Build standard tablebase tools (rtbgen, rtbgenp, rtbver, rtbverp, tbcheck)
make atomic       # Build atomic chess variant tools (atbgen, atbgenp, atbver, atbverp, tbcheck)
make suicide      # Build suicide chess variant tools (stbgen, stbgenp, tbcheck)
make giveaway     # Build giveaway chess variant tools (gtbgen, gtbgenp, tbcheck)
make shatranj     # Build shatranj tools (jtbgen, jtbgenp, jtbver, jtbverp, tbcheck)
```

### Main Tools
- `rtbgen` / `rtbgenp` - Generate pawnless/pawnful regular tablebases
- `rtbver` / `rtbverp` - Verify regular tablebases
- `tbcheck` - Check file integrity via embedded checksums (runs from current directory only)
- `atbgen` / `atbgenp` - Generate atomic chess tablebases (`.atbw`/`.atbz`)
- `stbgen` / `stbgenp` - Generate suicide chess tablebases (`.stbw`/`.stbz`)
- `gtbgen` / `gtbgenp` - Generate giveaway chess tablebases (`.gtbw`/`.gtbz`)
- `jtbgen` / `jtbgenp` - Generate shatranj tablebases (`.jtbw`/`.jtbz`)

### Usage Examples
```bash
cd src
rtbgen KQRvKR                    # Generate pawnless tablebase
rtbgenp KRPvKR                   # Generate pawnful tablebase
rtbgen -t 8 --stats KQRvKR       # Multi-threaded with stats
rtbver --log KQRvKR              # Verify with logging
tbcheck KQRvKR.rtbw              # Check integrity (from current dir)
```

### Python Script
```bash
python src/run.py --generate --min 3 --max 5
python src/run.py --verify --threads 8
```
The Python script is a port of `src/run.pl` and is used for generating and verifying all tablebases in bulk.

## Key Variables and Paths
- `RTBPATH` - Directory containing subtablebases (required during generation)
- `RTBSTATSDIR` - Directory for statistics files
- `WDLSUFFIX` / `DTZSUFFIX` - File extensions vary by variant (.rtbw/.rtbz for regular)

## Architecture

The codebase uses a modular design with variant-specific builds via compiler flags and separate Makefiles:

### Build Targets
| Target | Makefile | File Suffix | Env Var |
|--------|----------|-------------|----------|
| Regular (default) | Makefile.regular | .rtbw/.rtbz | RTBPATH |
| Atomic | Makefile.atomic | .atbw/.atbz | ATBPATH |
| Suicide | Makefile.suicide | .stbw/.stbz | STBPATH |
| Giveaway | Makefile.giveaway | .gtbw/.gtbz | GTBPATH |
| Shatranj | Makefile.shatranj | .jtbw/.jtbz | JTBPATH |

### Variant Flags
- `REGULAR` - Standard chess (default, implied by Makefile.regular)
- `ATOMIC` - Atomic chess (captures explode)
- `SUICIDE` - Suicide chess (must capture)
- `GIVEAWAY` - Giveaway chess (must lose pieces, subset of SUICIDE)
- `SHATRANJ` - Ancient chess variant (slower pieces, 70-move rule)

### Core Components
- **board.c/h** - Chess board representation, piece moves, magic/BMI2/hyper attack generation
- **probe.c/h** - Tablebase probing and entry structures (defines TBEntry, PairsData)
- **util.c/h** - File I/O, memory mapping, compression utilities, platform abstraction
- **compress.c/h** - WDL/DTZ compression with Huffman coding (constructs optimal codes)
- **reduce.c/p** - Table reduction (removes transpositions, categorizes values)
- **permute.c** - Permutation indexing for piece arrangements
- **types.h** - Basic types (bitboard as u64, Move as u16, piece constants, dtz_map)
- **defs.h** - Common definitions (DRAW_RULE, MAX_VALS, compiler hints like assume())

### Tablebase Files
- `.rtbw` / `.stbw` / `.gtbw` / `.atbw` / `.jtbw` - WDL data (two-sided, suffix varies by variant)
- `.rtbz` / `.stbz` / `.gtbz` / `.atbz` / `.jtbz` - DTZ data (single-sided, suffix varies by variant)

### Tablebase Naming
Format: `<attacking_material>v<defending_material>` where:
- `K` = King (always included, not counted in piece total)
- `Q` = Queen, `R` = Rook, `B` = Bishop, `N` = Knight, `P` = Pawn
- Examples: `KQvK` (2 pieces), `KQRvK` (3 pieces), `KQvKR` (4 pieces)
- Total pieces = length of string - 1 (kings included)

## Environment Variables
- `RTBPATH` - Directory containing subtablebases for generation (required)
- `RTBSTATSDIR` - Directory for statistics files (defaults to current directory)
- `RTBWDIR` / `RTBZDIR` - Separate directories for WDL/DTZ files during verification with `-d` flag

### Development Notes
- **Attack generation** - BMI2 by default (requires CPU support), with Magic and Hyper alternatives
- **Compression** - ZSTD (configurable in Makefile, requires libzstd) or LZ4 (built-in fallback)
- **Threaded compression** - Controlled by `COMPRESSION_THREADS` flag
- **Statistics** - Written to `$RTBSTATSDIR/<tbname>.txt` when `--stats` flag is used
- **Custom checksums** - Not MD5, but correct checksums are known and embeds are verified
- **Template-based generation** - `compress_tmpl.c`, `permute_tmpl.c`, `reduce_tmpl.c` used with `EVALUATOR` macro for code reuse
- **6-piece tables** - ~68GB WDL, ~82GB DTZ; requires `--disk` option on 16GB RAM systems

### Core Algorithm
The generator uses retrograde analysis:
1. **Initialize** - Start with known positions (mates, captures, draws within DRAW_RULE)
2. **Reduce** - Contract the table by removing transpositions and categorizing values
3. **Iterate backwards** - For each position, determine if it's a win (exists move to loss for opponent) or loss (all moves lead to win for opponent)
4. **Compress** - Apply Huffman coding to achieve ~3-4 bits per position (from 8 bits raw)

The key insight is that chess endgames can be solved exhaustively because the state space is small enough (e.g., 4-piece = 64^4 / symmetry ≈ 1M positions).