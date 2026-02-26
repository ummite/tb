# Auto-Generation Mode Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add command-line auto-generation mode to tbgen.c that generates all valid tablebase combinations for specified piece counts (3-7) with confirmation and prerequisite checking.

**Architecture:** Add new `-a`/`--auto` and `-n <pieces>` options to tbgen.c that generate all valid piece combinations recursively, checking for and generating missing subtablebases first.

**Tech Stack:** C11, MinGW GCC, existing tablebase generation infrastructure (rtbgen/rtbgenp)

---

## Overview

This plan implements the user's request: instead of specifying individual tablebases like "KQvK", users can specify piece counts (3,4,5,6,7) and the program auto-generates ALL valid combinations, asking for confirmation and handling prerequisites.

## Task Structure

### Task 1: Add auto-generation command-line options

**Files:**
- Modify: `src/tbgen.c:702-710` (options array)
- Modify: `src/tbgen.c:712-800` (main function)

**Step 1: Add new options to options array**

Add at lines 702-710:
```c
static struct option options[] = {
  { "threads", 1, NULL, 't' },
  { "wdl", 0, NULL, 'w' },
  { "dtz", 0, NULL, 'z' },
  { "stats", 0, NULL, 's' },
  { "disk", 0, NULL, 'd' },
  { "affinity", 0, NULL, 'a' },
  { "auto", 0, NULL, 'A' },    // NEW: auto-generation mode
  { "pieces", 1, NULL, 'n' },  // NEW: number of pieces
  { 0, 0, NULL, 0 }
};
```

**Step 2: Add variables for auto-generation mode**

Add at lines 107-111 (after existing static variables):
```c
static int minfreq = 8;
static int only_generate = 0;
static int generate_dtz = 1;
static int generate_wdl = 1;
static int auto_mode = 0;              // NEW
static int num_pieces_to_generate = 0; // NEW
```

**Step 3: Handle new options in getopt_long**

Modify the switch at lines 724-750 to add:
```c
case 'A':
  auto_mode = 1;
  break;
case 'n':
  num_pieces_to_generate = atoi(optarg);
  break;
```

**Step 4: Add auto-generation logic in main**

After line 751 (after getopt_long loop), add:
```c
  // Handle auto-generation mode
  if (auto_mode) {
    if (num_pieces_to_generate < 3 || num_pieces_to_generate > 7) {
      fprintf(stderr, "Number of pieces must be between 3 and 7.\n");
      exit(1);
    }
    // Call auto-generation function (to be implemented in Task 2)
    auto_generate_all(num_pieces_to_generate);
    exit(0);
  }
```

**Step 5: Run test to verify it fails**

Run: `gcc -O3 -flto=auto -o ../bin/tbgen_test.exe tbgen.c tbgenp.c tbver.c tbverp.c permute.c compress.c huffman.c threads.c lz4.c decompress.c checksum.c city-c.c tbcheck.c util.c -DREGULAR 2>&1 | head -20`
Expected: FAIL with "implicit declaration of function 'auto_generate_all'"

**Step 6: Commit**

```bash
cd src
git add tbgen.c
git commit -m "cli: add auto-generation mode command-line options"
```

### Task 2: Implement combination generation functions

**Files:**
- Modify: `src/tbgen.c` (add new functions before main)

**Step 1: Add helper function to generate pawnless combinations**

Add at lines 90-103 (before HUGEPAGESIZE define):
```c
// Generate all pawnless combinations for N pieces
static void generate_pawnless_combos(int n) {
  // For 3 pieces: KQvK, KRvK, KNvK, KBvK
  // For 4 pieces: KQQvK, KQNvK, KQBvK, KQRvK, KRRvK, KRNvK, KRBvK, KNNvK, KBNvK, KBBvK
  // For 5+ pieces: all combinations of n-1 pieces + King vs King
  // Implementation uses recursive combination generation
}
```

**Step 2: Add helper function to generate pawnful combinations**

Add after pawnless function:
```c
// Generate all pawnful combinations for N pieces
static void generate_pawnful_combos(int n) {
  // For 3 pieces: KPvK, KAPvK, KRPvK, KNPvK, KBPvK, KQPvK
  // For 4+ pieces: all combinations with pawns
  // Uses rtbgenp instead of rtbgen
}
```

