# CLAUDE.md

--compact-threshold 180000

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a chess tablebase generator for up to 7 pieces, producing Syzygy-style endgame databases. The generator creates compressed WDL (win/draw/loss) and DTZ (distance-to-zero) files used by chess engines for optimal endgame play.

## Build and Run

### Prerequisites

**GCC/MinGW (Linux/WSL):**
- GCC/MinGW with C11 support
- ZSTD library and headers (or LZ4 as alternative)
- 16GB+ RAM for 6-piece tables, ~1TB for 7-piece tables

**Visual Studio (Windows):**
- Visual Studio 2022 or later with C++ workload
- MSBuild (included with Visual Studio)

**CMake (Cross-platform):**
- CMake 3.15 or later
- C11-compatible compiler (GCC, Clang, or MSVC)

### Build Commands

**GCC/MinGW (Linux/WSL):**
```bash
cd src
make all          # Build standard tablebase tools (rtbgen, rtbgenp, rtbver, rtbverp, tbcheck)
make atomic       # Build atomic chess variant tools (atbgen, atbgenp, atbver, atbverp, tbcheck)
make suicide      # Build suicide chess variant tools (stbgen, stbgenp, tbcheck)
make giveaway     # Build giveaway chess variant tools (gtbgen, gtbgenp, tbcheck)
make shatranj     # Build shatranj tools (jtbgen, jtbgenp, jtbver, jtbverp, tbcheck)
```

**Visual Studio (Windows):**
```cmd
REM Quick build
build.bat

REM Build with options
build.bat release    # Build Release configuration
build.bat debug      # Build Debug configuration
build.bat verify     # Build and verify all 21 executables
build.bat clean      # Clean build artifacts
build.bat info       # Show build info
```

**CMake (Cross-platform):**
```bash
# Create build directory
mkdir build && cd build

# Configure with default options (LZ4, BMI2 attack generation)
cmake .. -DCMAKE_BUILD_TYPE=Release

# Build all variants
cmake --build . --config Release --target build_all

# Or configure with specific options
cmake .. -DCMAKE_BUILD_TYPE=Release -DATTACK_METHOD=BMI2 -DUSE_ZSTD=ON
```

### Visual Studio Solution

The project includes a complete Visual Studio solution (`tbgen.sln`) with 21 projects:

| Variant | Generators | Verifiers |
|---------|------------|-----------|
| Regular | tbgen, tbgenp | tbver, tbverp, tbcheck |
| Atomic | atbgen, atbgenp | atbver, atbverp |
| Suicide | stbgen, stbgenp | stbver, stbverp |
| Giveaway | gtbgen, gtbgenp | gtbver, gtbverp |
| Shatranj | jtbgen, jtbgenp | jtbver, jtbverp |

**To use:**
1. Open `tbgen.sln` in Visual Studio 2022 or later
2. Select Release or Debug configuration
3. Build All (Ctrl+Shift+B)
4. Executables output to `bin/` directory

**Architecture note:** The project uses preprocessor-based templating where `tbgen.c` and `tbver.c` include variant-specific code via `#include` directives. Each vcxproj only lists the base files (tbgen.c/tbver.c) plus common sources.

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
- **board.c/h** - Chess board representation, piece moves, attack generation. Includes `magic.c`, `hyper.c`, `bmi2.c` for sliding piece attacks. Uses bitboards (u64) for efficient position encoding.
- **probe.c/h** - Tablebase probing and entry structures. Defines `TBEntry` (base, piece, pawn variants), `PairsData` for compressed data access. Contains variant-specific suffixes and magic numbers.
- **util.c/h** - File I/O, memory mapping, compression utilities, platform abstraction. Handles `.rtbw`/`.rtbz` file format with embedded checksums.
- **compress.c/h** - WDL/DTZ compression with Huffman coding. Uses template-based code generation (`compress_tmpl.c` included twice with `T=u8` and `T=u16`). Constructs optimal codes based on symbol frequency.
- **reduce.c/p** - Table reduction via retrograde analysis. Removes transpositions, categorizes values. Separate files for pawnless (`reduce.c`) and pawnful (`reducep.c`) positions.
- **permute.c** - Permutation indexing for piece arrangements. Uses `permute_tmpl.c` with `EVALUATOR` macro for code reuse.
- **threads.c/h** - Thread pool implementation using C11 threads (`c11threads.h`). `wincompat.c` provides MSVC compatibility.
- **types.h** - Basic types: `bitboard` (u64), `Move` (u16), piece constants (PAWN=1..KING=6, WPAWN=1..BKING=14).
- **defs.h** - Common definitions: `DRAW_RULE` (100 plies regular, 140 shatranj), `MAX_VALS`, compiler hints (`likely`, `unlikely`, `assume`).

