#Requires -Version 5.1
<#
.SYNOPSIS
  Validate every Syzygy table on disk against official CityHash checksum lists
  (checksums/wdl*.txt + dtz*.txt) and optionally full-content tbcheck.

.DESCRIPTION
  Phase 1 (default, fast): read the 16-byte embedded CityHash at end of each
  .rtbw/.rtbz and compare to the official lists shipped with this repo.
  Phase 2 (-FullVerify): run tbcheck (recompute CityHash over whole file) for
  integrity / bitrot detection. Very slow on multi-TB collections.

.EXAMPLE
  .\Verify-Syzygy-OfficialHashes.ps1
  .\Verify-Syzygy-OfficialHashes.ps1 -Root T:\Syzygy -FullVerify -Threads 4
#>
[CmdletBinding()]
param(
    [string]$Root = 'T:\Syzygy',
    [string]$ChecksumDir = '',
    [string]$Tbcheck = '',
    [string]$LogDir = '',
    [switch]$FullVerify,
    [int]$Threads = 1,
    [int]$FullVerifyMaxFiles = 0  # 0 = all
)

$ErrorActionPreference = 'Stop'
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $ChecksumDir) { $ChecksumDir = Join-Path $ScriptDir 'checksums' }
if (-not $Tbcheck) { $Tbcheck = Join-Path $ScriptDir 'bin\tbcheck.exe' }
if (-not $LogDir) { $LogDir = Join-Path $ScriptDir 'logs' }

