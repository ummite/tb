# Benchmark - 4pc (30 tables)

**Verdict: INVALID - generated files differ from reference** - 44/60 files byte-identical to reference T:\Syzygy\3-4-5, tbcheck ok: 60/60.

Interpretation (2026-09-14, post `setup_pairs` UAF fix in `C:\Programmation\tb-1\src\probe.c`): all 20 pawnless 4pc tables are byte-identical (40/40 files). All 10 pawnful tables pass `tbcheck` with generator exit 0; most are not SHA-identical to the 2021-02-23 official files (upstream pawnful mapping commits `aae0f26` / `ea44cb9` / `976c128`). KQvKP is an exception (both files identical). Peak RAM 458.13 MB, wall 86.6 s, `tbgen.exe` / `tbgenp.exe` dated 2026-09-14 17:54.

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
| Captured | 2026-09-14 17:55:50 |

## Generator

- tbgen.exe: 203264 bytes, modified 2026-09-14 17:54:55
- tbgenp.exe: 217088 bytes, modified 2026-09-14 17:54:56
- Threads requested: **0** - 0 = generator default (all logical cores)
- Peak RAM measured by sampling WorkingSet every 25 ms
- OutDir: C:\Programmation\tb-1\gen_4pc   |   RTBPATH: C:\Programmation\tb-1\gen_3pc   |   Reference: T:\Syzygy\3-4-5

## Summary (set total: 86,614 ms, max peak RAM: 458.13 MB, total output: 4.14 MB)

| Table | Kind | Exe | Threads | Wall time | Peak RAM | Exit | Identical to ref |
|---|---|---|---|---|---|---|---|
| KBBvK | pawnless | tbgen.exe | 24 | 1,048 ms | 158.16 MB | 0 | OK |
| KBNvK | pawnless | tbgen.exe | 24 | 3,354 ms | 277.55 MB | 0 | OK |
| KNNvK | pawnless | tbgen.exe | 24 | 236 ms | 30.08 MB | 0 | OK |
| KQBvK | pawnless | tbgen.exe | 24 | 1,829 ms | 232.76 MB | 0 | OK |
| KQNvK | pawnless | tbgen.exe | 24 | 2,445 ms | 339.61 MB | 0 | OK |
| KQQvK | pawnless | tbgen.exe | 24 | 365 ms | 49.39 MB | 0 | OK |
| KQRvK | pawnless | tbgen.exe | 24 | 1,100 ms | 96.26 MB | 0 | OK |
| KRBvK | pawnless | tbgen.exe | 24 | 2,848 ms | 357.45 MB | 0 | OK |
| KRNvK | pawnless | tbgen.exe | 24 | 2,876 ms | 330.81 MB | 0 | OK |
| KRRvK | pawnless | tbgen.exe | 24 | 588 ms | 129.96 MB | 0 | OK |
| KBvKB | pawnless | tbgen.exe | 24 | 480 ms | 47.54 MB | 0 | OK |
| KBvKN | pawnless | tbgen.exe | 24 | 994 ms | 49.14 MB | 0 | OK |
| KNvKN | pawnless | tbgen.exe | 24 | 538 ms | 47.1 MB | 0 | OK |
| KQvKB | pawnless | tbgen.exe | 24 | 2,747 ms | 290.79 MB | 0 | OK |
| KQvKN | pawnless | tbgen.exe | 24 | 2,613 ms | 246.12 MB | 0 | OK |
| KQvKQ | pawnless | tbgen.exe | 24 | 661 ms | 65.98 MB | 0 | OK |
| KQvKR | pawnless | tbgen.exe | 24 | 3,106 ms | 320.96 MB | 0 | OK |
| KRvKB | pawnless | tbgen.exe | 24 | 1,421 ms | 74.8 MB | 0 | OK |
| KRvKN | pawnless | tbgen.exe | 24 | 1,594 ms | 100.23 MB | 0 | OK |
| KRvKR | pawnless | tbgen.exe | 24 | 904 ms | 63.12 MB | 0 | OK |
| KQPvK | pawnful | tbgenp.exe | 24 | 4,360 ms | 55.04 MB | 0 | NO |
| KRPvK | pawnful | tbgenp.exe | 24 | 3,954 ms | 48.88 MB | 0 | NO |
| KBPvK | pawnful | tbgenp.exe | 24 | 6,266 ms | 442.48 MB | 0 | NO |
| KNPvK | pawnful | tbgenp.exe | 24 | 5,286 ms | 445.98 MB | 0 | NO |
| KPPvK | pawnful | tbgenp.exe | 24 | 2,725 ms | 419.88 MB | 0 | NO |
| KQvKP | pawnful | tbgenp.exe | 24 | 6,898 ms | 458.13 MB | 0 | OK |
| KRvKP | pawnful | tbgenp.exe | 24 | 7,224 ms | 457.24 MB | 0 | NO |
| KBvKP | pawnful | tbgenp.exe | 24 | 5,765 ms | 440.1 MB | 0 | NO |
| KNvKP | pawnful | tbgenp.exe | 24 | 6,613 ms | 443.05 MB | 0 | NO |
| KPvKP | pawnful | tbgenp.exe | 24 | 5,776 ms | 121.61 MB | 0 | NO |

## Per-table detail (steps + files)

### KBBvK  (pawnless, wall 1,048 ms, peak 158.16 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 21 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.000 |
| 6 | tb_size = 873642 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 0 | - |
| 9 | best permutation: 14 6 3 3 | 0:00.002 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for btm/wdl | - |
| 12 | best order: 0 | - |
| 13 | best permutation: 6 14 3 3 | 0:00.002 |
| 14 | compressing data for btm/wdl | - |
| 15 | find optimal permutation for wtm/dtz | - |
| 16 | best order: 0 | - |
| 17 | best permutation: 14 6 3 3 | - |
| 18 | find optimal permutation for btm/dtz | - |
| 19 | best order: 0 | - |
| 20 | best permutation: 6 14 3 3 | - |
| 21 | permute table for btm/dtz | 0:00.002 |
| 22 | compressing data for btm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KBBvK.rtbw | 56.64 KB | 3AFA74FCFD61... | OK | OK |
| KBBvK.rtbz | 133.08 KB | D3786BA13D73... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KBBvK.out

### KBNvK  (pawnless, wall 3,354 ms, peak 277.55 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 35 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.000 |
| 6 | tb_size = 1911252 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 1 | - |
| 9 | best permutation: 14 3 2 6 | 0:00.003 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for btm/wdl | - |
| 12 | best order: 1 | - |
| 13 | best permutation: 14 3 2 6 | 0:00.002 |
| 14 | compressing data for btm/wdl | - |
| 15 | find optimal permutation for wtm/dtz | - |
| 16 | best order: 1 | - |
| 17 | best permutation: 14 3 2 6 | - |
| 18 | find optimal permutation for btm/dtz | - |
| 19 | best order: 1 | - |
| 20 | best permutation: 6 3 2 14 | - |
| 21 | permute table for btm/dtz | 0:00.011 |
| 22 | compressing data for btm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KBNvK.rtbw | 7.45 KB | 76958DA65BC2... | OK | OK |
| KBNvK.rtbz | 451.02 KB | CAD874516A23... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KBNvK.out

### KNNvK  (pawnless, wall 236 ms, peak 30.08 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 3 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.000 |
| 6 | tb_size = 873642 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 1 | - |
| 9 | best permutation: 6 14 2 2 | 0:00.003 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for btm/wdl | - |
| 12 | best order: 0 | - |
| 13 | best permutation: 14 6 2 2 | 0:00.003 |
| 14 | compressing data for btm/wdl | - |
| 15 | find optimal permutation for wtm/dtz | - |
| 16 | best order: 0 | - |
| 17 | best permutation: 6 14 2 2 | - |
| 18 | find optimal permutation for btm/dtz | - |
| 19 | best order: 0 | - |
| 20 | best permutation: 6 14 2 2 | - |
| 21 | permute table for wtm/dtz | 0:00.003 |
| 22 | compressing data for wtm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KNNvK.rtbw | 1.33 KB | 8B5195ABD7F1... | OK | OK |
| KNNvK.rtbz | 80 B | 9B2F7F8046CC... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KNNvK.out

### KQBvK  (pawnless, wall 1,829 ms, peak 232.76 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 8 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.001 |
| 6 | tb_size = 1911252 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 1 | - |
| 9 | best permutation: 14 6 5 3 | 0:00.002 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for btm/wdl | - |
| 12 | best order: 1 | - |
| 13 | best permutation: 14 5 3 6 | 0:00.002 |
| 14 | compressing data for btm/wdl | - |
| 15 | find optimal permutation for wtm/dtz | - |
| 16 | best order: 1 | - |
| 17 | best permutation: 14 5 3 6 | - |
| 18 | find optimal permutation for btm/dtz | - |
| 19 | best order: 1 | - |
| 20 | best permutation: 14 5 3 6 | - |
| 21 | permute table for wtm/dtz | 0:00.001 |
| 22 | compressing data for wtm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KQBvK.rtbw | 4.83 KB | 55948E960DCD... | OK | OK |
| KQBvK.rtbz | 135.83 KB | 27B12F2C8083... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KQBvK.out

