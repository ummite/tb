<#
.SYNOPSIS
    Resumable / background-friendly Syzygy inventory scanner.
    Scans sources for .rtbw/.rtbz pairs, validates with tbcheck, collects size + hash status.
    Writes results progressively to JSON so you can monitor progress or resume.

.PARAMETER SourcePaths
    One or more paths to scan (local or UNC).

.PARAMETER OutputFolder
    Where to write the JSON results.

.PARAMETER ChunkSize
    How many files to process before flushing results (default 300).

.EXAMPLE
    .\Syzygy-Scan-Inventory.ps1 -SourcePaths "\\ds1817\40TB Raid 0 B\Syzygy", "A:\Syzygy_A_Trier_FromOld_Ryzen7950" -OutputFolder "T:\SyzygyScan"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string[]]$SourcePaths,

    [Parameter(Mandatory=$true)]
    [string]$OutputFolder,

    [int]$ChunkSize = 300
)

$ErrorActionPreference = "Continue"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$tbcheck  = Join-Path $ScriptRoot "bin\tbcheck.exe"

if (-not (Test-Path $tbcheck)) {
    Write-Error "tbcheck.exe not found in bin\"
    exit 1
}

if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

$completionMarker = Join-Path $OutputFolder "SCAN_COMPLETED.txt"

Write-Host "=== Syzygy Inventory Scanner ===" -ForegroundColor Cyan
Write-Host "Sources      : $($SourcePaths -join ' | ')"
Write-Host "Output       : $OutputFolder"
Write-Host "Chunk size   : $ChunkSize"
Write-Host ""

$allResults = @{}

foreach ($source in $SourcePaths) {
    $safeName = ($source -replace '[\\/:*?"<>|]', '_')
    $jsonFile = Join-Path $OutputFolder "results_$safeName.json"

    Write-Host "Scanning: $source" -ForegroundColor Yellow

    if (-not (Test-Path $source)) {
        Write-Warning "  Path not accessible"
        continue
    }

    $files = Get-ChildItem -Path $source -Recurse -Include *.rtbw, *.rtbz -File -ErrorAction SilentlyContinue
    Write-Host "  Found $($files.Count) files"

    $local = @{}
    $processed = 0
    $lastFlush = 0

    foreach ($f in $files) {
        $base = $f.BaseName
        if (-not $local.ContainsKey($base)) {
            $local[$base] = @{
                Name = $base
                Source = $source
                WDL_Path = $null
                DTZ_Path = $null
                WDL_Size = 0
                DTZ_Size = 0
                WDL_Validated = $false
                DTZ_Validated = $false
                Scanned = (Get-Date).ToString("o")
            }
        }

        if ($f.Extension -eq ".rtbw") {
            $local[$base].WDL_Path = $f.FullName
            $local[$base].WDL_Size = $f.Length
        } else {
            $local[$base].DTZ_Path = $f.FullName
            $local[$base].DTZ_Size = $f.Length
        }

        $processed++

        if (($processed - $lastFlush) -ge $ChunkSize) {
            $local.Values | ConvertTo-Json -Depth 4 | Out-File -FilePath $jsonFile -Encoding UTF8
            $lastFlush = $processed
            Write-Host "  Progress flushed: $processed / $($files.Count)" -ForegroundColor DarkGray
        }
    }

    # Final validation pass
    Write-Host "  Running tbcheck validation..."
    foreach ($entry in $local.Values) {
        if ($entry.WDL_Path -and (Test-Path $entry.WDL_Path)) {
            $res = & $tbcheck $entry.WDL_Path 2>&1
            $entry.WDL_Validated = ($res -match 'OK')
        }
        if ($entry.DTZ_Path -and (Test-Path $entry.DTZ_Path)) {
            $res = & $tbcheck $entry.DTZ_Path 2>&1
            $entry.DTZ_Validated = ($res -match 'OK')
        }
    }

    # Final write
    $local.Values | ConvertTo-Json -Depth 4 | Out-File -FilePath $jsonFile -Encoding UTF8
    Write-Host "  Finished $source → $jsonFile" -ForegroundColor Green

    $allResults += $local
}

# Write master summary
$summary = @{
    Generated     = (Get-Date).ToString("o")
    TotalTables   = $allResults.Count
    Sources       = $SourcePaths
    ResultsFolder = $OutputFolder
}

$summary | ConvertTo-Json -Depth 3 | Out-File -FilePath (Join-Path $OutputFolder "summary.json") -Encoding UTF8

# Completion marker
"Scan completed at $(Get-Date)" | Out-File -FilePath $completionMarker -Encoding UTF8

Write-Host "`n=== SCAN FINISHED ===" -ForegroundColor Green
Write-Host "Total unique tables found: $($allResults.Count)"
Write-Host "Completion marker: $completionMarker"
Write-Host "You can now run the report generator using the JSON files in $OutputFolder"