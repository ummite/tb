<# 
.SYNOPSIS
    Priority consolidation of all Syzygy tables to T:\Syzygy (Master Plan Phase 3).

.DESCRIPTION
    This is the production-grade script for the current phase:
    - Prioritizes the richest remaining sources first:
        1. A:\Syzygy_A_Trier_FromOld_Ryzen7950  (historical 6/7pc DTZ goldmine)
        2. Other A: and S: splits (5v2_pawnful, 6v1_*, 4v3_pawnless_ManyMissing, etc.)
    - Uses robocopy for resumable network copies (cross-NAS from ds1821 <-> ds1817).
    - Proper deduplication (filename + size).
    - Excellent logging and progress.
    - Safe WhatIf + MaxFiles / MaxGB limits for phased execution.

    After plots are gone and T: has space, run this repeatedly until T:\Syzygy contains everything.

.EXAMPLE
    # 1. Always start with simulation
    .\Syzygy-Priority-Consolidate.ps1 -WhatIf -ReportOnly

    # 2. First real pass: high-value DTZ from A: only, limited size
    .\Syzygy-Priority-Consolidate.ps1 -SourceFilter "*A_Trier*" -MaxGB 2000 -Threads 12

    # 3. Later passes for the rest
    .\Syzygy-Priority-Consolidate.ps1 -MaxFiles 300
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$Destination = "T:\Syzygy",
    [string[]]$SourceFilter,           # e.g. "*A_Trier*", "*5v2_pawnful*"
    [double]$MaxGB = 0,                # Safety: stop after copying this many GB this run
    [int]$MaxFiles = 0,
    [int]$Threads = 12,
    [switch]$ReportOnly,               # Just show the plan + counts, no robocopy
    [switch]$Flatten                   # Copy everything flat into $Destination (instead of preserving subdirs)
)

$ErrorActionPreference = "Continue"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logDir = Join-Path $ScriptRoot "logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = Join-Path $logDir "Syzygy-Priority-Consolidate_$timestamp.log"

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $line = "[$(Get-Date -Format 'HH:mm:ss')] $Message"
    Add-Content -Path $logFile -Value $line -Encoding UTF8
    Write-Host $line -ForegroundColor $Color
}

Write-Host "╔════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║   SYZYGY PRIORITY CONSOLIDATE  →  T:\Syzygy (Master Repository Phase 3)   ║" -ForegroundColor Magenta
Write-Host "╚════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# ==================== SOURCE DEFINITION WITH PRIORITY ====================
$allSources = @(
    @{ Priority=1; Label="A_Historical_6_7pc_DTZ"; Path="A:\Syzygy_A_Trier_FromOld_Ryzen7950" },
    @{ Priority=2; Label="A_Syzygy";               Path="A:\Syzygy" },
    @{ Priority=3; Label="S_5v2_pawnful";          Path="S:\5v2_pawnful" },
    @{ Priority=4; Label="S_6v1_pawnful";          Path="S:\6v1_pawnful" },
    @{ Priority=5; Label="S_4v3_pawnless_ManyMissing"; Path="S:\4v3_pawnless_ManyMissing" },
    @{ Priority=6; Label="S_5v2_pawnless";         Path="S:\5v2_pawnless" },
    @{ Priority=7; Label="S_6v1_pawnless";         Path="S:\6v1_pawnless" },
    @{ Priority=8; Label="S_Syzygy_3-6men";        Path="S:\Syzygy" },
    @{ Priority=9; Label="Local_Syzygy";           Path=(Join-Path $ScriptRoot "Syzygy") },
    @{ Priority=10; Label="T_Syzygy_itself";       Path="T:\Syzygy" }
)

$sources = $allSources | Where-Object { Test-Path $_.Path }

if ($SourceFilter) {
    $sources = $sources | Where-Object {
        $match = $false
        foreach ($f in $SourceFilter) { if ($_.Label -like $f -or $_.Path -like $f) { $match = $true } }
        $match
    }
}

$sources = $sources | Sort-Object Priority

Write-Host "Active sources (priority order):" -ForegroundColor Green
$sources | ForEach-Object { Write-Host ("  [{0}] {1}" -f $_.Priority, $_.Label) }

# ==================== INVENTORY + DEDUP ====================
Write-Log "Starting inventory..." "Cyan"

$inventory = @()
$seen = @{}

foreach ($src in $sources) {
    Write-Host "  Scanning $($src.Label) ..." -ForegroundColor DarkGray
    $files = Get-ChildItem -Path $src.Path -Recurse -File -Include *.rtbw,*.rtbz -ErrorAction SilentlyContinue
    foreach ($f in $files) {
        $key = $f.Name
        if ($seen.ContainsKey($key)) {
            # Keep the first (highest priority source wins)
            continue
        }
        $seen[$key] = $true
        $inventory += [pscustomobject]@{
            Name      = $f.Name
            SizeGB    = [math]::Round($f.Length / 1GB, 3)
            Source    = $src.Label
            FullPath  = $f.FullName
            IsDTZ     = $f.Name -like "*.rtbz"
            IsWDL     = $f.Name -like "*.rtbw"
        }
    }
}

