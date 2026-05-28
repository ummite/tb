<# 
.SYNOPSIS
    Master Orchestrator for moving ALL Syzygy to T: as the clean single source of truth.

.DESCRIPTION
    This is THE script you run for the entire operation requested:
    - Phase 1: Clear 35+ TB of plot* files from T: to F: (freeing space)
    - Phase 3+: Consolidate every Syzygy you own into T:\Syzygy (clean flat master)

    On every launch, it automatically detects the current state and tells you exactly
    what to do next (or offers to do it for you).

    Run it often. It is safe and resumable.

.EXAMPLE
    .\Start-Syzygy-T-Master-Setup.ps1
#>

[CmdletBinding()]
param(
    [switch]$Force   # Skip some confirmations (use with care)
)

$ErrorActionPreference = "Continue"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Clear-Host
Write-Host "===============================================" -ForegroundColor Magenta
Write-Host "  SYZYGY T: MASTER SETUP" -ForegroundColor Magenta
Write-Host "  Single Source of Truth on T:\Syzygy" -ForegroundColor Magenta
Write-Host "===============================================" -ForegroundColor Magenta
Write-Host ""

# ===================== STATE DETECTION =====================

Write-Host "=== Detecting current state (this may take a minute) ===" -ForegroundColor Cyan

# Space
$tDrive = Get-PSDrive -Name T -ErrorAction SilentlyContinue
$fDrive = Get-PSDrive -Name F -ErrorAction SilentlyContinue

$freeT_TB = if ($tDrive) { [math]::Round($tDrive.Free / 1TB, 2) } else { 0 }
$freeF_TB = if ($fDrive) { [math]::Round($fDrive.Free / 1TB, 2) } else { 0 }
$usedT_TB = if ($tDrive) { [math]::Round($tDrive.Used / 1TB, 2) } else { 0 }

Write-Host "Space  →  T: $freeT_TB TB free   |   F: $freeF_TB TB free" -ForegroundColor $(if ($freeT_TB -gt 30) { "Green" } elseif ($freeT_TB -gt 10) { "Yellow" } else { "Red" })

# Plots remaining on T:
$plotsRemaining = (Get-ChildItem -Path T:\ -File -Filter "plot*" -ErrorAction SilentlyContinue | Measure-Object).Count
Write-Host "Plots remaining on T:\   : $plotsRemaining" -ForegroundColor $(if ($plotsRemaining -eq 0) { "Green" } else { "Yellow" })

# Syzygy already on T:\Syzygy
$masterPath = "T:\Syzygy"
$syzygyOnMaster = 0
if (Test-Path $masterPath) {
    $syzygyOnMaster = (Get-ChildItem -Path $masterPath -File -Include *.rtbw,*.rtbz -ErrorAction SilentlyContinue | Measure-Object).Count
}
Write-Host "Syzygy files in T:\Syzygy : $syzygyOnMaster" -ForegroundColor Cyan