if (-not (Test-Path -LiteralPath $Root)) { throw "Root not found: $Root" }
if (-not (Test-Path -LiteralPath $ChecksumDir)) { throw "ChecksumDir not found: $ChecksumDir" }
if (-not (Test-Path -LiteralPath $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$reportCsv = Join-Path $LogDir "syzygy-hash-verify-$stamp.csv"
$reportTxt = Join-Path $LogDir "syzygy-hash-verify-$stamp.txt"
$failList  = Join-Path $LogDir "syzygy-hash-FAIL-$stamp.txt"

function Get-EmbeddedCityHash {
    param([string]$Path)
    $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    try {
        $len = $fs.Length
        if ($len -lt 16) { return $null }
        # Official Syzygy: file size ≡ 16 (mod 64); CityHash trailer is the last 16 bytes.
        if (($len -band 0x3f) -ne 0x10) { return $null }
        $null = $fs.Seek($len - 16, [System.IO.SeekOrigin]::Begin)
        $buf = New-Object byte[] 16
        $read = $fs.Read($buf, 0, 16)
        if ($read -ne 16) { return $null }
        -join ($buf | ForEach-Object { $_.ToString('x2') })
    } finally {
        $fs.Dispose()
    }
}

function Write-Log {
    param([string]$Line, [ConsoleColor]$Color = 'Gray')
    Write-Host $Line -ForegroundColor $Color
    Add-Content -LiteralPath $reportTxt -Value $Line
}

# --- Load official checksums ---
$official = @{}
$chkFiles = @('wdl345.txt','wdl6.txt','wdl7.txt','dtz345.txt','dtz6.txt','dtz7.txt')
foreach ($f in $chkFiles) {
    $p = Join-Path $ChecksumDir $f
    if (-not (Test-Path -LiteralPath $p)) { throw "Missing checksum file: $p" }
    Get-Content -LiteralPath $p | ForEach-Object {
        if ($_ -match '^([^:]+):\s*([0-9a-fA-F]{32})\s*$') {
            $official[$matches[1]] = $matches[2].ToLowerInvariant()
        }
    }
}

Write-Log "=== Syzygy official hash verification ===" 'Cyan'
Write-Log "Started : $(Get-Date -Format o)"
Write-Log "Root    : $Root"
Write-Log "Official entries loaded: $($official.Count)"
Write-Log ""

# --- Enumerate tables ---
$files = @(Get-ChildItem -LiteralPath $Root -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Extension -in '.rtbw','.rtbz' -and
        $_.FullName -notmatch '\\(agent-tools|terminals|logs)\\'
    })

Write-Log "Files found: $($files.Count)"
Write-Log "Phase 1: embedded CityHash vs official lists (fast)..."
Write-Log ""

$results = New-Object System.Collections.Generic.List[object]
$stats = [ordered]@{
    MATCH          = 0
    MISMATCH       = 0
    NO_EMBEDDED    = 0
    NO_OFFICIAL    = 0
    OFFICIAL_MISSING_ON_DISK = 0
    FULL_OK        = 0
    FULL_FAIL      = 0
    FULL_SKIP      = 0
}

$i = 0
foreach ($file in $files) {
    $i++
    if (($i % 200) -eq 0) {
        Write-Host ("  ... {0}/{1}" -f $i, $files.Count) -ForegroundColor DarkGray
    }

    $name = $file.Name
    $emb = Get-EmbeddedCityHash -Path $file.FullName
    $off = $null
    if ($official.ContainsKey($name)) { $off = $official[$name] }

    if (-not $emb) {
        $status = 'NO_EMBEDDED'
    } elseif (-not $off) {
        $status = 'NO_OFFICIAL'   # present on disk, not in reference lists (bonus/flip)
    } elseif ($emb -eq $off) {
        $status = 'MATCH'
    } else {
        $status = 'MISMATCH'
    }
    $stats[$status]++

    $results.Add([PSCustomObject]@{
        Name           = $name
        Path           = $file.FullName
        SizeMB         = [math]::Round($file.Length / 1MB, 2)
        EmbeddedHash   = $emb
        OfficialHash   = $off
        OfficialStatus = $status
        FullVerify     = ''
    }) | Out-Null
}

# Official entries not found on disk
$onDiskNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($f in $files) { [void]$onDiskNames.Add($f.Name) }
$missingOfficial = @($official.Keys | Where-Object { -not $onDiskNames.Contains($_) } | Sort-Object)
$stats['OFFICIAL_MISSING_ON_DISK'] = $missingOfficial.Count

Write-Log ""
Write-Log "=== Phase 1 results (official lists) ===" 'Cyan'
Write-Log ("  MATCH (embedded == official) : {0}" -f $stats.MATCH) $(if ($stats.MATCH -gt 0) { 'Green' } else { 'Gray' })
Write-Log ("  MISMATCH                     : {0}" -f $stats.MISMATCH) $(if ($stats.MISMATCH -gt 0) { 'Red' } else { 'Green' })
Write-Log ("  NO_EMBEDDED (bad format)     : {0}" -f $stats.NO_EMBEDDED) $(if ($stats.NO_EMBEDDED -gt 0) { 'Red' } else { 'Green' })
Write-Log ("  NO_OFFICIAL (bonus on disk)  : {0}" -f $stats.NO_OFFICIAL) 'Yellow'
Write-Log ("  Official listed but missing  : {0}" -f $stats.OFFICIAL_MISSING_ON_DISK) $(if ($stats.OFFICIAL_MISSING_ON_DISK -gt 0) { 'Yellow' } else { 'Green' })

if ($stats.MISMATCH -gt 0) {
    Write-Log ""
    Write-Log "MISMATCH files:" 'Red'
    $results | Where-Object OfficialStatus -eq 'MISMATCH' | ForEach-Object {
        Write-Log ("  {0}" -f $_.Name) 'Red'
        Write-Log ("    emb={0}" -f $_.EmbeddedHash)
        Write-Log ("    off={0}" -f $_.OfficialHash)
        Write-Log ("    path={0}" -f $_.Path)
    }
}

if ($missingOfficial.Count -gt 0 -and $missingOfficial.Count -le 50) {
    Write-Log ""
    Write-Log "Official entries not on disk:" 'Yellow'
    $missingOfficial | ForEach-Object { Write-Log "  $_" }
} elseif ($missingOfficial.Count -gt 50) {
    Write-Log ""
    Write-Log ("Official entries not on disk: {0} (see CSV / fail list)" -f $missingOfficial.Count) 'Yellow'
}

# --- Phase 2: full content verify ---
if ($FullVerify) {
    if (-not (Test-Path -LiteralPath $Tbcheck)) {
        throw "tbcheck not found: $Tbcheck"
    }
    Write-Log ""
    Write-Log "=== Phase 2: full tbcheck (recompute CityHash) ===" 'Cyan'
    Write-Log "This validates content integrity (bitrot), not only the trailer hash."
    Write-Log "Threads: $Threads"

    $toCheck = $results
    if ($FullVerifyMaxFiles -gt 0) {
        $toCheck = $results | Select-Object -First $FullVerifyMaxFiles
        Write-Log "Limited to first $FullVerifyMaxFiles files"
    }

    $j = 0
    foreach ($r in $toCheck) {
        $j++
        if (($j % 25) -eq 0 -or $j -eq 1) {
            Write-Host ("  full-verify {0}/{1}: {2} ({3} MB)" -f $j, $toCheck.Count, $r.Name, $r.SizeMB) -ForegroundColor DarkCyan
        }
        $out = & $Tbcheck -t $Threads $r.Path 2>&1 | Out-String
        if ($out -match 'OK!') {
            $r.FullVerify = 'OK'
            $stats.FULL_OK++
        } else {
            $r.FullVerify = 'FAIL'
            $stats.FULL_FAIL++
            Write-Log ("  FULL FAIL: {0} :: {1}" -f $r.Name, ($out.Trim() -replace '\s+',' ')) 'Red'
        }
    }
    $stats.FULL_SKIP = $results.Count - $toCheck.Count
    Write-Log ("Full OK  : {0}" -f $stats.FULL_OK) 'Green'
    Write-Log ("Full FAIL: {0}" -f $stats.FULL_FAIL) $(if ($stats.FULL_FAIL -gt 0) { 'Red' } else { 'Green' })
} else {
    Write-Log ""
    Write-Log "Phase 2 skipped (pass -FullVerify to recompute CityHash on every file)." 'DarkGray'
    Write-Log "Note: Phase 1 confirms authenticity vs official lists (embedded hash)."
    Write-Log "      Phase 2 would detect mid-file corruption if trailer was left intact."
}

# --- Export ---
$results | Export-Csv -LiteralPath $reportCsv -NoTypeInformation -Encoding UTF8

$failLines = @()
$failLines += $results | Where-Object OfficialStatus -in 'MISMATCH','NO_EMBEDDED' | ForEach-Object { "$($_.OfficialStatus) $($_.Path)" }
$failLines += $missingOfficial | ForEach-Object { "OFFICIAL_MISSING_ON_DISK $_" }
if ($FullVerify) {
    $failLines += $results | Where-Object FullVerify -eq 'FAIL' | ForEach-Object { "FULL_FAIL $($_.Path)" }
}
if ($failLines.Count -gt 0) {
    $failLines | Set-Content -LiteralPath $failList -Encoding UTF8
} else {
    "NONE" | Set-Content -LiteralPath $failList -Encoding UTF8
}

Write-Log ""
Write-Log "CSV report : $reportCsv"
Write-Log "Text report: $reportTxt"
Write-Log "Fail list  : $failList"
Write-Log "Finished   : $(Get-Date -Format o)"
Write-Log ""

$allGood = ($stats.MISMATCH -eq 0) -and ($stats.NO_EMBEDDED -eq 0) -and ($stats.FULL_FAIL -eq 0)
if ($allGood) {
    Write-Log "OVERALL: PASS (all files with official entries match; no full-verify failures)" 'Green'
    exit 0
} else {
    Write-Log "OVERALL: ISSUES DETECTED - see fail list" 'Red'
    exit 1
}
