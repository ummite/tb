<#
.SYNOPSIS
    Background job to surgically organize ONLY the loose .rtbw/.rtbz files sitting
    directly in the root of the 40TB target (the ~210 7pc files) into the proper
    net structure subfolders (7men/4v3_*, 5v2_*, 6v1_*, etc.).

    This is the immediate next job after (or in parallel with) the ds1821 bulk copy.
    - Copy-only (never deletes)
    - tbcheck enforced on every pair
    - Very fast because it only looks at the root, not the whole 40TB volume
    - Creates the marker 40TB_OrganizeLoose.COMPLETED when done
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$target   = "\\ds1817\40TB Raid 0 B\Syzygy"
$logFile  = Join-Path $ScriptRoot "logs\40TB_OrganizeLoose_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$doneFile = Join-Path $ScriptRoot "logs\40TB_OrganizeLoose.COMPLETED"

# Ensure log dir exists
$logDir = Split-Path $logFile -Parent
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

Write-Host "=== Starting SURGICAL organization of LOOSE ROOT files on 40TB ===" -ForegroundColor Cyan
Write-Host "Target : $target"
Write-Host "Mode   : Only files directly in the root (the ~210 loose 7pc tables)"
Write-Host "Log    : $logFile"
Write-Host "Marker : $doneFile"
Write-Host ""

& "$ScriptRoot\Syzygy-Populate-NetStructure.ps1" `
    -SourcePaths $target `
    -DestinationRoot $target `
    -LinkType Copy `
    2>&1 | Tee-Object -FilePath $logFile

"Completed at $(Get-Date -Format 'o')" | Out-File -FilePath $doneFile -Encoding UTF8

Write-Host "`n=== Organization job finished ===" -ForegroundColor Green
Write-Host "Log file : $logFile"
Write-Host "Marker   : $doneFile" -ForegroundColor Green

# Post-job hint
Write-Host ""
Write-Host "Next suggested: Check the marker, then review the log for any BAD HASH 7pc." -ForegroundColor Yellow
Write-Host "After that we can pull the rich 7pc material from A:\Syzygy_A_Trier..." -ForegroundColor Yellow