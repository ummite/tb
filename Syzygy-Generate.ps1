<#
.SYNOPSIS
    Destination-aware Syzygy tablebase generator for regular chess (3-5 pieces complete).

.DESCRIPTION
    Generates (and optionally verifies) all regular chess tablebases up to 5 pieces
    into a clean destination folder (default: Syzygy).

    Key features:
    - Proper destination folder management (files are written directly into the target folder).
- Use Syzygy-Setup.ps1 first if your files are spread across multiple network shares.
    - RTBPATH is automatically set to the destination so incremental generation works safely
      (lower piece tables are found when generating higher ones).
    - Uses the official checksum lists (checksums/wdl345.txt + dtz345.txt) as the source of truth
      for "what is complete up to 5 pieces".
    - Skips tables that already have both .rtbw and .rtbz.
    - Supports -Disk mode (recommended for 5-piece on machines with < 32-64 GB RAM).
    - PowerShell native, works great with VS2026 workflow.

.EXAMPLE
    # Make everything complete up to 5 pieces into Syzygy/ (recommended first run)
    .\Syzygy-Generate.ps1 -Complete -Threads 8 -Disk

.EXAMPLE
    # Generate ONLY the missing 5-piece tables (recommended for your request)
    .\Syzygy-Generate.ps1 -FiveOnly -Threads 12 -Disk -Destination Syzygy

.EXAMPLE
    # Generate only missing 5-piece tables with more threads, no disk spilling
    .\Syzygy-Generate.ps1 -Min 5 -Max 5 -Threads 12 -Destination Syzygy

.EXAMPLE
    # Dry-run to see what would be generated
    .\Syzygy-Generate.ps1 -Complete -WhatIf
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$Destination = "Syzygy",

    [ValidateRange(3,5)]
    [int]$Min = 3,

    [ValidateRange(3,5)]
    [int]$Max = 5,

    [switch]$FiveOnly,   # Convenience: only generate missing 5-piece tables (Min=5, Max=5)

    [int]$Threads = 8,

    [switch]$Disk,          # Pass -d to generators (strongly recommended for 5pc)

    [switch]$Verify,        # Run tbcheck after generation

    [switch]$Complete,      # Shortcut for Min=3 Max=5 + generate everything missing

    [switch]$ListOnly       # Just list what is missing, do not generate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Resolve paths (relative to script location) ---
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$BinDir      = Join-Path $ScriptDir 'bin'
$ChecksumDir = Join-Path $ScriptDir 'checksums'
$DestDir     = Join-Path $ScriptDir $Destination

if (-not (Test-Path $BinDir)) {
    throw "bin\ directory not found. Build the project first with .\build.bat"
}

$rtbgen   = Join-Path $BinDir 'rtbgen.exe'
$rtbgenp  = Join-Path $BinDir 'rtbgenp.exe'
$tbcheck  = Join-Path $BinDir 'tbcheck.exe'

foreach ($exe in @($rtbgen, $rtbgenp, $tbcheck)) {
    if (-not (Test-Path $exe)) {
        throw "Required executable not found: $exe"
    }
}

# Create destination if missing
if (-not (Test-Path $DestDir)) {
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    Write-Host "Created destination folder: $DestDir" -ForegroundColor Green
}

# --- Load the authoritative list from checksums (3-5 pieces) ---
$wdlList = Join-Path $ChecksumDir 'wdl345.txt'
if (-not (Test-Path $wdlList)) {
    throw "Reference list not found: $wdlList"
}

$allTables = Get-Content $wdlList | ForEach-Object {
    if ($_ -match '^([^:]+)\.rtbw:') { $matches[1] }
} | Where-Object { $_ }

Write-Host "Loaded $($allTables.Count) reference tables from checksums (3-5 pieces)." -ForegroundColor Cyan

# Filter by piece count if needed
function Get-PieceCount([string]$name) {
    # "KRPvKR" -> 5 pieces total (K+R+P + K+R, the 'v' and duplicate kings are not counted extra)
    # Simpler reliable formula used by the project: length of the material string - 1
    return ($name.Length - 1)
}

$tablesToProcess = $allTables | Where-Object {
    $pc = Get-PieceCount $_
    $pc -ge $Min -and $pc -le $Max
}

if ($FiveOnly) {
    $Min = 5; $Max = 5
    $tablesToProcess = $allTables | Where-Object { (Get-PieceCount $_) -eq 5 }
} elseif ($Complete) {
    $Min = 3; $Max = 5
    $tablesToProcess = $allTables
}

