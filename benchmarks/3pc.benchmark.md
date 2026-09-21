# Benchmark - 3pc (5 tables)

**Verdict: INVALID - generated files differ from reference** - 8/10 files byte-identical to reference T:\Syzygy\3-4-5, tbcheck ok: 10/10.

## Machine

| Field | Value |
|---|---|
| Machine name | INTEL13900 |
| CPU | 13th Gen Intel(R) Core(TM) i9-13900KF |
| Cores (physical / logical) | 24 / 24 |
| Max clock | 3000 MHz |
| Total RAM | 95.84 GB |
| OS | Microsoft Windows 11 Education (10.0.26200) |
| GPU | NVIDIA GeForce GTX 1080 |
| User | Ummite |
| PowerShell | 5.1.26100.9444 |
| Captured | 2026-09-14 13:12:23 |

## Generator

- tbgen.exe: 203264 bytes, modified 2026-09-14 11:25:03
- tbgenp.exe: 217088 bytes, modified 2026-09-14 11:25:05
- Threads requested: **0** - 0 = generator default (all logical cores)
- Peak RAM measured by sampling WorkingSet every 25 ms
- OutDir: C:\Programmation\tb-1\gen_3pc   |   RTBPATH: C:\Programmation\tb-1\Syzygy   |   Reference: T:\Syzygy\3-4-5

## Summary (set total: 1,789 ms, max peak RAM: 30.50 MB, total output: 26.28 KB)

| Table | Kind | Exe | Threads | Wall time | Peak RAM | Exit | Identical to ref |
|---|---|---|---|---|---|---|---|
| KBvK | pawnless | tbgen.exe | 24 | 179 ms | 4.01 MB | -1 | OK |
| KNvK | pawnless | tbgen.exe | 24 | 112 ms | 5.32 MB | -1 | OK |
| KPvK | pawnful | tbgenp.exe | 24 | 1,011 ms | 27.01 MB | -1 | NO |
| KQvK | pawnless | tbgen.exe | 24 | 236 ms | 26.55 MB | -1 | OK |
| KRvK | pawnless | tbgen.exe | 24 | 251 ms | 30.5 MB | -1 | OK |

## Per-table detail (steps + files)

### KBvK  (pawnless, wall 179 ms, peak 4.01 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 2 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.000 |
| 6 | tb_size = 31332 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 0 | - |
| 9 | best permutation: 14 6 3 | 0:00.000 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for btm/wdl | - |
| 12 | best order: 0 | - |
| 13 | best permutation: 14 6 3 | 0:00.000 |
| 14 | compressing data for btm/wdl | - |
| 15 | find optimal permutation for wtm/dtz | - |
| 16 | best order: 0 | - |
| 17 | best permutation: 14 6 3 | - |
| 18 | find optimal permutation for btm/dtz | - |
| 19 | best order: 0 | - |
| 20 | best permutation: 14 6 3 | - |
| 21 | permute table for wtm/dtz | 0:00.000 |
| 22 | compressing data for wtm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KBvK.rtbw | 80 B | BC0D8AB3560D... | OK | OK |
| KBvK.rtbz | 80 B | 6246C8A5C643... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\3pc\KBvK.out

### KNvK  (pawnless, wall 112 ms, peak 5.32 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 2 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.000 |
| 6 | tb_size = 31332 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 0 | - |
| 9 | best permutation: 14 6 2 | 0:00.000 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for btm/wdl | - |
| 12 | best order: 0 | - |
| 13 | best permutation: 14 6 2 | 0:00.000 |
| 14 | compressing data for btm/wdl | - |
| 15 | find optimal permutation for wtm/dtz | - |
| 16 | best order: 0 | - |
| 17 | best permutation: 14 6 2 | - |
| 18 | find optimal permutation for btm/dtz | - |
| 19 | best order: 0 | - |
| 20 | best permutation: 14 6 2 | - |
| 21 | permute table for wtm/dtz | 0:00.000 |
| 22 | compressing data for wtm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KNvK.rtbw | 80 B | 9D3518B12DF3... | OK | OK |
| KNvK.rtbz | 80 B | 0E49A0F2810A... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\3pc\KNvK.out