### KQNvK  (pawnless, wall 2,445 ms, peak 339.61 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 9 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.001 |
| 6 | tb_size = 1911252 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 1 | - |
| 9 | best permutation: 14 6 5 2 | 0:00.002 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for btm/wdl | - |
| 12 | best order: 1 | - |
| 13 | best permutation: 14 5 2 6 | 0:00.002 |
| 14 | compressing data for btm/wdl | - |
| 15 | find optimal permutation for wtm/dtz | - |
| 16 | best order: 1 | - |
| 17 | best permutation: 14 5 2 6 | - |
| 18 | find optimal permutation for btm/dtz | - |
| 19 | best order: 1 | - |
| 20 | best permutation: 14 5 2 6 | - |
| 21 | permute table for wtm/dtz | 0:00.002 |
| 22 | compressing data for wtm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KQNvK.rtbw | 3.52 KB | CD807DF1B6F5... | OK | OK |
| KQNvK.rtbz | 152.77 KB | A86A0900D84C... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KQNvK.out

### KQQvK  (pawnless, wall 365 ms, peak 49.39 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 5 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.001 |
| 6 | tb_size = 873642 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 0 | - |
| 9 | best permutation: 6 14 5 5 | 0:00.001 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for btm/wdl | - |
| 12 | best order: 0 | - |
| 13 | best permutation: 14 6 5 5 | 0:00.002 |
| 14 | compressing data for btm/wdl | - |
| 15 | find optimal permutation for wtm/dtz | - |
| 16 | best order: 0 | - |
| 17 | best permutation: 14 6 5 5 | - |
| 18 | find optimal permutation for btm/dtz | - |
| 19 | best order: 0 | - |
| 20 | best permutation: 14 6 5 5 | - |
| 21 | permute table for wtm/dtz | 0:00.002 |
| 22 | compressing data for wtm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KQQvK.rtbw | 6.89 KB | B1C0D3EABF12... | OK | OK |
| KQQvK.rtbz | 25.33 KB | 0D8E14A93BA2... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KQQvK.out

### KQRvK  (pawnless, wall 1,100 ms, peak 96.26 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 6 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.001 |
| 6 | tb_size = 1911252 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 1 | - |
| 9 | best permutation: 14 6 5 4 | 0:00.002 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for btm/wdl | - |
| 12 | best order: 1 | - |
| 13 | best permutation: 14 5 4 6 | 0:00.002 |
| 14 | compressing data for btm/wdl | - |
| 15 | find optimal permutation for wtm/dtz | - |
| 16 | best order: 1 | - |
| 17 | best permutation: 14 5 4 6 | - |
| 18 | find optimal permutation for btm/dtz | - |
| 19 | best order: 1 | - |
| 20 | best permutation: 14 5 4 6 | - |
| 21 | permute table for wtm/dtz | 0:00.002 |
| 22 | compressing data for wtm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KQRvK.rtbw | 4.45 KB | B018ECE9CC19... | OK | OK |
| KQRvK.rtbz | 43.08 KB | 9766D3E68458... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KQRvK.out

### KRBvK  (pawnless, wall 2,848 ms, peak 357.45 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 14 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.000 |
| 6 | tb_size = 1911252 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 1 | - |
| 9 | best permutation: 14 6 4 3 | 0:00.002 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for btm/wdl | - |
| 12 | best order: 1 | - |
| 13 | best permutation: 14 3 4 6 | 0:00.002 |
| 14 | compressing data for btm/wdl | - |
| 15 | find optimal permutation for wtm/dtz | - |
| 16 | best order: 1 | - |
| 17 | best permutation: 6 14 3 4 | - |
| 18 | find optimal permutation for btm/dtz | - |
| 19 | best order: 1 | - |
| 20 | best permutation: 6 3 4 14 | - |
| 21 | permute table for wtm/dtz | 0:00.002 |
| 22 | compressing data for wtm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KRBvK.rtbw | 2.77 KB | 9E6ECED11A37... | OK | OK |
| KRBvK.rtbz | 255.64 KB | E3BB6FBD54A5... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KRBvK.out

### KRNvK  (pawnless, wall 2,876 ms, peak 330.81 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 14 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.000 |
| 6 | tb_size = 1911252 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 1 | - |
| 9 | best permutation: 14 6 4 2 | 0:00.002 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for btm/wdl | - |
| 12 | best order: 1 | - |
| 13 | best permutation: 14 2 6 4 | 0:00.002 |
| 14 | compressing data for btm/wdl | - |
| 15 | find optimal permutation for wtm/dtz | - |
| 16 | best order: 1 | - |
| 17 | best permutation: 6 14 2 4 | - |
| 18 | find optimal permutation for btm/dtz | - |
| 19 | best order: 1 | - |
| 20 | best permutation: 6 2 4 14 | - |
| 21 | permute table for wtm/dtz | 0:00.002 |
| 22 | compressing data for wtm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KRNvK.rtbw | 2.27 KB | 4F96CAB9FC00... | OK | OK |
| KRNvK.rtbz | 288.70 KB | 150B85874A78... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KRNvK.out

### KRRvK  (pawnless, wall 588 ms, peak 129.96 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 7 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.000 |
| 6 | tb_size = 873642 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 0 | - |
| 9 | best permutation: 6 14 4 4 | 0:00.002 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for btm/wdl | - |
| 12 | best order: 1 | - |
| 13 | best permutation: 14 6 4 4 | 0:00.002 |
| 14 | compressing data for btm/wdl | - |
| 15 | find optimal permutation for wtm/dtz | - |
| 16 | best order: 0 | - |
| 17 | best permutation: 14 6 4 4 | - |
| 18 | find optimal permutation for btm/dtz | - |
| 19 | best order: 0 | - |
| 20 | best permutation: 14 6 4 4 | - |
| 21 | permute table for wtm/dtz | 0:00.009 |
| 22 | compressing data for wtm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KRRvK.rtbw | 1.89 KB | 4C05EC32E6E4... | OK | OK |
| KRRvK.rtbz | 52.27 KB | E68314E00BF9... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KRRvK.out

### KBvKB  (pawnless, wall 480 ms, peak 47.54 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 3 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.000 |
| 6 | tb_size = 1911252 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 1 | - |
| 9 | best permutation: 6 14 11 3 | 0:00.002 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for wtm/dtz | - |
| 12 | best order: 1 | - |
| 13 | best permutation: 14 11 6 3 | - |
| 14 | permute table for wtm/dtz | 0:00.003 |
| 15 | compressing data for wtm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KBvKB.rtbw | 1.20 KB | F0BFFF470A97... | OK | OK |
| KBvKB.rtbz | 80 B | 104404C12C01... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KBvKB.out

### KBvKN  (pawnless, wall 994 ms, peak 49.14 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 3 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.000 |
| 6 | tb_size = 1911252 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 1 | - |
| 9 | best permutation: 14 3 10 6 | 0:00.004 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for btm/wdl | - |
| 12 | best order: 1 | - |
| 13 | best permutation: 6 14 3 10 | 0:00.003 |
| 14 | compressing data for btm/wdl | - |
| 15 | find optimal permutation for wtm/dtz | - |
| 16 | best order: 1 | - |
| 17 | best permutation: 14 10 6 3 | - |
| 18 | find optimal permutation for btm/dtz | - |
| 19 | best order: 1 | - |
| 20 | best permutation: 14 10 6 3 | - |
| 21 | permute table for wtm/dtz | 0:00.003 |
| 22 | compressing data for wtm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KBvKN.rtbw | 2.20 KB | 1D0C01BFB86B... | OK | OK |
| KBvKN.rtbz | 80 B | 268EECBF84F5... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KBvKN.out

### KNvKN  (pawnless, wall 538 ms, peak 47.1 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 3 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.000 |
| 6 | tb_size = 1911252 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 1 | - |
| 9 | best permutation: 10 14 6 2 | 0:00.005 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for wtm/dtz | - |
| 12 | best order: 1 | - |
| 13 | best permutation: 14 10 6 2 | - |
| 14 | permute table for wtm/dtz | 0:00.003 |
| 15 | compressing data for wtm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KNvKN.rtbw | 1.14 KB | 290B5D295F53... | OK | OK |
| KNvKN.rtbz | 80 B | 540ABBC141BE... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KNvKN.out

### KQvKB  (pawnless, wall 2,747 ms, peak 290.79 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 14 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.001 |
| 6 | tb_size = 1911252 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 1 | - |
| 9 | best permutation: 11 5 6 14 | 0:00.003 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for btm/wdl | - |
| 12 | best order: 1 | - |
| 13 | best permutation: 11 6 5 14 | 0:00.003 |
| 14 | compressing data for btm/wdl | - |
| 15 | find optimal permutation for wtm/dtz | - |
| 16 | best order: 1 | - |
| 17 | best permutation: 14 5 11 6 | - |
| 18 | find optimal permutation for btm/dtz | - |
| 19 | best order: 1 | - |
| 20 | best permutation: 14 5 11 6 | - |
| 21 | permute table for wtm/dtz | 0:00.021 |
| 22 | compressing data for wtm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KQvKB.rtbw | 6.52 KB | 0C18BBCAEC0E... | OK | OK |
| KQvKB.rtbz | 190.64 KB | A63BEFD64DBD... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KQvKB.out

### KQvKN  (pawnless, wall 2,613 ms, peak 246.12 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 21 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.000 |
| 6 | tb_size = 1911252 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 1 | - |
| 9 | best permutation: 5 10 6 14 | 0:00.003 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for btm/wdl | - |
| 12 | best order: 1 | - |
| 13 | best permutation: 5 10 6 14 | 0:00.002 |
| 14 | compressing data for btm/wdl | - |
| 15 | find optimal permutation for wtm/dtz | - |
| 16 | best order: 1 | - |
| 17 | best permutation: 14 5 10 6 | - |
| 18 | find optimal permutation for btm/dtz | - |
| 19 | best order: 1 | - |
| 20 | best permutation: 10 5 14 6 | - |
| 21 | permute table for wtm/dtz | 0:00.010 |
| 22 | compressing data for wtm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KQvKN.rtbw | 9.83 KB | BA07BD47C6EA... | OK | OK |
| KQvKN.rtbz | 158.83 KB | 0E99385BBD90... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KQvKN.out