# Filter to those not already on destination (simple name+size check)
$existing = @{}
if (Test-Path $Destination) {
    Get-ChildItem $Destination -Recurse -File -Include *.rtbw,*.rtbz -ErrorAction SilentlyContinue | ForEach-Object {
        $existing[$_.Name] = $_.Length
    }
}

$toCopy = $inventory | Where-Object {
    -not $existing.ContainsKey($_.Name) -or $existing[$_.Name] -ne (Get-Item $_.FullPath).Length
}

Write-Host ""
Write-Log ("Total unique candidates found : {0}" -f $inventory.Count) "Green"
Write-Log ("Already on T:\Syzygy (skipped): {0}" -f ($inventory.Count - $toCopy.Count)) "DarkGray"
Write-Log ("Need to copy this run         : {0}" -f $toCopy.Count) "Yellow"

# Breakdown
$wdl = ($toCopy | Where-Object IsWDL).Count
$dtz = ($toCopy | Where-Object IsDTZ).Count
Write-Host ("  WDL to copy : {0}" -f $wdl)
Write-Host ("  DTZ to copy : {0}" -f $dtz)

# ==================== REPORT ONLY MODE ====================
if ($ReportOnly) {
    Write-Host "`n=== TOP 30 HIGHEST VALUE TO COPY ===" -ForegroundColor Magenta
    $toCopy | Sort-Object SizeGB -Descending | Select-Object -First 30 | ForEach-Object {
        Write-Host ("  {0,8} GB  {1,-45}  [{2}]" -f $_.SizeGB, $_.Name, $_.Source)
    }
    Write-Host "`nRun without -ReportOnly to actually copy (use -WhatIf first!)." -ForegroundColor Cyan
    exit 0
}

# ==================== ACTUAL COPY PHASE ====================
if (-not (Test-Path $Destination)) {
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
}

$copiedGB = 0
$copiedCount = 0
$skipped = 0
$errors = 0

foreach ($item in ($toCopy | Sort-Object Source, SizeGB -Descending)) {   # big files first within priority
    if ($MaxFiles -gt 0 -and $copiedCount -ge $MaxFiles) { break }
    if ($MaxGB -gt 0 -and $copiedGB -ge $MaxGB) { break }

    $destPath = if ($Flatten) {
        Join-Path $Destination $item.Name
    } else {
        # Try to preserve some structure (e.g. keep 7men/ etc. if present in source path)
        $rel = $item.FullPath -replace "^[A-Z]:\\", ''
        Join-Path $Destination $rel
    }

    $destDir = Split-Path $destPath -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

    if ($PSCmdlet.ShouldProcess($item.Name, "Copy from $($item.Source)")) {
        Write-Log ("Copying {0} GB : {1}  ({2})" -f $item.SizeGB, $item.Name, $item.Source) "Gray"

        $robocopyArgs = @(
            (Split-Path $item.FullPath -Parent),
            (Split-Path $destPath -Parent),
            $item.Name,
            "/COPY:DAT", "/R:2", "/W:5", "/MT:$Threads", "/NFL", "/NDL"
        )

        $result = robocopy @robocopyArgs
        if ($LASTEXITCODE -lt 8) {
            $copiedCount++
            $copiedGB += $item.SizeGB
            Write-Log ("  OK - {0} GB copied so far" -f [math]::Round($copiedGB,1)) "Green"
        } else {
            $errors++
            Write-Log ("  FAILED (robocopy exit $LASTEXITCODE)") "Red"
        }
    } else {
        # WhatIf
        Write-Host "  [WHATIF] Would copy $($item.Name) ($($item.SizeGB) GB) from $($item.Source)" -ForegroundColor DarkGray
        $copiedCount++
        $copiedGB += $item.SizeGB
    }
}

Write-Host ""
Write-Log "=== CONSOLIDATION PASS FINISHED ===" "Magenta"
Write-Log ("Copied this pass : {0} files / {1:N1} GB" -f $copiedCount, $copiedGB) "Green"
Write-Log ("Errors           : $errors") $(if ($errors -gt 0) { "Red" } else { "Green" })
Write-Log "Log file         : $logFile"

Write-Host "`nNext: Re-run the script (it will automatically skip what is already there)." -ForegroundColor Cyan
Write-Host "When done: set RTBPATH=T:\Syzygy and test with rtbver / tbcheck on big 7pc tables." -ForegroundColor Yellow