### KPvK  (pawnful, wall 1,011 ms, peak 27.01 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Initialising broken positions. | 0:00.000 |
| 2 | Calculating white piece captures. | 0:00.000 |
| 3 | Calculating white pawn captures. | 0:00.000 |
| 4 | Calculating black piece captures. | 0:00.000 |
| 5 | Calculating pawn table. | - |
| 6 | tb_size = 23436 | - |
| 7 | find optimal permutation for wtm/wdl, file a | - |
| 8 | best order: 1 | - |
| 9 | best permutation: 1 6 14 | 0:00.000 |
| 10 | compressing data for wtm/wdl, file a | - |
| 11 | find optimal permutation for btm/wdl, file a | - |
| 12 | best order: 1 | - |
| 13 | best permutation: 1 6 14 | 0:00.000 |
| 14 | compressing data for btm/wdl, file a | - |
| 15 | find optimal permutation for wtm/dtz, file a | - |
| 16 | best order: 0 | - |
| 17 | best permutation: 1 6 14 | - |
| 18 | find optimal permutation for btm/dtz, file a | - |
| 19 | best order: 2 | - |
| 20 | best permutation: 1 14 6 | - |
| 21 | permute table for wtm/dtz, file a | 0:00.000 |
| 22 | compressing data for wtm/dtz, file a | - |
| 23 | Initialising broken positions. | 0:00.000 |
| 24 | Calculating white piece captures. | 0:00.000 |
| 25 | Calculating white pawn captures. | 0:00.000 |
| 26 | Calculating black piece captures. | 0:00.000 |
| 27 | Calculating pawn table. | - |
| 28 | tb_size = 23436 | - |
| 29 | find optimal permutation for wtm/wdl, file b | - |
| 30 | best order: 1 | - |
| 31 | best permutation: 1 6 14 | 0:00.000 |
| 32 | compressing data for wtm/wdl, file b | - |
| 33 | find optimal permutation for btm/wdl, file b | - |
| 34 | best order: 1 | - |
| 35 | best permutation: 1 6 14 | 0:00.000 |
| 36 | compressing data for btm/wdl, file b | - |
| 37 | find optimal permutation for wtm/dtz, file b | - |
| 38 | best order: 2 | - |
| 39 | best permutation: 1 6 14 | - |
| 40 | find optimal permutation for btm/dtz, file b | - |
| 41 | best order: 2 | - |
| 42 | best permutation: 1 14 6 | - |
| 43 | permute table for wtm/dtz, file b | 0:00.000 |
| 44 | compressing data for wtm/dtz, file b | - |
| 45 | Initialising broken positions. | 0:00.000 |
| 46 | Calculating white piece captures. | 0:00.000 |
| 47 | Calculating white pawn captures. | 0:00.000 |
| 48 | Calculating black piece captures. | 0:00.000 |
| 49 | Calculating pawn table. | - |
| 50 | tb_size = 23436 | - |
| 51 | find optimal permutation for wtm/wdl, file c | - |
| 52 | best order: 2 | - |
| 53 | best permutation: 1 6 14 | 0:00.000 |
| 54 | compressing data for wtm/wdl, file c | - |
| 55 | find optimal permutation for btm/wdl, file c | - |
| 56 | best order: 1 | - |
| 57 | best permutation: 1 6 14 | 0:00.000 |
| 58 | compressing data for btm/wdl, file c | - |
| 59 | find optimal permutation for wtm/dtz, file c | - |
| 60 | best order: 2 | - |
| 61 | best permutation: 1 6 14 | - |
| 62 | find optimal permutation for btm/dtz, file c | - |
| 63 | best order: 2 | - |
| 64 | best permutation: 1 14 6 | - |
| 65 | permute table for wtm/dtz, file c | 0:00.000 |
| 66 | compressing data for wtm/dtz, file c | - |
| 67 | Initialising broken positions. | 0:00.000 |
| 68 | Calculating white piece captures. | 0:00.000 |
| 69 | Calculating white pawn captures. | 0:00.000 |
| 70 | Calculating black piece captures. | 0:00.000 |
| 71 | Calculating pawn table. | - |
| 72 | tb_size = 23436 | - |
| 73 | find optimal permutation for wtm/wdl, file d | - |
| 74 | best order: 2 | - |
| 75 | best permutation: 1 6 14 | 0:00.000 |
| 76 | compressing data for wtm/wdl, file d | - |
| 77 | find optimal permutation for btm/wdl, file d | - |
| 78 | best order: 1 | - |
| 79 | best permutation: 1 14 6 | 0:00.000 |
| 80 | compressing data for btm/wdl, file d | - |
| 81 | find optimal permutation for wtm/dtz, file d | - |
| 82 | best order: 1 | - |
| 83 | best permutation: 1 6 14 | - |
| 84 | find optimal permutation for btm/dtz, file d | - |
| 85 | best order: 2 | - |
| 86 | best permutation: 1 14 6 | - |
| 87 | permute table for wtm/dtz, file d | 0:00.000 |
| 88 | compressing data for wtm/dtz, file d | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KPvK.rtbw | 8.64 KB | EBFC5C8CE57E... | NO | OK |
| KPvK.rtbz | 4.14 KB | 53D1AC4D2E88... | NO | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\3pc\KPvK.out