### KQvKQ  (pawnless, wall 661 ms, peak 65.98 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 12 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.000 |
| 6 | tb_size = 1911252 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 1 | - |
| 9 | best permutation: 13 6 14 5 | 0:00.001 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for wtm/dtz | - |
| 12 | best order: 1 | - |
| 13 | best permutation: 14 6 13 5 | - |
| 14 | permute table for wtm/dtz | 0:00.002 |
| 15 | compressing data for wtm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KQvKQ.rtbw | 16.14 KB | 571A85D86E63... | OK | OK |
| KQvKQ.rtbz | 6.58 KB | 98327247BA50... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KQvKQ.out

### KQvKR  (pawnless, wall 3,106 ms, peak 320.96 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 33 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.001 |
| 6 | tb_size = 1911252 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 1 | - |
| 9 | best permutation: 6 12 5 14 | 0:00.002 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for btm/wdl | - |
| 12 | best order: 1 | - |
| 13 | best permutation: 5 14 6 12 | 0:00.002 |
| 14 | compressing data for btm/wdl | - |
| 15 | find optimal permutation for wtm/dtz | - |
| 16 | best order: 1 | - |
| 17 | best permutation: 14 5 12 6 | - |
| 18 | find optimal permutation for btm/dtz | - |
| 19 | best order: 1 | - |
| 20 | best permutation: 5 14 6 12 | - |
| 21 | permute table for wtm/dtz | 0:00.002 |
| 22 | compressing data for wtm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KQvKR.rtbw | 20.02 KB | 8CDBE3C8E098... | OK | OK |
| KQvKR.rtbz | 301.77 KB | 0C15A2AAA3BD... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KQvKR.out

### KRvKB  (pawnless, wall 1,421 ms, peak 74.8 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 20 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.001 |
| 6 | tb_size = 1911252 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 1 | - |
| 9 | best permutation: 11 14 6 4 | 0:00.011 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for btm/wdl | - |
| 12 | best order: 1 | - |
| 13 | best permutation: 4 14 11 6 | 0:00.011 |
| 14 | compressing data for btm/wdl | - |
| 15 | find optimal permutation for wtm/dtz | - |
| 16 | best order: 1 | - |
| 17 | best permutation: 6 11 14 4 | - |
| 18 | find optimal permutation for btm/dtz | - |
| 19 | best order: 1 | - |
| 20 | best permutation: 14 11 6 4 | - |
| 21 | permute table for btm/dtz | 0:00.010 |
| 22 | compressing data for btm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KRvKB.rtbw | 32.14 KB | 69B247CB390F... | OK | OK |
| KRvKB.rtbz | 9.70 KB | 4FA644478A51... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KRvKB.out

### KRvKN  (pawnless, wall 1,594 ms, peak 100.23 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 29 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.000 |
| 6 | tb_size = 1911252 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 1 | - |
| 9 | best permutation: 14 10 6 4 | 0:00.001 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for btm/wdl | - |
| 12 | best order: 1 | - |
| 13 | best permutation: 14 10 4 6 | 0:00.012 |
| 14 | compressing data for btm/wdl | - |
| 15 | find optimal permutation for wtm/dtz | - |
| 16 | best order: 1 | - |
| 17 | best permutation: 14 6 10 4 | - |
| 18 | find optimal permutation for btm/dtz | - |
| 19 | best order: 1 | - |
| 20 | best permutation: 14 10 6 4 | - |
| 21 | permute table for btm/dtz | 0:00.010 |
| 22 | compressing data for btm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KRvKN.rtbw | 97.70 KB | A8CDE902B010... | OK | OK |
| KRvKN.rtbz | 91.02 KB | C0DF57D0B066... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KRvKN.out

### KRvKR  (pawnless, wall 904 ms, peak 63.12 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Retrograde iterations: 6 | (see log) |
| 2 | Initialising broken positions. | 0:00.000 |
| 3 | Calculating white captures. | 0:00.000 |
| 4 | Calculating black captures. | 0:00.000 |
| 5 | Calculating mate positions. | 0:00.000 |
| 6 | tb_size = 1911252 | - |
| 7 | find optimal permutation for wtm/wdl | - |
| 8 | best order: 1 | - |
| 9 | best permutation: 12 6 14 4 | 0:00.002 |
| 10 | compressing data for wtm/wdl | - |
| 11 | find optimal permutation for wtm/dtz | - |
| 12 | best order: 1 | - |
| 13 | best permutation: 6 14 12 4 | - |
| 14 | permute table for wtm/dtz | 0:00.019 |
| 15 | compressing data for wtm/dtz | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KRvKR.rtbw | 12.64 KB | 797081B5B3FB... | OK | OK |
| KRvKR.rtbz | 3.33 KB | C23FA5A02092... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KRvKR.out

### KQPvK  (pawnful, wall 4,360 ms, peak 55.04 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Initialising broken positions. | 0:00.000 |
| 2 | Calculating white piece captures. | 0:00.000 |
| 3 | Calculating white pawn captures. | 0:00.001 |
| 4 | Calculating black piece captures. | 0:00.000 |
| 5 | Calculating pawn table. | - |
| 6 | tb_size = 1429596 | - |
| 7 | find optimal permutation for wtm/wdl, file a | - |
| 8 | best order: 3 | - |
| 9 | best permutation: 1 5 6 14 | 0:00.002 |
| 10 | compressing data for wtm/wdl, file a | - |
| 11 | find optimal permutation for btm/wdl, file a | - |
| 12 | best order: 0 | - |
| 13 | best permutation: 1 6 5 14 | 0:00.002 |
| 14 | compressing data for btm/wdl, file a | - |
| 15 | find optimal permutation for wtm/dtz, file a | - |
| 16 | best order: 2 | - |
| 17 | best permutation: 1 14 6 5 | - |
| 18 | find optimal permutation for btm/dtz, file a | - |
| 19 | best order: 3 | - |
| 20 | best permutation: 1 6 5 14 | - |
| 21 | permute table for wtm/dtz, file a | 0:00.026 |
| 22 | compressing data for wtm/dtz, file a | - |
| 23 | Initialising broken positions. | 0:00.001 |
| 24 | Calculating white piece captures. | 0:00.000 |
| 25 | Calculating white pawn captures. | 0:00.002 |
| 26 | Calculating black piece captures. | 0:00.000 |
| 27 | Calculating pawn table. | - |
| 28 | tb_size = 1429596 | - |
| 29 | find optimal permutation for wtm/wdl, file b | - |
| 30 | best order: 3 | - |
| 31 | best permutation: 1 5 6 14 | 0:00.003 |
| 32 | compressing data for wtm/wdl, file b | - |
| 33 | find optimal permutation for btm/wdl, file b | - |
| 34 | best order: 0 | - |
| 35 | best permutation: 1 6 5 14 | 0:00.003 |
| 36 | compressing data for btm/wdl, file b | - |
| 37 | find optimal permutation for wtm/dtz, file b | - |
| 38 | best order: 2 | - |
| 39 | best permutation: 1 5 6 14 | - |
| 40 | find optimal permutation for btm/dtz, file b | - |
| 41 | best order: 3 | - |
| 42 | best permutation: 1 6 5 14 | - |
| 43 | permute table for wtm/dtz, file b | 0:00.011 |
| 44 | compressing data for wtm/dtz, file b | - |
| 45 | Initialising broken positions. | 0:00.001 |
| 46 | Calculating white piece captures. | 0:00.000 |
| 47 | Calculating white pawn captures. | 0:00.005 |
| 48 | Calculating black piece captures. | 0:00.000 |
| 49 | Calculating pawn table. | - |
| 50 | tb_size = 1429596 | - |
| 51 | find optimal permutation for wtm/wdl, file c | - |
| 52 | best order: 3 | - |
| 53 | best permutation: 1 5 6 14 | 0:00.003 |
| 54 | compressing data for wtm/wdl, file c | - |
| 55 | find optimal permutation for btm/wdl, file c | - |
| 56 | best order: 0 | - |
| 57 | best permutation: 1 6 5 14 | 0:00.002 |
| 58 | compressing data for btm/wdl, file c | - |
| 59 | find optimal permutation for wtm/dtz, file c | - |
| 60 | best order: 3 | - |
| 61 | best permutation: 1 5 6 14 | - |
| 62 | find optimal permutation for btm/dtz, file c | - |
| 63 | best order: 3 | - |
| 64 | best permutation: 1 6 5 14 | - |
| 65 | permute table for wtm/dtz, file c | 0:00.022 |
| 66 | compressing data for wtm/dtz, file c | - |
| 67 | Initialising broken positions. | 0:00.001 |
| 68 | Calculating white piece captures. | 0:00.000 |
| 69 | Calculating white pawn captures. | 0:00.001 |
| 70 | Calculating black piece captures. | 0:00.000 |
| 71 | Calculating pawn table. | - |
| 72 | tb_size = 1429596 | - |
| 73 | find optimal permutation for wtm/wdl, file d | - |
| 74 | best order: 3 | - |
| 75 | best permutation: 1 5 6 14 | 0:00.003 |
| 76 | compressing data for wtm/wdl, file d | - |
| 77 | find optimal permutation for btm/wdl, file d | - |
| 78 | best order: 0 | - |
| 79 | best permutation: 1 6 5 14 | 0:00.011 |
| 80 | compressing data for btm/wdl, file d | - |
| 81 | find optimal permutation for wtm/dtz, file d | - |
| 82 | best order: 3 | - |
| 83 | best permutation: 1 5 6 14 | - |
| 84 | find optimal permutation for btm/dtz, file d | - |
| 85 | best order: 3 | - |
| 86 | best permutation: 1 6 5 14 | - |
| 87 | permute table for wtm/dtz, file d | 0:00.025 |
| 88 | compressing data for wtm/dtz, file d | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KQPvK.rtbw | 12.20 KB | E7CD0729A1B2... | OK | OK |
| KQPvK.rtbz | 31.45 KB | CB382FA5BA01... | NO | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KQPvK.out

