# run_6pc.ps1 - uninterrupted 6pc tablebase generation loop, batched over tb_benchmark.ps1.
#
# Style rules (PowerShell 5.1 safe, pure ASCII):
#   - no backtick characters anywhere
#   - no line continuations (every statement on one line)
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File C:\Programmation\tb-1\benchmarks\run_6pc.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File C:\Programmation\tb-1\benchmarks\run_6pc.ps1 -DryRun
#   powershell -NoProfile -ExecutionPolicy Bypass -File C:\Programmation\tb-1\benchmarks\run_6pc.ps1 -OutDir C:\Programmation\tb-1\gen_6pc -RtbPath 'T:\Syzygy;T:\Syzygy\3-4-5' -Threads 24 -BatchSize 10
#   powershell -NoProfile -ExecutionPolicy Bypass -File C:\Programmation\tb-1\benchmarks\run_6pc.ps1 -List 'KBBBBvK KBBBNvK'   (calibration mode)
#   powershell -NoProfile -ExecutionPolicy Bypass -File C:\Programmation\tb-1\benchmarks\run_6pc.ps1 -Keep   (never delete local files)
#
# Behavior:
#   - Table names come from C:\Programmation\tb-1\checksums\wdl6.txt ('Name.rtbw: hash' lines) or -List.
#   - Status CSV: <OutDir>\6pc.status.csv, columns: table,statut,essais,erreur,sha_wdl,sha_dtz.
#   - A table is DONE (skipped on later runs) only if its CSV row has statut ok_identique or diff_garde.
#     Any other row (ref_unavailable, absent_ref, echec, absent) or a missing row = remaining; if the
#     local files already exist and tbcheck passes, they are REVALIDATED (tbcheck + SHA-256) without
#     being regenerated.
#   - After each batch, every tbcheck-ok table is validated against T:\Syzygy\6-WDL\<name>.rtbw and
#     T:\Syzygy\6-DTZ\<name>.rtbz (SHA-256). sha_wdl / sha_dtz = identique, diff, absent_ref (reference
#     file missing on T:) or ref_unavailable (T: drive not reachable at that moment).
#   - Disk management: both SHA-256 identique AND -Keep not set -> both local files deleted, statut
#     ok_identique. Any diff (or absent_ref / ref_unavailable) -> local files kept, statut diff_garde
#     (or absent_ref / ref_unavailable). -Keep: local files are NEVER deleted, statut ok_identique.
#   - Orphan cleanup before each batch, in -OutDir: *.w *.b *.w.k *.b.k *.rtbw.1 *.dtz.1 (validated
#     .rtbw / .rtbz are never touched).
#   - Preflight (non-blocking): prints 'powercfg /query SCHEME_CURRENT SUB_SLEEP' filtered on
#     'Power Setting State', plus the actual Current AC/DC Power Setting Index values, and
#     'bcdedit /enum {current}' filtered on 'bootstatuspolicy'; Write-Warning if the sleep value is
#     != 0xffffffff or bootstatuspolicy is missing.
#   - Loop: batches of -BatchSize tables, each batch = one Start-Process -Wait call of tb_benchmark.ps1
#     (-Set 6pc -Tables 'a b c' -OutDir ... -RtbPath ... -Threads N -RefDir NONE).
#   - A failed batch does not stop the loop: the same tables are retried next batch, max 2 attempts per
#     table, then the table is skipped (statut echec) and listed in the final report / status CSV.
#   - Batch exit code is logged but is NOT the success criterion: tb_benchmark.ps1 exits 1 whenever the
#     reference comparison fails (it is not satisfied with -RefDir NONE), so success is re-evaluated per
#     table after each batch via file presence + tbcheck + SHA-256.
#   - Ref note: -RefDir is intentionally the sentinel NONE (it is Mandatory in tb_benchmark.ps1, so a real
#     omission would abort it); the byte-identical reference check is done here, per file, against
#     T:\Syzygy\6-WDL and T:\Syzygy\6-DTZ.
#
# Outputs:
#   - Per-batch log: C:\Programmation\tb-1\benchmarks\logs\6pc\run_6pc.log (timestamp, batch, exit code, duration)
#   - Per-table logs + benchmark report: C:\Programmation\tb-1\benchmarks\logs\6pc\ and C:\Programmation\tb-1\benchmarks\6pc.benchmark.md / .json (written by tb_benchmark.ps1)
#   - Status CSV: <OutDir>\6pc.status.csv
#   - Exit code: 0 if all tables done (ok_identique / diff_garde), 1 otherwise.

