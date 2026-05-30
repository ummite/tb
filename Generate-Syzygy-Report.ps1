<#
.SYNOPSIS
    Generates a Syzygy Inventory Report (.md) at the root of a target Syzygy folder.

.DESCRIPTION
    Creates a clean executive summary report including:
    - Overall statistics
    - Validation status (tbcheck pass/fail) for every table
    - Cross-check against official checksums/ documentation
    - Known generation timings from logs/ (for work done on this computer)
    - Special section for the 5 critical 7pc tables (KBBBBvKR etc.)

    Run this after consolidation to document the final state.

.PARAMETER TargetPath
    Path to the root of the final Syzygy folder (e.g. \\ds1817\40TB Raid 0 B\Syzygy or T:\Syzygy)

.PARAMETER OutputFile
    Name of the report file to create inside TargetPath (default: Syzygy-Inventory-Report.md)

.EXAMPLE
    .\Generate-Syzygy-Report.ps1 -TargetPath "\\ds1817\40TB Raid 0 B\Syzygy"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$TargetPath,

    [string]$OutputFile = "Syzygy-Inventory-Report.md"
)

$ErrorActionPreference = "Continue"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$tbcheck  = Join-Path $ScriptRoot "bin\tbcheck.exe"
$checksumDir = Join-Path $ScriptRoot "checksums"
$logsDir    = Join-Path $ScriptRoot "logs"

if (-not (Test-Path $tbcheck)) {
    Write-Error "tbcheck.exe not found. Build the project first."
    exit 1
}

$TargetPath = (Resolve-Path $TargetPath).Path
$reportPath = Join-Path $TargetPath $OutputFile

Write-Host "Generating Syzygy Inventory Report for: $TargetPath"
Write-Host "Output: $reportPath"

# Load official checksum references
function Get-ExpectedHashes {
    param([string]$Type) # "wdl" or "dtz"
    $result = @{}
    $files = Get-ChildItem $checksumDir -Filter "$Type*.txt" -File
    foreach ($f in $files) {
        $content = Get-Content $f.FullName
        foreach ($line in $content) {
            if ($line -match '^([^:]+)\.rtb[zw]:\s*([0-9a-f]+)') {
                $name = $matches[1]
                $hash = $matches[2]
                if (-not $result.ContainsKey($name)) {
                    $result[$name] = @{}
                }
                $result[$name][$Type] = $hash
            }
        }
    }
    return $result
}

$expected = Get-ExpectedHashes -Type "wdl"
$dtzExpected = Get-ExpectedHashes -Type "dtz"

# Find all tables in target
$allTables = @{}
Get-ChildItem $TargetPath -Recurse -Include *.rtbw,*.rtbz -File -ErrorAction SilentlyContinue | ForEach-Object {
    $base = $_.BaseName
    if (-not $allTables.ContainsKey($base)) {
        $allTables[$base] = @{ WDL = $null; DTZ = $null; Path = $_.DirectoryName }
    }
    if ($_.Extension -eq ".rtbw") {
        $allTables[$base].WDL = $_.FullName
    } else {
        $allTables[$base].DTZ = $_.FullName
    }
}

# Validate with tbcheck
$validated = @{}
$totalValidated = 0
$totalInvalid = 0

foreach ($name in $allTables.Keys) {
    $entry = $allTables[$name]
    $wOk = $false
    $zOk = $false

    if ($entry.WDL) {
        $res = & $tbcheck $entry.WDL 2>&1
        $wOk = $res -match 'OK'
    }
    if ($entry.DTZ) {
        $res = & $tbcheck $entry.DTZ 2>&1
        $zOk = $res -match 'OK'
    }

    $validated[$name] = @{
        WDL_Ok = $wOk
        DTZ_Ok = $zOk
        BothOk = $wOk -and $zOk
        Location = $entry.Path
    }

    if ($wOk -and $zOk) { $totalValidated++ }
    elseif ($wOk -or $zOk) { $totalInvalid++ }  # partial
}

