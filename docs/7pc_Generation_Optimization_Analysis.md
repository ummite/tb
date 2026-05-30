# 7-Piece Syzygy Generation – Optimization, Distribution & Checkpointing Analysis

**Date:** 2026-05-29  
**Author:** Grok (analysis for user)  
**Goal:** Enable reliable, resumable, memory-efficient, and potentially distributed generation of 7-piece Syzygy tables (initial focus: KBBBBvKR, KBBBNvKN, KBBNNvKN, KBNPvKRB, KBNPvKRN) targeting the 40TB SAN volume.

---

## 1. Executive Summary

The current generator (based on Ronald de Man's original code) **technically supports 7-piece tables**, but its architecture is fundamentally designed for machines with very large amounts of RAM. On typical modern hardware (even high-end servers with 256–512 GB RAM), generating 7pc tables is extremely painful or impractical without major changes.

### Current State vs Requirements

| Requirement                    | Current State                          | Gap Level   | Notes |
|--------------------------------|----------------------------------------|-------------|-------|
| **Major RAM optimization**     | Partial (`-d` flag + some disk spilling in reduce) | **High**    | Not sufficient for comfortable 7pc runs |
| **Distributed / Multi-PC work**| None                                   | **Very High** | Single-process only |
| **Checkpoint / Resume**        | Very weak (only coarse reduce saves)   | **High**    | No safe resume after power loss |
| **VS2026 compatibility**       | Good baseline                          | Low         | Project already builds on VS2026 |

**Conclusion:** Significant architectural work is required. The existing disk spilling mechanisms provide a useful foundation, but they are not enough for the user's goals.

---

## 2. Memory Architecture & Hotspots

### 2.1 Core Allocation (the biggest problem)

**File:** `src/tbgen.c` (and equivalent logic in `tbgenp.c`)

```c
uint64_t alloc_size = ...;
table_w = alloc_huge(2 * alloc_size);
table_b = table_w + alloc_size;
```

Where `alloc_size` comes from:

```c
size = 10ULL << (6 * (numpcs-1));   // non-SMALL (atomic/suicide/giveaway)
```

For 7 pieces → **~687 GB** theoretical size before any reduction.

Even in SMALL mode (regular chess):

```c
size = 462ULL << (6 * (numpcs-2));
```

This is still hundreds of gigabytes for 7pc.

**Impact:** This single allocation is the primary reason 7pc generation requires ~1 TB RAM without heavy disk usage.

### 2.2 Other Significant Memory Consumers

- `MAX_STATS` = 2560 for 7pc (vs 1536 for ≤6pc) → `stats` arrays in threads
- Work queues (`create_work`)
- Thread-local data structures
- During DTZ phase: additional mapping structures (`dtz_map`)

### 2.3 Current Disk Mode (`-d` / `save_to_disk`)

**Location:** `tbgen.c` and `tbgenp.c`

- When enabled, the code writes one side of the table to disk (`store_table`) during WDL generation and loads it later (`load_table_u8`).
- This helps, but the spilling is **late** in the process (mostly during final compression).
- The heavy memory usage during the actual retrograde analysis / reduction passes is barely mitigated.

**Verdict:** Useful starting point, but far from a real external-memory solution.

---

## 3. Existing Disk Usage & Checkpointing Foundations

### 3.1 Reduce Phase (Best Existing Asset)

**Files:** `reduce.c`, `reduce_tmpl.c`, `reducep.c`

The reduction phase already does multiple passes and writes intermediate results:

```c
save_table(table_w, 'w');
save_table(table_b, 'b');   // when not symmetric
```

It uses files named `<tablename>.w.N` / `<tablename>.b.N` (`num_saves`).

Later it can reconstruct:

```c
reconstruct_table_u8(table_w, 'w', &map_w);
```

**Strengths:**
- Already writes partial reduced states to disk.
- Multiple reduction levels with different value mappings.

**Weaknesses:**
- Not designed as a general checkpoint system.
- No metadata about generation progress (what phase, what ply, etc.).
- Cleanup logic (`unlink_saves`) assumes the run completes successfully.
- No way to resume the *main* generation loop from a mid-reduce state.

### 3.2 Other Disk I/O

- `store_table` / `load_table` for full tables.
- Compression writes to disk.

These are mostly one-way (write at the end) rather than resumable.

---

## 4. Current Parallelism Model

**File:** `threads.c`

- Simple multi-threaded model within a **single process**.
- Work is divided using `create_work()` which generates ranges.
- Threads use barriers + atomic counter (`__sync_fetch_and_add`) to claim work items.
- `run_threaded()` is the main entry point.

**Limitations for distributed work:**
- Everything lives in one address space.
- No persistent work queue.
- No concept of "this range was already done by another machine".
- No way to split a 7pc table across machines at a fine granularity.

---

## 5. Visual Studio 2026 Compatibility

**Current Status:** Good baseline.

- The project already has `build_vs2026.bat` and recent `.vcxproj` files targeting VS2026.
- Uses C11 threads via `c11threads_win32.c` wrapper (necessary because MSVC does not have native `<threads.h>`).
- `alloc_huge` on Windows already has workarounds (huge pages were temporarily disabled in some paths for stability).
- Atomic operations use Windows intrinsics or C11 atomics where available.

**Risk Areas for Future Changes:**
- Any heavy use of C23 features or advanced C11 atomics may need fallbacks.
- File I/O and large file support on Windows (already handled via `util.c`).
- Thread affinity and huge page code paths need to stay Windows-friendly.

Overall: Feasible, but any new checkpointing or distributed code must be written with clean MSVC compatibility in mind from day one.

---

## 6. High-Level Architecture Proposal (Draft)

### 6.1 Core Principles

- **External Memory First**: Assume we cannot keep full 7pc tables in RAM. Design around disk (local fast NVMe + SAN) as primary storage for working state.
- **Checkpoint as First-Class Citizen**: Every major phase must be able to save progress and resume.
- **Work as Files on SAN**: Units of work (ranges of indices, pawn slices, reduction levels) can be represented as files/directories on the SAN. Machines pick up available work.
- **Separation of Concerns**:
  - Single-machine high-performance path (for when lots of RAM is available).
  - Distributed/resilient path (the main target for 7pc).

### 6.2 Proposed Components

1. **Persistent Work Queue**
   - Represented as directories/files on SAN.
   - Example: `work/<tablename>/reduce/level-N/pending/`, `done/`, `in-progress/`.

2. **Checkpoint Format**
   - Versioned binary + metadata (JSON or simple header).
   - Must include: current reduction level, value mapping, stats, which work items are done.
   - Should be robust to partial writes (use temp files + atomic rename).

3. **External-Memory Reduce Engine**
   - Build on top of existing `reconstruct_table` / `save_table` logic.
   - Add support for streaming / block-based processing instead of loading huge ranges.

4. **Coordinator (optional but useful)**
   - Lightweight process (can run on one machine) that assigns work units.
   - Or fully decentralized: machines just scan the SAN work directory.

5. **Resume Logic**
   - At startup, detect existing checkpoint for the table.
   - Validate consistency.
   - Skip completed phases.

### 6.3 Minimal Viable First Step (Recommended)

For the 5 specific tables you want:

1. Improve the existing `-d` path + reduce spilling so that a single 7pc table can run with "only" 128–256 GB RAM.
2. Add proper checkpointing around the `num_saves` loop (serialize `num_saves`, current `reduce_cnt`, and which reduction levels are done).
3. Make the work ranges (from `create_work`) persistable so individual pawn slices or index ranges can be resumed independently.
4. Test resumability aggressively (kill the process, restart, verify correctness).

Only after that, move to full multi-machine distribution.

---

## 7. Risks & Open Questions

- **Correctness after resume**: Extremely important. Bad checkpointing will produce wrong tablebases (silent corruption is the worst case).
- **Performance vs Resumability trade-off**: Frequent checkpoints have a cost.
- **SAN latency**: If using the SAN heavily for intermediate files during reduce, it may become a bottleneck.
- **Windows large file / memory mapping issues**: Some historical stability problems with huge allocations on Windows (see comments in `util.c`).
- **Testing**: How do we validate that a resumed 7pc table is identical to one generated without interruption?

---

## 8. Recommended Next Steps

1. **Deep dive** into the exact memory usage during a 7pc run (profiling on a smaller table first).
2. Design a minimal checkpoint format for the reduce phase.
3. Prototype resumable reduce for one 7pc table (even if slow at first).
4. Improve the disk mode to be more aggressive during the main retrograde passes.
5. Once resumability works on one machine, design the distributed work queue on top of it.

---

**Would you like me to start with step 1 (detailed memory profiling plan + code instrumentation) or directly draft the checkpoint format + resumable reduce design?**

I can also create follow-up documents:
- `7pc_Checkpoint_Design.md`
- `7pc_Distributed_Architecture.md`
- `7pc_Memory_Optimization_Plan.md`

Just say the word. I'm ready to go deep.