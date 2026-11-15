# Benchmark - KQQQQQQvK (partial, stopped)

**Verdict: STOPPED** - no .rtbw and no .rtbz. The run was killed by the RAM guard. Nothing to compare to a reference, tbcheck not run.

## Machine

| Field | Value |
|---|---|
| Machine name | INTEL13900 |
| CPU | 13th Gen Intel(R) Core(TM) i9-13900KF |
| Cores (physical / logical) | 24 / 24 |
| Max clock | 3000 MHz |
| Total RAM | 191.84 GB |
| OS | Microsoft Windows 11 Education (10.0.26200) |
| GPU | NVIDIA GeForce RTX 5090 |
| User | Ummite |
| Captured | 2026-11-10 19:33:00 |

## Generator

- tbgen.exe: 203264 bytes, modified 2026-09-14 17:54:55
- Command: `C:\Programmation\tb-1\bin\tbgen.exe -t 1 -d -w --stats KQQQQQQvK`
- Threads requested: **1**. The line `number of threads = N` was not captured (stdout stayed on the visible console).
- Work directory: `W:\tbgen-KQQQQQQvK` (`\\ds1821\18TBWWW`)
- RTBPATH: `\\ds1817\40TB Raid 0 B\Syzygy;\\ds1817\40TB Raid 0 B\Syzygy\3-4-5;\\ds1817\40TB Raid 0 B\Syzygy\6-WDL;\\ds1817\40TB Raid 0 B\Syzygy\6-DTZ;\\ds1817\40TB Raid 0 B\Syzygy\7-WDL;\\ds1817\40TB Raid 0 B\Syzygy\7-DTZ`
- STATSDIR: `C:\Programmation\tb-1\benchmarks\logs\KQQQQQQvK`
- Peak RAM: max WorkingSet64 from `ram.csv`, sampled about once per second (not 25 ms)

## Summary

| Table | Kind | Exe | Threads | Wall time | Peak RAM | Exit | Identical to ref |
|---|---|---|---|---|---|---|---|
| KQQQQQQvK | pawnless | tbgen.exe | 1 requested | 126 s | 157.72 GB | -1 | no output |

Wall time is the span of `ram.csv`: 2026-11-11T00:30:04.652Z to 2026-11-11T00:32:10.215Z. Window stamp: Tue 11/10/2026 19:30:04.09 local.

## What happened

`alloc_mapped` created `W:\tbgen-KQQQQQQvK\KQQQQQQvK.tmp0.table` with logical length 63496796504064 bytes (57.75 TiB, both sides, `462 << 37`). `W:` reported free space stayed at 16080.96 GB for the whole run, including while that file existed. The volume has about 15.7 TB free, so the 57.75 TiB length was not a full allocation.

The process then touched the map. Working set climbed to 161502 MB (157.72 GB). Private bytes stayed at 118654 MB. Free RAM fell from about 169 GB to 7781 MB. The watcher stopped `tbgen` because free RAM went under 8 GB. Exit code written by the console script: -1.

On process exit the temp file was removed (`FILE_FLAG_DELETE_ON_CLOSE`). After the stop, `W:\tbgen-KQQQQQQvK` was empty and `W:` still showed 16080.96 GB free. Free RAM returned to about 170 GB.

No generator phase line (`time taken =`) was captured. No `.rtbw`, no `.rtbz`, no SHA-256, no 16-byte trailer, no `tbcheck`.

## Run 2 - cancelled by request (2026-11-10 21:05 local)

Command: `C:\Programmation\tb-1\bin\tbgen.exe -t 1 -d -w --stats KQQQQQQvK`

RAM cap requested in the window: 150 Gio. Working set stayed at 153600 MB. Private bytes stayed at 118654 MB. Free RAM stayed near 14 GB. `W:` free space stayed at 16080.95 GB.

`ram.csv` for this run: 2026-11-11T00:39:19Z to 2026-11-11T02:05:50Z. One thread. Phase still `Initialising broken positions` when stopped. Process read bytes stayed at 0. SMB data reads stayed at 0. The only share with traffic was `\\ds1821\18TBWWW`, about 1 metadata request per second.

Stopped on request. Temp file `W:\tbgen-KQQQQQQvK\KQQQQQQvK.tmp0.table` (logical length 63496796504064) was removed. `W:\tbgen-KQQQQQQvK` is empty. Free RAM after the stop: about 170 GB. No `.rtbw`, no `.rtbz`.

The earlier `ram.csv` of run 1 was overwritten by this run.

## Logs

- `C:\Programmation\tb-1\benchmarks\logs\KQQQQQQvK\ram.csv`
- `C:\Programmation\tb-1\benchmarks\logs\KQQQQQQvK\exit.txt`
- `C:\Programmation\tb-1\benchmarks\logs\KQQQQQQvK\window-started.txt`
- `C:\Programmation\tb-1\benchmarks\logs\KQQQQQQvK\run-KQQQQQQvK.cmd`