# Count by piece number (rough)
$byPieces = @{}
foreach ($name in $allTables.Keys) {
    $pc = ($name -replace 'v','' -replace '[^KQRBNP]','').Length
    if (-not $byPieces.ContainsKey($pc)) { $byPieces[$pc] = 0 }
    $byPieces[$pc]++
}

# Helper: Try to find generation duration for a specific table from logs
function Get-GenerationDuration {
    param([string]$TableName)
    if (-not (Test-Path $logsDir)) { return $null }
    
    $logs = Get-ChildItem $logsDir -Filter "*$TableName*.log" -File -ErrorAction SilentlyContinue
    if (-not $logs) { return $null }
    
    foreach ($log in $logs) {
        $content = Get-Content $log.FullName -ErrorAction SilentlyContinue
        $durationLine = $content | Select-String -Pattern "time taken|elapsed|took|duration|finished in" -SimpleMatch | Select-Object -Last 1
        if ($durationLine) {
            return "See $($log.Name): $($durationLine.Line.Trim())"
        }
    }
    return "Generated (log exists: $($logs[0].Name)) - duration not clearly recorded"
}

# Known generations from logs (this computer) - for summary section
$knownGenerations = @()
if (Test-Path $logsDir) {
    Get-ChildItem $logsDir -Filter "*_*.log" -File | ForEach-Object {
        $logName = $_.BaseName
        if ($logName -match '^(K[A-Z0-9v]+)_.*_(\d+pc)') {
            $table = $matches[1]
            $pc = $matches[2]
            $durationNote = Get-GenerationDuration -TableName $table
            $knownGenerations += [pscustomobject]@{
                Table = $table
                Pieces = $pc
                Log = $_.Name
                DurationNote = $durationNote
            }
        }
    }
}

# Special 5 tables status
$special5 = @("KBBBBvKR","KBBBNvKN","KBBNNvKN","KBNPvKRB","KBNPvKRN")
$specialStatus = @()
foreach ($t in $special5) {
    $hasEntry = $allTables.ContainsKey($t)
    $val = if ($hasEntry) { $validated[$t] } else { $null }
    $genTime = Get-GenerationDuration -TableName $t
    if (-not $genTime) { $genTime = "Unknown (not generated on this computer or no log)" }
    
    $specialStatus += [pscustomobject]@{
        Table = $t
        Present = $hasEntry
        WDL_Validated = if ($hasEntry) { $val.WDL_Ok } else { $false }
        DTZ_Validated = if ($hasEntry) { $val.DTZ_Ok } else { $false }
        Both_Validated = if ($hasEntry) { $val.BothOk } else { $false }
        ExpectedInChecksums = $expected.ContainsKey($t) -or $dtzExpected.ContainsKey($t)
        GenerationTime = $genTime
    }
}

# Group all tables for detailed inventory (by piece count + pawn/pawnless)
$groupedTables = @{}
foreach ($name in ($allTables.Keys | Sort-Object)) {
    $letters = $name -replace 'v','' -replace '[^KQRBNP]',''
    $pc = $letters.Length
    if ($pc -lt 3 -or $pc -gt 7) { continue }

    $hasPawn = $name -match 'P'
    $groupKey = "$pc-Piece"
    $subKey = if ($hasPawn) { "Pawnful" } else { "Pawnless" }

    if (-not $groupedTables.ContainsKey($groupKey)) {
        $groupedTables[$groupKey] = @{ Pawnless = @(); Pawnful = @() }
    }

    $val = $validated[$name]
    $genTime = Get-GenerationDuration -TableName $name
    if (-not $genTime) { $genTime = "Unknown (not generated on this computer or no log)" }

    $entry = [pscustomobject]@{
        Name = $name
        WDL_Ok = if ($val) { $val.WDL_Ok } else { $false }
        DTZ_Ok = if ($val) { $val.DTZ_Ok } else { $false }
        Both_Ok = if ($val) { $val.BothOk } else { $false }
        GenerationTime = $genTime
    }

    if ($subKey -eq "Pawnless") {
        $groupedTables[$groupKey].Pawnless += $entry
    } else {
        $groupedTables[$groupKey].Pawnful += $entry
    }
}