# Quick count on main sources (fast top-level only for speed)
Write-Host "`nQuick source inventory (top level):" -ForegroundColor DarkGray
$sources = @(
    @{Name='Local Syzygy'; Path=(Join-Path $ScriptRoot 'Syzygy')},
    @{Name='A:\Syzygy'; Path='A:\Syzygy'},
    @{Name='A:\Syzygy_A_Trier'; Path='A:\Syzygy_A_Trier_FromOld_Ryzen7950'},
    @{Name='S:\Syzygy + 3-6men'; Path='S:\Syzygy'},
    @{Name='S: split folders'; Path='S:\5v2_pawnful'}
)
foreach ($s in $sources) {
    if (Test-Path $s.Path) {
        $c = (Get-ChildItem -Path $s.Path -Recurse -File -Include *.rtbw -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-Host "  $($s.Name) : ~$c tables" -ForegroundColor DarkGray
    }
}

Write-Host ""

# ===================== PHASE DECISION =====================

$phase = "UNKNOWN"

if ($plotsRemaining -gt 0) {
    $phase = "PHASE 1 - CLEAR PLOTS FROM T:"
    Write-Host "CURRENT PHASE: $phase" -ForegroundColor Red -BackgroundColor Black
    Write-Host "Action required: Move plot* files to F: to free space on T:." -ForegroundColor Yellow
}
elseif ($freeT_TB -lt 25) {
    $phase = "WAITING FOR MORE SPACE ON T:"
    Write-Host "CURRENT PHASE: $phase" -ForegroundColor Yellow
    Write-Host "You still need more free space on T: before starting big Syzygy copies." -ForegroundColor Yellow
}
elseif ($syzygyOnMaster -lt 500) {
    $phase = "PHASE 3 - CONSOLIDATE SYZYGY TO T:\Syzygy"
    Write-Host "CURRENT PHASE: $phase" -ForegroundColor Green -BackgroundColor Black
    Write-Host "T: has enough space and plots are gone. Time to build the master repository." -ForegroundColor Green
}
else {
    $phase = "MAINTENANCE / VERIFICATION"
    Write-Host "CURRENT PHASE: $phase" -ForegroundColor Green
    Write-Host "You already have a substantial master on T:\Syzygy ($syzygyOnMaster files)." -ForegroundColor Green
}

Write-Host "`n═══════════════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta

# ===================== RECOMMENDED ACTION =====================

switch ($phase) {
    "PHASE 1 - CLEAR PLOTS FROM T:" {
        Write-Host "`nRECOMMENDED ACTION:" -ForegroundColor Cyan
        Write-Host "  Run the plot mover (smart auto-batch recommended):" -ForegroundColor White
        Write-Host "    .\Move-Plots-T-to-F.ps1 -AutoBatch -Threads 16" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Or with a hard limit for this session:" -ForegroundColor White
        Write-Host "    .\Move-Plots-T-to-F.ps1 -MaxFiles 60 -Threads 12" -ForegroundColor Yellow
        Write-Host ""
        if (-not $Force) {
            $answer = Read-Host "Do you want to launch the plot mover now with AutoBatch? (Y/n)"
            if ($answer -ne 'n') {
                & "$ScriptRoot\Move-Plots-T-to-F.ps1" -AutoBatch -Threads 16
            }
        }
    }

    "PHASE 3 - CONSOLIDATE SYZYGY TO T:\Syzygy" {
        Write-Host "`nRECOMMENDED ACTION:" -ForegroundColor Cyan
        Write-Host "  Build / complete the master repository on T:" -ForegroundColor White
        Write-Host "    .\Syzygy-Consolidate-To-T.ps1 -WhatIf" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  When ready for real copy (will take time):" -ForegroundColor White
        Write-Host "    .\Syzygy-Consolidate-To-T.ps1" -ForegroundColor Yellow
        Write-Host ""
        if (-not $Force) {
            $answer = Read-Host "Launch consolidation in WHATIF mode now? (Y/n)"
            if ($answer -ne 'n') {
                & "$ScriptRoot\Syzygy-Consolidate-To-T.ps1" -WhatIf
            }
        }
    }

    default {
        Write-Host "`nRun one of the following manually:" -ForegroundColor Cyan
        Write-Host "  - .\Move-Plots-T-to-F.ps1 -WhatIf"
        Write-Host "  - .\Syzygy-Consolidate-To-T.ps1 -WhatIf"
        Write-Host "  - .\Check-Migration-State.ps1   (recommended for frequent checks)"
    }
}

Write-Host "`nUseful one-liners:" -ForegroundColor DarkGray
Write-Host "  Check state anytime : .\Check-Migration-State.ps1" -ForegroundColor DarkGray
Write-Host "  Full plan           : Get-Content Syzygy-T-Master-Plan.md -Raw" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Run this master script again after every big session to see updated recommendations." -ForegroundColor DarkGray