param(
  [string]$OutDir = 'C:\Programmation\tb-1\gen_6pc',
  [string]$RtbPath = 'T:\Syzygy;T:\Syzygy\3-4-5',
  [int]$Threads = 24,
  [int]$BatchSize = 10,
  [string]$List = '',
  [switch]$DryRun,
  [switch]$Keep
)

$ErrorActionPreference = 'Stop'

$Root = 'C:\Programmation\tb-1'
$ListFile = Join-Path $Root 'checksums\wdl6.txt'
$Benchmark = Join-Path $Root 'benchmarks\tb_benchmark.ps1'
$Tbcheck = Join-Path $Root 'bin\tbcheck.exe'
$LogDir = Join-Path $Root 'benchmarks\logs\6pc'
$LogFile = Join-Path $LogDir 'run_6pc.log'
$RefWdlDir = 'T:\Syzygy\6-WDL'
$RefDtzDir = 'T:\Syzygy\6-DTZ'
$MaxAttempts = 2

function Write-Log {
  param([string]$Msg)
  $line = ('{0} {1}' -f (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'), $Msg)
  Add-Content -Path $LogFile -Value $line -Encoding ascii
  Write-Host $line
}

function Read-TableList {
  if ($List -ne '') {
    return @($List -split '[,;\s]+' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
  }
  $names = New-Object System.Collections.Generic.List[string]
  foreach ($raw in [System.IO.File]::ReadAllLines($ListFile)) {
    $s = $raw.Trim()
    if ($s -eq '') { continue }
    $ci = $s.IndexOf(':')
    if ($ci -ge 0) { $s = $s.Substring(0, $ci).Trim() }
    if ($s.EndsWith('.rtbw')) { $s = $s.Substring(0, $s.Length - 5) }
    if ($s -ne '') { $names.Add($s) }
  }
  return @($names)
}

function Read-StatusCsv {
  param([string]$Path)
  $map = @{}
  if (-not (Test-Path $Path)) { return $map }
  $lines = [System.IO.File]::ReadAllLines($Path)
  foreach ($ln in $lines) {
    $s = $ln.Trim()
    if ($s -eq '' -or $s.StartsWith('table,')) { continue }
    $p = $s -split ','
    if ($p.Count -lt 2) { continue }
    $t = $p[0].Trim()
    if ($t -eq '') { continue }
    $statut = $p[1].Trim()
    $essais = 0
    if ($p.Count -ge 3) { [int]::TryParse($p[2].Trim(), [ref]$essais) | Out-Null }
    $erreur = ''
    if ($p.Count -ge 4) { $erreur = $p[3] }
    $sw = ''
    if ($p.Count -ge 6) { $sw = $p[4] }
    $sz = ''
    if ($p.Count -ge 6) { $sz = $p[5] }
    $map[$t] = @{ statut = $statut; essais = $essais; erreur = $erreur; sha_wdl = $sw; sha_dtz = $sz }
  }
  return $map
}

function Save-StatusCsv {
  param([hashtable]$Map, [string]$Path)
  $enc = New-Object System.Text.ASCIIEncoding
  $out = New-Object System.Collections.Generic.List[string]
  $out.Add('table,statut,essais,erreur,sha_wdl,sha_dtz')
  foreach ($t in ($Map.Keys | Sort-Object)) {
    $r = $Map[$t]
    $err = [string]$r.erreur
    $err = $err.Replace(',', ';')
    $out.Add(('{0},{1},{2},{3},{4},{5}' -f $t, $r.statut, [int]$r.essais, $err, $r.sha_wdl, $r.sha_dtz))
  }
  [System.IO.File]::WriteAllLines($Path, $out, $enc)
}

function Test-IsDone {
  param([hashtable]$R)
  return (($R.statut -eq 'ok_identique') -or ($R.statut -eq 'diff_garde'))
}

function Invoke-Tbcheck {
  param([string]$Path)
  & $Tbcheck $Path 2>$null
  return $LASTEXITCODE
}

function Test-RefAvailable {
  param([string]$RefDir)
  return [System.IO.Directory]::Exists($RefDir)
}

function Compare-Sha {
  param([string]$LocalPath, [string]$RefPath)
  $hl = (Get-FileHash -Algorithm SHA256 -Path $LocalPath).Hash.ToLowerInvariant()
  $hr = (Get-FileHash -Algorithm SHA256 -Path $RefPath).Hash.ToLowerInvariant()
  if ($hl -eq $hr) { return 'identique' }
  return 'diff'
}

# Returns a record: statut, erreur, sha_wdl, sha_dtz.
# Re-validates an existing pair (no regeneration): files present + tbcheck ok, then SHA-256 vs T: refs.
function Validate-Table {
  param([string]$T, [string]$Out, [string]$Rt)
  $w = Join-Path $Out ($T + '.rtbw')
  $z = Join-Path $Out ($T + '.rtbz')
  $missing = @()
  if (-not (Test-Path $w)) { $missing += '.rtbw' }
  if (-not (Test-Path $z)) { $missing += '.rtbz' }
  if ($missing.Count -gt 0) {
    return @{ statut = 'absent'; erreur = ('missing ' + ($missing -join '+')); sha_wdl = ''; sha_dtz = '' }
  }
  $cw = Invoke-Tbcheck $w
  if ($cw -ne 0) {
    return @{ statut = 'echec'; erreur = ('tbcheck .rtbw exit ' + [string]$cw); sha_wdl = ''; sha_dtz = '' }
  }
  $cz = Invoke-Tbcheck $z
  if ($cz -ne 0) {
    return @{ statut = 'echec'; erreur = ('tbcheck .rtbz exit ' + [string]$cz); sha_wdl = ''; sha_dtz = '' }
  }
  $sw = ''
  $sz = ''
  if ((Test-RefAvailable $Rt.wdl) -and (Test-RefAvailable $Rt.dtz)) {
    $rw = Join-Path $Rt.wdl ($T + '.rtbw')
    $rz = Join-Path $Rt.dtz ($T + '.rtbz')
    if (-not (Test-Path $rw)) { $sw = 'absent_ref' } else { $sw = Compare-Sha $w $rw }
    if (-not (Test-Path $rz)) { $sz = 'absent_ref' } else { $sz = Compare-Sha $z $rz }
  } else {
    $sw = 'ref_unavailable'
    $sz = 'ref_unavailable'
  }
  $bothIdentique = ($sw -eq 'identique') -and ($sz -eq 'identique')
  if ($bothIdentique) {
    if ($Keep) {
      Write-Log ('VALIDATE {0}: ok_identique (-Keep, local files kept)' -f $T)
    } else {
      Remove-Item -LiteralPath $w -Force -ErrorAction SilentlyContinue
      Remove-Item -LiteralPath $z -Force -ErrorAction SilentlyContinue
      Write-Log ('VALIDATE {0}: ok_identique (local files deleted, T: reference is authoritative)' -f $T)
    }
    return @{ statut = 'ok_identique'; erreur = ''; sha_wdl = $sw; sha_dtz = $sz }
  }
  if ($sw -eq 'diff' -or $sz -eq 'diff') {
    return @{ statut = 'diff_garde'; erreur = ('local files differ from T: reference (kept for diff)'); sha_wdl = $sw; sha_dtz = $sz }
  }
  if ($sw -eq 'ref_unavailable' -or $sz -eq 'ref_unavailable') {
    return @{ statut = 'ref_unavailable'; erreur = ('T: reference not reachable at that moment (local files kept)'); sha_wdl = $sw; sha_dtz = $sz }
  }
  return @{ statut = 'absent_ref'; erreur = ('reference file missing on T: (local files kept)'); sha_wdl = $sw; sha_dtz = $sz }
}

# Removes orphan files left by crashed generator runs in $OutDir. Never touches .rtbw / .rtbz.
function Invoke-OrphanCleanup {
  param([string]$Out)
  if (-not (Test-Path $Out)) { return }
  $pats = @('*.w', '*.b', '*.w.k', '*.b.k', '*.rtbw.1', '*.dtz.1')
  $n = 0
  foreach ($p in $pats) {
    $files = Get-ChildItem -LiteralPath $Out -Filter $p -File -ErrorAction SilentlyContinue
    foreach ($f in $files) {
      $ext = $f.Extension.ToLowerInvariant()
      if ($ext -eq '.rtbw' -or $ext -eq '.rtbz') { continue }
      try {
        Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop
        $n = $n + 1
        Write-Log ('CLEANUP removed orphan: ' + $f.Name)
      } catch {
        Write-Log ('CLEANUP failed to remove orphan: ' + $f.Name)
      }
    }
  }
  if ($n -eq 0) { Write-Log 'CLEANUP no orphan files' }
  Write-Log ('CLEANUP total orphans removed: {0}' -f $n)
}

function Invoke-Preflight {
  Write-Log 'PREFLIGHT powercfg /query SCHEME_CURRENT SUB_SLEEP | Select-String ''Power Setting State'''
  $ps1 = $null
  try { $ps1 = powercfg /query SCHEME_CURRENT SUB_SLEEP 2>$null | Select-String 'Power Setting State' } catch { }
  if ($ps1) {
    foreach ($l in $ps1) { Write-Log ('PREFLIGHT ' + $l.ToString().Trim()) }
  } else {
    Write-Log 'PREFLIGHT note: no line matching ''Power Setting State'' in powercfg output (localized build); showing Current AC/DC Power Setting Index values'
  }
  $curName = ''
  $sleepVal = ''
  foreach ($l in (powercfg /query SCHEME_CURRENT SUB_SLEEP 2>$null)) {
    $s = [string]$l
    $g = $s -match 'Power Setting GUID:\s+\S+\s+\(([^)]*)\)'
    if ($g) { $curName = $Matches[1]; continue }
    $i = $s -match 'Current AC Power Setting Index:\s+(\S+)'
    if ($i -and ($curName -ne '')) {
      $val = $Matches[1]
      Write-Log ('PREFLIGHT ' + $curName + ' = ' + $val)
      if (($curName -like 'Sleep after*') -and ($sleepVal -eq '')) { $sleepVal = $val }
    }
  }
  $sleepOff = ($sleepVal -eq '0x00000000') -or ($sleepVal.ToLowerInvariant() -eq '0xffffffff')
  if (($sleepVal -ne '') -and (-not $sleepOff)) {
    Write-Warning ('PREFLIGHT: sleep setting value is ' + $sleepVal + ' (0x00000000 or 0xffffffff = disabled). The machine may sleep during a long 6pc run. Non-blocking warning.')
  } elseif ($sleepVal -eq '') {
    Write-Log 'PREFLIGHT note: no sleep value parsed from powercfg output'
  } else {
    Write-Log ('PREFLIGHT sleep disabled (' + $sleepVal + '): OK')
  }
  Write-Log 'PREFLIGHT bcdedit /enum {current} | Select-String ''bootstatuspolicy'''
  $bs = $null
  try { $bs = bcdedit /enum {current} 2>$null | Select-String 'bootstatuspolicy' } catch { }
  if ($bs) {
    foreach ($l in $bs) { Write-Log ('PREFLIGHT ' + $l.ToString().Trim()) }
  } else {
    Write-Warning 'PREFLIGHT: bootstatuspolicy not found (auto-restart on failure not set, or bcdedit output unavailable in this session). Non-blocking warning.'
  }
}

# --- main ---

if ($List -eq '' -and -not (Test-Path $ListFile)) { throw ('Table list file not found: ' + $ListFile) }
if ($BatchSize -lt 1) { throw 'BatchSize must be >= 1' }
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
if (-not $DryRun.IsPresent -and -not (Test-Path $Tbcheck)) { throw ('tbcheck not found: ' + $Tbcheck) }
if (-not $DryRun.IsPresent -and -not (Test-Path $Benchmark)) { throw ('benchmark script not found: ' + $Benchmark) }

$srcTag = '-List'
if ($List -eq '') { $srcTag = $ListFile }
$tables = @(Read-TableList)
if ($tables.Count -eq 0) { throw 'No tables found in source' }

Invoke-Preflight

$StatusCsv = Join-Path $OutDir '6pc.status.csv'
$state = Read-StatusCsv $StatusCsv
# NOTE: explicit loop, not Where-Object with 'Test-IsDone $state[$_] -eq $false': in command form the
# '-eq $false' tail would be swallowed as extra arguments ($args), silently inverting the test.
$remaining = @()
foreach ($t in $tables) {
  if ($state.ContainsKey($t) -and (Test-IsDone $state[$t])) { continue }
  $remaining = $remaining + @($t)
}

Write-Log ('START source={0} total={1} remaining={2} OutDir={3} RtbPath={4} Threads={5} BatchSize={6} Keep={7} DryRun={8}' -f $srcTag, $tables.Count, $remaining.Count, $OutDir, $RtbPath, $Threads, $BatchSize, $Keep.IsPresent, $DryRun.IsPresent)
Write-Log ('NOTE RefDir sentinel NONE passed to tb_benchmark.ps1 (parameter is Mandatory); byte-identical reference check is done here against ' + $RefWdlDir + ' and ' + $RefDtzDir)

if ($DryRun) {
  Write-Log ('DRYRUN source={0} total={1} remaining={2} OutDir={3} (no generation, no cleanup, no deletion)' -f $srcTag, $tables.Count, $remaining.Count, $OutDir)
  foreach ($t in $remaining) { Write-Host $t }
  Write-Log ('DRYRUN done: {0} remaining' -f $remaining.Count)
  exit 0
}
if ($List -ne '') {
  foreach ($t in $remaining) { Write-Host $t }
  exit 0
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# Phase 1: re-validate existing tbcheck-ok files without regenerating; everything else goes to the queue.
$genQueue = New-Object System.Collections.Generic.List[string]
foreach ($t in $remaining) {
  $w = Join-Path $OutDir ($t + '.rtbw')
  $z = Join-Path $OutDir ($t + '.rtbz')
  if ((Test-Path $w) -and (Test-Path $z)) {
    $r = Validate-Table $t $OutDir @{ wdl = $RefWdlDir; dtz = $RefDtzDir }
    $state[$t] = @{ statut = $r.statut; essais = 0; erreur = $r.erreur; sha_wdl = $r.sha_wdl; sha_dtz = $r.sha_dtz }
    if (-not (Test-IsDone $r)) { $genQueue.Add($t) }
  } else {
    $state[$t] = @{ statut = 'absent'; essais = 0; erreur = 'not present in OutDir'; sha_wdl = ''; sha_dtz = '' }
    $genQueue.Add($t)
  }
  Save-StatusCsv $state $StatusCsv
}
Write-Log ('PHASE1 remaining={0} revalidated-kept={1} queue={2}' -f $remaining.Count, ($remaining.Count - $genQueue.Count), $genQueue.Count)

$attempts = @{}
foreach ($t in $tables) { $attempts[$t] = 0 }

$batchNo = 0
while ($genQueue.Count -gt 0) {
  $pending = @($genQueue | Where-Object { [int]$attempts[$_] -lt $MaxAttempts })
  if ($pending.Count -eq 0) { break }
  $n = [Math]::Min($BatchSize, $pending.Count)
  $batch = @($pending[0..($n - 1)])
  $batchNo = $batchNo + 1
  $batchStr = $batch -join ' '
  Write-Log ('BATCH {0}: {1} tables [{2}]' -f $batchNo, $batch.Count, $batchStr)
  Invoke-OrphanCleanup $OutDir
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $argStr = ('-NoProfile -ExecutionPolicy Bypass -File "{0}" -Set 6pc -Tables "{1}" -OutDir "{2}" -RtbPath "{3}" -Threads {4} -RefDir NONE' -f $Benchmark, $batchStr, $OutDir, $RtbPath, $Threads)
  $proc = Start-Process -FilePath 'powershell.exe' -ArgumentList $argStr -WorkingDirectory $Root -NoNewWindow -Wait -PassThru
  $sw.Stop()
  $code = $proc.ExitCode
  $dur = [math]::Round($sw.Elapsed.TotalSeconds, 1)
  Write-Log ('BATCH {0}: exit={1} dur={2}s' -f $batchNo, $code, $dur)
  $retry = @()
  foreach ($t in $batch) {
    $r = Validate-Table $t $OutDir @{ wdl = $RefWdlDir; dtz = $RefDtzDir }
    $attempts[$t] = [int]$attempts[$t] + 1
    $essais = [int]$attempts[$t]
    if (Test-IsDone $r) {
      $state[$t] = @{ statut = $r.statut; essais = $essais; erreur = $r.erreur; sha_wdl = $r.sha_wdl; sha_dtz = $r.sha_dtz }
    } else {
      if ($essais -lt $MaxAttempts) {
        $retry += $t
        $state[$t] = @{ statut = $r.statut; essais = $essais; erreur = ('attempt {0} failed, retrying: ' -f $essais) + $r.erreur; sha_wdl = $r.sha_wdl; sha_dtz = $r.sha_dtz }
      } else {
        $state[$t] = @{ statut = 'echec'; essais = $essais; erreur = ('failed after {0} attempts, last: ' -f $essais) + $r.erreur; sha_wdl = $r.sha_wdl; sha_dtz = $r.sha_dtz }
      }
    }
    Save-StatusCsv $state $StatusCsv
  }
  $genQueue = [System.Collections.Generic.List[string]]($retry)
}

$c = @{ ok_identique = 0; diff_garde = 0; absent_ref = 0; ref_unavailable = 0; echec = 0; absent = 0 }
foreach ($t in $tables) {
  $s = [string]$state[$t].statut
  if ($c.ContainsKey($s)) { $c[$s] = [int]$c[$s] + 1 }
}
$done = 0
foreach ($t in $tables) {
  if ($state.ContainsKey($t) -and (Test-IsDone $state[$t])) { $done = $done + 1 }
}
Write-Log ('DONE done={0}/{1} ok_identique={2} diff_garde={3} absent_ref={4} ref_unavailable={5} echec={6} absent={7} batches={8}' -f $done, $tables.Count, $c.ok_identique, $c.diff_garde, $c.absent_ref, $c.ref_unavailable, $c.echec, $c.absent, $batchNo)
Write-Host ('Status CSV: ' + $StatusCsv)
if ($done -lt $tables.Count) { exit 1 }
exit 0