### KRPvK  (pawnful, wall 3,954 ms, peak 48.88 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Initialising broken positions. | 0:00.000 |
| 2 | Calculating white piece captures. | 0:00.000 |
| 3 | Calculating white pawn captures. | 0:00.001 |
| 4 | Calculating black piece captures. | 0:00.000 |
| 5 | Calculating pawn table. | - |
| 6 | tb_size = 1429596 | - |
| 7 | find optimal permutation for wtm/wdl, file a | - |
| 8 | best order: 3 | - |
| 9 | best permutation: 1 4 6 14 | 0:00.002 |
| 10 | compressing data for wtm/wdl, file a | - |
| 11 | find optimal permutation for btm/wdl, file a | - |
| 12 | best order: 1 | - |
| 13 | best permutation: 1 4 6 14 | 0:00.002 |
| 14 | compressing data for btm/wdl, file a | - |
| 15 | find optimal permutation for wtm/dtz, file a | - |
| 16 | best order: 1 | - |
| 17 | best permutation: 1 4 6 14 | - |
| 18 | find optimal permutation for btm/dtz, file a | - |
| 19 | best order: 3 | - |
| 20 | best permutation: 1 6 4 14 | - |
| 21 | permute table for wtm/dtz, file a | 0:00.027 |
| 22 | compressing data for wtm/dtz, file a | - |
| 23 | Initialising broken positions. | 0:00.001 |
| 24 | Calculating white piece captures. | 0:00.000 |
| 25 | Calculating white pawn captures. | 0:00.005 |
| 26 | Calculating black piece captures. | 0:00.000 |
| 27 | Calculating pawn table. | - |
| 28 | tb_size = 1429596 | - |
| 29 | find optimal permutation for wtm/wdl, file b | - |
| 30 | best order: 3 | - |
| 31 | best permutation: 1 4 6 14 | 0:00.022 |
| 32 | compressing data for wtm/wdl, file b | - |
| 33 | find optimal permutation for btm/wdl, file b | - |
| 34 | best order: 1 | - |
| 35 | best permutation: 1 4 6 14 | 0:00.003 |
| 36 | compressing data for btm/wdl, file b | - |
| 37 | find optimal permutation for wtm/dtz, file b | - |
| 38 | best order: 1 | - |
| 39 | best permutation: 1 4 6 14 | - |
| 40 | find optimal permutation for btm/dtz, file b | - |
| 41 | best order: 3 | - |
| 42 | best permutation: 1 6 14 4 | - |
| 43 | permute table for wtm/dtz, file b | 0:00.002 |
| 44 | compressing data for wtm/dtz, file b | - |
| 45 | Initialising broken positions. | 0:00.000 |
| 46 | Calculating white piece captures. | 0:00.000 |
| 47 | Calculating white pawn captures. | 0:00.000 |
| 48 | Calculating black piece captures. | 0:00.000 |
| 49 | Calculating pawn table. | - |
| 50 | tb_size = 1429596 | - |
| 51 | find optimal permutation for wtm/wdl, file c | - |
| 52 | best order: 3 | - |
| 53 | best permutation: 1 4 6 14 | 0:00.002 |
| 54 | compressing data for wtm/wdl, file c | - |
| 55 | find optimal permutation for btm/wdl, file c | - |
| 56 | best order: 1 | - |
| 57 | best permutation: 1 4 6 14 | 0:00.003 |
| 58 | compressing data for btm/wdl, file c | - |
| 59 | find optimal permutation for wtm/dtz, file c | - |
| 60 | best order: 1 | - |
| 61 | best permutation: 1 4 6 14 | - |
| 62 | find optimal permutation for btm/dtz, file c | - |
| 63 | best order: 3 | - |
| 64 | best permutation: 1 6 14 4 | - |
| 65 | permute table for wtm/dtz, file c | 0:00.002 |
| 66 | compressing data for wtm/dtz, file c | - |
| 67 | Initialising broken positions. | 0:00.001 |
| 68 | Calculating white piece captures. | 0:00.000 |
| 69 | Calculating white pawn captures. | 0:00.000 |
| 70 | Calculating black piece captures. | 0:00.000 |
| 71 | Calculating pawn table. | - |
| 72 | tb_size = 1429596 | - |
| 73 | find optimal permutation for wtm/wdl, file d | - |
| 74 | best order: 3 | - |
| 75 | best permutation: 1 4 6 14 | 0:00.015 |
| 76 | compressing data for wtm/wdl, file d | - |
| 77 | find optimal permutation for btm/wdl, file d | - |
| 78 | best order: 1 | - |
| 79 | best permutation: 1 4 6 14 | 0:00.011 |
| 80 | compressing data for btm/wdl, file d | - |
| 81 | find optimal permutation for wtm/dtz, file d | - |
| 82 | best order: 1 | - |
| 83 | best permutation: 1 4 6 14 | - |
| 84 | find optimal permutation for btm/dtz, file d | - |
| 85 | best order: 3 | - |
| 86 | best permutation: 1 6 14 4 | - |
| 87 | permute table for wtm/dtz, file d | 0:00.006 |
| 88 | compressing data for wtm/dtz, file d | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KRPvK.rtbw | 5.02 KB | 6BC2AA9DB5EE... | OK | OK |
| KRPvK.rtbz | 12.64 KB | EF0545434B2D... | NO | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KRPvK.out

### KBPvK  (pawnful, wall 6,266 ms, peak 442.48 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Initialising broken positions. | 0:00.000 |
| 2 | Calculating white piece captures. | 0:00.000 |
| 3 | Calculating white pawn captures. | 0:00.001 |
| 4 | Calculating black piece captures. | 0:00.000 |
| 5 | Calculating pawn table. | - |
| 6 | tb_size = 1429596 | - |
| 7 | find optimal permutation for wtm/wdl, file a | - |
| 8 | best order: 2 | - |
| 9 | best permutation: 1 6 3 14 | 0:00.002 |
| 10 | compressing data for wtm/wdl, file a | - |
| 11 | find optimal permutation for btm/wdl, file a | - |
| 12 | best order: 2 | - |
| 13 | best permutation: 1 6 3 14 | 0:00.002 |
| 14 | compressing data for btm/wdl, file a | - |
| 15 | find optimal permutation for wtm/dtz, file a | - |
| 16 | best order: 2 | - |
| 17 | best permutation: 1 6 3 14 | - |
| 18 | find optimal permutation for btm/dtz, file a | - |
| 19 | best order: 3 | - |
| 20 | best permutation: 1 6 3 14 | - |
| 21 | permute table for wtm/dtz, file a | 0:00.011 |
| 22 | compressing data for wtm/dtz, file a | - |
| 23 | Initialising broken positions. | 0:00.002 |
| 24 | Calculating white piece captures. | 0:00.000 |
| 25 | Calculating white pawn captures. | 0:00.001 |
| 26 | Calculating black piece captures. | 0:00.000 |
| 27 | Calculating pawn table. | - |
| 28 | tb_size = 1429596 | - |
| 29 | find optimal permutation for wtm/wdl, file b | - |
| 30 | best order: 2 | - |
| 31 | best permutation: 1 6 3 14 | 0:00.015 |
| 32 | compressing data for wtm/wdl, file b | - |
| 33 | find optimal permutation for btm/wdl, file b | - |
| 34 | best order: 1 | - |
| 35 | best permutation: 1 6 14 3 | 0:00.013 |
| 36 | compressing data for btm/wdl, file b | - |
| 37 | find optimal permutation for wtm/dtz, file b | - |
| 38 | best order: 2 | - |
| 39 | best permutation: 1 6 3 14 | - |
| 40 | find optimal permutation for btm/dtz, file b | - |
| 41 | best order: 3 | - |
| 42 | best permutation: 1 6 3 14 | - |
| 43 | permute table for wtm/dtz, file b | 0:00.003 |
| 44 | compressing data for wtm/dtz, file b | - |
| 45 | Initialising broken positions. | 0:00.002 |
| 46 | Calculating white piece captures. | 0:00.000 |
| 47 | Calculating white pawn captures. | 0:00.001 |
| 48 | Calculating black piece captures. | 0:00.000 |
| 49 | Calculating pawn table. | - |
| 50 | tb_size = 1429596 | - |
| 51 | find optimal permutation for wtm/wdl, file c | - |
| 52 | best order: 3 | - |
| 53 | best permutation: 1 6 3 14 | 0:00.022 |
| 54 | compressing data for wtm/wdl, file c | - |
| 55 | find optimal permutation for btm/wdl, file c | - |
| 56 | best order: 1 | - |
| 57 | best permutation: 1 6 3 14 | 0:00.011 |
| 58 | compressing data for btm/wdl, file c | - |
| 59 | find optimal permutation for wtm/dtz, file c | - |
| 60 | best order: 2 | - |
| 61 | best permutation: 1 6 3 14 | - |
| 62 | find optimal permutation for btm/dtz, file c | - |
| 63 | best order: 3 | - |
| 64 | best permutation: 1 6 3 14 | - |
| 65 | permute table for wtm/dtz, file c | 0:00.012 |
| 66 | compressing data for wtm/dtz, file c | - |
| 67 | Initialising broken positions. | 0:00.002 |
| 68 | Calculating white piece captures. | 0:00.000 |
| 69 | Calculating white pawn captures. | 0:00.001 |
| 70 | Calculating black piece captures. | 0:00.000 |
| 71 | Calculating pawn table. | - |
| 72 | tb_size = 1429596 | - |
| 73 | find optimal permutation for wtm/wdl, file d | - |
| 74 | best order: 2 | - |
| 75 | best permutation: 1 6 3 14 | 0:00.011 |
| 76 | compressing data for wtm/wdl, file d | - |
| 77 | find optimal permutation for btm/wdl, file d | - |
| 78 | best order: 1 | - |
| 79 | best permutation: 1 6 14 3 | 0:00.011 |
| 80 | compressing data for btm/wdl, file d | - |
| 81 | find optimal permutation for wtm/dtz, file d | - |
| 82 | best order: 2 | - |
| 83 | best permutation: 1 6 3 14 | - |
| 84 | find optimal permutation for btm/dtz, file d | - |
| 85 | best order: 3 | - |
| 86 | best permutation: 1 6 3 14 | - |
| 87 | permute table for wtm/dtz, file d | 0:00.004 |
| 88 | compressing data for wtm/dtz, file d | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KBPvK.rtbw | 80.77 KB | 0F1FCA018988... | NO | OK |
| KBPvK.rtbz | 75.52 KB | 210F2000E093... | NO | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KBPvK.out

