# tb_benchmark.ps1 - regenerate a set of tablebases, measure it, validate it, write a benchmark report.
#
# Style rules (PowerShell 5.1 safe, pure ASCII):
#   - no backtick characters anywhere
#   - no line continuations (every statement on one line)
#   - -f format patterns in single quotes, all format args precomputed into variables
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File tb_benchmark.ps1 -Set 3pc -Tables "KRvK;KQvK;KBvK;KNvK;KPvK" -OutDir C:\Programmation\tb-1\test_gen_3pc_full -RtbPath C:\Programmation\tb-1\test_gen_3pc_full -RefDir T:\Syzygy\3-4-5
#   (Tables separator: ';' or ',' - use ';' when invoked through a shell that mangles commas in quotes)

param(
  [Parameter(Mandatory=$true)][string]$Set,
  [string]$Tables = '',
  [string]$TablesFile = '',
  [Parameter(Mandatory=$true)][string]$OutDir,
  [Parameter(Mandatory=$true)][string]$RtbPath,
  [Parameter(Mandatory=$true)][string]$RefDir,
  [string]$BinDir = 'C:\Programmation\tb-1\bin',
  [string]$ReportDir = 'C:\Programmation\tb-1\benchmarks',
  [int]$Threads = 0,
  [int]$PollMs = 25,
  [int]$TableTimeoutMin = 30,
  [switch]$NoValidate
)

