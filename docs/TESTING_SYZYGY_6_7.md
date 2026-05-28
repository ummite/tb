# Testing Syzygy 6-Piece and 7-Piece Tablebases

This document describes a **practical, reproducible test sequence** for 6-piece and 7-piece Syzygy (regular chess) WDL/DTZ tablebases in this project.

**Reality check (2026 hardware):**
- 6-piece generation: 50-200+ GB RAM (or heavy use of `-d` disk mode), days to weeks of CPU time, terabytes of disk for intermediates.
- 7-piece generation: ~1 TB RAM recommended without `-d`, months of CPU time on high-end hardware. Not feasible on typical developer machines.
- **Recommended testing approach for 6/7**: Focus on **verification + probing** of known-good files using the reference checksums in `checksums/`, rather than full generation from scratch.

The tools (`rtbgen`, `rtbgenp`, `rtbver`, `rtbverp`, `tbcheck`) are already compiled with `TBPIECES=7` support by default.

---

## 1. Prerequisites & Build (7-Piece Configuration)

### Visual Studio (Windows - primary)
```cmd
.\build.bat verify
```
This builds all 25 executables (including loser variants) with `TBPIECES=7`.

To force explicit 7-piece build (or experiment with 6):
- Edit the .vcxproj files (or use CMake) and ensure `-DTBPIECES=7`.
- Or use CMake below.

### CMake (recommended for configurable MAX_TBPIECES)
```bash
cmake -B build67 -DMAX_TBPIECES=7 -DATTACK_METHOD=BMI2 -DCMAKE_BUILD_TYPE=Release
cmake --build build67 --config Release --target build_all
```
- `MAX_TBPIECES=6` for a lighter 6-piece-only build.
- Output goes to `build67/bin/`.

### GCC / MinGW (bash / Git Bash / WSL)
```bash
cd src
make clean
TBPIECES=7 COMPRESSION_THREADS=8 make -j8 all variants
# Or for a specific 6-piece focused build:
TBPIECES=6 make -f Makefile.regular rtbgen rtbver tbcheck
```

**Verify your build supports 7 pieces**:
```bash
.\bin\rtbgen.exe -t 1 KQvK   # Should start (or complain about missing RTBPATH)
```

---

## 2. Environment Setup (Critical for 6/7)

```cmd
:: Windows
set RTBPATH=C:\path\to\your\3-5-piece\bases
set RTBSTATSDIR=C:\tb-stats
mkdir %RTBSTATSDIR%

:: Optional: separate output dirs (useful with -d)
set RTBWDIR=C:\tb-out\wdl
set RTBZDIR=C:\tb-out\dtz
```

The `RTBPATH` **must** contain all lower-piece tablebases (3-5 piece) for retrograde analysis during 6/7 generation. The `Syzygy/` directory in this repo contains many 3-5 piece files you can use.

For disk mode (`-d` / `--disk`):
- Generators will use far less RAM but require fast SSD + huge temporary space.

---

## 3. Verification Sequence (Safest & Most Practical for 6/7)

This is the **primary recommended test** for 6-piece and 7-piece.

### 3.1 Checksum Verification (`tbcheck`)

Reference files live in `checksums/`:
- `wdl6.txt` / `dtz6.txt`
- `wdl7.txt` / `dtz7.txt`

Example manual check (or use the script below):
```cmd
cd /d C:\your\6-7-piece\files
..\bin\tbcheck KQRNvKR.rtbw
..\bin\tbcheck KQRNvKR.rtbz
```

`tbcheck` validates the embedded CityHash checksum against the file content. It does **not** use the .txt files directly — the .txt files are human reference.

### 3.2 Full Logical Verification (`rtbver` / `rtbverp`)

```cmd
:: Pawnless 6-piece
.\bin\rtbver.exe -t 8 --log KQvKRR

:: Pawnful 7-piece example
.\bin\rtbverp.exe -t 4 --log KPPPvKRP
```

- Use `--log` (or `-l`) for detailed output.
- High thread count helps on multi-core machines.
- Verifiers also benefit from lots of RAM for large 6/7 files.

### 3.3 Automated Test Script

See the companion scripts in the repo root:
- `test_syzygy67.bat` (Windows)
- `test_syzygy67.sh` (Linux / Git Bash)

They perform:
1. Build verification (tools exist + recent).
2. RTBPATH sanity check.
3. Checksum presence report for 6/7.
4. Run `tbcheck` + `rtbver` on any 6/7 files you place in a test directory.
5. Optional probing smoke tests.

---

## 4. Generation Smoke Tests (6-Piece Only — With Extreme Caution)

**Never attempt full 6/7 generation without massive resources.**

Smallest feasible 6-piece smoke tests (with `-d` + high RAM/disk):