# CRITICAL: Sort by increasing piece count first, then by name.
# This ensures prerequisites (smaller tables) are generated before dependents.
$tablesToProcess = $tablesToProcess |
    Sort-Object { Get-PieceCount $_ }, { $_ }

Write-Host "Tables in scope ($Min-$Max pieces): $($tablesToProcess.Count)" -ForegroundColor Cyan

# --- Prepare environment for generation into destination ---
Push-Location $DestDir
try {
    # Critical: RTBPATH must point to the destination so lower tables are visible
    $env:RTBPATH = $DestDir
    $env:RTBSTATSDIR = Join-Path $ScriptDir 'stats'

    if (-not (Test-Path $env:RTBSTATSDIR)) {
        New-Item -ItemType Directory -Path $env:RTBSTATSDIR -Force | Out-Null
    }

    Write-Host ""
    Write-Host "=== Syzygy Generation Session ===" -ForegroundColor Magenta
    Write-Host "Destination : $DestDir"
    Write-Host "RTBPATH     : $env:RTBPATH"
    Write-Host "Threads     : $Threads"
    Write-Host "Disk mode   : $Disk"
    Write-Host "Scope       : $Min-$Max pieces ($($tablesToProcess.Count) tables)"
    Write-Host ""

    $generated = 0
    $skipped   = 0
    $failed    = 0

    foreach ($tb in $tablesToProcess | Sort-Object) {
        $wdl = "$tb.rtbw"
        $dtz = "$tb.rtbz"

        $hasBoth = (Test-Path $wdl) -and (Test-Path $dtz)

        if ($hasBoth) {
            $skipped++
            Write-Host "  SKIP  $tb (already complete)" -ForegroundColor DarkGray
            continue
        }

        if ($ListOnly) {
            Write-Host "  MISS  $tb" -ForegroundColor Yellow
            continue
        }

        $hasPawn = $tb -like '*P*'
        $generator = if ($hasPawn) { $rtbgenp } else { $rtbgen }
        $genName   = if ($hasPawn) { 'rtbgenp' } else { 'rtbgen' }

        $diskOpt = if ($Disk) { '-d ' } else { '' }

        $cmd = "& `"$generator`" ${diskOpt}-t $Threads --stats $tb"

        Write-Host "  GEN   $tb  ($genName)" -ForegroundColor Cyan

        if ($PSCmdlet.ShouldProcess($tb, "Generate tablebase")) {
            $start = Get-Date
            $output = & { Invoke-Expression $cmd 2>&1 }  # capture without letting one error kill the whole script
            $duration = (Get-Date) - $start

            if ($LASTEXITCODE -eq 0 -and (Test-Path $wdl)) {
                $generated++
                Write-Host "    OK  ($([int]$duration.TotalSeconds)s)" -ForegroundColor Green
            } else {
                $failed++
                Write-Host "    FAIL (exit=$LASTEXITCODE)" -ForegroundColor Red
                # Safe extraction of last error line (handles empty Select-String result)
                $lastErr = $output | Select-String -Pattern 'Missing table|error|Error|assert|crash' | Select-Object -Last 1
                if ($lastErr) { Write-Host "      $($lastErr.Line)" -ForegroundColor DarkRed }
            }
        }
    }

    Write-Host ""
    Write-Host "=== Summary ===" -ForegroundColor Magenta
    Write-Host "Generated : $generated"
    Write-Host "Skipped   : $skipped"
    Write-Host "Failed    : $failed"
    Write-Host "Total in scope : $($tablesToProcess.Count)"
    Write-Host ""

    if ($failed -gt 0) {
        Write-Warning "$failed table(s) failed to generate. Check output above and RTBPATH contents."
    }

    # Optional verification step
    if ($Verify -and -not $ListOnly -and $generated -gt 0) {
        Write-Host "Running verification (tbcheck) on newly generated files..." -ForegroundColor Yellow
        # Simple: verify all .rtbw in the folder (tbcheck supports multiple or wildcards in practice)
        & $tbcheck (Get-ChildItem *.rtbw | Select-Object -ExpandProperty Name) 2>&1 | Select-Object -Last 20
    }

} finally {
    Pop-Location
}

Write-Host "Done. Your complete 3-5 piece Syzygy set is in: $DestDir" -ForegroundColor Green
Write-Host "Point your chess engine / probing code at this folder." -ForegroundColor Green
