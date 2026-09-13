#Requires -Version 5.1
<#
  tb_benchmark.ps1 - Regenerate a set of Syzygy tablebases and produce a
  benchmark report: machine (CPU / cores / RAM / GPU / OS / name), generator
  binary, per-table wall time, PEAK RAM of the process, generation STEPS
  (phases + per-phase "time taken"), output file sizes + SHA-256 + trailer,
  and 100% byte-identity validation against a reference directory.

  RULE (see CLAUDE.md "Tablebase generation benchmark rule"): whenever tablebases
  are generated (via Grok or by running the .exe directly), ALWAYS run this and
  keep the produced <Set>.benchmark.{md,json}. If a full benchmark cannot be
  captured, at minimum store the partial generation log with whatever fields are
  available (machine, CPU, cores, time, peak RAM if known).

  Usage:
    powershell -NoProfile -ExecutionPolicy Bypass -File tb_benchmark.ps1 `
      -Set 3pc -Tables "KRvK,KQvK,KBvK,KNvK,KPvK" `
      -OutDir C:\Programmation\tb-1\test_gen_3pc_full `
      -RtbPath C:\Programmation\tb-1\test_gen_3pc_full `
      -RefDir T:\Syzygy\3-4-5

  Notes:
    - Pawnful tables (name contains "P") use tbgenp.exe; pawnless use tbgen.exe.
    - Tables are generated in the ORDER given (generate pawnless before pawnful
      when the pawnful set probes them as subtables).
    - Peak RAM = max of the process WorkingSet64 sampled every -PollMs while it
      runs (no memory pressure on this host, so sample max ~= true peak).
