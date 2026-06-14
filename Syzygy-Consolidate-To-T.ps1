<# 
.SYNOPSIS
    Consolidate ALL your Syzygy collections into T:\Syzygy as the single master repository.

.DESCRIPTION
    This is the Phase 3 script of the "Syzygy on T: Master Plan".

    After you have moved the plot* files off T: (freeing ~35 TB), run this script
    to pull every Syzygy file you own from A:, S:, local, F:, T: (any leftovers), etc.
    into a clean T:\Syzygy folder.

    Because T: lives on ds1817 and most other sources are on ds1821 (or local),
    this will perform real copies (no hardlinks possible across NAS).

    The script is deliberately a specialized version of Syzygy-Setup.ps1 with:
    - Hardcoded destination T:\Syzygy (or T:\Syzygy-Working)
    - LinkType default = Copy
    - All your known sources pre-populated
    - Extra safety messages about cross-NAS copies

.PARAMETER WorkingDir
    Override target (default: T:\Syzygy). Only change if you really know what you're doing.

.PARAMETER LinkType
    Copy (default and recommended here), HardLink (only works inside same NAS/volume), SymbolicLink.

.PARAMETER WhatIf
    Dry-run.

.EXAMPLE
    # Simulation (do this first!)
    .\Syzygy-Consolidate-To-T.ps1 -WhatIf

    # Real consolidation to T:\Syzygy
    .\Syzygy-Consolidate-To-T.ps1

.NOTES
    Run after Phase 1 (plots moved) when T: has sufficient free space.
    See Syzygy-T-Master-Plan.md for the full context and ordering.
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$WorkingDir = "T:\Syzygy",
    [ValidateSet('HardLink','SymbolicLink','Copy')]
    [string]$LinkType = "Copy",
    [switch]$WhatIf
)

$ErrorActionPreference = "Continue"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—" -ForegroundColor Magenta
Write-Host "â•‘     SYZYGY CONSOLIDATION â†’ T:\Syzygy  (Master Repository)        â•‘" -ForegroundColor Magenta
Write-Host "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•" -ForegroundColor Magenta
Write-Host ""
Write-Host "Target       : $WorkingDir" -ForegroundColor Cyan
Write-Host "LinkType     : $LinkType" -ForegroundColor Cyan
Write-Host "Mode         : $(if ($WhatIf) { 'WHATIF / DRY-RUN' } else { 'REAL EXECUTION' })" -ForegroundColor $(if ($WhatIf) { 'Yellow' } else { 'Red' })
Write-Host ""

# ===================== PRE-FLIGHT SPACE CHECK =====================
$tDrive = Get-PSDrive -Name T -ErrorAction SilentlyContinue
if ($tDrive -and $tDrive.Free -lt 20TB -and -not $WhatIf) {
    Write-Warning "T: has less than 20 TB free. Big consolidation may fail partway."
    Write-Host "Recommended: Wait until T: has at least 25-30 TB free." -ForegroundColor Yellow
    $cont = Read-Host "Continue anyway? (y/N)"
    if ($cont -ne 'y') { exit 1 }
}

# =============================================================================
# SOURCES - Add / remove paths as needed
# These are all the places you have (or had) Syzygy files
# =============================================================================
$Sources = @(
    # --- Local project folder (the one next to these scripts) ---
    (Join-Path $ScriptRoot 'Syzygy'),

    # --- A: drive (ds1817\IA) ---
    'A:\Syzygy',
    'A:\Syzygy_A_Trier_FromOld_Ryzen7950',   # Large historical collection (many 6pc + 7pc)

    # --- S: drive (ds1821) - the "plein de syzygy" one ---
    'S:\Syzygy',
    'S:\Syzygy\3-6men',
    'S:\5v2_pawnful',
    'S:\5v2_pawnless',
    'S:\6v1_pawnful',
    'S:\6v1_pawnless',
    'S:\4v3_pawnless_ManyMissing',

    # --- F: drive (ds1821\18TBExt2) - after you moved the plots here ---
    'F:\Plots',           # If you accidentally put Syzygy inside the plot folder
    'F:\Syzygy',          # If you ever created one
    'F:\',                # Root scan (will only pick up Syzygy files if any)

    # --- T: itself (any Syzygy you may have already copied manually or leftovers) ---
    'T:\Syzygy',
    'T:\Syzygy-Working',
    'T:\Syzygy-Flat',
    'T:\3-6men',
    'T:\7men'
)

