# Syzygy Consolidation Progress - June 2026 (Phase 3)

## Current State (as of 2026-06-01)

- **Plots on T:** 0 remaining → Phase 1 complete. T: has **34.94 TB free**.
- **T:\Syzygy master:** 1,518 files → 838 unique names
  - 534 complete pairs (WDL + DTZ)
  - 264 DTZ only
  - **40 conflicts** (same name, different file sizes — needs investigation)
  - Detailed report: `logs\T-Syzygy-Detailed-Inventory.csv`
- **A:\Syzygy_A_Trier_FromOld_Ryzen7950** (highest priority source):
  - 1,751 DTZ files
  - ~**8.42 TB** total size
  - **24 files > 50 GB** (biggest: KRBNvKRP.rtbz 102.3 GB, KRBNPvKQ.rtbz 101.7 GB)
- This source alone represents the single largest high-ROI copy target remaining.

**Overall collection insight:** ~2,773 unique tables across all your locations. The A: historical DTZ collection is currently the clearest "next 8+ TB" to secure on the master.

Other strong sources: A:\Syzygy, S: 5v2_pawnful, S: 4v3_pawnless_ManyMissing, S: 6v1 splits.

## Scripts Created / Fixed This Session (June 2026)

**Recommended daily / operational tools:**
- `Syzygy-Quick-Status.ps1` — Fast one-command health check (drives + master content + recommendation). Run this often.
- `Copy-A-Historical-DTZ-To-T.ps1` — Clean, focused, resumable robocopy wrapper for the #1 priority source (A: historical 6/7pc DTZ). Supports -WhatIf, -MaxFiles, -Threads, -Log.
- `NEXT-COMMANDS.txt` — The absolute best copy-paste commands for this phase.

- `Syzygy-Priority-Consolidate.ps1` — Broader priority copier (use after the A: historical is mostly done).

## Recommended Next Commands (copy-paste ready)

```powershell
# 1. Always simulate first
.\Copy-A-Historical-DTZ-To-T.ps1 -WhatIf -MaxFiles 30

# 2. First real small batch (top 30 biggest DTZ from A:)
.\Copy-A-Historical-DTZ-To-T.ps1 -MaxFiles 30 -Threads 12

# 3. Later, bigger passes (no limit = all remaining from that source)
.\Copy-A-Historical-DTZ-To-T.ps1 -Threads 16

# 4. When you want to tackle the other sources too
.\Syzygy-Priority-Consolidate.ps1 -WhatIf -ReportOnly
```

After the A: historical DTZ is mostly on T:, move to the S: 5v2_pawnful / 6v1 splits.

## Goal Reminder
End state: `set RTBPATH=T:\Syzygy` (or `T:\Syzygy\A_Historical_DTZ` + other subfolders) as the single source of truth for all your engines.

## Notes
- All copies are cross-NAS → real network copies, resumable thanks to robocopy.
- Re-run the copy scripts as many times as needed; they skip what is already present with matching size.
- After major copies, spot-check with `tbcheck` and `rtbver` on a few large 7pc files.

Next session goal: Keep chipping away at the A: historical + S: splits until the master on T: is substantially complete.