$ErrorActionPreference = 'Stop'
if ($TablesFile -ne '') { $Tables = [System.IO.File]::ReadAllText($TablesFile).Trim() }
if ($Tables -eq '') { throw 'Provide -Tables or -TablesFile' }
$script:md = New-Object System.Collections.Generic.List[string]
function Add { param($x) $script:md.Add([string]$x) }
function Format-Bytes { param([long]$B) if ($B -lt 1KB) { return ('{0:N0} B' -f $B) }; if ($B -lt 1MB) { return ('{0:N2} KB' -f ($B / 1KB)) }; if ($B -lt 1GB) { return ('{0:N2} MB' -f ($B / 1MB)) }; return ('{0:N2} GB' -f ($B / 1GB)) }
function Get-ExeInfo { param([string]$Path) if (-not (Test-Path $Path)) { return $null }; $f = Get-Item $Path; return [pscustomobject]@{ bytes = $f.Length; modified = $f.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss') } }

$cs  = Get-CimInstance Win32_ComputerSystem
$cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1)
$os  = Get-CimInstance Win32_OperatingSystem
$gpuName = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name
$osLine = ('{0} ({1})' -f $os.Caption, $os.Version)
$hw = [pscustomobject]@{
  machine = $env:COMPUTERNAME
  cpu = $cpu.Name
  cores_physical = $cpu.NumberOfCores
  cores_logical = $cpu.NumberOfLogicalProcessors
  max_clock_mhz = $cpu.MaxClockSpeed
  total_ram_gb = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
  os = $osLine
  gpu = $gpuName
  user = $env:USERNAME
  powershell = $PSVersionTable.PSVersion.ToString()
  captured = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
}

$tableList = @($Tables -split '[,;\s]' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
Write-Host ('DIAG tables param len={0} count={1} list=[{2}]' -f $Tables.Length, $tableList.Count, ($tableList -join '|'))
$g0 = Get-ExeInfo (Join-Path $BinDir 'tbgen.exe')
$g1 = Get-ExeInfo (Join-Path $BinDir 'tbgenp.exe')
$logDir = Join-Path $ReportDir ('logs' + '\' + $Set)
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
$tbcheckExe = Join-Path $BinDir 'tbcheck.exe'

$entries = New-Object System.Collections.Generic.List[object]
$allIdent = $true
$tbAllOk = $true
$maxPeakB = [long]0
$totalOutB = [long]0
$totalWallMs = [double]0

Write-Host ('SET {0}: generating {1} tables (threads flag: {2}, poll: {3} ms)' -f $Set, $tableList.Count, $Threads, $PollMs)

foreach ($t in $tableList) {
  if ($t -match 'P') { $kind = 'pawnful'; $exeName = 'tbgenp.exe' } else { $kind = 'pawnless'; $exeName = 'tbgen.exe' }
  $exe = Join-Path $BinDir $exeName
  $outLog = Join-Path $logDir ($t + '.out')
  $errLog = Join-Path $logDir ($t + '.err')
  $wdlOld = Join-Path $OutDir ($t + '.rtbw')
  $dtzOld = Join-Path $OutDir ($t + '.rtbz')
  if (Test-Path $wdlOld) { Remove-Item $wdlOld -Force }
  if (Test-Path $dtzOld) { Remove-Item $dtzOld -Force }

  $args_ = @()
  if ($Threads -gt 0) { $args_ = @('-t', $Threads.ToString()) }
  $args_ += $t
  $savedRtbPath = $env:RTBPATH
  if ($RtbPath -and ($RtbPath.Split(';') -contains $OutDir)) { $env:RTBPATH = $RtbPath } else { $env:RTBPATH = ($OutDir + ';' + $RtbPath) }
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $exe
  if ($args_.Count -gt 0) { $psi.Arguments = ($args_ -join ' ') }
  $psi.WorkingDirectory = $OutDir
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.CreateNoWindow = $true
  $ofs = [System.IO.File]::Open($outLog, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
  $ses = [System.IO.File]::Open($errLog, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
  $proc = New-Object System.Diagnostics.Process
  $proc.StartInfo = $psi
  [void]$proc.Start()
  $wa = $proc.StandardOutput.BaseStream.CopyToAsync($ofs)
  $we = $proc.StandardError.BaseStream.CopyToAsync($ses)
  $peak = [long]0
  $watchdogFired = $false
  $watchdogLimitMs = [double]($TableTimeoutMin * 60000)
  while (-not $proc.HasExited) {
    try { $proc.Refresh(); $ws = $proc.WorkingSet64; if ($ws -gt $peak) { $peak = $ws } } catch { }
    if ($watchdogLimitMs -gt 0 -and $sw.ElapsedMilliseconds -ge $watchdogLimitMs) {
      try { $proc.Kill() } catch { }
      $watchdogFired = $true
      break
    }
    Start-Sleep -Milliseconds $PollMs
  }
  $proc.WaitForExit()
  try { [void]$wa.Wait([TimeSpan]::FromSeconds(5)); [void]$we.Wait([TimeSpan]::FromSeconds(5)) } catch { }
  $ofs.Close(); $ses.Close()
  $sw.Stop()
  $code = -1
  if (-not $watchdogFired) {
    $proc.Refresh()
    $code = $proc.ExitCode
    if ($null -eq $code) { $code = -1 }
  }
  try { $wsFinal = $proc.WorkingSet64; if ($wsFinal -gt $peak) { $peak = $wsFinal } } catch { }
  if ($null -eq $savedRtbPath) { Remove-Item Env:\RTBPATH -ErrorAction SilentlyContinue } else { $env:RTBPATH = $savedRtbPath }

  $outText = @()
  if (Test-Path $outLog) { $outText = @(Get-Content $outLog -Encoding ASCII) }
  $threadsUsed = 0
  $steps = New-Object System.Collections.Generic.List[object]
  $lastPhase = ''
  $iterCount = 0
  foreach ($ln in $outText) {
    if ($ln -match 'number of threads\s*=\s*(\d+)') { $threadsUsed = [int]$Matches[1]; continue }
    if ($ln -match '^\s*time taken\s*=\s*(.+?)\s*$') {
      if ($lastPhase -ne '') { [void]$steps.Add([pscustomobject]@{ phase = $lastPhase; time = $Matches[1].Trim() }) }
      $lastPhase = ''
      continue
    }
    if ($ln -match '^\s*Iteration\s+(\d+)') { $iterCount = [int]$Matches[1]; continue }
    if ($ln -match '^\s*$') { continue }
    if ($ln -match '^\[') { continue }
    if ($ln -match '^#') { continue }
    if ($ln -match 'positions (win|are|lose)') { continue }
    $notable = $false
    if ($ln -match '^(Initialising|Calculating|find optimal|permute |compressing |best permutation|best order|tb_size)') { $notable = $true }
    if ($notable) {
      if ($lastPhase -ne '') { [void]$steps.Add([pscustomobject]@{ phase = $lastPhase; time = '-' }) }
      $lastPhase = $ln.Trim()
    }
  }
  if ($lastPhase -ne '') { [void]$steps.Add([pscustomobject]@{ phase = $lastPhase; time = '-' }) }
  if ($iterCount -gt 0) { [void]$steps.Insert(0, [pscustomobject]@{ phase = ('Retrograde iterations: {0}' -f $iterCount); time = '(see log)' }) }

  $fileRecs = @()
  foreach ($ext in @('rtbw', 'rtbz')) {
    $f = Join-Path $OutDir ($t + '.' + $ext)
    $ref = Join-Path $RefDir ($t + '.' + $ext)
    $rec = [pscustomobject]@{ ext = $ext; gen_bytes = [long]0; gen_sha256 = ''; gen_trailer = ''; ref_bytes = [long]0; ref_sha256 = ''; ref_trailer = ''; identical_to_ref = $false; tbcheck = 'NO' }
    if (Test-Path $f) {
      $rec.gen_bytes = (Get-Item $f).Length
      $rec.gen_sha256 = (Get-FileHash $f -Algorithm SHA256).Hash
      $gbytes = [System.IO.File]::ReadAllBytes($f)
      $gn = [Math]::Min(16, $gbytes.Length)
      $gtail = New-Object byte[] $gn
      [Array]::Copy($gbytes, $gbytes.Length - $gn, $gtail, 0, $gn)
      $rec.gen_trailer = (($gtail | ForEach-Object { '{0:x2}' -f [int]$_ }) -join '')
    }
    if (Test-Path $ref) {
      $rec.ref_bytes = (Get-Item $ref).Length
      $rec.ref_sha256 = (Get-FileHash $ref -Algorithm SHA256).Hash
      $rbytes = [System.IO.File]::ReadAllBytes($ref)
      $rn = [Math]::Min(16, $rbytes.Length)
      $rtail = New-Object byte[] $rn
      [Array]::Copy($rbytes, $rbytes.Length - $rn, $rtail, 0, $rn)
      $rec.ref_trailer = (($rtail | ForEach-Object { '{0:x2}' -f [int]$_ }) -join '')
      $rec.identical_to_ref = ($rec.gen_sha256 -ne '' -and $rec.gen_sha256 -eq $rec.ref_sha256)
    }
    if (-not $NoValidate -and (Test-Path $f)) {
      $tbLog = Join-Path $logDir ($t + '.' + $ext + '.tbcheck')
      & $tbcheckExe $f 2>&1 | Out-File -FilePath $tbLog -Encoding ascii
      if ($LASTEXITCODE -eq 0) { $rec.tbcheck = 'OK' } else { $rec.tbcheck = ('exit {0}' -f $LASTEXITCODE) }
    }
    $fileRecs += $rec
  }

  $ident = (@($fileRecs | Where-Object { -not $_.identical_to_ref }).Count -eq 0)
  $tbOk = (@($fileRecs | Where-Object { $_.tbcheck -ne 'OK' }).Count -eq 0)
  if (-not $ident) { $allIdent = $false }
  if (-not $tbOk) { $tbAllOk = $false }
  $setOutB = [long](@($fileRecs | Measure-Object -Property gen_bytes -Sum).Sum)
  $totalOutB += $setOutB
  $totalWallMs += [double]$sw.ElapsedMilliseconds
  if ($peak -gt $maxPeakB) { $maxPeakB = $peak }
  $entry = [pscustomobject]@{
    table = $t; kind = $kind; exe = $exeName; threads_used = $threadsUsed
    wall_ms = [double]$sw.ElapsedMilliseconds
    peak_ram_mb = [math]::Round($peak / 1MB, 2)
    exit_code = $code; log = $outLog; steps = $steps; files = $fileRecs; watchdog = $watchdogFired
  }
  $entries.Add($entry)
  $wallTxt = ('{0:N0} ms' -f $sw.ElapsedMilliseconds)
  $peakTxt = Format-Bytes $peak
  $wdTxt = if ($watchdogFired) { 'YES' } else { 'no' }
  Write-Host ('{0,-8} {1,-9} wall={2,-10} peak={3,-10} thr={4,-3} exit={5} identical={6} tbcheck={7} watchdog={8}' -f $t, $kind, $wallTxt, $peakTxt, $threadsUsed, $code, $ident, $tbOk, $wdTxt)
}

Write-Host 'LOOP_DONE'
try {
$allFiles = @()
foreach ($e in $entries) { foreach ($ff in @($e.files)) { $allFiles += $ff } }
$identCount = @($allFiles | Where-Object { $_.identical_to_ref }).Count
$tbOkCount = @($allFiles | Where-Object { $_.tbcheck -eq 'OK' }).Count
if ($allIdent -and $tbAllOk) { $verdict = 'VALID - 100% byte-identical to reference' }
elseif ($allIdent) { $verdict = 'PARTIAL - byte-identical but tbcheck not fully ok' }
else { $verdict = 'INVALID - generated files differ from reference' }
$entriesArr = New-Object System.Collections.ArrayList
foreach ($e in $entries) {
  $stepCopy = New-Object System.Collections.ArrayList
  if ($null -ne $e.steps) { foreach ($st in $e.steps) { [void]$stepCopy.Add($st) } }
  $fileCopy = New-Object System.Collections.ArrayList
  if ($null -ne $e.files) { foreach ($fl in $e.files) { [void]$fileCopy.Add($fl) } }
  $exCode = $e.exit_code; if ($null -eq $exCode) { $exCode = 0 }
  [void]$entriesArr.Add([pscustomobject]@{
    table = $e.table; kind = $e.kind; exe = $e.exe; threads_used = $e.threads_used
    wall_ms = $e.wall_ms; peak_ram_mb = $e.peak_ram_mb; exit_code = $exCode; log = $e.log; watchdog = $e.watchdog
    steps = $stepCopy; files = $fileCopy
  })
}
$report = [pscustomobject]@{
  set = $Set
  table_count = $tableList.Count
  generated_at = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
  threads_flag = $Threads
  poll_ms = $PollMs
  table_timeout_min = $TableTimeoutMin
  machine = $hw
  generator = [pscustomobject]@{ tbgen = $g0; tbgenp = $g1 }
  summary = [pscustomobject]@{ total_wall_ms = [math]::Round($totalWallMs, 1); max_peak_ram_mb = [math]::Round($maxPeakB / 1MB, 2); total_output_bytes = $totalOutB; files_identical = $identCount; files_total = $allFiles.Count; tbcheck_ok = $tbOkCount; tbcheck_total = $allFiles.Count }
  verdict = $verdict
  ref_dir = $RefDir
  out_dir = $OutDir
  rtb_path = $RtbPath
  entries = $entriesArr
}

$jsonPath = Join-Path $ReportDir ($Set + '.benchmark.json')

Add ('# Benchmark - ' + $Set + ' (' + $tableList.Count + ' tables)')
Add ''
$verdictLine = ('**Verdict: {0}** - {1}/{2} files byte-identical to reference {3}, tbcheck ok: {4}/{5}.' -f $verdict, $identCount, $allFiles.Count, $RefDir, $tbOkCount, $allFiles.Count)
Add $verdictLine
Add ''
Add '## Machine'
Add ''
Add '| Field | Value |'
Add '|---|---|'
Add ('| Machine name | ' + $hw.machine + ' |')
Add ('| CPU | ' + $hw.cpu + ' |')
$coresLine = ('| Cores (physical / logical) | {0} / {1} |' -f $hw.cores_physical, $hw.cores_logical)
Add $coresLine
$clockLine = ('| Max clock | {0} MHz |' -f $hw.max_clock_mhz)
Add $clockLine
$ramLine = ('| Total RAM | {0} GB |' -f $hw.total_ram_gb)
Add $ramLine
Add ('| OS | ' + $hw.os + ' |')
Add ('| GPU | ' + $hw.gpu + ' |')
Add ('| User | ' + $hw.user + ' |')
Add ('| PowerShell | ' + $hw.powershell + ' |')
Add ('| Captured | ' + $hw.captured + ' |')
Add ''
Add '## Generator'
Add ''
if ($null -ne $g0) { $g0Line = ('- tbgen.exe: {0} bytes, modified {1}' -f $g0.bytes, $g0.modified); Add $g0Line }
if ($null -ne $g1) { $g1Line = ('- tbgenp.exe: {0} bytes, modified {1}' -f $g1.bytes, $g1.modified); Add $g1Line }
$thrLine = ('- Threads requested: **{0}** - 0 = generator default (all logical cores)' -f $Threads)
Add $thrLine
$pollLine = ('- Peak RAM measured by sampling WorkingSet every {0} ms' -f $PollMs)
Add $pollLine
$pathsLine = ('- OutDir: ' + $OutDir + '   |   RTBPATH: ' + $RtbPath + '   |   Reference: ' + $RefDir)
Add $pathsLine
Add ''
$smTot = ('{0:N0} ms' -f $totalWallMs)
$smPeak = Format-Bytes $maxPeakB
$smOut = Format-Bytes $totalOutB
$sumLine = ('## Summary (set total: {0}, max peak RAM: {1}, total output: {2})' -f $smTot, $smPeak, $smOut)
Add $sumLine
Add ''
Add '| Table | Kind | Exe | Threads | Wall time | Peak RAM | Exit | Identical to ref |'
Add '|---|---|---|---|---|---|---|---|'
foreach ($e in $entries) {
  $rowIdent = @($e.files | Where-Object { -not $_.identical_to_ref }).Count -eq 0
  $rowIdTxt = if ($rowIdent) { 'OK' } else { 'NO' }
  $rowWall = ('{0:N0} ms' -f $e.wall_ms)
  $rowPeak = ('{0} MB' -f $e.peak_ram_mb)
  $rowLine = ('| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} |' -f $e.table, $e.kind, $e.exe, $e.threads_used, $rowWall, $rowPeak, $e.exit_code, $rowIdTxt)
  Add $rowLine
}
Add ''
Add '## Per-table detail (steps + files)'
foreach ($e in $entries) {
  Add ''
  $headTag = $e.kind
  if ($e.watchdog) { $headTag = $e.kind + ' - FAILED (watchdog: killed after ' + [string]$TableTimeoutMin + ' min)' }
  $headLine = ('### {0}  ({1}, wall {2:N0} ms, peak {3} MB, threads {4})' -f $e.table, $headTag, $e.wall_ms, $e.peak_ram_mb, $e.threads_used)
  Add $headLine
  if ($null -ne $e.steps -and $e.steps.Count -gt 0) {
    Add ''
    Add 'Steps (phases, duration reported by the generator) :'
    Add ''
    Add '| # | Phase | time taken |'
    Add '|---|---|---|'
    $i = 0
    foreach ($s in $e.steps) { $i++; $stepLine = ('| {0} | {1} | {2} |' -f $i, $s.phase, $s.time); Add $stepLine }
  }
  Add ''
  Add '| File | Gen size | SHA-256 (generated) | Identical to ref | tbcheck |'
  Add '|---|---|---|---|---|'
  foreach ($f in $e.files) {
    $fSize = Format-Bytes $f.gen_bytes
    $fSha = $f.gen_sha256
    if ($fSha.Length -gt 20) { $fSha = $fSha.Substring(0, 12) + '...' }
    $fId = if ($f.identical_to_ref) { 'OK' } else { 'NO' }
    $fLine = ('| {0}.{1} | {2} | {3} | {4} | {5} |' -f $e.table, $f.ext, $fSize, $fSha, $fId, $f.tbcheck)
    Add $fLine
  }
  Add ''
  $logLine = ('- Full log: ' + $e.log)
  Add $logLine
}
Add ''
Add '## Appendix - method'
Add ''
Add '- Wall time: [System.Diagnostics.Stopwatch] around the process (Start-Process to process exit).'
$apxPoll = ('- Peak RAM: max of process WorkingSet64 sampled every {0} ms while running (host under no memory pressure, so sampled max approx equals true peak).' -f $PollMs)
Add $apxPoll
$apxRef = ('- Byte-identical: equality of SHA-256 hashes of the generated file vs the reference file in {0}.' -f $RefDir)
Add $apxRef
Add '- tbcheck: tbcheck.exe <file> (embedded CityHash checksum), exit 0 = OK.'
Add '- Threads: the number-of-threads value read from the generator log (generator default when no -t flag passed).'
$apxWd = ('- Watchdog: per-table wall-clock limit of {0} min; if the generator is still running at the limit it is killed, the table is marked FAILED (watchdog) with the partial data collected, and the set continues.' -f $TableTimeoutMin)
Add $apxWd
$apxLogs = ('- Per-table logs (stdout, stderr, tbcheck output) stored in {0} - this is the partial-log fallback required by the project benchmark rule.' -f $logDir)
Add $apxLogs
Add ''
$mdPath = Join-Path $ReportDir ($Set + '.benchmark.md')
($script:md -join "`r`n") | Out-File -FilePath $mdPath -Encoding utf8
try {
  $jsonText = $report | ConvertTo-Json -Depth 6 -Compress:$false
  $jsonText | Out-File -FilePath $jsonPath -Encoding utf8
} catch {
  Write-Host ('WARN ConvertTo-Json failed: {0}' -f $_.Exception.Message)
  $jsonPath = $jsonPath + '.failed'
}

Write-Host ''
$finWall = ('{0:N0} ms' -f $totalWallMs)
$finPeak = Format-Bytes $maxPeakB
$finOut = Format-Bytes $totalOutB
Write-Host ('SET {0}: total_wall={1}  max_peak_RAM={2}  total_out={3}' -f $Set, $finWall, $finPeak, $finOut)
Write-Host ('VERDICT: {0}' -f $verdict)
Write-Host ('MD   : {0}' -f $mdPath)
Write-Host ('JSON : {0}' -f $jsonPath)
if (-not ($allIdent -and $tbAllOk)) { exit 1 }
} catch {
  Write-Host ('REPORT_ERR line={0} msg={1}' -f $_.InvocationInfo.ScriptLineNumber, $_.Exception.ToString())
  exit 2
}