#>
param(
  [string]$Set       = '3pc',
  [string]$Tables    = '',
  [string]$OutDir    = '',
  [string]$RtbPath   = '',
  [string]$RefDir    = '',
  [string]$BinDir    = 'C:\Programmation\tb-1\bin',
  [string]$ReportDir = 'C:\Programmation\tb-1\benchmarks',
  [int]   $Threads   = 0,   # 0 = use generator default (do not pass -t)
  [int]   $PollMs    = 25,
  [switch]$NoValidate
)
$ErrorActionPreference = 'Stop'
if (-not $Tables) { throw "Missing -Tables (comma/space separated table names, in generation order)" }
if (-not $OutDir)  { $OutDir = Join-Path $env:TEMP "tb_bench_$Set" }
if (-not $RtbPath) { $RtbPath = $OutDir }
$env:RTBPATH     = $RtbPath
$env:RTBSTATSDIR = $OutDir
New-Item -ItemType Directory -Force -Path $OutDir    | Out-Null
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
$logDir = Join-Path $ReportDir ("logs\" + $Set)
New-Item -ItemType Directory -Force -Path $logDir    | Out-Null

function Get-Trailer([string]$p){
  $fs = [System.IO.File]::OpenRead($p)
  try {
    $n = [Math]::Min(16, $fs.Length); if ($n -le 0) { return '' }
    $buf = New-Object byte[] $n
    [void]$fs.Seek(-$n, 'End'); [void]$fs.Read($buf, 0, $n)
    -join ($buf | ForEach-Object { $_.ToString('x2') })
  } finally { $fs.Close() }
}
function Get-ExeInfo([string]$p){
  if (-not (Test-Path $p)) { return $null }
  $f = Get-Item $p
  [pscustomobject]@{ path=$p; bytes=$f.Length; mtime=$f.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss') }
}
function Format-Bytes([double]$b){
  if ($b -ge 1GB) { return ('{0:N2} GB' -f ($b/1GB)) }
  if ($b -ge 1MB) { return ('{0:N1} MB' -f ($b/1MB)) }
  if ($b -ge 1KB) { return ('{0:N1} KB' -f ($b/1KB)) }
  return ('{0} B' -f $b)
}

# ---- machine snapshot ----
$cpu = Get-CimInstance Win32_Processor
$cs  = Get-CimInstance Win32_ComputerSystem
$os  = Get-CimInstance Win32_OperatingSystem
$gpu = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name
$hw = [ordered]@{
  machine          = $env:COMPUTERNAME
  cpu              = $cpu.Name.Trim()
  cores_physical   = $cpu.NumberOfCores
  cores_logical    = $cpu.NumberOfLogicalProcessors
  max_clock_mhz    = $cpu.MaxClockSpeed
  total_ram_gb     = [math]::Round($cs.TotalPhysicalMemory/1GB, 2)
  os               = "$($os.Caption)  build $($os.Version).Build$($os.BuildNumber)"
  gpu              = $gpu
  captured         = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
}

$tbcheckExe = Join-Path $BinDir 'tbcheck.exe'
$tables = @($Tables -split '[,\s]+' | Where-Object { $_ })
$entries = New-Object System.Collections.ArrayList

foreach ($t in $tables) {
  $isPawnful = $t -match 'P'
  $exe = if ($isPawnful) { Join-Path $BinDir 'tbgenp.exe' } else { Join-Path $BinDir 'tbgen.exe' }
  $wdl = Join-Path $OutDir "$t.rtbw"
  $dtz = Join-Path $OutDir "$t.rtbz"
  Remove-Item $wdl, $dtz -ErrorAction SilentlyContinue

  $outLog = Join-Path $logDir "$t.out"
  $errLog = Join-Path $logDir "$t.err"
  $args_  = @('--stats', $t)
  if ($Threads -gt 0) { $args_ += @('-t', [string]$Threads) }

  $sw   = [System.Diagnostics.Stopwatch]::StartNew()
  $proc = Start-Process -FilePath $exe -ArgumentList $args_ -WorkingDirectory $OutDir `
           -RedirectStandardOutput $outLog -RedirectStandardError $errLog -PassThru -WindowStyle Hidden
  $peak = 0
  while (-not $proc.HasExited) {
    try {
      $ws = (Get-Process -Id $proc.Id -ErrorAction SilentlyContinue).WorkingSet64
      if ($null -ne $ws -and $ws -gt $peak) { $peak = $ws }
    } catch {}
    Start-Sleep -Milliseconds $PollMs
  }
  $code = $proc.WaitForExit()
  $sw.Stop()

  $logLines = @(Get-Content $outLog -ErrorAction SilentlyContinue)
  $threadsUsed = $null
  $tm = $logLines | Select-String 'number of threads = (\d+)' | Select-Object -First 1
  if ($tm) { $threadsUsed = [int]($tm.Matches[0].Groups[1].Value) }

  $steps = New-Object System.Collections.ArrayList
  $prev = ''
  foreach ($ln in $logLines) {
    if ($ln -match 'time taken\s*=\s*(\S+)') {
      [void]$steps.Add([pscustomobject]@{ phase=$prev.Trim(); time=$matches[1] })
    } else { $prev = $ln }
  }

  $fileRecs = New-Object System.Collections.ArrayList
  foreach ($ext in 'rtbw','rtbz') {
    $g = Join-Path $OutDir "$t.$ext"
    $r = if ($RefDir) { Join-Path $RefDir "$t.$ext" } else { $null }
    $gOk = Test-Path $g
    $gSize  = if ($gOk) { (Get-Item $g).Length } else { $null }
    $gHash  = if ($gOk) { (Get-FileHash $g -Algorithm SHA256).Hash } else { $null }
    $gTrail = if ($gOk) { Get-Trailer $g } else { $null }
    $rOk = ($null -ne $r) -and (Test-Path $r)
    $rSize  = if ($rOk) { (Get-Item $r).Length } else { $null }
    $rHash  = if ($rOk) { (Get-FileHash $r -Algorithm SHA256).Hash } else { $null }
    $identical = ($null -ne $gHash) -and ($null -ne $rHash) -and ($gHash -ceq $rHash)
    $tb = 'n/a (no tbcheck or missing file)'
    if ((Test-Path $tbcheckExe) -and $gOk) {
      $tc = (& $tbcheckExe $g 2>&1 | Out-String).Trim()
      $tb = if ($LASTEXITCODE -eq 0) { "ok - $tc" } else { "FAIL (exit $LASTEXITCODE) - $tc" }
    }
    [void]$fileRecs.Add([pscustomobject]@{
      ext=$ext; gen_bytes=$gSize; gen_sha256=$gHash; gen_trailer=$gTrail
      ref_bytes=$rSize; ref_sha256=$rHash
      identical_to_ref=$identical; tbcheck=$tb
    })
  }

  $entry = [pscustomobject]@{
    table=$t; kind=($(if ($isPawnful) { 'pawnful' } else { 'pawnless' })); exe=(Split-Path $exe -Leaf)
    exe_info=(Get-ExeInfo $exe)
    threads_requested=$(if ($Threads -gt 0) { $Threads } else { 'default' })
    threads_used=$threadsUsed
    wall_ms=$sw.ElapsedMilliseconds
    peak_ram_bytes=$peak
    peak_ram_mb=[math]::Round($peak/1MB, 1)
    exit_code=$code
    steps=$steps
    files=$fileRecs
    log=$outLog
  }
  [void]$entries.Add($entry)
  $allIdent = @($fileRecs | Where-Object { -not $_.identical_to_ref }).Count -eq 0
  Write-Host ("{0,-8} {1,-9} wall={2,7} ms  peak={3,8} MB  thr={4,-3} exit={5}  identical_to_ref={6}" -f `
    $t, $entry.kind, $sw.ElapsedMilliseconds, $entry.peak_ram_mb, $threadsUsed, $code, $allIdent)
}

# ---- set totals ----
$allFiles    = $entries | ForEach-Object { $_.files } | ForEach-Object { $_ }
$allIdent    = @($allFiles | Where-Object { -not $_.identical_to_ref }).Count -eq 0
$tbAllOk     = @($allFiles | Where-Object { $_.tbcheck -notlike 'ok*' }).Count -eq 0
$totalWallMs = ($entries | Measure-Object wall_ms -Sum).Sum
$maxPeakB    = ($entries | Measure-Object peak_ram_bytes -Maximum).Maximum
$totalOutB   = (@($allFiles | Where-Object { $_.gen_bytes }) | Measure-Object gen_bytes -Sum).Sum
$refCount    = @($allFiles | Where-Object { $_.ref_sha256 }).Count

# ---- JSON report ----
$report = [ordered]@{
  set=$Set; generated=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
  machine=$hw
  generator=$(Get-ExeInfo (Join-Path $BinDir 'tbgen.exe'))
  generator_pawnful=$(Get-ExeInfo (Join-Path $BinDir 'tbgenp.exe'))
  threads_flag=$(if ($Threads -gt 0) { $Threads } else { 'default' })
  poll_ms=$PollMs; outdir=$OutDir; rtpath=$RtbPath; refdir=$RefDir
  total_wall_ms=$totalWallMs
  max_peak_ram_bytes=$maxPeakB
  total_output_bytes=$totalOutB
  files_checked=$refCount
  all_identical_to_ref=$allIdent
  tbcheck_all_ok=$tbAllOk
  verdict=$(if ($allIdent -and $tbAllOk) { 'VALID - 100% byte-identical to reference' } else { 'INVALID - see details' })
  entries=$entries
}
$jsonPath = Join-Path $ReportDir "$Set.benchmark.json"
$report | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding utf8

# ---- Markdown report ----
$md = New-Object System.Collections.ArrayList
function Add([string]$s){ [void]$md.Add($s) }
Add "# Benchmark - set $Set"
Add ''
Add ("Generated {0}   |   machine {1}" -f (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'), $hw.machine)
Add ''
Add "## Verdict"
Add ''
Add ("**{0}**  -  {1}/{2} files byte-identical to reference `{3}`, tbcheck ok: {4}." -f `
  $report.verdict, (@($allFiles | Where-Object { $_.identical_to_ref }).Count), $refCount, $RefDir, $tbAllOk)
Add ''
Add "## Machine"
Add ''
Add "| Field | Value |"
Add "|---|---|"
Add ("| Machine name | `{0}` |" -f $hw.machine)
Add ("| CPU | {0} |" -f $hw.cpu)
Add ("| Cores (physical / logical) | {0} / {1} |" -f $hw.cores_physical, $hw.cores_logical)
Add ("| Max clock | {0} MHz |" -f $hw.max_clock_mhz)
Add ("| Total RAM | {0} GB |" -f $hw.total_ram_gb)
Add ("| OS | {0} |" -f $hw.os)
Add ("| GPU | {0} |" -f $hw.gpu)
Add ''
Add "## Generator"
Add ''
$g0 = Get-ExeInfo (Join-Path $BinDir 'tbgen.exe'); $g1 = Get-ExeInfo (Join-Path $BinDir 'tbgenp.exe')
if ($g0) { Add ("- `tbgen.exe`: {0} bytes, modified {1}" -f $g0.bytes, $g0.mtime) }
if ($g1) { Add ("- `tbgenp.exe`: {0} bytes, modified {1}" -f $g1.bytes, $g1.mtime) }
Add ("- Threads requested: **{0}** (0 = generator default)" -f $report.threads_flag)
Add ("- Peak RAM measured by sampling WorkingSet every {0} ms" -f $PollMs)
Add ("- OutDir: `{0}`   |   RTBPATH: `{1}`   |   Reference: `{2}`" -f $OutDir, $RtbPath, $RefDir)
Add ''
Add ("## Summary (set total: {0}, max peak RAM: {1}, total output: {2})" -f `
  ('{0:N0} ms' -f $totalWallMs), (Format-Bytes $maxPeakB), (Format-Bytes $totalOutB))
Add ''
Add "| Table | Kind | Exe | Threads | Wall time | Peak RAM | Exit | Identical to ref |"
Add "|---|---|---|---|---|---|---|---|"
foreach ($e in $entries) {
  $id = @($e.files | Where-Object { -not $_.identical_to_ref }).Count -eq 0
  Add ("| {0} | {1} | {2} | {3} | {4:N0} ms | {5} MB | {6} | {7} |" -f `
    $e.table, $e.kind, $e.exe, $e.threads_used, $e.wall_ms, $e.peak_ram_mb, $e.exit_code, $(if ($id) { 'OK' } else { 'NO' }))
}
Add ''
Add "## Per-table detail (steps + files)"
foreach ($e in $entries) {
  Add ''
  Add "### {0}  ({1}, wall {2:N0} ms, peak {3} MB, threads {4})" -f $e.table, $e.kind, $e.wall_ms, $e.peak_ram_mb, $e.threads_used
  if ($e.steps -and $e.steps.Count -gt 0) {
    Add ''
    Add "Steps (phases, duration reported by the generator) :"
    Add ''
    Add "| # | Phase | time taken |"
    Add "|---|---|---|"
    $i = 0
    foreach ($s in $e.steps) { $i++; Add ("| {0} | {1} | {2} |" -f $i, $s.phase, $s.time) }
  }
  Add ''
  Add "| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |"
  Add "|---|---|---|---|---|"
  foreach ($f in $e.files) {
    $short = $f.gen_sha256; if ($short -and $short.Length -gt 20) { $short = $short.Substring(0, 12) + '...' }
    Add ("| {0}.{1} | {2} | `{3}` | {4} | {5} |" -f $e.table, $f.ext, (Format-Bytes $f.gen_bytes), $short, $(if ($f.identical_to_ref) { 'OK' } else { 'NO' }), $f.tbcheck)
  }
  Add ''
  Add ("- Full log: `{0}`" -f $e.log)
}
Add ''
Add "## Appendix - method"
Add ''
Add "- Wall time: `[System.Diagnostics.Stopwatch]` around the process."
Add ("- Peak RAM: max of process `WorkingSet64`, sampled every {0} ms while running (host under no memory pressure, so sample max ~= true peak)." -f $PollMs)
Add ("- Byte-identical: equality of SHA-256 hashes of the generated file vs the reference file in `{0}`." -f $RefDir)
Add ("- tbcheck: `tbcheck.exe <file>` (embedded CityHash checksum), exit 0 = ok.")
Add "- Threads: the `number of threads = N` value read from the generator log (the generator picks N by default when -t is not passed)."
Add ''
$mdPath = Join-Path $ReportDir "$Set.benchmark.md"
($md -join "`n") | Out-File -FilePath $mdPath -Encoding utf8

Write-Host ''
Write-Host ("SET {0}: total_wall={1:N0} ms  max_peak_RAM={2}  total_out={3}" -f $Set, $totalWallMs, (Format-Bytes $maxPeakB), (Format-Bytes $totalOutB))
Write-Host ("VERDICT: {0}" -f $report.verdict)
Write-Host ("MD   : {0}" -f $mdPath)
Write-Host ("JSON : {0}" -f $jsonPath)
if (-not ($allIdent -and $tbAllOk)) { exit 1 }
exit 0
