# Verify-Syzygy.ps1
# Verifies the Syzygy depot against C:\Programmation\tb-1\verification\expected-manifest.csv.
# Modes: Presence (fast), Hash (MD5, resumable), Full (both), Report (local summary only).
# Read-only on $Root (T:\Syzygy). All writes under C:\Programmation\tb-1\verification\.
# PowerShell 5.1 compatible: no ??, no ?., no ForEach-Object -Parallel
# (parallelism via System.Threading.Tasks.Parallel.For).
# Exit codes: 0 = OK, 1 = missing/wrong-folder/mismatch, 2 = pending remain (Hash).

param(
    [string]$Root = 'T:\Syzygy',
    [ValidateSet('Presence', 'Hash', 'Full', 'Report')][string]$Mode = 'Presence',
    [int]$Parallel = 4,
    [string]$StateFile = 'C:\Programmation\tb-1\verification\hash-state.csv',
    [string]$Manifest = 'C:\Programmation\tb-1\verification\expected-manifest.csv',
    [string]$ReportsDir = 'C:\Programmation\tb-1\verification\reports',
    [string]$Only = '',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Get-Md5Hex([string]$Path) {
    $md5 = [System.Security.Cryptography.MD5]::Create()
    try {
        $fs = [System.IO.File]::OpenRead($Path)
        try {
            $buf = New-Object byte[] 1MB
            while (($n = $fs.Read($buf, 0, $buf.Length)) -gt 0) { [void]$md5.TransformBlock($buf, 0, $n, $null, 0) }
            [void]$md5.TransformFinalBlock([byte[]]::Empty, 0, 0)
        } finally { $fs.Dispose() }
        $h = $md5.Hash
        $sb = New-Object System.Text.StringBuilder
        foreach ($b in $h) { [void]$sb.Append($b.ToString('x2')) }
        return $sb.ToString()
    } finally { $md5.Dispose() }
}

# --- common -----------------------------------------------------------------
if (-not (Test-Path -LiteralPath $Manifest)) {
    Write-Host "ERROR: manifest not found: $Manifest (run Build-Manifest.ps1 first)"
    exit 1
}
$rows = @((Import-Csv -LiteralPath $Manifest -Delimiter ';'))
if ($Only) { $rows = @($rows | Where-Object { $_.name -like $Only }) }
$total = $rows.Count
New-Item -ItemType Directory -Force -Path $ReportsDir | Out-Null

$script:stateRows = $null

function Get-StateLines {
    $ls = New-Object System.Collections.Generic.List[string]
    $ls.Add('name;expected_md5;actual_md5;status;verified_at')
    foreach ($e in $script:stateRows) {
        $ls.Add(('{0};{1};{2};{3};{4}' -f $e.name, $e.expected_md5, $e.actual_md5, $e.status, $e.verified_at))
    }
    return $ls
}

function Save-State {
    $tmp = $StateFile + '.tmp'
    [System.IO.File]::WriteAllLines($tmp, (Get-StateLines), [System.Text.Encoding]::ASCII)
    Move-Item -LiteralPath $tmp -Destination $StateFile -Force
}

# --- Presence ----------------------------------------------------------------
function Invoke-Presence {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $found = [System.Collections.Hashtable]::new([System.StringComparer]::OrdinalIgnoreCase)
    $scanned = New-Object System.Collections.Generic.List[string]
    $locations = @('', '3-4-5', '6-WDL', '6-DTZ', '7-WDL', '7-DTZ')
    foreach ($loc in $locations) {
        if ($loc -eq '') { $dir = $Root } else { $dir = Join-Path $Root $loc }
        if (-not (Test-Path -LiteralPath $dir -PathType Container)) { continue }
        foreach ($f in @(Get-ChildItem -LiteralPath $dir -File)) {
            if (-not $found.ContainsKey($f.Name)) {
                $found[$f.Name] = $loc
                $scanned.Add($f.Name)
            }
        }
    }
    $manifestNames = [System.Collections.Hashtable]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($r in $rows) { $manifestNames[$r.name] = $true }
    $present = 0; $missing = 0; $wrong = 0
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('name;expected_folder;actual_folder;status')
    foreach ($r in $rows) {
        if (-not $found.Contains($r.name)) {
            $status = 'MISSING'; $actual = ''; $missing++
        } elseif ($found[$r.name] -eq $r.expected_folder) {
            $status = 'PRESENT'; $actual = $found[$r.name]; $present++
        } else {
            $status = 'WRONG_FOLDER'; $actual = $found[$r.name]; $wrong++
        }
        $lines.Add(("{0};{1};{2};{3}" -f $r.name, $r.expected_folder, $actual, $status))
    }
    $extra = 0
    foreach ($n in $scanned) {
        $ln = $n.ToLowerInvariant()
        if (($ln.EndsWith('.rtbw') -or $ln.EndsWith('.rtbz')) -and -not $manifestNames.Contains($n)) {
            $extra++
            $loc = $found[$n]
            if ($loc -eq '') {
                Write-Host ("WARN extra file (not in manifest): " + $n + " (root)")
            } else {
                Write-Host ("WARN extra file (not in manifest): " + $loc + "\" + $n)
            }
        }
    }
    $report = Join-Path $ReportsDir ($stamp + '-presence.csv')
    [System.IO.File]::WriteAllLines($report, $lines, [System.Text.Encoding]::ASCII)
    Write-Host ("PRESENCE present={0}/{1} missing={2} wrong_folder={3} extra={4}" -f $present, $total, $missing, $wrong, $extra)
    if ($missing -eq 0 -and $wrong -eq 0) { return 0 }
    return 1
}

# --- Hash ---------------------------------------------------------------------
function Invoke-Hash {
    $script:stateRows = New-Object System.Collections.Generic.List[object]
    $prevState = [System.Collections.Hashtable]::new([System.StringComparer]::OrdinalIgnoreCase)
    if (Test-Path -LiteralPath $StateFile) {
        foreach ($r in @((Import-Csv -LiteralPath $StateFile -Delimiter ';'))) {
            if ($r.name) { $prevState[$r.name] = $r }
        }
    }
    $pending = New-Object System.Collections.Generic.List[int]
    for ($i = 0; $i -lt $rows.Count; $i++) {
        $r = $rows[$i]
        $prev = $null
        if ($prevState.ContainsKey($r.name)) { $prev = $prevState[$r.name] }
        $keep = ($null -ne $prev) -and ($prev.status -eq 'OK') -and (-not $Force)
        $script:stateRows.Add([ordered]@{
            name         = $r.name
            expected_md5 = $r.expected_md5
            actual_md5   = $(if ($keep) { $prev.actual_md5 } else { '' })
            status       = $(if ($keep) { 'OK' } else { 'PENDING' })
            verified_at  = $(if ($keep) { $prev.verified_at } else { '' })
        })
        if (-not $keep) { $pending.Add($i) }
    }
    # remaining volume (sizes of pending files), measured at the start of the phase
    $totalBytes = [long]0
    foreach ($i in $pending) {
        $p = Join-Path $Root ($rows[$i].expected_folder + '\' + $rows[$i].name)
        $item = Get-Item -LiteralPath $p -ErrorAction SilentlyContinue
        if ($item) { $totalBytes += [long]$item.Length }
    }
    $bytesDone = [long]0
    $phaseStart = Get-Date
    $chunkSize = 50
    for ($start = 0; $start -lt $pending.Count; $start += $chunkSize) {
        $end = [Math]::Min($start + $chunkSize, $pending.Count)
        $count = $end - $start
        $chunkIdx = New-Object int[] $count
        for ($k = 0; $k -lt $count; $k++) { $chunkIdx[$k] = $pending[$start + $k] }
        $results = New-Object object[] $count
        $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $body = {
            param($i)
            $idx = $chunkIdx[$i]
            $row = $rows[$idx]
            $p = Join-Path $Root ($row.expected_folder + '\' + $row.name)
            $item = Get-Item -LiteralPath $p -ErrorAction SilentlyContinue
            if (-not $item) {
                $results[$i] = @{ actual_md5 = 'MISSING'; status = 'MISMATCH'; size = [long]0 }
                return
            }
            $h = Get-Md5Hex -Path $p
            if ($h -eq $row.expected_md5) { $st = 'OK' } else { $st = 'MISMATCH' }
            $results[$i] = @{ actual_md5 = $h; status = $st; size = [long]$item.Length }
        }
        $action = [System.Action[int]]$body
        $options = New-Object System.Threading.Tasks.ParallelOptions
        $options.MaxDegreeOfParallelism = $Parallel
        [System.Threading.Tasks.Parallel]::For(0, $count, $options, $action)
        for ($k = 0; $k -lt $count; $k++) {
            $idx = $chunkIdx[$k]
            $res = $results[$k]
            $script:stateRows[$idx].actual_md5 = $res.actual_md5
            $script:stateRows[$idx].status = $res.status
            $script:stateRows[$idx].verified_at = $stamp
            $bytesDone += [long]$res.size
        }
        # atomic state rewrite + progress line
        Save-State
        $ok = 0; $mismatch = 0; $pendingLeft = 0
        foreach ($e in $script:stateRows) {
            if ($e.status -eq 'OK') { $ok++ }
            elseif ($e.status -eq 'MISMATCH') { $mismatch++ }
            else { $pendingLeft++ }
        }
        $done = $ok + $mismatch
        $elapsed = ((Get-Date) - $phaseStart).TotalSeconds
        $rate = 0.0
        if ($elapsed -gt 0) { $rate = $bytesDone / $elapsed / 1MB }
        $remain = $totalBytes - $bytesDone
        if ($remain -lt 0) { $remain = 0 }
        if ($rate -gt 0) {
            $etaSec = [int]($remain / ($rate * 1MB))
            $eta = ('{0:D2}:{1:D2}' -f [Math]::Floor($etaSec / 3600), [Math]::Floor(($etaSec % 3600) / 60))
        } else {
            $eta = '--:--'
        }
        Write-Host ("HASH done={0} total={1} ok={2} mismatch={3} pending={4} rate={5:F1}MiB/s eta={6}" -f $done, $total, $ok, $mismatch, $pendingLeft, $rate, $eta)
    }
    # final state + snapshot report
    Save-State
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $report = Join-Path $ReportsDir ($stamp + '-hash.csv')
    [System.IO.File]::WriteAllLines($report, (Get-StateLines), [System.Text.Encoding]::ASCII)
    $ok = 0; $mismatch = 0; $pendingLeft = 0
    foreach ($e in $script:stateRows) {
        if ($e.status -eq 'OK') { $ok++ }
        elseif ($e.status -eq 'MISMATCH') { $mismatch++ }
        else { $pendingLeft++ }
    }
    if ($pendingLeft -gt 0) { return 2 }
    if ($mismatch -gt 0) { return 1 }
    return 0
}

# --- Report (local only, no access to $Root) ---------------------------------
function Invoke-Report {
    Write-Host '=== hash state ==='
    Write-Host ("file: {0}" -f $StateFile)
    if (Test-Path -LiteralPath $StateFile) {
        $s = @((Import-Csv -LiteralPath $StateFile -Delimiter ';'))
        $ok = @($s | Where-Object { $_.status -eq 'OK' }).Count
        $mismatch = @($s | Where-Object { $_.status -eq 'MISMATCH' }).Count
        $pending = @($s | Where-Object { $_.status -eq 'PENDING' }).Count
        $last = ''
        foreach ($r in $s) { if ($r.verified_at -and $r.verified_at -gt $last) { $last = $r.verified_at } }
        Write-Host ("rows={0} ok={1} mismatch={2} pending={3} last_verified_at={4}" -f $s.Count, $ok, $mismatch, $pending, $last)
    } else {
        Write-Host 'no state file yet (no hash run so far)'
    }
    Write-Host '=== last presence report ==='
    $rep = $null
    if (Test-Path -LiteralPath $ReportsDir) {
        $cand = @(Get-ChildItem -LiteralPath $ReportsDir -Filter '*-presence.csv' -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
        if ($cand.Count -gt 0) { $rep = $cand[0] }
    }
    if ($rep) {
        $p = @((Import-Csv -LiteralPath $rep.FullName -Delimiter ';'))
        $present = @($p | Where-Object { $_.status -eq 'PRESENT' }).Count
        $missing = @($p | Where-Object { $_.status -eq 'MISSING' }).Count
        $wrong = @($p | Where-Object { $_.status -eq 'WRONG_FOLDER' }).Count
        Write-Host ("file: {0}" -f $rep.FullName)
        Write-Host ("present={0} missing={1} wrong_folder={2} (of {3} rows)" -f $present, $missing, $wrong, $p.Count)
    } else {
        Write-Host 'no presence report yet'
    }
    return 0
}

# --- dispatch ------------------------------------------------------------------
switch ($Mode) {
    'Presence' { exit (Invoke-Presence) }
    'Hash'     { exit (Invoke-Hash) }
    'Full' {
        $p = Invoke-Presence
        $h = Invoke-Hash
        if ($p -ge $h) { exit $p } else { exit $h }
    }
    'Report'   { exit (Invoke-Report) }
}