### Template-Based Code Generation
The codebase uses preprocessor templates to avoid code duplication:
- `compress_tmpl.c` - Included in `compress.c` with `#define T u8` and `#define T u16` to generate type-specialized functions
- `permute_tmpl.c`, `reduce_tmpl.c`, `reducep_tmpl.c` - Use `EVALUATOR(x,y)` macro for function name generation
- `tbgen.c`/`tbver.c` - Include variant-specific code: `rtbgen.c`, `atbgen.c`, `stbgen.c`, `jtbgen.c`
- `generics.c`/`generic.c`/`generics2.c` - Include based on `SMALL`/`SMALL2` defines for different piece counts

### Attack Generation Methods
Three methods for computing sliding piece attacks (bishop/rook/queen):
- **MAGIC** - Magic numbers with precomputed tables (most portable)
- **BMI2** - Uses `pext` instruction for bit manipulation (fastest, requires AVX2)
- **HYPER** - Hyperbola tables (alternative to magic numbers)

Selected via `ATTACK_METHOD` in CMake or Makefile. BMI2 requires `-mbmi2` (GCC) or `/arch:AVX2` (MSVC).

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

### Development Workflow

**Build and Test a Single Variant:**
```bash
# GCC
cd src && make regular      # Build rtbgen, rtbgenp, rtbver, rtbverp, tbcheck

# MSVC
build.bat release           # Build all 21 executables to bin/

# CMake
cmake -B build -DATTACK_METHOD=BMI2 && cmake --build build --target regular
```

**Generate a Single Tablebase:**
```bash
cd src
export RTBPATH=/path/to/subtablebases   # Linux
set RTBPATH=C:\path\to\subtablebases    # Windows
rtbgen -t 8 --stats KQRvKR              # 4-piece pawnless
rtbgenp -t 8 --stats KRPvKR             # 4-piece pawnful
```

**Verify Generated Tables:**
```bash
tbcheck KQRvKR.rtbw                     # Checksum verification only
rtbver --log KQRvKR                     # Full verification with logging
```

**Bulk Generation:**
```bash
python src/run.py --generate --min 3 --max 5 --threads 8
python src/run.py --verify --threads 8
```

### Key Development Patterns

**Variant-Specific Code:**
Variants are implemented via preprocessor flags. The `tbgen.c` file includes:
- `rtbgen.c` for REGULAR (standard chess)
- `atbgen.c` for ATOMIC (captures explode)
- `stbgen.c` for SUICIDE (must capture)
- `jtbgen.c` for SHATRANJ (ancient chess)

**Type-Specialized Templates:**
The `compress.c` file demonstrates the template pattern:
```c
#define T u8
#include "compress_tmpl.c"
#undef T

#define T u16
#include "compress_tmpl.c"
#undef T
```
This generates both `compress_u8_*` and `compress_u16_*` functions.

**Thread Pool Usage:**
The `threads.c` implementation uses C11 threads. Worker functions receive `struct thread_data` with `begin`, `end`, and `thread` fields for parallel processing of position ranges.

### Core Algorithm
The generator uses retrograde analysis working backwards from known end positions:

**Phase 1: Initialization**
- Start with terminal positions: checkmate (DTZ=0), stalemate (draw), captures, pawn moves
- Positions within `DRAW_RULE` (100 plies for regular, 140 for shatranj) are marked as draws

**Phase 2: Retrograde Iteration**
For each position, compute WDL values by examining all legal moves:
- **Win**: exists a move to a losing position for opponent
- **Loss**: all moves lead to winning positions for opponent  
- **Draw**: no winning move exists, but not all moves lose

**Phase 3: Table Reduction**
- Apply symmetry (flip board, swap identical pieces) to reduce state space
- Remove transpositions via permutation indexing (`permute.c`)
- Categorize positions by value for compression

**Phase 4: Compression**
- Count symbol frequencies across the table
- Build optimal Huffman codes (common values get shorter codes)
- Use pair-based compression for adjacent symbols
- Achieve ~3-4 bits per position (from 8 bits raw)

**State Space Sizes** (approximate, after symmetry):
- 3-piece: ~40K positions
- 4-piece: ~1M positions
- 5-piece: ~20M positions
- 6-piece: ~7B positions (68GB WDL, 82GB DTZ)
- 7-piece: ~1TB RAM required

### File Format
Tablebase files use a custom format with:
- Magic number header (variant-specific: `0x5d23e871` for regular WDL)
- Embedded checksum (CityHash-based, not MD5)
- Compressed data blocks with Huffman coding
- Metadata: piece types, symmetry flags, value mappings