**Step 3: Implement main auto-generation function**

Add the complete `auto_generate_all(int n)` function:
```c
static void auto_generate_all(int n) {
  printf("Auto-generating all %d-piece tablebases...\n", n);

  // First, check for and generate missing subtablebases
  printf("Checking prerequisites...\n");
  // Implementation checks existing .rtbw files in bin folder

  // Then generate all combinations
  printf("Generating combinations...\n");
  // Call generate_pawnless_combos(n)
  // Call generate_pawnful_combos(n)

  printf("Generation complete!\n");
}
```

**Step 4: Run test to verify it fails**

Run: `gcc -O3 -flto=auto -o ../bin/tbgen_test.exe tbgen.c tbgenp.c tbver.c tbverp.c permute.c compress.c huffman.c threads.c lz4.c decompress.c checksum.c city-c.c tbcheck.c util.c -DREGULAR`
Expected: FAIL with "undefined reference to 'auto_generate_all'"

**Step 5: Write minimal implementation**

Complete all three functions with actual combination generation logic

**Step 6: Run test to verify it passes**

Run: `gcc -O3 -flto=auto -o ../bin/tbgen_test.exe tbgen.c tbgenp.c tbver.c tbverp.c permute.c compress.c huffman.c threads.c lz4.c decompress.c checksum.c city-c.c tbcheck.c util.c -DREGULAR && ../bin/tbgen_test.exe --help`
Expected: PASS with new options shown in help

**Step 7: Commit**

```bash
git add tbgen.c
git commit -m "feat: implement auto-generation combination functions"
```

### Task 3: Add prerequisite checking and confirmation

**Files:**
- Modify: `src/tbgen.c` (modify auto_generate_all function)

**Step 1: Add file existence checking**

In auto_generate_all, add code to check if subtablebase files exist in bin folder

**Step 2: Add missing prerequisite listing**

List all missing subtablebases before generating

**Step 3: Add confirmation prompt**

Before generating, ask user: "Generate X tablebases? (Y/N)"

**Step 4: Run test**

Run: `../bin/tbgen_test.exe -A -n 3`
Expected: Shows list and asks for confirmation

**Step 5: Commit**

```bash
git add tbgen.c
git commit -m "feat: add prerequisite checking and user confirmation"
```

### Task 4: Update tbgenp.c similarly

**Files:**
- Modify: `src/tbgenp.c:814-824` (options and main)

**Step 1: Mirror changes from tbgen.c**

Apply same auto-generation mode changes to tbgenp.c

**Step 2: Run compilation test**

Run: `make all`
Expected: PASS with 0 errors and 0 warnings

**Step 3: Commit**

```bash
git add tbgenp.c
git commit -m "feat: add auto-generation mode to tbgenp for pawnful tables"
```

### Task 5: Final verification and testing

**Files:**
- Test: bin/ directory

**Step 1: Build everything**

Run: `make clean && make all`
Expected: PASS with 0 errors and 0 warnings

**Step 2: Test auto-generation with 3 pieces**

Run: `../bin/tbgen.exe -A -n 3` and confirm with Y
Expected: Generates all 3-piece pawnless tablebases

**Step 3: Test auto-generation with 4 pieces**

Run: `../bin/tbgen.exe -A -n 4` and confirm with Y
Expected: Generates all 4-piece pawnless tablebases

**Step 4: Test auto-generation with pawns**

Run: `../bin/tbgenp.exe -A -n 3` and confirm with Y
Expected: Generates all 3-piece pawnful tablebases

**Step 5: Commit**

```bash
git add .
git commit -m "test: verify auto-generation mode works correctly"
```

## Notes

- Use `system()` calls to invoke rtbgen/rtbgenp for each combination
- Check existing .rtbw files to avoid regenerating
- Handle the "v" separator correctly in combination names
- For pawnful, use rtbgenp which has different options

## Prerequisites

- Understanding of how tablebase naming works (KQvK format)
- Knowledge of existing rtbgen/rtbgenp command-line options
- Access to bin/ folder for file existence checking