# Fix Compilation Issue Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix the compilation issues in the chess tablebase generator project to produce working .exe files.

**Architecture:** The project uses template-based code generation where `tbgen.c` is the main entry point that includes variant-specific files (rtbgen.c, atbgen.c, etc.). The Makefile expects to compile `tbgen.c` first, which then links with the variant code.

**Tech Stack:** MinGW GCC, C11, Makefiles, ZSTD/LZ4 compression

---

## Task 1: Restore Clean Working Tree

**Files:**
- Modify: `src/tbgen.c`
- Modify: `src/tbgenp.c`
- Modify: `src/tbver.c`
- Modify: `src/tbverp.c`

**Step 1: Restore all source files from the last working commit (34b43e7)**

Run:
```bash
cd src
git checkout 34b43e7 -- src/tbgen.c src/tbgenp.c src/tbver.c src/tbverp.c
git checkout 34b43e7 -- src/probe.c src/sprobe.c
git checkout 34b43e7 -- src/reduce.c src/reducep.c src/decompress.c src/checksum.c
git checkout 34b43e7 -- src/compress.c src/permute.c src/generic.c src/generics.c src/stats.c src/statsp.c
```

**Step 2: Remove orphaned variant files that shouldn't be compiled directly**

Run:
```bash
rm -f src/rtbgen.c src/rtbgenp.c src/rtbver.c src/rtbverp.c
rm -f src/atbgen.c src/atbgenp.c src/atbver.c src/atbverp.c
rm -f src/stbgen.c src/stbgenp.c src/jtbgen.c src/jtbgenp.c src/jtbver.c src/jtbverp.c
```

**Step 3: Verify file structure**

Run:
```bash
ls src/*.c | head -20
```

Expected: Should see `tbgen.c`, `tbgenp.c`, `tbver.c`, `tbverp.c`, and supporting files only.

---

## Task 2: Fix types.h Include Order

**Files:**
- Modify: `src/types.h:1-10`

**Step 1: Read current types.h**

Run `Read` tool on `src/types.h`

**Step 2: Fix include order**

The current file likely has `#include "defs.h"` before type definitions. The correct order should be:

```c
#ifndef TYPES_H
#define TYPES_H

#include <inttypes.h>

typedef uint64_t bitboard;
typedef uint16_t Move;

typedef uint8_t u8;
typedef uint16_t u16;

#include "defs.h"
```

**Step 3: Verify fix**

Run:
```bash
bash -c 'cd /c/Programmation/tb-1/src && make clean && make all 2>&1'
```

---

## Task 3: Fix compress.h Include Order

**Files:**
- Modify: `src/compress.h:10-15`

**Step 1: Read current compress.h**

Run `Read` tool on `src/compress.h`

**Step 2: Ensure defs.h is included first, then TBPIECES, then huffman/types**

```c
#ifndef COMPRESS_H
#define COMPRESS_H

#include "defs.h"
#define TBPIECES 7
#include "huffman.h"
#include "types.h"
```

**Step 3: Verify fix**

Run:
```bash
bash -c 'cd /c/Programmation/tb-1/src && make all 2>&1'
```

---

## Task 4: Fix Makefile to Build .exe Files

**Files:**
- Modify: `src/Makefile.regular:1-5`

**Step 1: Update output paths**

The Makefile should output to `../bin/rtbgen.exe` on Windows:

```makefile
GENTBNAME = ../bin/rtbgen.exe
GENTBPNAME = ../bin/rtbgenp.exe
VERTBNAME = ../bin/rtbver.exe
VERTBPNAME = ../bin/rtbverp.exe
CLEAN = clean
```

**Step 2: Create bin directory**

Run:
```bash
mkdir -p ../bin
```

**Step 3: Build and verify**

Run:
```bash
bash -c 'cd /c/Programmation/tb-1/src && make all 2>&1'
```

---

## Task 5: Build All Variant Targets

**Files:**
- Modify: `Makefile.atomic`, `Makefile.suicide`, `Makefile.giveaway`, `Makefile.shatranj`

**Step 1: Build regular**

Run:
```bash
bash -c 'cd /c/Programmation/tb-1/src && make -f Makefile.regular all'
```

**Step 2: Build atomic**

Run:
```bash
bash -c 'cd /c/Programmation/tb-1/src && make -f Makefile.atomic all'
```

**Step 3: Build suicide**

Run:
```bash
bash -c 'cd /c/Programmation/tb-1/src && make -f Makefile.suicide all'
```

**Step 4: Build shatranj**

Run:
```bash
bash -c 'cd /c/Programmation/tb-1/src && make -f Makefile.shatranj all'
```

---

## Task 6: Verification

**Step 1: Check that .exe files were created**

Run:
```bash
ls -la ../bin/*.exe
```

Expected: Should see rtbgen.exe, rtbgenp.exe, rtbver.exe, rtbverp.exe

**Step 2: Run help on rtbgen**

Run:
```bash
../bin/rtbgen.exe --help
```

Expected: Should show usage information

**Step 3: Update tasks**

Mark all tasks as completed.

---

**Plan complete. Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?**