```cmd
set RTBPATH=Syzygy

:: Example 6-piece pawnless (still very heavy)
.\bin\rtbgen.exe -t 16 -d --stats KQvKQR

:: 6-piece with pawns (even heavier)
.\bin\rtbgenp.exe -t 8 -d --stats KRPvKRP
```

Useful flags for 6/7:
- `-d` / `--disk` : drastically reduces RAM at cost of I/O and speed.
- `-t N` : threads (start with 4-8 on workstations).
- `--stats` : writes detailed stats to `$RTBSTATSDIR`.
- `-p` : ply-accurate DTZ (slower, more accurate for some use cases).
- `-g` : generate only (no compression) — for debugging.

**Expected for real 6-piece on good hardware (2026):**
- 64 GB+ RAM or heavy `-d` usage
- Fast NVMe SSD (multiple TB free)
- Days per table on 16+ cores

7-piece is currently only realistic on specialized clusters or with distributed generation (not supported in this codebase out of the box).

---

## 5. Probing Tests (Engine Integration Path)

The core probing code lives in `src/probe.c` + `probe.h`. It is designed to be embedded in chess engines (Stockfish, etc. use similar code).

### Quick Probing Smoke Test (Future Enhancement)
You can build a tiny standalone tester:

```c
// probe_test67.c (example skeleton)
#include "probe.h"
#include <stdio.h>

int main(int argc, char **argv) {
    // tb_init() or equivalent from the probe API
    // Then tb_probe_wdl() / tb_probe_dtz() on positions from 6/7 piece FENs
    printf("6/7-piece probing test placeholder\n");
    return 0;
}
```

Compile against the probe object (requires defining the variant and linking `city-c.c`, `util.c` etc.). See how `tbver.c` uses the probe structures for inspiration.

For now, the best "probing test" for 6/7 is simply successfully loading a large `.rtbw`/`.rtbz` with `rtbver` without crashing or reporting corruption.

---

## 6. Using Python `run.py` for 6/7 Batches

The script already supports `--min` / `--max`:

```bash
python src/run.py --generate --verify --min 6 --max 6 --threads 8 --disk
python src/run.py --verify --min 7 --max 7 --threads 4
```

**Current limitations (as of this writing):**
- The combination generator loop is tuned for ≤5 pieces. For serious 6/7 work you will want to extend `multiset_sequences` usage or write a dedicated generator list.
- Always use `--disk` for `--max 6` or higher.

---

## 7. Reference Checksums Location

| File          | Purpose                     |
|---------------|-----------------------------|
| `checksums/wdl6.txt` | WDL checksums for all known 6-piece |
| `checksums/dtz6.txt` | DTZ checksums for 6-piece |
| `checksums/wdl7.txt` | WDL for 7-piece |
| `checksums/dtz7.txt` | DTZ for 7-piece |

These are the authoritative references. Any generated 6/7 file must match when run through `tbcheck`.

---

## 8. Recommended Test Matrix for 6/7

| Test Type              | 6-Piece                     | 7-Piece                  | Command Example                     |
|------------------------|-----------------------------|--------------------------|-------------------------------------|
| Checksum only          | tbcheck *.rtbw *.rtbz     | Same                     | `tbcheck KQvKQR.rtbw`              |
| Logical verification   | rtbver --log                | rtbver --log             | `rtbver -t 8 --log KBBvKNP`        |
| Pawnful verification   | rtbverp --log               | rtbverp --log            | `rtbverp -t 4 KPPvKRP`             |
| Huffman structure      | rtbver -h                   | rtbver -h                | `rtbver -h KQRNvKR`                |
| Generation (disk mode) | rtbgen -d -t 8              | Not recommended locally  | `rtbgen -d --stats KQvKQ`          |
| Stats collection       | --stats + $RTBSTATSDIR      | Same (if you dare)       | See generation step                |

---

## 9. Common Pitfalls & Tips

- **RTBPATH missing lower tables** → generation aborts or produces garbage.
- **Not enough RAM + no `-d`** → OOM or extremely slow swapping.
- **Wrong TBPIECES at compile time** → runtime index errors or truncated tables.
- 7-piece files are enormous (hundreds of GB each for complex material).
- Always keep `tbcheck` results + `rtbver --log` output when claiming "6/7 verified".
- For engine integration testing, the gold standard is loading a 7-piece file in an engine and confirming it returns the correct WDL/DTZ for known positions (e.g. from the Lomonosov or Syzygy online tables, cross-checked manually).

---

## 10. Next Steps / Future Work

- Add a real `probe_test67` binary that exercises the full probe API on 6/7 files.
- Distributed generation support for 7-piece.
- ZSTD compression support (faster/better ratio for huge tables).
- Automated download + verification of official 6/7 Syzygy sets (when legal mirrors exist).

**This sequence makes the 6-piece and 7-piece capabilities testable and documented without requiring impossible local resources.**

Run `test_syzygy67.bat` (or `.sh`) after placing any 6/7 files you want to validate into a dedicated directory.