### KNPvK  (pawnful, wall 5,286 ms, peak 445.98 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Initialising broken positions. | 0:00.000 |
| 2 | Calculating white piece captures. | 0:00.000 |
| 3 | Calculating white pawn captures. | 0:00.001 |
| 4 | Calculating black piece captures. | 0:00.000 |
| 5 | Calculating pawn table. | - |
| 6 | tb_size = 1429596 | - |
| 7 | find optimal permutation for wtm/wdl, file a | - |
| 8 | best order: 2 | - |
| 9 | best permutation: 1 6 2 14 | 0:00.002 |
| 10 | compressing data for wtm/wdl, file a | - |
| 11 | find optimal permutation for btm/wdl, file a | - |
| 12 | best order: 2 | - |
| 13 | best permutation: 1 6 2 14 | 0:00.002 |
| 14 | compressing data for btm/wdl, file a | - |
| 15 | find optimal permutation for wtm/dtz, file a | - |
| 16 | best order: 2 | - |
| 17 | best permutation: 1 6 2 14 | - |
| 18 | find optimal permutation for btm/dtz, file a | - |
| 19 | best order: 3 | - |
| 20 | best permutation: 1 6 2 14 | - |
| 21 | permute table for wtm/dtz, file a | 0:00.002 |
| 22 | compressing data for wtm/dtz, file a | - |
| 23 | Initialising broken positions. | 0:00.003 |
| 24 | Calculating white piece captures. | 0:00.000 |
| 25 | Calculating white pawn captures. | 0:00.001 |
| 26 | Calculating black piece captures. | 0:00.000 |
| 27 | Calculating pawn table. | - |
| 28 | tb_size = 1429596 | - |
| 29 | find optimal permutation for wtm/wdl, file b | - |
| 30 | best order: 3 | - |
| 31 | best permutation: 1 6 2 14 | 0:00.011 |
| 32 | compressing data for wtm/wdl, file b | - |
| 33 | find optimal permutation for btm/wdl, file b | - |
| 34 | best order: 3 | - |
| 35 | best permutation: 1 6 2 14 | 0:00.024 |
| 36 | compressing data for btm/wdl, file b | - |
| 37 | find optimal permutation for wtm/dtz, file b | - |
| 38 | best order: 2 | - |
| 39 | best permutation: 1 6 2 14 | - |
| 40 | find optimal permutation for btm/dtz, file b | - |
| 41 | best order: 3 | - |
| 42 | best permutation: 1 6 2 14 | - |
| 43 | permute table for wtm/dtz, file b | 0:00.003 |
| 44 | compressing data for wtm/dtz, file b | - |
| 45 | Initialising broken positions. | 0:00.003 |
| 46 | Calculating white piece captures. | 0:00.000 |
| 47 | Calculating white pawn captures. | 0:00.002 |
| 48 | Calculating black piece captures. | 0:00.000 |
| 49 | Calculating pawn table. | - |
| 50 | tb_size = 1429596 | - |
| 51 | find optimal permutation for wtm/wdl, file c | - |
| 52 | best order: 2 | - |
| 53 | best permutation: 1 6 2 14 | 0:00.013 |
| 54 | compressing data for wtm/wdl, file c | - |
| 55 | find optimal permutation for btm/wdl, file c | - |
| 56 | best order: 1 | - |
| 57 | best permutation: 1 6 14 2 | 0:00.002 |
| 58 | compressing data for btm/wdl, file c | - |
| 59 | find optimal permutation for wtm/dtz, file c | - |
| 60 | best order: 3 | - |
| 61 | best permutation: 1 6 2 14 | - |
| 62 | find optimal permutation for btm/dtz, file c | - |
| 63 | best order: 3 | - |
| 64 | best permutation: 1 6 2 14 | - |
| 65 | permute table for wtm/dtz, file c | 0:00.006 |
| 66 | compressing data for wtm/dtz, file c | - |
| 67 | Initialising broken positions. | 0:00.003 |
| 68 | Calculating white piece captures. | 0:00.000 |
| 69 | Calculating white pawn captures. | 0:00.001 |
| 70 | Calculating black piece captures. | 0:00.000 |
| 71 | Calculating pawn table. | - |
| 72 | tb_size = 1429596 | - |
| 73 | find optimal permutation for wtm/wdl, file d | - |
| 74 | best order: 2 | - |
| 75 | best permutation: 1 6 2 14 | 0:00.005 |
| 76 | compressing data for wtm/wdl, file d | - |
| 77 | find optimal permutation for btm/wdl, file d | - |
| 78 | best order: 1 | - |
| 79 | best permutation: 1 6 14 2 | 0:00.002 |
| 80 | compressing data for btm/wdl, file d | - |
| 81 | find optimal permutation for wtm/dtz, file d | - |
| 82 | best order: 3 | - |
| 83 | best permutation: 1 6 2 14 | - |
| 84 | find optimal permutation for btm/dtz, file d | - |
| 85 | best order: 3 | - |
| 86 | best permutation: 1 6 2 14 | - |
| 87 | permute table for wtm/dtz, file d | 0:00.003 |
| 88 | compressing data for wtm/dtz, file d | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KNPvK.rtbw | 95.27 KB | C9BA4E523070... | NO | OK |
| KNPvK.rtbz | 113.08 KB | D9F7333665C7... | NO | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KNPvK.out

### KPPvK  (pawnful, wall 2,725 ms, peak 419.88 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Initialising broken positions. | 0:00.000 |
| 2 | Calculating white piece captures. | 0:00.000 |
| 3 | Calculating white pawn captures. | 0:00.001 |
| 4 | Calculating black piece captures. | 0:00.000 |
| 5 | Calculating pawn table. | - |
| 6 | tb_size = 953064 | - |
| 7 | find optimal permutation for wtm/wdl, file a | - |
| 8 | best order: 2 | - |
| 9 | best permutation: 1 1 6 14 | 0:00.001 |
| 10 | compressing data for wtm/wdl, file a | - |
| 11 | find optimal permutation for btm/wdl, file a | - |
| 12 | best order: 2 | - |
| 13 | best permutation: 1 1 6 14 | 0:00.001 |
| 14 | compressing data for btm/wdl, file a | - |
| 15 | find optimal permutation for wtm/dtz, file a | - |
| 16 | best order: 2 | - |
| 17 | best permutation: 1 1 6 14 | - |
| 18 | find optimal permutation for btm/dtz, file a | - |
| 19 | best order: 2 | - |
| 20 | best permutation: 1 1 6 14 | - |
| 21 | permute table for wtm/dtz, file a | 0:00.001 |
| 22 | compressing data for wtm/dtz, file a | - |
| 23 | Initialising broken positions. | 0:00.000 |
| 24 | Calculating white piece captures. | 0:00.000 |
| 25 | Calculating white pawn captures. | 0:00.001 |
| 26 | Calculating black piece captures. | 0:00.000 |
| 27 | Calculating pawn table. | - |
| 28 | tb_size = 680760 | - |
| 29 | find optimal permutation for wtm/wdl, file b | - |
| 30 | best order: 2 | - |
| 31 | best permutation: 1 1 6 14 | 0:00.001 |
| 32 | compressing data for wtm/wdl, file b | - |
| 33 | find optimal permutation for btm/wdl, file b | - |
| 34 | best order: 2 | - |
| 35 | best permutation: 1 1 6 14 | 0:00.001 |
| 36 | compressing data for btm/wdl, file b | - |
| 37 | find optimal permutation for wtm/dtz, file b | - |
| 38 | best order: 2 | - |
| 39 | best permutation: 1 1 14 6 | - |
| 40 | find optimal permutation for btm/dtz, file b | - |
| 41 | best order: 2 | - |
| 42 | best permutation: 1 1 14 6 | - |
| 43 | permute table for wtm/dtz, file b | 0:00.001 |
| 44 | compressing data for wtm/dtz, file b | - |
| 45 | Initialising broken positions. | 0:00.001 |
| 46 | Calculating white piece captures. | 0:00.000 |
| 47 | Calculating white pawn captures. | 0:00.001 |
| 48 | Calculating black piece captures. | 0:00.000 |
| 49 | Calculating pawn table. | - |
| 50 | tb_size = 408456 | - |
| 51 | find optimal permutation for wtm/wdl, file c | - |
| 52 | best order: 2 | - |
| 53 | best permutation: 1 1 6 14 | 0:00.001 |
| 54 | compressing data for wtm/wdl, file c | - |
| 55 | find optimal permutation for btm/wdl, file c | - |
| 56 | best order: 2 | - |
| 57 | best permutation: 1 1 14 6 | 0:00.001 |
| 58 | compressing data for btm/wdl, file c | - |
| 59 | find optimal permutation for wtm/dtz, file c | - |
| 60 | best order: 2 | - |
| 61 | best permutation: 1 1 6 14 | - |
| 62 | find optimal permutation for btm/dtz, file c | - |
| 63 | best order: 2 | - |
| 64 | best permutation: 1 1 14 6 | - |
| 65 | permute table for wtm/dtz, file c | 0:00.001 |
| 66 | compressing data for wtm/dtz, file c | - |
| 67 | Initialising broken positions. | 0:00.000 |
| 68 | Calculating white piece captures. | 0:00.000 |
| 69 | Calculating white pawn captures. | 0:00.001 |
| 70 | Calculating black piece captures. | 0:00.000 |
| 71 | Calculating pawn table. | - |
| 72 | tb_size = 136152 | - |
| 73 | find optimal permutation for wtm/wdl, file d | - |
| 74 | best order: 2 | - |
| 75 | best permutation: 1 1 6 14 | 0:00.000 |
| 76 | compressing data for wtm/wdl, file d | - |
| 77 | find optimal permutation for btm/wdl, file d | - |
| 78 | best order: 2 | - |
| 79 | best permutation: 1 1 14 6 | 0:00.000 |
| 80 | compressing data for btm/wdl, file d | - |
| 81 | find optimal permutation for wtm/dtz, file d | - |
| 82 | best order: 2 | - |
| 83 | best permutation: 1 1 6 14 | - |
| 84 | find optimal permutation for btm/dtz, file d | - |
| 85 | best order: 2 | - |
| 86 | best permutation: 1 1 6 14 | - |
| 87 | permute table for wtm/dtz, file d | 0:00.001 |
| 88 | compressing data for wtm/dtz, file d | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KPPvK.rtbw | 26.89 KB | 143D4CDFA413... | NO | OK |
| KPPvK.rtbz | 9.33 KB | F5825F4C7356... | NO | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KPPvK.out

