# Goal: Unified Tablebase Generator System
Last updated: 2026-02-27

## Quick Reference
**Essential Commands:**

| Task | Command |
|------|---------|
| **Build (GCC)** | `./build.sh` (WSL/Linux) or `make -C src all` |
| **Build (VS2026)** | `.\\build.bat` or `msbuild tbgen.sln` |
| **Generate All** | `.\generate_all.bat` (set RTBPATH first) |
| **Verify All** | `.\verify_all.bat` |
| **Check Status** | `.\status.bat` |
| **Test 4-piece** | `rtbgen KQvK` |
| **Generate 5-piece** | `rtbgen KQvKR` |

---

## Objective

Build a **unified, idempotent tablebase generation system** that:
1. Always compiles with both GCC (MinGW) and Visual Studio 2026
2. Generates all legitimate 3-5 piece tablebase combinations systematically
3. Can be run thousands of times and reliably track progress
4. Provides verification and status reporting
5. Handles RTBPATH dependencies correctly

**Phase 1**: 3-5 piece tablebases (complete)
**Phase 2**: 6-7 piece tablebases (future, requires more RAM)

---

## Requirements

1. **Dual-compiler support**: Both GCC and VS2026 builds must work identically
2. **Complete combination coverage**: All legitimate 3-5 piece combinations
3. **Idempotent operation**: Safe to run repeatedly without side effects
4. **Progress tracking**: Know what's generated, what's missing
5. **Verification**: Automatic checking of generated files
6. **RTBPATH handling**: Proper dependency management for retrograde analysis

---

## System Architecture

### Build System
| Script | Platform | Purpose |
|--------|----------|---------|
| `build.sh` | GCC/MinGW | Runs `make all` in src/ |
| `build.bat` | VS2026 | Runs MSBuild on tbgen.sln |

### Generation System
| Script | Platform | Purpose |
|--------|----------|---------|
| `generate_all.sh` | GCC/MinGW | Generates all combos via rtbgen |
| `generate_all.bat` | VS2026 | Generates all combos via rtbgen |

### Verification System
| Script | Platform | Purpose |
|--------|----------|---------|
| `verify_all.sh` | GCC/MinGW | Runs tbver on all .rtbw files |
| `verify_all.bat` | VS2026 | Runs tbver on all .rtbw files |

### Status System
| Script | Platform | Purpose |
|--------|----------|---------|
| `status.sh` | GCC/MinGW | Shows generated vs. expected count |
| `status.bat` | VS2026 | Shows generated vs. expected count |

---

## Expected Combinations

### 3-Piece Tablebases
**Pawnless (rtbgen):** KQvK, KRvK, KNvK, KBvK (4 combos)
**Pawnful (rtbgenp):** KPvK, KRPvK, KNPvK, KBPvK, KQPvK (5 combos)

### 4-Piece Tablebases
**Pawnless (rtbgen):** KQQvK, KQNvK, KQBvK, KQRvK, KRRvK, KRNvK, KRBvK, KNNvK, KBNvK, KBBvK (10 combos)
**Pawnful (rtbgenp):** KAPPvK, KARPvK, KANPvK, KABPvK, KQPPvK, KQRPvK, KQNPvK, KQBPvK, KRNPvK, K RBPvK, KQBBvK, KQRPvK... (~20 combos)

### 5-Piece Tablebases
**Pawnless (rtbgen):** KQQQvK, KQQNvK, KQQBvK, KQQRvK, KQRRvK, KQNNvK, KQNBvK, KQBBvK, KRRNvK, KRRBvK, KRNvK, KNNvK, KBNvK, KBBvK... (~30+ combos)
**Pawnful (rtbgenp):** KQRRPvK, KQRRBPvK... (~50+ combos)

**Total**: ~100-150 combinations for 3-5 pieces

---

## Usage Workflow

### Step 1: Build
```bash
# Option A: GCC (Linux/WSL)
./build.sh

# Option B: VS2026 (Windows)
.\build.bat
```

### Step 2: Set RTBPATH (Required for generation)
```bash
# Windows
set RTBPATH=C:\Programmation\tb-1\src

# Linux/WSL
export RTBPATH=/mnt/c/Programmation/tb-1/src
```

### Step 3: Generate
```bash
# Generate all 3-5 piece combinations
.\generate_all.bat

# Or generate specific combo
rtbgen KQvKR
```

### Step 4: Verify
```bash
# Verify all generated files
.\verify_all.bat

# Check specific file
tbcheck KQvKR.rtbw
```

### Step 5: Check Status
```bash
# See what's generated vs. missing
.\status.bat
```

---

## Idempotency Guarantees

The system is designed for repeated execution:

1. **First run**: Generates all missing combinations
2. **Subsequent runs**: Skips existing files, logs "SKIP" messages
3. **After RTBPATH update**: Regenerate affected combinations
4. **After verification failure**: Re-generate failed files

**Safe to run**: Thousands of times without degradation

---

## Progress Tracking

### Pre-generated Status
- **76 files** pre-generated in `src/` directory
- Includes: KQvKR, KNvKR, KBvKR, and other 4-5 piece combos

### What Needs Generation
Run `status.bat` to see:
```
Status: 76/120 generated (44 missing)
MISSING: KQvK
MISSING: KRvK
...
```

---

## Build Verification

After building, verify:
- [ ] `bin/rtbgen.exe` exists (~1-2 MB)
- [ ] `bin/rtbgenp.exe` exists (~1-2 MB)
- [ ] `bin/rtbver.exe` exists (~500 KB - 1 MB)
- [ ] `bin/rtbverp.exe` exists (~500 KB - 1 MB)
- [ ] `bin/tbcheck.exe` exists (~500 KB - 1 MB)
- [ ] All executables respond to arguments

---

## Environment Variables

| Variable | Purpose | Required For |
|----------|---------|--------------|
| `RTBPATH` | Directory with subtablebases | Generation (retrograde analysis) |
| `RTBSTATSDIR` | Directory for stats files | Optional (--stats flag) |
| `RTBWDIR` | Separate WDL directory | Optional (-d flag for verification) |
| `RTBZDIR` | Separate DTZ directory | Optional (-d flag for verification) |

---

## Notes

- **Retrograde analysis**: Generation requires existing subtablebases in RTBPATH
- **Memory requirements**: 3-piece ~1GB, 4-piece ~8GB, 5-piece ~50GB, 6-piece ~68GB WDL
- **Disk requirements**: 3-piece ~100MB, 4-piece ~1GB, 5-piece ~10GB, 6-piece ~150GB
- **Time requirements**: 3-piece ~minutes, 4-piece ~hours, 5-piece ~days, 6-piece ~weeks

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Build fails with include errors | Use MSBuild or IDE for proper SDK paths |
| Generation fails with "no subtablebases" | Set RTBPATH to directory with lower-piece tables |
| tbcheck reports checksum mismatch | Regenerate the file; existing checksums may be outdated |
| Out of memory during generation | Use --disk option for 6+ piece tables |

---

## Related Files

- `TASKS.md` - Detailed task breakdown and implementation steps
- `CLAUDE.md` - Project overview and architecture
- `expected_combos.txt` - Reference list of all legitimate combinations (to be created)

---

## Future Phases

**Phase 2** (future work):
- 6-piece tablebase generation (requires ~16GB RAM)
- 7-piece tablebase generation (requires ~1TB RAM)
- Parallel generation across multiple machines
- Cloud-based generation infrastructure