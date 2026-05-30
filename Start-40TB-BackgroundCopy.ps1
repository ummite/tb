<#
.SYNOPSIS
    Launches a background copy job to consolidate Syzygy files into the 40TB target.

.DESCRIPTION
    Uses Syzygy-Populate-NetStructure.ps1 with safe copy-only behavior.
    Writes its own log and creates a .COMPLETED marker when finished.

.PARAMETER Sources
    Array of source paths to scan and copy from (validated + classified).

.EXAMPLE
    .\Start-40TB-BackgroundCopy.ps1 -Sources "\\ds1821\32TB RAID0\Syzygy", "A:\Syzygy_A_Trier_FromOld_Ryzen7950"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string[]]$Sources
)

$ErrorActionPreference = "Continue"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$target   = "\\ds1817\40TB Raid 0 B\Syzygy"
$logFile  = Join-Path $ScriptRoot "logs\40TB_BackgroundCopy_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$doneFile = Join-Path $ScriptRoot "logs\40TB_BackgroundCopy.COMPLETED"

Write-Host "=== Starting background copy to 40TB ===" -ForegroundColor Cyan
Write-Host "Target : $target"
Write-Host "Log    : $logFile"
Write-Host "Sources: $($Sources -join ' | ')"

# Ensure log folder exists
$logDir = Split-Path $logFile -Parent
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

# Launch the population script with full logging
& "$ScriptRoot\Syzygy-Populate-NetStructure.ps1" `
    -SourcePaths $Sources `
    -DestinationRoot $target `
    -LinkType Copy `
    2>&1 | Tee-Object -FilePath $logFile

# Create completion marker
"Completed at $(Get-Date -Format 'o')" | Out-File -FilePath $doneFile -Encoding UTF8

Write-Host "`n=== Background copy finished ===" -ForegroundColor Green
Write-Host "Log file : $logFile"
Write-Host "Marker   : $doneFile" -ForegroundColor Green