### KQvKP  (pawnful, wall 6,898 ms, peak 458.13 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Initialising broken positions. | 0:00.000 |
| 2 | Calculating white piece captures. | 0:00.000 |
| 3 | Calculating black piece captures. | 0:00.000 |
| 4 | Calculating black pawn captures. | 0:00.001 |
| 5 | Calculating pawn table. | - |
| 6 | tb_size = 1429596 | - |
| 7 | find optimal permutation for wtm/wdl, file a | - |
| 8 | best order: 2 | - |
| 9 | best permutation: 9 5 14 6 | 0:00.003 |
| 10 | compressing data for wtm/wdl, file a | - |
| 11 | find optimal permutation for btm/wdl, file a | - |
| 12 | best order: 3 | - |
| 13 | best permutation: 9 6 5 14 | 0:00.006 |
| 14 | compressing data for btm/wdl, file a | - |
| 15 | find optimal permutation for wtm/dtz, file a | - |
| 16 | best order: 2 | - |
| 17 | best permutation: 9 6 5 14 | - |
| 18 | find optimal permutation for btm/dtz, file a | - |
| 19 | best order: 3 | - |
| 20 | best permutation: 9 6 5 14 | - |
| 21 | permute table for wtm/dtz, file a | 0:00.011 |
| 22 | compressing data for wtm/dtz, file a | - |
| 23 | Initialising broken positions. | 0:00.003 |
| 24 | Calculating white piece captures. | 0:00.000 |
| 25 | Calculating black piece captures. | 0:00.000 |
| 26 | Calculating black pawn captures. | 0:00.002 |
| 27 | Calculating pawn table. | - |
| 28 | tb_size = 1429596 | - |
| 29 | find optimal permutation for wtm/wdl, file b | - |
| 30 | best order: 3 | - |
| 31 | best permutation: 9 5 14 6 | 0:00.010 |
| 32 | compressing data for wtm/wdl, file b | - |
| 33 | find optimal permutation for btm/wdl, file b | - |
| 34 | best order: 2 | - |
| 35 | best permutation: 9 6 5 14 | 0:00.003 |
| 36 | compressing data for btm/wdl, file b | - |
| 37 | find optimal permutation for wtm/dtz, file b | - |
| 38 | best order: 3 | - |
| 39 | best permutation: 9 6 5 14 | - |
| 40 | find optimal permutation for btm/dtz, file b | - |
| 41 | best order: 2 | - |
| 42 | best permutation: 9 6 5 14 | - |
| 43 | permute table for wtm/dtz, file b | 0:00.004 |
| 44 | compressing data for wtm/dtz, file b | - |
| 45 | Initialising broken positions. | 0:00.005 |
| 46 | Calculating white piece captures. | 0:00.000 |
| 47 | Calculating black piece captures. | 0:00.000 |
| 48 | Calculating black pawn captures. | 0:00.001 |
| 49 | Calculating pawn table. | - |
| 50 | tb_size = 1429596 | - |
| 51 | find optimal permutation for wtm/wdl, file c | - |
| 52 | best order: 3 | - |
| 53 | best permutation: 9 5 6 14 | 0:00.002 |
| 54 | compressing data for wtm/wdl, file c | - |
| 55 | find optimal permutation for btm/wdl, file c | - |
| 56 | best order: 3 | - |
| 57 | best permutation: 9 6 5 14 | 0:00.002 |
| 58 | compressing data for btm/wdl, file c | - |
| 59 | find optimal permutation for wtm/dtz, file c | - |
| 60 | best order: 2 | - |
| 61 | best permutation: 9 6 5 14 | - |
| 62 | find optimal permutation for btm/dtz, file c | - |
| 63 | best order: 3 | - |
| 64 | best permutation: 9 6 5 14 | - |
| 65 | permute table for wtm/dtz, file c | 0:00.002 |
| 66 | compressing data for wtm/dtz, file c | - |
| 67 | Initialising broken positions. | 0:00.006 |
| 68 | Calculating white piece captures. | 0:00.000 |
| 69 | Calculating black piece captures. | 0:00.000 |
| 70 | Calculating black pawn captures. | 0:00.002 |
| 71 | Calculating pawn table. | - |
| 72 | tb_size = 1429596 | - |
| 73 | find optimal permutation for wtm/wdl, file d | - |
| 74 | best order: 3 | - |
| 75 | best permutation: 9 5 14 6 | 0:00.003 |
| 76 | compressing data for wtm/wdl, file d | - |
| 77 | find optimal permutation for btm/wdl, file d | - |
| 78 | best order: 3 | - |
| 79 | best permutation: 9 6 5 14 | 0:00.002 |
| 80 | compressing data for btm/wdl, file d | - |
| 81 | find optimal permutation for wtm/dtz, file d | - |
| 82 | best order: 3 | - |
| 83 | best permutation: 9 6 14 5 | - |
| 84 | find optimal permutation for btm/dtz, file d | - |
| 85 | best order: 3 | - |
| 86 | best permutation: 9 6 5 14 | - |
| 87 | permute table for wtm/dtz, file d | 0:00.002 |
| 88 | compressing data for wtm/dtz, file d | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KQvKP.rtbw | 56.70 KB | 2F92788170E8... | OK | OK |
| KQvKP.rtbz | 200.95 KB | FAEDB2DB23BE... | OK | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KQvKP.out

