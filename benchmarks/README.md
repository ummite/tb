# Tablebase generation benchmarks

Mandatory project rule: every generation of `.rtbw` / `.rtbz` (via Grok or by invoking the `.exe`, including a partial run) must leave a benchmark report here.

## Tool

`C:\Programmation\tb-1\benchmarks\tb_benchmark.ps1`

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Programmation\tb-1\benchmarks\tb_benchmark.ps1 -Set 3pc -Tables "KRvK KQvK KBvK KNvK KPvK" -OutDir C:\Programmation\tb-1\test_gen_3pc_full -RtbPath C:\Programmation\tb-1\test_gen_3pc_full -RefDir T:\Syzygy\3-4-5
```

`-Tables` accepts comma, semicolon, or whitespace as separator.

Optional: `-Threads N` (0 = generator default = 1 thread), `-BinDir`, `-ReportDir`, `-PollMs`, `-NoValidate`.

## Outputs

- `C:\Programmation\tb-1\benchmarks\<Set>.benchmark.md` — human report
- `C:\Programmation\tb-1\benchmarks\<Set>.benchmark.json` — machine-readable
- `C:\Programmation\tb-1\benchmarks\logs\<Set>\<table>.out` — generator stdout (partial-log fallback)
- `C:\Programmation\tb-1\benchmarks\logs\<Set>\<table>.err` — generator stderr
- `C:\Programmation\tb-1\benchmarks\logs\<Set>\<table>.rtbw.tbcheck` — tbcheck output

## Required fields

Machine name, CPU, cores physical/logical, max clock, total RAM, OS, GPU, threads requested vs used, per-table wall time, peak process RAM (WorkingSet sampled), generation steps (`time taken` phases), output sizes + SHA-256, 100% byte-identity vs `T:\Syzygy\...` plus `tbcheck.exe` exit 0.

## Validation

The script exits 1 unless every generated file is SHA-256-identical to the reference directory **and** tbcheck is OK.

Pawnless 3–5pc gate = byte-identity vs `T:\Syzygy\3-4-5`. Pawnful official files are dated 2021-02-23 and predate upstream value-mapping commits `aae0f26` (2024-09-29), `ea44cb9` (2025-09-08), `976c128` (2025-09-29); KPvK and other pawnful tables may differ in size/mapping while still passing `tbcheck`. The harness prepends `-OutDir` to `RTBPATH` so later pawnful tables in the same set can probe promotions into already-generated pawnless tables.

## Current reports

- `C:\Programmation\tb-1\benchmarks\3pc.benchmark.md` / `C:\Programmation\tb-1\benchmarks\3pc.benchmark.json`
- `C:\Programmation\tb-1\benchmarks\4pc.benchmark.md` / `C:\Programmation\tb-1\benchmarks\4pc.benchmark.json`
- `C:\Programmation\tb-1\benchmarks\5pc.benchmark.md` / `C:\Programmation\tb-1\benchmarks\5pc.benchmark.json`

Re-validation of the 2026-09-14 build (post `setup_pairs` UAF fix) against `T:\Syzygy\3-4-5`:

- 3pc pawnless: 4/4 tables byte-identical (KPvK pawnful differs — 2021 mapping).
- 4pc pawnless: 20/20 byte-identical. 4pc pawnful: 10/10 `tbcheck` + exit 0; 9/10 not SHA-identical (KQvKP is).
- 5pc pawnless: 60/60 byte-identical (`C:\Programmation\tb-1\benchmarks\5pc_pawnless.benchmark.md`, wall 857 s, peak 860 MB).
- 5pc pawnful: in progress (`C:\Programmation\tb-1\gen_5pc_pf`).
