<#
.SYNOPSIS
    Batch verification tool for a Syzygy master folder.
    Runs tbcheck on all files (or a subset) with resumable logging and progress.

.DESCRIPTION
    Designed for Phase 5 of the cleanup plan.
    Can verify thousands of files safely, skipping already-checked ones.

.EXAMPLE
    # Verify everything on T:\Syzygy (can take a long time)
    .\Syzygy-Verify-Master.ps1 -Path "T:\Syzygy" -LogDir "logs\verification"

    # Verify only the biggest files first (> 1 GB)
    .\Syzygy-Verify-Master.ps1 -Path "T:\Syzygy" -MinSizeGB 1 -MaxFiles 100
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Path,

    [string]$LogDir = "logs\verification",

    [double]$MinSizeGB = 0,
    [int]$MaxFiles = 0,

    [switch]$WhatIf,
    [switch]$ForceReverify
)

if (-not (Test-Path $Path)) {
    Write-Error "Path not found: $Path"
    exit 1
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

$summaryLog = Join-Path $LogDir "verify-summary-$timestamp.log"
$detailLog  = Join-Path $LogDir "verify-detail-$timestamp.log"
$doneFile   = Join-Path $LogDir "verified-files.txt"

Write-Host "=== Syzygy Master Verification ===" -ForegroundColor Magenta
Write-Host "Target     : $Path"
Write-Host "MinSize    : $MinSizeGB GB"
Write-Host "Logs       : $LogDir"
Write-Host ""

# Load already verified files if exists
$alreadyDone = @{}
if ((Test-Path $doneFile) -and -not $ForceReverify) {
    Get-Content $doneFile | ForEach-Object { $alreadyDone[$_] = $true }
    Write-Host "Loaded $($alreadyDone.Count) previously verified files (skipping them)"
}

$files = Get-ChildItem -Path $Path -Recurse -File -Include *.rtbw,*.rtbz -ErrorAction SilentlyContinue |
         Where-Object { $_.Length -ge ($MinSizeGB * 1GB) }

if ($MaxFiles -gt 0) {
    $files = $files | Select-Object -First $MaxFiles
}

$toVerify = $files | Where-Object { -not $alreadyDone.ContainsKey($_.FullName) }

Write-Host "Total files found     : $($files.Count)"
Write-Host "Already verified      : $($alreadyDone.Count)"
Write-Host "Need to verify now    : $($toVerify.Count)" -ForegroundColor Yellow
Write-Host ""

if ($WhatIf) {
    Write-Host "WHATIF mode - would verify these files:" -ForegroundColor Cyan
    $toVerify | Select-Object -First 20 | ForEach-Object {
        Write-Host "  $($_.FullName)"
    }
    if ($toVerify.Count -gt 20) { Write-Host "  ... and $($toVerify.Count - 20) more" }
    exit 0
}

$passed = 0
$failed = 0
$errors = 0

foreach ($file in $toVerify) {
    $relPath = $file.FullName -replace [regex]::Escape($Path), ''
    Write-Host "Checking: $relPath ... " -NoNewline

    $start = Get-Date
    $result = & tbcheck $file.FullName 2>&1
    $duration = (Get-Date) - $start

    if ($LASTEXITCODE -eq 0) {
        Write-Host "PASS" -ForegroundColor Green
        $passed++
        Add-Content -Path $doneFile -Value $file.FullName -Encoding UTF8
    } else {
        Write-Host "FAIL" -ForegroundColor Red
        $failed++
        $msg = "FAIL: $relPath`n$result"
        Add-Content -Path $detailLog -Value $msg -Encoding UTF8
    }

    Add-Content -Path $summaryLog -Value "[$($duration.ToString('mm\:ss'))] $relPath -> $(if($LASTEXITCODE -eq 0){'PASS'}else{'FAIL'})" -Encoding UTF8
}

Write-Host ""
Write-Host "=== VERIFICATION FINISHED ===" -ForegroundColor Magenta
Write-Host "Passed  : $passed" -ForegroundColor Green
Write-Host "Failed  : $failed" -ForegroundColor $(if($failed -gt 0){"Red"}else{"Green"})
Write-Host "Summary : $summaryLog"
Write-Host "Details : $detailLog" -ForegroundColor $(if($failed -gt 0){"Yellow"}else{"Gray"})

if ($failed -gt 0) {
    Write-Host ""
    Write-Host "Some files failed tbcheck. Review $detailLog and consider re-copying them." -ForegroundColor Red
}