### KRvKP  (pawnful, wall 7,224 ms, peak 457.24 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Initialising broken positions. | 0:00.001 |
| 2 | Calculating white piece captures. | 0:00.000 |
| 3 | Calculating black piece captures. | 0:00.000 |
| 4 | Calculating black pawn captures. | 0:00.002 |
| 5 | Calculating pawn table. | - |
| 6 | tb_size = 1429596 | - |
| 7 | find optimal permutation for wtm/wdl, file a | - |
| 8 | best order: 3 | - |
| 9 | best permutation: 9 4 6 14 | 0:00.002 |
| 10 | compressing data for wtm/wdl, file a | - |
| 11 | find optimal permutation for btm/wdl, file a | - |
| 12 | best order: 2 | - |
| 13 | best permutation: 9 6 4 14 | 0:00.002 |
| 14 | compressing data for btm/wdl, file a | - |
| 15 | find optimal permutation for wtm/dtz, file a | - |
| 16 | best order: 3 | - |
| 17 | best permutation: 9 4 6 14 | - |
| 18 | find optimal permutation for btm/dtz, file a | - |
| 19 | best order: 1 | - |
| 20 | best permutation: 9 4 6 14 | - |
| 21 | permute table for wtm/dtz, file a | 0:00.011 |
| 22 | compressing data for wtm/dtz, file a | - |
| 23 | Initialising broken positions. | 0:00.003 |
| 24 | Calculating white piece captures. | 0:00.000 |
| 25 | Calculating black piece captures. | 0:00.000 |
| 26 | Calculating black pawn captures. | 0:00.002 |
| 27 | Calculating pawn table. | - |
| 28 | tb_size = 1429596 | - |
| 29 | find optimal permutation for wtm/wdl, file b | - |
| 30 | best order: 3 | - |
| 31 | best permutation: 9 4 6 14 | 0:00.011 |
| 32 | compressing data for wtm/wdl, file b | - |
| 33 | find optimal permutation for btm/wdl, file b | - |
| 34 | best order: 3 | - |
| 35 | best permutation: 9 6 4 14 | 0:00.003 |
| 36 | compressing data for btm/wdl, file b | - |
| 37 | find optimal permutation for wtm/dtz, file b | - |
| 38 | best order: 3 | - |
| 39 | best permutation: 9 4 6 14 | - |
| 40 | find optimal permutation for btm/dtz, file b | - |
| 41 | best order: 2 | - |
| 42 | best permutation: 9 6 14 4 | - |
| 43 | permute table for wtm/dtz, file b | 0:00.004 |
| 44 | compressing data for wtm/dtz, file b | - |
| 45 | Initialising broken positions. | 0:00.004 |
| 46 | Calculating white piece captures. | 0:00.000 |
| 47 | Calculating black piece captures. | 0:00.000 |
| 48 | Calculating black pawn captures. | 0:00.002 |
| 49 | Calculating pawn table. | - |
| 50 | tb_size = 1429596 | - |
| 51 | find optimal permutation for wtm/wdl, file c | - |
| 52 | best order: 3 | - |
| 53 | best permutation: 9 4 6 14 | 0:00.004 |
| 54 | compressing data for wtm/wdl, file c | - |
| 55 | find optimal permutation for btm/wdl, file c | - |
| 56 | best order: 3 | - |
| 57 | best permutation: 9 6 4 14 | 0:00.022 |
| 58 | compressing data for btm/wdl, file c | - |
| 59 | find optimal permutation for wtm/dtz, file c | - |
| 60 | best order: 3 | - |
| 61 | best permutation: 9 4 6 14 | - |
| 62 | find optimal permutation for btm/dtz, file c | - |
| 63 | best order: 2 | - |
| 64 | best permutation: 9 14 6 4 | - |
| 65 | permute table for wtm/dtz, file c | 0:00.011 |
| 66 | compressing data for wtm/dtz, file c | - |
| 67 | Initialising broken positions. | 0:00.006 |
| 68 | Calculating white piece captures. | 0:00.001 |
| 69 | Calculating black piece captures. | 0:00.000 |
| 70 | Calculating black pawn captures. | 0:00.002 |
| 71 | Calculating pawn table. | - |
| 72 | tb_size = 1429596 | - |
| 73 | find optimal permutation for wtm/wdl, file d | - |
| 74 | best order: 3 | - |
| 75 | best permutation: 9 4 6 14 | 0:00.004 |
| 76 | compressing data for wtm/wdl, file d | - |
| 77 | find optimal permutation for btm/wdl, file d | - |
| 78 | best order: 2 | - |
| 79 | best permutation: 9 6 4 14 | 0:00.022 |
| 80 | compressing data for btm/wdl, file d | - |
| 81 | find optimal permutation for wtm/dtz, file d | - |
| 82 | best order: 3 | - |
| 83 | best permutation: 9 4 6 14 | - |
| 84 | find optimal permutation for btm/dtz, file d | - |
| 85 | best order: 2 | - |
| 86 | best permutation: 9 6 14 4 | - |
| 87 | permute table for wtm/dtz, file d | 0:00.010 |
| 88 | compressing data for wtm/dtz, file d | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KRvKP.rtbw | 175.33 KB | 1518D677CDA3... | NO | OK |
| KRvKP.rtbz | 188.89 KB | 464CD0C1140D... | NO | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KRvKP.out

### KBvKP  (pawnful, wall 5,765 ms, peak 440.1 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Initialising broken positions. | 0:00.000 |
| 2 | Calculating white piece captures. | 0:00.000 |
| 3 | Calculating black piece captures. | 0:00.000 |
| 4 | Calculating black pawn captures. | 0:00.001 |
| 5 | Calculating pawn table. | - |
| 6 | tb_size = 1429596 | - |
| 7 | find optimal permutation for wtm/wdl, file a | - |
| 8 | best order: 3 | - |
| 9 | best permutation: 9 6 14 3 | 0:00.002 |
| 10 | compressing data for wtm/wdl, file a | - |
| 11 | find optimal permutation for btm/wdl, file a | - |
| 12 | best order: 3 | - |
| 13 | best permutation: 9 6 14 3 | 0:00.002 |
| 14 | compressing data for btm/wdl, file a | - |
| 15 | find optimal permutation for wtm/dtz, file a | - |
| 16 | best order: 2 | - |
| 17 | best permutation: 9 6 14 3 | - |
| 18 | find optimal permutation for btm/dtz, file a | - |
| 19 | best order: 3 | - |
| 20 | best permutation: 9 6 14 3 | - |
| 21 | permute table for btm/dtz, file a | 0:00.002 |
| 22 | compressing data for btm/dtz, file a | - |
| 23 | Initialising broken positions. | 0:00.001 |
| 24 | Calculating white piece captures. | 0:00.000 |
| 25 | Calculating black piece captures. | 0:00.000 |
| 26 | Calculating black pawn captures. | 0:00.001 |
| 27 | Calculating pawn table. | - |
| 28 | tb_size = 1429596 | - |
| 29 | find optimal permutation for wtm/wdl, file b | - |
| 30 | best order: 3 | - |
| 31 | best permutation: 9 6 3 14 | 0:00.003 |
| 32 | compressing data for wtm/wdl, file b | - |
| 33 | find optimal permutation for btm/wdl, file b | - |
| 34 | best order: 3 | - |
| 35 | best permutation: 9 6 14 3 | 0:00.002 |
| 36 | compressing data for btm/wdl, file b | - |
| 37 | find optimal permutation for wtm/dtz, file b | - |
| 38 | best order: 2 | - |
| 39 | best permutation: 9 6 14 3 | - |
| 40 | find optimal permutation for btm/dtz, file b | - |
| 41 | best order: 2 | - |
| 42 | best permutation: 9 6 14 3 | - |
| 43 | permute table for btm/dtz, file b | 0:00.002 |
| 44 | compressing data for btm/dtz, file b | - |
| 45 | Initialising broken positions. | 0:00.001 |
| 46 | Calculating white piece captures. | 0:00.000 |
| 47 | Calculating black piece captures. | 0:00.000 |
| 48 | Calculating black pawn captures. | 0:00.001 |
| 49 | Calculating pawn table. | - |
| 50 | tb_size = 1429596 | - |
| 51 | find optimal permutation for wtm/wdl, file c | - |
| 52 | best order: 3 | - |
| 53 | best permutation: 9 6 3 14 | 0:00.003 |
| 54 | compressing data for wtm/wdl, file c | - |
| 55 | find optimal permutation for btm/wdl, file c | - |
| 56 | best order: 3 | - |
| 57 | best permutation: 9 6 14 3 | 0:00.002 |
| 58 | compressing data for btm/wdl, file c | - |
| 59 | find optimal permutation for wtm/dtz, file c | - |
| 60 | best order: 3 | - |
| 61 | best permutation: 9 6 14 3 | - |
| 62 | find optimal permutation for btm/dtz, file c | - |
| 63 | best order: 2 | - |
| 64 | best permutation: 9 6 3 14 | - |
| 65 | permute table for btm/dtz, file c | 0:00.002 |
| 66 | compressing data for btm/dtz, file c | - |
| 67 | Initialising broken positions. | 0:00.000 |
| 68 | Calculating white piece captures. | 0:00.000 |
| 69 | Calculating black piece captures. | 0:00.000 |
| 70 | Calculating black pawn captures. | 0:00.001 |
| 71 | Calculating pawn table. | - |
| 72 | tb_size = 1429596 | - |
| 73 | find optimal permutation for wtm/wdl, file d | - |
| 74 | best order: 3 | - |
| 75 | best permutation: 9 6 14 3 | 0:00.002 |
| 76 | compressing data for wtm/wdl, file d | - |
| 77 | find optimal permutation for btm/wdl, file d | - |
| 78 | best order: 3 | - |
| 79 | best permutation: 9 6 14 3 | 0:00.012 |
| 80 | compressing data for btm/wdl, file d | - |
| 81 | find optimal permutation for wtm/dtz, file d | - |
| 82 | best order: 3 | - |
| 83 | best permutation: 9 6 14 3 | - |
| 84 | find optimal permutation for btm/dtz, file d | - |
| 85 | best order: 3 | - |
| 86 | best permutation: 9 6 14 3 | - |
| 87 | permute table for btm/dtz, file d | 0:00.011 |
| 88 | compressing data for btm/dtz, file d | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KBvKP.rtbw | 104.89 KB | 9E944CA27E6B... | NO | OK |
| KBvKP.rtbz | 5.83 KB | 22AE98CFA6B6... | NO | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KBvKP.out

