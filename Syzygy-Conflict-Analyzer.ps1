<#
.SYNOPSIS
    Analyzes conflicts detected in a Syzygy inventory (same base name, different file sizes).
    Produces a detailed report with recommendations for resolution.

.DESCRIPTION
    Use this after running Syzygy-Inventory.ps1 on your master folder.
    It helps you decide what to do with the 40 conflicting files found on T:\Syzygy.

.EXAMPLE
    .\Syzygy-Conflict-Analyzer.ps1 -InventoryCsv "logs\T-Syzygy-Detailed-Inventory.csv" -MasterPath "T:\Syzygy"
#>

[CmdletBinding()]
param(
    [string]$InventoryCsv = "logs\T-Syzygy-Detailed-Inventory.csv",
    [string]$MasterPath = "T:\Syzygy",
    [string]$OutputReport = "logs\T-Syzygy-Conflicts-Report.txt",
    [string]$OutputKeepList = "logs\Conflicts-Keep-These.csv",
    [string]$OutputInvestigate = "logs\Conflicts-Investigate-These.csv"
)

if (-not (Test-Path $InventoryCsv)) {
    Write-Error "Inventory CSV not found: $InventoryCsv"
    Write-Host "Run first: .\Syzygy-Inventory.ps1 -Path 'T:\Syzygy' -Output '$InventoryCsv'"
    exit 1
}

Write-Host "=== Syzygy Conflict Analyzer ===" -ForegroundColor Magenta
Write-Host "Reading inventory: $InventoryCsv"

$inventory = Import-Csv $InventoryCsv
$conflicts = $inventory | Where-Object Status -eq "Conflict"

if ($conflicts.Count -eq 0) {
    Write-Host "No conflicts found in the inventory. Great!" -ForegroundColor Green
    exit 0
}

Write-Host "Found $($conflicts.Count) conflicting base names." -ForegroundColor Yellow
Write-Host "Analyzing physical files on disk..."

$report = @()
$keepList = @()
$investigateList = @()

foreach ($conflict in $conflicts) {
    $base = $conflict.BaseName

    # Find all actual files for this base name
    $pattern = "$base.*"
    $files = Get-ChildItem -Path $MasterPath -Recurse -File -Filter "*$base*" -ErrorAction SilentlyContinue |
             Where-Object { $_.Name -match "^$base\.(rtbw|rtbz)$" }

    $wdlFiles = $files | Where-Object Extension -eq '.rtbw' | Sort-Object Length -Descending
    $dtzFiles = $files | Where-Object Extension -eq '.rtbz' | Sort-Object Length -Descending

    $entry = [pscustomobject]@{
        BaseName       = $base
        WDL_Count      = $wdlFiles.Count
        DTZ_Count      = $dtzFiles.Count
        WDL_Sizes      = ($wdlFiles | ForEach-Object { [math]::Round($_.Length / 1MB, 1) }) -join " | "
        DTZ_Sizes      = ($dtzFiles | ForEach-Object { [math]::Round($_.Length / 1MB, 1) }) -join " | "
        WDL_Paths      = ($wdlFiles.FullName | ForEach-Object { $_ -replace [regex]::Escape($MasterPath), '' }) -join " ; "
        DTZ_Paths      = ($dtzFiles.FullName | ForEach-Object { $_ -replace [regex]::Escape($MasterPath), '' }) -join " ; "
        Recommendation = ""
    }

    # Decision logic
    $rec = ""

    if ($wdlFiles.Count -gt 1 -or $dtzFiles.Count -gt 1) {
        $rec = "MULTIPLE FILES - Manual review needed. Keep largest?"
        $investigateList += [pscustomobject]@{
            BaseName = $base
            Issue    = "Multiple files of same type"
            Action   = "Compare dates and sizes manually"
        }
    }
    else {
        # Single file per type but inventory showed conflict (should not happen often)
        $rec = "Single file per type - likely false positive from previous scan"
    }

    if ($wdlFiles.Count -ge 1 -and $dtzFiles.Count -ge 1) {
        $rec += " | Has both WDL+DTZ now"
    }

    $entry.Recommendation = $rec
    $report += $entry

    # Simple "keep the largest" proposal for now
    if ($wdlFiles.Count -gt 0) {
        $keepWDL = $wdlFiles[0]
        $keepList += [pscustomobject]@{
            BaseName = $base
            Type     = "WDL"
            KeepPath = $keepWDL.FullName
            SizeMB   = [math]::Round($keepWDL.Length / 1MB, 1)
            Note     = "Largest WDL"
        }
    }
    if ($dtzFiles.Count -gt 0) {
        $keepDTZ = $dtzFiles[0]
        $keepList += [pscustomobject]@{
            BaseName = $base
            Type     = "DTZ"
            KeepPath = $keepDTZ.FullName
            SizeMB   = [math]::Round($keepDTZ.Length / 1MB, 1)
            Note     = "Largest DTZ"
        }
    }
}

# Write text report
$report | Format-Table -AutoSize | Out-String | Set-Content $OutputReport -Encoding UTF8

# Write CSVs
$keepList | Export-Csv $OutputKeepList -NoTypeInformation -Encoding UTF8
$investigateList | Export-Csv $OutputInvestigate -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "=== CONFLICT ANALYSIS COMPLETE ===" -ForegroundColor Magenta
Write-Host "Conflicts analyzed     : $($conflicts.Count)"
Write-Host "Text report            : $OutputReport"
Write-Host "Proposed files to keep : $OutputKeepList"
Write-Host "Need manual review     : $OutputInvestigate"

Write-Host ""
Write-Host "Quick recommendation:" -ForegroundColor Yellow
Write-Host "  1. Review $OutputInvestigate"
Write-Host "  2. For most cases, the 'Largest' version is usually the correct one."
Write-Host "  3. Run tbcheck on the files you decide to keep."
Write-Host "  4. Delete the smaller/conflicting duplicates only after verification."
