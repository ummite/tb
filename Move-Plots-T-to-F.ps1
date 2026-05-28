<# 
.SYNOPSIS
    Move all 'plot*' files from T: (source) to F: (destination) safely, in phases if needed.

.DESCRIPTION
    Designed for the user's specific situation:
    - T: (\\ds1817\40TB Raid 0 B) is currently ~99% full with 358 plot* files (~35.4 TB).
    - F: (\\ds1821\18TBExt2) has plenty of free space (~13 TB).
    - Moving plots first is REQUIRED to free ~35+ TB on T: before consolidating all Syzygy onto T: as the master repository.

    Uses robocopy /MOV (copy + delete source) for resumability and robustness over network.

    IMPORTANT: This is a multi-pass / space-constrained operation.
    Run with -WhatIf first. You may need to run it multiple times as space frees on T: and fills on F:.

.PARAMETER Source
    Root folder containing the plot* files. Default: T:\

.PARAMETER Destination
    Target folder on F:. Default: F:\Plots\  (recommended to keep them organized)

.PARAMETER WhatIf
    List-only mode (robocopy /L). Shows what would be moved without doing anything.

.PARAMETER MaxFiles
    Safety limit: move at most this many files this run (0 = no limit). Useful for phased moves.

.PARAMETER Threads
    Robocopy /MT value. Default 8. Increase if your network can handle it (try 16-32).

.EXAMPLE
    # Simulation first (highly recommended)
    .\Move-Plots-T-to-F.ps1 -WhatIf

    # Real move, all files
    .\Move-Plots-T-to-F.ps1

    # Phased: move only 50 plots this session
    .\Move-Plots-T-to-F.ps1 -MaxFiles 50

.NOTES
    - Run in an elevated PowerShell if permissions require it.
    - Network copy of 35+ TB will take a long time (days). Robocopy is resumable.
    - After plots are moved, T: will have massive free space for Syzygy consolidation.
    - See Syzygy-T-Master-Plan.md for the full phased roadmap.
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$Source = "T:\",
    [string]$Destination = "F:\Plots\",
    [int]$MaxFiles = 0,
    [int]$Threads = 8,
    [switch]$AutoBatch   # Automatically calculate safe batch size based on free space on F:
)

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logDir = ".\logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$logFile = Join-Path $logDir "Move-Plots-T-to-F_$timestamp.log"

Write-Host "=== Move plot* files : T: → F: ===" -ForegroundColor Cyan
Write-Host "Source      : $Source"
Write-Host "Destination : $Destination"
Write-Host "Threads     : $Threads"
Write-Host "MaxFiles    : $(if ($MaxFiles -gt 0) { $MaxFiles } else { 'Unlimited' })"
Write-Host "Log         : $logFile"
Write-Host ""

if (-not (Test-Path $Source)) {
    Write-Error "Source folder not found: $Source"
    exit 1
}

# Ensure destination exists
if (-not (Test-Path $Destination)) {
    Write-Host "Creating destination folder: $Destination" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
}

# Find all plot* files (non-recursive at root is fastest for the known layout)
$plots = Get-ChildItem -Path $Source -File -Filter "plot*" -ErrorAction SilentlyContinue | Sort-Object Name

$totalFound = $plots.Count
Write-Host "Found $totalFound plot* files in $Source" -ForegroundColor Green

if ($totalFound -eq 0) {
    Write-Host "Nothing to move. Exiting." -ForegroundColor Yellow
    exit 0
}

# Apply MaxFiles limit if requested
if ($MaxFiles -gt 0 -and $totalFound -gt $MaxFiles) {
    Write-Host "Limiting this run to first $MaxFiles files (out of $totalFound)" -ForegroundColor Yellow
    $plots = $plots | Select-Object -First $MaxFiles
}

$toMove = $plots.Count
Write-Host "Will process $toMove file(s) this run." -ForegroundColor Cyan