### KNvKP  (pawnful, wall 6,613 ms, peak 443.05 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Initialising broken positions. | 0:00.000 |
| 2 | Calculating white piece captures. | 0:00.000 |
| 3 | Calculating black piece captures. | 0:00.000 |
| 4 | Calculating black pawn captures. | 0:00.001 |
| 5 | Calculating pawn table. | - |
| 6 | tb_size = 1429596 | - |
| 7 | find optimal permutation for wtm/wdl, file a | - |
| 8 | best order: 3 | - |
| 9 | best permutation: 9 6 14 2 | 0:00.002 |
| 10 | compressing data for wtm/wdl, file a | - |
| 11 | find optimal permutation for btm/wdl, file a | - |
| 12 | best order: 2 | - |
| 13 | best permutation: 9 6 2 14 | 0:00.003 |
| 14 | compressing data for btm/wdl, file a | - |
| 15 | find optimal permutation for wtm/dtz, file a | - |
| 16 | best order: 1 | - |
| 17 | best permutation: 9 6 14 2 | - |
| 18 | find optimal permutation for btm/dtz, file a | - |
| 19 | best order: 2 | - |
| 20 | best permutation: 9 6 14 2 | - |
| 21 | permute table for btm/dtz, file a | 0:00.011 |
| 22 | compressing data for btm/dtz, file a | - |
| 23 | Initialising broken positions. | 0:00.001 |
| 24 | Calculating white piece captures. | 0:00.000 |
| 25 | Calculating black piece captures. | 0:00.000 |
| 26 | Calculating black pawn captures. | 0:00.001 |
| 27 | Calculating pawn table. | - |
| 28 | tb_size = 1429596 | - |
| 29 | find optimal permutation for wtm/wdl, file b | - |
| 30 | best order: 3 | - |
| 31 | best permutation: 9 6 14 2 | 0:00.004 |
| 32 | compressing data for wtm/wdl, file b | - |
| 33 | find optimal permutation for btm/wdl, file b | - |
| 34 | best order: 2 | - |
| 35 | best permutation: 9 6 2 14 | 0:00.003 |
| 36 | compressing data for btm/wdl, file b | - |
| 37 | find optimal permutation for wtm/dtz, file b | - |
| 38 | best order: 1 | - |
| 39 | best permutation: 9 6 2 14 | - |
| 40 | find optimal permutation for btm/dtz, file b | - |
| 41 | best order: 2 | - |
| 42 | best permutation: 9 6 14 2 | - |
| 43 | permute table for btm/dtz, file b | 0:00.010 |
| 44 | compressing data for btm/dtz, file b | - |
| 45 | Initialising broken positions. | 0:00.001 |
| 46 | Calculating white piece captures. | 0:00.000 |
| 47 | Calculating black piece captures. | 0:00.000 |
| 48 | Calculating black pawn captures. | 0:00.002 |
| 49 | Calculating pawn table. | - |
| 50 | tb_size = 1429596 | - |
| 51 | find optimal permutation for wtm/wdl, file c | - |
| 52 | best order: 3 | - |
| 53 | best permutation: 9 6 14 2 | 0:00.011 |
| 54 | compressing data for wtm/wdl, file c | - |
| 55 | find optimal permutation for btm/wdl, file c | - |
| 56 | best order: 3 | - |
| 57 | best permutation: 9 6 2 14 | 0:00.023 |
| 58 | compressing data for btm/wdl, file c | - |
| 59 | find optimal permutation for wtm/dtz, file c | - |
| 60 | best order: 2 | - |
| 61 | best permutation: 9 6 2 14 | - |
| 62 | find optimal permutation for btm/dtz, file c | - |
| 63 | best order: 3 | - |
| 64 | best permutation: 9 6 14 2 | - |
| 65 | permute table for btm/dtz, file c | 0:00.005 |
| 66 | compressing data for btm/dtz, file c | - |
| 67 | Initialising broken positions. | 0:00.001 |
| 68 | Calculating white piece captures. | 0:00.000 |
| 69 | Calculating black piece captures. | 0:00.000 |
| 70 | Calculating black pawn captures. | 0:00.002 |
| 71 | Calculating pawn table. | - |
| 72 | tb_size = 1429596 | - |
| 73 | find optimal permutation for wtm/wdl, file d | - |
| 74 | best order: 3 | - |
| 75 | best permutation: 9 6 14 2 | 0:00.004 |
| 76 | compressing data for wtm/wdl, file d | - |
| 77 | find optimal permutation for btm/wdl, file d | - |
| 78 | best order: 3 | - |
| 79 | best permutation: 9 6 2 14 | 0:00.004 |
| 80 | compressing data for btm/wdl, file d | - |
| 81 | find optimal permutation for wtm/dtz, file d | - |
| 82 | best order: 3 | - |
| 83 | best permutation: 9 6 2 14 | - |
| 84 | find optimal permutation for btm/dtz, file d | - |
| 85 | best order: 1 | - |
| 86 | best permutation: 9 6 2 14 | - |
| 87 | permute table for btm/dtz, file d | 0:00.004 |
| 88 | compressing data for btm/dtz, file d | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KNvKP.rtbw | 144.95 KB | 13C073E8CA17... | NO | OK |
| KNvKP.rtbz | 10.39 KB | ED2119BAA017... | NO | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KNvKP.out

### KPvKP  (pawnful, wall 5,776 ms, peak 121.61 MB, threads 24)

Steps (phases, duration reported by the generator) :

| # | Phase | time taken |
|---|---|---|
| 1 | Initialising broken positions. | 0:00.000 |
| 2 | Calculating white piece captures. | 0:00.000 |
| 3 | Calculating white pawn captures. | 0:00.001 |
| 4 | Calculating black piece captures. | 0:00.000 |
| 5 | Calculating black pawn captures. | 0:00.001 |
| 6 | Calculating pawn table. | - |
| 7 | tb_size = 1066524 | - |
| 8 | find optimal permutation for wtm/wdl, file a | - |
| 9 | best order: 3 2 | - |
| 10 | best permutation: 1 9 6 14 | 0:00.001 |
| 11 | compressing data for wtm/wdl, file a | - |
| 12 | find optimal permutation for wtm/dtz, file a | - |
| 13 | best order: 1 3 | - |
| 14 | best permutation: 1 9 6 14 | - |
| 15 | permute table for wtm/dtz, file a | 0:00.008 |
| 16 | compressing data for wtm/dtz, file a | - |
| 17 | Initialising broken positions. | 0:00.001 |
| 18 | Calculating white piece captures. | 0:00.000 |
| 19 | Calculating white pawn captures. | 0:00.002 |
| 20 | Calculating black piece captures. | 0:00.000 |
| 21 | Calculating black pawn captures. | 0:00.002 |
| 22 | Calculating pawn table. | - |
| 23 | tb_size = 1066524 | - |
| 24 | find optimal permutation for wtm/wdl, file b | - |
| 25 | best order: 3 1 | - |
| 26 | best permutation: 1 9 6 14 | 0:00.003 |
| 27 | compressing data for wtm/wdl, file b | - |
| 28 | find optimal permutation for wtm/dtz, file b | - |
| 29 | best order: 3 2 | - |
| 30 | best permutation: 1 9 6 14 | - |
| 31 | permute table for wtm/dtz, file b | 0:00.002 |
| 32 | compressing data for wtm/dtz, file b | - |
| 33 | Initialising broken positions. | 0:00.001 |
| 34 | Calculating white piece captures. | 0:00.000 |
| 35 | Calculating white pawn captures. | 0:00.001 |
| 36 | Calculating black piece captures. | 0:00.000 |
| 37 | Calculating black pawn captures. | 0:00.001 |
| 38 | Calculating pawn table. | - |
| 39 | tb_size = 1066524 | - |
| 40 | find optimal permutation for wtm/wdl, file c | - |
| 41 | best order: 3 1 | - |
| 42 | best permutation: 1 9 14 6 | 0:00.008 |
| 43 | compressing data for wtm/wdl, file c | - |
| 44 | find optimal permutation for wtm/dtz, file c | - |
| 45 | best order: 3 1 | - |
| 46 | best permutation: 1 9 6 14 | - |
| 47 | permute table for wtm/dtz, file c | 0:00.004 |
| 48 | compressing data for wtm/dtz, file c | - |
| 49 | Initialising broken positions. | 0:00.001 |
| 50 | Calculating white piece captures. | 0:00.000 |
| 51 | Calculating white pawn captures. | 0:00.002 |
| 52 | Calculating black piece captures. | 0:00.000 |
| 53 | Calculating black pawn captures. | 0:00.002 |
| 54 | Calculating pawn table. | - |
| 55 | tb_size = 1066524 | - |
| 56 | find optimal permutation for wtm/wdl, file d | - |
| 57 | best order: 2 1 | - |
| 58 | best permutation: 1 9 14 6 | 0:00.008 |
| 59 | compressing data for wtm/wdl, file d | - |
| 60 | find optimal permutation for wtm/dtz, file d | - |
| 61 | best order: 3 1 | - |
| 62 | best permutation: 1 9 6 14 | - |
| 63 | permute table for wtm/dtz, file d | 0:00.002 |
| 64 | compressing data for wtm/dtz, file d | - |

| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |
|---|---|---|---|---|
| KPvKP.rtbw | 240.89 KB | 2D8CCD147E86... | NO | OK |
| KPvKP.rtbz | 53.20 KB | A3BE50922C30... | NO | OK |

- Full log: C:\Programmation\tb-1\benchmarks\logs\4pc\KPvKP.out

## Appendix - method

- Wall time: [System.Diagnostics.Stopwatch] around the process (Start-Process to process exit).
- Peak RAM: max of process WorkingSet64 sampled every 25 ms while running (host under no memory pressure, so sampled max approx equals true peak).
- Byte-identical: equality of SHA-256 hashes of the generated file vs the reference file in T:\Syzygy\3-4-5.
- tbcheck: tbcheck.exe <file> (embedded CityHash checksum), exit 0 = OK.
- Threads: the number-of-threads value read from the generator log (generator default when no -t flag passed).
- Watchdog: per-table wall-clock limit of 30 min; if the generator is still running at the limit it is killed, the table is marked FAILED (watchdog) with the partial data collected, and the set continues.
- Per-table logs (stdout, stderr, tbcheck output) stored in C:\Programmation\tb-1\benchmarks\logs\4pc - this is the partial-log fallback required by the project benchmark rule.

