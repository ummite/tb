<#
.SYNOPSIS
    Generate 5-piece Syzygy tables ONE AT A TIME, but with high thread count per table.

.DESCRIPTION
    This is a simple wrapper around Syzygy-Generate.ps1 designed exactly for your use case:
    - One table at a time (sequential, safer, easier to monitor)
    - High number of threads per table (good for 24-core machines)

    Recommended thread count for 5-piece with -Disk: 12 to 18 on a 24-core CPU.
    Using all 24 cores on one table often gives diminishing returns because of memory bandwidth and disk I/O.

.PARAMETER Threads
    Number of threads to use for each table (default: 16 for a 24-core machine)

.PARAMETER Disk
    Use disk mode (-d). Strongly recommended for 5-piece.

.EXAMPLE
    # Recommended for your 24-core machine
    .\Generate-5pc-OneByOne.ps1 -Threads 16 -Disk
#>

param(
    [int]$Threads = 16,
    [switch]$Disk,
    [string]$Destination = "Syzygy"
)

$ErrorActionPreference = 'Stop'

Write-Host "=== 5-Piece Syzygy Generation - One Table at a Time ===" -ForegroundColor Magenta
Write-Host "Threads per table : $Threads"
Write-Host "Disk mode         : $Disk"
Write-Host "Destination       : $Destination"
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$genScript = Join-Path $scriptDir 'Syzygy-Generate.ps1'

if (-not (Test-Path $genScript)) {
    throw "Syzygy-Generate.ps1 not found next to this script."
}

# Set RTBPATH to the destination so lower tables are found
$destPath = Join-Path $scriptDir $Destination
$env:RTBPATH = $destPath

Write-Host "RTBPATH set to: $env:RTBPATH"
Write-Host ""

# Call the main script with -FiveOnly
# It will process tables one by one internally.
$diskArg = if ($Disk) { '-Disk' } else { '' }

& $genScript -FiveOnly -Threads $Threads $diskArg -Verify -Destination $Destination

Write-Host ""
Write-Host "Generation session finished (or interrupted)." -ForegroundColor Green
Write-Host "You can re-run the same command anytime to continue with the remaining tables." -ForegroundColor Yellow
