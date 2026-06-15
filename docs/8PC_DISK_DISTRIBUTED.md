# Syzygy 8pc Low-RAM Generation with Disk + Distributed Storage/Compute

## Why
8pc tables (e.g. KPPPPPPvK) have position index ~6^7 = ~280 billion entries.
- u8 WDL table ~260 GiB per side (w+b).
- Plus DTZ (u16 when wide), temps during compress/reduce, etc. → "incredible RAM" on single machine.

Traditional dense in-RAM retrograde is impossible on normal hardware.

## Solutions (Implemented + In Progress)

### 1. Basic Disk-Backed (Immediate, OS Paging)
In `tbgenp.c` / `tbgen.c` (for pawnful/pawnless):
- `int use_disk_table = save_to_disk || (numpcs >= 7);`
- `alloc_mapped(2 * size, ...)` : create large temp file (`tablename.tmpN.table`), ftruncate, mmap (Unix) or CreateFileMapping+MapViewOfFile (Win, with DELETE_ON_CLOSE support).
- The "table" appears as normal uint8_t* array in code.
- Physical RAM = working set of current slices/pawn files + OS cache, not full size.
- Trade-off: more CPU (page faults) + I/O, but runs on typical machines with big volume (T: etc.).
- Cleanup at end; resumption via num_saves limited.

See `util.c:alloc_mapped` / `free_mapped` and comments in tbgenp.c around line 1277.

### 2. Advanced VirtualTable (Explicit Control, Multi-Backing, Prefetch)
Prototype in `virtual_table.c/h` + supporting `vt_drive_utils.*`, `vt_drive_setup.c`:
- **Bounded RAM cache**: Only `cache_size` worth of pages (e.g. 32 GiB) resident. Not the full 500+ GiB table in RAM. Pages loaded on demand from backing.
- **Multiple backing stores**: Array of paths (local fast NVMe + large slow HDDs or SAN UNC paths). Prioritized. Total disk capacity across volumes.
- **Page-based** (default 1 MiB), dirty tracking, flush.
- **`vt_prefetch_range(begin, end)`**: Hook for generator to announce "about to process this work range" (pawn slice or work partition) so cache can warm pages.
- Stats for tuning.
- Drive tool: enumerates drives, benchmarks seq R/W, suggests cache (leave headroom for OS), helps choose mix of speed vs capacity.

Polished (2026): MRU move-to-front + hash lookup for fast hot-path access, better multi-backing (priority sort, try in order on load), improved eviction/flush/destroy.

**Not yet fully wired**: tbgenp.c still uses classic mapped for compatibility. See skeleton comments and the approved plan.md for the integration path (VT as the table for 8pc, prefetch calls in calc_*/run_threaded/pawn paths).

### 3. Natural Sharding + Distributed
The algorithm already has good parallel/distrib units:
- Pawn-file loop (0-3 for leading pawn a-d files) — mostly independent (some cross-file via captures).
- `create_work` / `run_threaded` partitions.
- `num_saves` / reduce / save/load_table — progressive checkpoints. After a save, values are stable; later passes more read-heavy.

**Distributed compute/storage pattern**:
- Put VT backing files on fast shared storage (SAN, high-speed SMB/NFS, RDMA).
- Each "node" (machine or process) runs the generator with its *own* local RAM cache (tuned to its RAM) against the *shared* backing.
- Coordinator (Distribute-8pc-Slices.ps1 stub or manual) assigns slices (e.g. file=0 to node A, file=1 to B...).
- Each node processes its slice(s), writing progress to shared storage.
- Final compress/merge on a node that sees everything.
- Resume: any node can restart its slice from last num_save on shared storage.

Benefits: aggregate compute from many machines, peak RAM per machine = its cache + overhead (not full table), "more disk" spread across volumes/machines.

Safety: same low-thread, monitoring, RTBPATH for 3-7pc subtables, etc. Only traditional for 8pc.

## How to Use (Current State)

1. **Build with 8pc regular**:
   - CMake: `cmake -B build -DMAX_TBPIECES=8 ... ; cmake --build build --target regular`
   - Or make in src/ (updated Makefiles include VT objs for regular).
   - Produces rtbgenp (with TBPIECES=8 via define) etc. (history had rtbgenp8 naming for the 8pc build).

2. **Prepare backings (disk distribution)**:
   - Run the VT drive setup tool (compile `src/vt_drive_setup.c` + utils) on your volumes.
   - It shows RAM, benchmarks drives, suggests cache, helps pick mix (fast for hot + large for capacity, including network).
   - Example: T:\8pc_fast (NVMe) + T:\8pc_large or SAN UNC.

3. **Launch safely (with VT awareness)**:
   - `cd T:\8pc_work` (or large volume with 50+ TB free for backing + stores + output).
   - `.\Start-8pc-KPPPPPPvK-OnT-Safe.ps1 -Threads 2 -MonitorRAMGB 40 -UseVT -VTCacheGB 32 -VTBackings @("T:\8pc_fast","T:\8pc_large") -TableName KPPPPPPvK`
   - It validates space (sum across backings), RAM, sets RTBPATH (point to your 3-7pc tables), launches with -d, monitors, low priority, logs, post checks.
   - The -UseVT writes a config stub for future generator support.

4. **Distributed (manual / stub)**:
   - Shared config/backing visible to all nodes (SAN recommended).
   - Use `Distribute-8pc-Slices.ps1` or manually assign pawn files.
   - Node A: launcher with its cache + slice 0.
   - Node B: slice 1 etc.
   - After, one node does final output.

5. **Monitor / Resume**:
   - Watch logs, proc WS (should stay << logical size thanks to cache/mapping), disk on backings.
   - num_saves allow partial resume (limited; full restart of slice if interrupted badly).

6. **Verify**:
   - `tbcheck` on produced .rtbw/.rtbz.
   - Probe with your tools / Stockfish (once 8pc probing support is complete).

## Current Limitations & Next Steps (see approved plan.md)
- Full switch to VT accessors (vt_read_u8 etc.) + prefetch in hot paths of tbgenp.c still pending (current uses mapped for compat; VT ready and polished).
- Generator arg parsing for --use-vt / config started.
- Multi-backing in practice relies on OS/SAN for sharing + per-node caches.
- No automatic coordinator yet beyond stub.
- Only regular 8pc; variants stay 7pc.

See the full plan.md (the 8pc one) for architecture details, files changed, reuse (alloc_mapped, VT prototype, slicing, num_saves, safe launchers), and verification checklist (build, correctness vs classic on small, low-RAM demo, multi-backing, distributed sketch, tbcheck success on real 8pc table).

This gets you "davantage d'espace disque" (multi-volume/SAN backings + paging) and "calcul distribué" (sharded across nodes sharing storage) without needing a single monster RAM machine.

Questions or specific next piece (e.g. more VT integration code)? The plan has the roadmap.