# Remove duplicates and non-existing paths
$Sources = $Sources | Select-Object -Unique | Where-Object { Test-Path $_ }

Write-Host "Sources that will be scanned:" -ForegroundColor Green
$Sources | ForEach-Object { Write-Host "  $_" }

Write-Host ""
Write-Host "WARNING: Because T: (ds1817) and most sources (ds1821 or local) are on different machines," -ForegroundColor Yellow
Write-Host "         this will perform REAL COPIES, not hardlinks. It will take time and network bandwidth." -ForegroundColor Yellow
Write-Host ""

if (-not (Test-Path $WorkingDir)) {
    Write-Host "Creating master target folder: $WorkingDir" -ForegroundColor Green
    New-Item -ItemType Directory -Path $WorkingDir -Force | Out-Null
}

# Ensure clean flat structure (recommended)
$readme = @"
Syzygy Master Repository
========================
This is the single source of truth for all Syzygy tablebases on this machine.
All *.rtbw and *.rtbz files are stored flat in this folder.

RTBPATH / SyzygyPath should point here:
    T:\Syzygy

Generated/Consolidated on: $(Get-Date)
"@
$readme | Out-File -FilePath (Join-Path $WorkingDir 'README-Syzygy-Master.txt') -Encoding UTF8 -Force
Write-Host "README written to master folder." -ForegroundColor DarkGray

# =============================================================================
# Core deduplication + copy logic (simplified version of Syzygy-Setup.ps1)
# =============================================================================

$copied = 0
$skipped = 0
$errors = 0
$log = @()

foreach ($src in $Sources) {
    Write-Host "`n>>> Scanning $src ..." -ForegroundColor Cyan

    $files = Get-ChildItem -Path $src -Recurse -File -Include *.rtbw,*.rtbz -ErrorAction SilentlyContinue

    foreach ($file in $files) {
        $destPath = Join-Path $WorkingDir $file.Name

        if (Test-Path $destPath) {
            # Simple size check for dedup (good enough for Syzygy)
            $existing = Get-Item $destPath
            if ($existing.Length -eq $file.Length) {
                $skipped++
                continue
            }
        }

        if ($WhatIf) {
            Write-Host "  [WHATIF] Would copy: $($file.Name)" -ForegroundColor DarkGray
            $copied++
            continue
        }

        try {
            Write-Host "  Copying: $($file.Name)  ($([math]::Round($file.Length/1GB,1)) GB)" -ForegroundColor Gray
            Copy-Item -Path $file.FullName -Destination $destPath -Force -ErrorAction Stop
            $copied++
        }
        catch {
            Write-Warning "Failed to copy $($file.FullName) : $_"
            $errors++
        }
    }
}

# =============================================================================
# Summary
# =============================================================================

Write-Host "`n================================================================" -ForegroundColor Magenta
Write-Host " CONSOLIDATION TO T:\Syzygy FINISHED" -ForegroundColor Magenta
Write-Host "================================================================" -ForegroundColor Magenta
Write-Host " Files copied   : $copied" -ForegroundColor Green
Write-Host " Files skipped  : $skipped (already present with same size)" -ForegroundColor DarkGray
Write-Host " Errors         : $errors" -ForegroundColor $(if ($errors -gt 0) { "Red" } else { "Green" })
Write-Host " Master folder  : $WorkingDir" -ForegroundColor Cyan
Write-Host ""

if (-not $WhatIf) {
    "T:\Syzygy" | Out-File -FilePath (Join-Path $WorkingDir "RTBPATH.txt") -Encoding UTF8 -Force
    Write-Host "RTBPATH.txt written. You can now set:" -ForegroundColor Green
    Write-Host "    `$env:RTBPATH = `"T:\Syzygy`"" -ForegroundColor White
}

Write-Host "`nNext recommended steps:" -ForegroundColor Cyan
Write-Host "  1. Run tbcheck or rtbver on a few tables from T:\Syzygy"
Write-Host "  2. Update your chess engines to point to T:\Syzygy"
Write-Host "  3. (Later) Clean up the old scattered locations on A:, S:, local, etc."
Write-Host ""
Write-Host "See Syzygy-T-Master-Plan.md for the complete roadmap." -ForegroundColor DarkGray
