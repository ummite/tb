# Syzygy Full Cleanup & Consolidation Plan
**Date:** 2026-06-01  
**Goal:** Arrive at a single, clean, verified master repository on `T:\Syzygy` that can be safely used as `RTBPATH`.

## Current Problems (as of June 2026)

- Files are scattered across A:, S:, T:, and local.
- `T:\Syzygy` (the intended master) has quality issues that must be fixed:
  - 534 complete pairs (WDL + DTZ) out of 838 unique names
  - 264 tables with only DTZ
  - **40 conflicts** (same base name with different file sizes) — needs investigation
  - Mix of flat files + sub-directory structures
  - Detailed inventory: `logs\T-Syzygy-Detailed-Inventory.csv` (generated 2026-06-01)
- Large high-value collection still on `A:\Syzygy_A_Trier_FromOld_Ryzen7950` (~8.4 TB, mostly 6/7pc DTZ)
- No systematic verification has been performed across the whole collection
- Probing will be unreliable until this is fixed

---

## Final Target State (Definition of Done)

- All valuable tables (3-7 pieces, all variants you care about) in **one single location**: `T:\Syzygy`
- Recommended structure: **Flat** (all `*.rtbw` and `*.rtbz` directly in `T:\Syzygy\`)
- Every important endgame has both WDL and DTZ when possible
- No duplicate names with different sizes
- Regular `tbcheck` passes clean on the master
- `RTBPATH=T:\Syzygy` works reliably in Stockfish / other engines
- Old scattered locations can be archived or deleted safely

---

## Phased Plan

### Phase 0 — Preparation & Tooling (Do this first)

**Goal:** Have reliable tools and a complete picture before moving terabytes.

**Actions:**
1. Create and validate inventory tools (**DONE** - `Syzygy-Inventory.ps1` created and tested)
2. Run full inventory of current `T:\Syzygy` → **DONE** (see `logs\T-Syzygy-Detailed-Inventory.csv`)
3. Run full inventory of the A: Historical collection (recommended next)
4. Decide final directory structure (flat recommended)
5. Document current checksum / verification status

**Deliverables:**
- `logs/T-Syzygy-Current-Inventory.csv`
- `logs/A-Historical-Full-Inventory.csv`
- Decision on final structure (flat vs 3-7men/)

---

### Phase 1 — Secure the Highest Value Data (Priority #1)

**Goal:** Bring the ~8.4 TB from `A:\Syzygy_A_Trier_FromOld_Ryzen7950` onto T: before anything else.

**Why first?** This is the richest remaining source (mostly 6/7pc DTZ). Losing access to it later would be painful.

**Tools to use:**
- `Copy-A-Historical-DTZ-To-T.ps1` (already created and clean)

**Recommended approach:**
- Copy in multiple sessions (e.g. 1-2 TB per session)
- Always start with `-WhatIf -MaxFiles 50`
- After each session: run `Syzygy-Quick-Status.ps1`
- Store the A: source in `T:\Syzygy\A_Historical_DTZ\` temporarily, then integrate later

**Exit criteria:**
- All 1751 DTZ files from A: Historical are on T: (or at least the ones > 10 GB)
- No data loss on the source until verification is done

---

### Phase 2 — Full Inventory & Conflict Resolution on T:\Syzygy

**Goal:** Understand exactly what is currently on the master and fix the 77 conflicting-size problems + incomplete pairs.

**Actions:**
1. Generate complete inventory of `T:\Syzygy` with:
   - For each base name: WDL present? DTZ present? Sizes? Last modified?
2. Identify the 77 conflicting names → manual or scripted investigation
3. Decide for each conflict: keep which version? (usually the larger one, or re-copy)
4. Build a "desired final set" list

**Tools to create:**
- `Syzygy-Inventory.ps1` (detailed, with pair matching and conflict detection)
- `Syzygy-Conflict-Resolver.ps1` (helper to analyze and propose fixes for the 77 bad names)

**Exit criteria:**
- Clean inventory CSV of everything on T:
- All size conflicts resolved (either fixed or documented)
- Clear list of what is missing on the master (WDL without DTZ and vice-versa)

---

### Phase 3 — Bring Remaining High-Value Sources

**Goal:** Consolidate the rest of the valuable tables.

**Priority order after Phase 1:**
1. `A:\Syzygy` (the other A: folder)
2. S: 5v2_pawnful + 6v1_pawnful (high density 5-6pc)
3. S: 4v3_pawnless_ManyMissing
4. S: 5v2/6v1 pawnless
5. S:\Syzygy + 3-6men (the mirror copy)
6. Local Syzygy folder

**Tool:**
- Use or extend `Syzygy-Priority-Consolidate.ps1`

**Important rule:**
- Never delete anything from the source locations until:
  - It is safely on T:
  - `tbcheck` passes
  - You have run at least one probing test in an engine

---

### Phase 4 — Final Structure & Deduplication

**Goal:** Arrive at the clean final master.

**Two options (choose one):**

**Option A — Recommended: Flat structure**
- All `*.rtbw` and `*.rtbz` directly in `T:\Syzygy\`
- Simple, best compatibility

**Option B — Structured**
- `T:\Syzygy\3-6men\`
- `T:\Syzygy\7men\`
- More organized but more complex for probing

**Actions in this phase:**
- Move everything into the final structure
- Remove true duplicates (same name + same size)
- Create `RTBPATH.txt` marker file
- Update all your engine configs

---

### Phase 5 — Systematic Verification

**Goal:** Have high confidence that the master is good.

**Actions:**
1. Run `tbcheck` on **all** files in `T:\Syzygy` (can be done in batches)
2. Run `rtbver --log` on a representative sample:
   - All 3-4 piece tables
   - 20-30 random 5pc tables
   - 10-15 important 6/7pc tables (especially the big ones from A:)
3. Test probing in Stockfish (or your main engine) on known positions
4. Keep a `verification.log` with dates and results

**Tools to create:**
- `Syzygy-Verify-Master.ps1` (batch tbcheck + rtbver with logging)

---

### Phase 6 — Cleanup of Old Sources (Last step)

Only after Phase 5 is solid.

**Actions:**
- Move old locations to cold storage (another drive or external) for 1-2 months
- After 2 months with no issues → delete the old copies
- Keep at least one full backup of the A: Historical collection somewhere safe

---

## Risk Management

| Risk                              | Mitigation |
|-----------------------------------|----------|
| Copy fails in the middle          | Use robocopy (resumable) + always copy in limited batches |
| Wrong version kept during conflicts | Document every conflict decision |
| Accidentally deleting good data   | Never delete from source until master is verified |
| Probing breaks after restructuring | Test in engine **before** deleting old paths |
| Running out of space on T:        | Monitor with `Syzygy-Quick-Status.ps1` before every big copy session |

---

## Tools Inventory (June 2026)

Already created and usable:
- `Syzygy-Quick-Status.ps1` → daily health check
- `Copy-A-Historical-DTZ-To-T.ps1` → best tool for Phase 1
- `Syzygy-Priority-Consolidate.ps1` → broader consolidation
- `NEXT-COMMANDS.txt` → quick reference

To be created during the plan:
- `Syzygy-Inventory.ps1` (detailed pair + conflict analysis)
- `Syzygy-Verify-Master.ps1` (batch verification)
- Possibly a global "Syzygy-Master-Orchestrator.ps1"

---

## How to Execute This Plan

1. Read this document completely.
2. Run `.\Syzygy-Quick-Status.ps1` today and every time you work on this.
3. Start **Phase 1** using `Copy-A-Historical-DTZ-To-T.ps1`.
4. After every 500-1000 GB copied, run an inventory pass.
5. When you feel ready, move to Phase 2 (conflict resolution on T:).

---

**Next immediate action (recommended right now):**

```powershell
# 1. Get current picture
.\Syzygy-Quick-Status.ps1

# 2. Start safely securing the biggest remaining treasure
.\Copy-A-Historical-DTZ-To-T.ps1 -WhatIf -MaxFiles 40
```

Do you want me to create the missing high-value scripts (`Syzygy-Inventory.ps1` and the verification helper) right now so you can start the plan properly?