### KQvK  (pawnless, wall 236 ms, peak 26.55 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 12 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.000 |
| 6 | tb_size = 31332 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 0 | - |
| 9 | best permutation: 14 6 5 | 0:00.000 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for btm/wdl | - |
| 12 | best order: 0 | - |
| 13 | best permutation: 14 5 6 | 0:00.000 |
| 14 | compressing data for btm/wdl | - |
| 15 | find optimal permutation for wtm/dtz | - |
| 16 | best order: 0 | - |
| 17 | best permutation: 6 14 5 | - |
| 18 | find optimal permutation for btm/dtz | - |
| 19 | best order: 0 | - |
| 20 | best permutation: 6 5 14 | - |
| 21 | permute table for wtm/dtz | 0:00.000 |
| 22 | compressing data for wtm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KQvK.rtbw | 272 B | 517667DFF787... | OK | OK |
| KQvK.rtbz | 5.27 KB | 71EA9444FA5B... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\3pc\KQvK.out

### KRvK  (pawnless, wall 251 ms, peak 30.5 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 18 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.000 |
| 6 | tb_size = 31332 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 0 | - |
| 9 | best permutation: 14 6 4 | 0:00.000 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for btm/wdl | - |
| 12 | best order: 0 | - |
| 13 | best permutation: 6 14 4 | 0:00.000 |
| 14 | compressing data for btm/wdl | - |
| 15 | find optimal permutation for wtm/dtz | - |
| 16 | best order: 0 | - |
| 17 | best permutation: 6 14 4 | - |
| 18 | find optimal permutation for btm/dtz | - |
| 19 | best order: 0 | - |
| 20 | best permutation: 6 14 4 | - |
| 21 | permute table for wtm/dtz | 0:00.000 |
| 22 | compressing data for wtm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KRvK.rtbw | 208 B | 386FBDE73308... | OK | OK |
| KRvK.rtbz | 7.45 KB | CAB59F42E75C... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\3pc\KRvK.out

## Appendix - method

- Wall time: [System.Diagnostics.Stopwatch] around the process (Start-Process to process exit).
- Peak RAM: max of process WorkingSet64 sampled every 25 ms while running (host under no memory pressure, so sampled max approx equals true peak).
- Byte-identical: equality of SHA-256 hashes of the generated file vs the reference file in T:\Syzygy\3-4-5.
- tbcheck: tbcheck.exe <file> (embedded CityHash checksum), exit 0 = OK.
- Threads: the number-of-threads value read from the generator log (generator default when no -t flag passed).
- Watchdog: per-table wall-clock limit of 30 min; if the generator is still running at the limit it is killed, the table is marked FAILED (watchdog) with the partial data collected, and the set continues.
- Per-table logs (stdout, stderr, tbcheck output) stored in C:\Programmation\tb-1\benchmarks\logs\3pc - this is the partial-log fallback required by the project benchmark rule.