# Build the report
$reportLines = @()
$reportLines += "# Syzygy Inventory Report"
$reportLines += ""
$reportLines += "**Generated on:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$reportLines += "**Target Folder:** $TargetPath"
$reportLines += "**Report generated from:** This computer"
$reportLines += ""
$reportLines += "> **Note on Generation Times**:  "
$reportLines += "> Most tables were imported/copied from SAN or other drives.  "
$reportLines += "> Generation time is only known when a log exists in the logs/ folder from a run on *this computer*.  "
$reportLines += "> Everything else is marked **Unknown (not generated on this computer or no log available)**."
$reportLines += ""

# Special 5 section
$reportLines += "## Special 7-Piece Tables (Priority Goal)"
$reportLines += ""
$reportLines += "These 5 tables were requested for re-creation:"
$reportLines += ""
$reportLines += "| Table | Present | WDL | DTZ | Both OK | In Checksums | Generation Time |"
$reportLines += "|-------|---------|-----|-----|---------|--------------|-----------------|"

foreach ($s in $specialStatus) {
    $pres = if ($s.Present) { "[x]" } else { "[ ]" }
    $w    = if ($s.WDL_Validated) { "[x]" } else { "[ ]" }
    $z    = if ($s.DTZ_Validated) { "[x]" } else { "[ ]" }
    $both = if ($s.Both_Validated) { "[x]" } else { "[ ]" }
    $exp  = if ($s.ExpectedInChecksums) { "[x]" } else { "[ ]" }
    $reportLines += "| $($s.Table) | $pres | $w | $z | $both | $exp | $($s.GenerationTime) |"
}

$reportLines += ""
$reportLines += "## Detailed Inventory by Piece Count"
$reportLines += ""
$reportLines += "Grouped by piece count → Pawnless / Pawnful → sorted alphabetically."
$reportLines += "Generation time = Unknown unless a log was found."

foreach ($pc in 3..7) {
    $groupKey = "$pc-Piece"
    if (-not $groupedTables.ContainsKey($groupKey)) { continue }

    $reportLines += ""
    $reportLines += "### $groupKey Tables"

    foreach ($sub in @("Pawnless", "Pawnful")) {
        $list = $groupedTables[$groupKey][$sub]
        if (-not $list -or $list.Count -eq 0) { continue }

        $header = if ($sub -eq "Pawnless") { "Pawnless (no P)" } else { "Pawnful (contains P)" }
        $reportLines += ""
        $reportLines += "#### $header"
        $reportLines += "| Table | WDL | DTZ | Both OK | Generation Time |"
        $reportLines += "|-------|-----|-----|---------|-----------------|"

        foreach ($item in $list) {
            $w = if ($item.WDL_Ok) { "[x]" } else { "[ ]" }
            $z = if ($item.DTZ_Ok) { "[x]" } else { "[ ]" }
            $both = if ($item.Both_Ok) { "[x]" } else { "[ ]" }
            $reportLines += "| $($item.Name) | $w | $z | $both | $($item.GenerationTime) |"
        }
    }
}

# Final report assembly (clean single write)
$finalReport = $reportLines -join "`n"
$finalReport | Out-File -FilePath $reportPath -Encoding UTF8 -Force

Write-Host "Report written to: $reportPath" -ForegroundColor Green

# Console summary
Write-Host "`n=== Special 5 Tables Status ===" -ForegroundColor Cyan
$specialStatus | Select Table, Present, Both_Validated, GenerationTime | Format-Table -AutoSize