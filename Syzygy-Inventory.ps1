<#
.SYNOPSIS
    Professional inventory tool for a Syzygy collection.
    Analyzes WDL/DTZ pairing, detects conflicts (same name, different size), and produces a clean CSV report.

.DESCRIPTION
    Use this on T:\Syzygy (current master) and on source folders to understand exactly what you have.

.EXAMPLE
    # Analyze your current master
    .\Syzygy-Inventory.ps1 -Path "T:\Syzygy" -Output "logs\T-Syzygy-Inventory.csv"

    # Analyze the historical A: collection
    .\Syzygy-Inventory.ps1 -Path "A:\Syzygy_A_Trier_FromOld_Ryzen7950" -Output "logs\A-Historical-Inventory.csv"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Path,

    [string]$Output = "logs\Syzygy-Inventory.csv",

    [switch]$ShowProgress
)

$ErrorActionPreference = "Continue"

if (-not (Test-Path $Path)) {
    Write-Error "Path not found: $Path"
    exit 1
}

# Ensure output directory exists
$outputDir = Split-Path $Output -Parent
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

Write-Host "=== Syzygy Inventory ===" -ForegroundColor Magenta
Write-Host "Scanning: $Path"
Write-Host "Output  : $Output"
Write-Host ""

$files = Get-ChildItem -Path $Path -Recurse -File -Include *.rtbw,*.rtbz -ErrorAction SilentlyContinue

Write-Host "Found $($files.Count) Syzygy files. Analyzing..."

$groups = $files | Group-Object { $_.Name -replace '\.(rtbw|rtbz)$', '' }

$results = @()
$index = 0

foreach ($group in $groups) {
    $index++
    if ($ShowProgress -and ($index % 200 -eq 0)) {
        Write-Host "  Processed $index / $($groups.Count) ..."
    }

    $baseName = $group.Name
    $wdlFiles = $group.Group | Where-Object { $_.Name -like '*.rtbw' }
    $dtzFiles = $group.Group | Where-Object { $_.Name -like '*.rtbz' }

    $wdl = $wdlFiles | Select-Object -First 1
    $dtz = $dtzFiles | Select-Object -First 1

    $wdlSize = if ($wdl) { $wdl.Length } else { 0 }
    $dtzSize = if ($dtz) { $dtz.Length } else { 0 }

    # Detect conflicts (multiple files with same extension but different sizes)
    $wdlConflict = ($wdlFiles | Select-Object -Unique Length).Count -gt 1
    $dtzConflict = ($dtzFiles | Select-Object -Unique Length).Count -gt 1

    $status = if ($wdl -and $dtz -and -not $wdlConflict -and -not $dtzConflict) {
        "Complete"
    } elseif ($wdlConflict -or $dtzConflict) {
        "Conflict"
    } elseif ($wdl) {
        "WDL only"
    } elseif ($dtz) {
        "DTZ only"
    } else {
        "Unknown"
    }

    $results += [pscustomobject]@{
        BaseName     = $baseName
        HasWDL       = [bool]$wdl
        HasDTZ       = [bool]$dtz
        WDL_Size     = $wdlSize
        DTZ_Size     = $dtzSize
        WDL_SizeGB   = if ($wdl) { [math]::Round($wdl.Length / 1GB, 3) } else { 0 }
        DTZ_SizeGB   = if ($dtz) { [math]::Round($dtz.Length / 1GB, 3) } else { 0 }
        Status       = $status
        WDL_Conflict = $wdlConflict
        DTZ_Conflict = $dtzConflict
        FullPath_WDL = if ($wdl) { $wdl.FullName } else { "" }
        FullPath_DTZ = if ($dtz) { $dtz.FullName } else { "" }
    }
}

# Export CSV
$results | Export-Csv -Path $Output -NoTypeInformation -Encoding UTF8

# Summary
Write-Host ""
Write-Host "=== INVENTORY SUMMARY ===" -ForegroundColor Magenta
Write-Host ("Total unique base names : {0}" -f $results.Count)

$complete   = ($results | Where-Object Status -eq "Complete").Count
$wdlOnly    = ($results | Where-Object Status -eq "WDL only").Count
$dtzOnly    = ($results | Where-Object Status -eq "DTZ only").Count
$conflicts  = ($results | Where-Object Status -eq "Conflict").Count

Write-Host ("Complete pairs (WDL+DTZ): {0}" -f $complete) -ForegroundColor Green
Write-Host ("WDL only                : {0}" -f $wdlOnly) -ForegroundColor Yellow
Write-Host ("DTZ only                : {0}" -f $dtzOnly) -ForegroundColor Yellow
Write-Host ("Conflicts (bad sizes)   : {0}" -f $conflicts) -ForegroundColor $(if ($conflicts -gt 0) { "Red" } else { "Green" })

$totalWDL = ($results | Where-Object HasWDL).Count
$totalDTZ = ($results | Where-Object HasDTZ).Count
Write-Host ""
Write-Host ("Total WDL files         : {0}" -f $totalWDL)
Write-Host ("Total DTZ files         : {0}" -f $totalDTZ)

Write-Host ""
Write-Host "Report saved to: $Output" -ForegroundColor Cyan

# Show conflicts if any
if ($conflicts -gt 0) {
    Write-Host ""
    Write-Host "!!! CONFLICTS DETECTED !!!" -ForegroundColor Red
    Write-Host "These base names have multiple files with the same extension but different sizes."
    Write-Host "You should investigate them manually."
    Write-Host ""
    $results | Where-Object Status -eq "Conflict" | Select-Object -First 20 | ForEach-Object {
        Write-Host ("  {0}" -f $_.BaseName) -ForegroundColor Red
    }
    if ($conflicts -gt 20) {
        Write-Host "  ... and $($conflicts - 20) more (see the CSV)"
    }
}