# ===================== AUTO-BATCH LOGIC =====================
if ($AutoBatch -and -not $WhatIf) {
    Write-Host "`n[AutoBatch] Calculating safe number of plots to move based on free space..." -ForegroundColor Yellow

    $fDrive = Get-PSDrive -Name F
    $freeOnF = $fDrive.Free
    $avgPlotSize = ($plots | Measure-Object Length -Average).Average
    if ($avgPlotSize -lt 1) { $avgPlotSize = 100GB }  # fallback

    $safeToFit = [math]::Floor($freeOnF / $avgPlotSize * 0.92)  # leave 8% headroom
    if ($safeToFit -lt 1) { $safeToFit = 1 }

    if ($toMove -gt $safeToFit) {
        Write-Host "  Free space on F: allows ~$safeToFit plots safely." -ForegroundColor Cyan
        Write-Host "  Reducing batch from $toMove to $safeToFit files." -ForegroundColor Yellow
        $plots = $plots | Select-Object -First $safeToFit
        $toMove = $plots.Count
    } else {
        Write-Host "  Enough space on F: for all remaining $toMove plots (with headroom)." -ForegroundColor Green
    }
}

if ($WhatIfPreference) {
    Write-Host "`n--- WHATIF MODE (no changes will be made) ---" -ForegroundColor Magenta
}

# Build robocopy argument list
# /MOV   = Move (copy + delete source)
# /MT    = Multi-threaded
# /R:3   = Retry 3 times
# /W:5   = Wait 5 seconds between retries
# /NP    = No progress percentage (cleaner logs)
# /LOG+  = Append to log
# /TEE   = Output to console + log
# /L     = List only (when -WhatIf)

$robocopyArgs = @(
    $Source,
    $Destination,
    "plot*",
    "/MOV",
    "/MT:$Threads",
    "/R:3",
    "/W:5",
    "/NP",
    "/LOG+:$logFile",
    "/TEE"
)

if ($WhatIfPreference) {
    $robocopyArgs += "/L"
}

Write-Host "`nStarting robocopy... (this can take a very long time for large files)" -ForegroundColor Yellow
Write-Host "Command equivalent: robocopy $($robocopyArgs -join ' ')" -ForegroundColor DarkGray

# Execute robocopy
$process = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow

$exitCode = $process.ExitCode

# Robocopy exit codes: 0-7 are success (some files copied, some skipped, etc.)
# 8+ are failures
Write-Host "`nRobocopy finished with exit code $exitCode" -ForegroundColor $(if ($exitCode -lt 8) { "Green" } else { "Red" })

if ($exitCode -lt 8) {
    Write-Host "Move operation completed successfully (or with only warnings)." -ForegroundColor Green
    Write-Host "Log file: $logFile" -ForegroundColor DarkGray
} else {
    Write-Warning "Robocopy reported errors (exit code $exitCode). Check the log: $logFile"
}

# ===================== POST-RUN VERIFICATION =====================
Write-Host "`n--- Post-run verification ---" -ForegroundColor Cyan

$remainingOnT = (Get-ChildItem -Path $Source -File -Filter "plot*" -ErrorAction SilentlyContinue).Count
$nowOnF = (Get-ChildItem -Path $Destination -File -Filter "plot*" -ErrorAction SilentlyContinue).Count

Write-Host "Plots remaining on T:\   : $remainingOnT"
Write-Host "Plots now on F:\Plots\   : $nowOnF"

$fDriveAfter = Get-PSDrive -Name F
$tDriveAfter = Get-PSDrive -Name T
Write-Host "Free space now →  T: $([math]::Round($tDriveAfter.Free/1TB,2)) TB   |   F: $([math]::Round($fDriveAfter.Free/1TB,2)) TB"

if ($remainingOnT -eq 0 -and $nowOnF -gt 0) {
    Write-Host "`n🎉 SUCCESS: All plot* files have been moved off T: !" -ForegroundColor Green
    Write-Host "T: now has massive free space. You can proceed to Syzygy consolidation." -ForegroundColor Green
}

Write-Host "`nNext steps recommendation:" -ForegroundColor Cyan
Write-Host "  1. Check free space on T: (should have increased a lot)"
Write-Host "  2. When T: has > 30 TB free, run the Master Orchestrator:"
Write-Host "     .\Start-Syzygy-T-Master-Setup.ps1"
Write-Host "  3. Full plan: Syzygy-T-Master-Plan.md"

exit $exitCode
