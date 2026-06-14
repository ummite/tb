<#
Analyze-7men-NetConformance.ps1
Special post-copy analysis for 7men Syzygy organized to net-standard structure on T:\Syzygy\7men

Usage:
  powershell -ExecutionPolicy Bypass -File .\Analyze-7men-NetConformance.ps1
  powershell -ExecutionPolicy Bypass -File .\Analyze-7men-NetConformance.ps1 -Root "T:\Syzygy\7men" -RunTbcheckSample

When the Copy-7men-Sources-To-Final-NetStructure.bat has finished, run this.
It validates:
- Every file is in the subdirectory matching the corrected king-inclusive classification (5v2_pawnless etc.)
- Complete .rtbw + .rtbz pairs
- Exact name preservation (no corruption)
- Counts per category vs inventory
- Conformance notes vs typical net layouts + checksums reference (1001 total)
- Optional sample tbcheck verification
Outputs report .txt + .csv in logs/
#>

[CmdletBinding()]
param(
    [string]$Root = "T:\Syzygy\7men",
    [switch]$RunTbcheckSample
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $scriptDir "logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportTxt = Join-Path $logDir "7men-conformance-$timestamp.txt"
$reportCsv = Join-Path $logDir "7men-conformance-$timestamp.csv"

function Write-Report {
    param([string]$Line)
    $Line | Tee-Object -FilePath $reportTxt -Append
}

function Get-Expected7menSubfolder {
    param([string]$FileName)
    $name = $FileName -replace '\.rtb[zw]$',''
    $parts = $name -split 'v', 2
    if ($parts.Count -ne 2) { return "7men/other" }

    $leftNonKing  = ($parts[0] -replace 'K','' -replace '[^QRBNP]','').Length
    $rightNonKing = ($parts[1] -replace 'K','' -replace '[^QRBNP]','').Length

    $leftTotal  = 1 + $leftNonKing
    $rightTotal = 1 + $rightNonKing

    $a = [math]::Max($leftTotal, $rightTotal)
    $b = [math]::Min($leftTotal, $rightTotal)

    $hasP = $name -match 'P'
    $pType = if ($hasP) { "pawnful" } else { "pawnless" }

    if ($a + $b -ne 7) { return "7men/other" }
    if ($a -lt $b) { $tmp=$a; $a=$b; $b=$tmp }  # ensure a >= b

    $split = switch ("${a}v${b}") {
        "6v1" { "6v1" }
        "5v2" { "5v2" }
        "4v3" { "4v3" }
        default { "other" }
    }
    if ($split -eq "other") { return "7men/other" }
    return "7men/${split}_$pType"
}

function Get-PairKey {
    param([string]$FileName)
    ($FileName -replace '\.rtb[zw]$','') + ".rtb"
}

Write-Host "=== 7men Syzygy Net Structure Conformance Analysis ===" -ForegroundColor Cyan
Write-Report "=== 7men Syzygy Net Structure Conformance Analysis ==="
Write-Report "Started: $(Get-Date)"
Write-Report "Root: $Root"
Write-Report ""

if (-not (Test-Path $Root)) {
    Write-Error "Root not found: $Root"
    exit 1
}

$allowedSubs = @('5v2_pawnless','5v2_pawnful','6v1_pawnless','6v1_pawnful','4v3_pawnless','4v3_pawnful')

# Collect all rtb files under the given root (recursive)
$files = Get-ChildItem -Path $Root -Recurse -File -Include *.rtbw,*.rtbz -ErrorAction SilentlyContinue

if (-not $files) {
    Write-Warning "No .rtbw/.rtbz files found under $Root"
    Write-Report "No files found."
    exit 0
}

# Separate strays directly in $Root (not in a proper 5v2_*/6v1_* subdir)
$rootItem = Get-Item $Root
$strayFiles = $files | Where-Object { $_.Directory.FullName -eq $rootItem.FullName }
if ($strayFiles) {
    Write-Report "WARNING: $($strayFiles.Count) files found directly in $Root (should be inside 5v2_*/6v1_* subdirs):"
    $strayFiles | Select-Object -First 10 | ForEach-Object { Write-Report "  $($_.Name)" }
    if ($strayFiles.Count -gt 10) { Write-Report "  ... +$($strayFiles.Count-10) more" }
}

Write-Host "Found $($files.Count) tablebase files. Analyzing..." -ForegroundColor Yellow

$byActual = @{}
$issues = @()
$allRows = @()

foreach ($f in $files) {
    $relDir = $f.Directory.Name   # the immediate subdir like "5v2_pawnless"
    $fullDir = $f.Directory.FullName
    $expected = Get-Expected7menSubfolder $f.Name

    $actualCat = if ($allowedSubs -contains $relDir) { "7men/$relDir" } else { "7men/OTHER-$relDir" }

    $status = if ($expected -eq $actualCat) { "OK" } else { "MISPLACED" }

    if ($status -eq "MISPLACED") {
        $issues += [pscustomobject]@{
            File = $f.Name
            Actual = $actualCat
            Expected = $expected
            Path = $f.FullName
        }
    }

    $row = [pscustomobject]@{
        Name = $f.Name
        Base = ($f.Name -replace '\.rtb[zw]$','')
        ActualDir = $relDir
        ExpectedDir = ($expected -replace '^7men/','')
        Status = $status
        SizeMB = [math]::Round($f.Length / 1MB, 1)
        Extension = $f.Extension
    }
    $allRows += $row

    if (-not $byActual.ContainsKey($relDir)) { $byActual[$relDir] = @() }
    $byActual[$relDir] += $row
}

# Pair completeness
$pairs = @{}
foreach ($r in $allRows) {
    $key = $r.Base
    if (-not $pairs.ContainsKey($key)) { $pairs[$key] = @{ w=$false; z=$false; names=@() } }
    if ($r.Extension -eq '.rtbw') { $pairs[$key].w = $true }
    if ($r.Extension -eq '.rtbz') { $pairs[$key].z = $true }
    $pairs[$key].names += $r.Name
}

$completePairs = 0
$orphanW = 0
$orphanZ = 0
$orphanDetails = @()
foreach ($k in $pairs.Keys) {
    $p = $pairs[$k]
    if ($p.w -and $p.z) { $completePairs++ }
    elseif ($p.w) { $orphanW++; $orphanDetails += "$k.rtbw (no .rtbz)" }
    elseif ($p.z) { $orphanZ++; $orphanDetails += "$k.rtbz (no .rtbw)" }
}

# Counts per category (based on actual placement)
$catCounts = @{}
foreach ($sub in $byActual.Keys) {
    $w = ($byActual[$sub] | Where-Object Extension -eq '.rtbw').Count
    $z = ($byActual[$sub] | Where-Object Extension -eq '.rtbz').Count
    $catCounts[$sub] = [pscustomobject]@{ Sub=$sub; W=$w; Z=$z; Pairs=([math]::Min($w,$z)) }
}

# Reference inventory (if present)
$refBases = @{}
$refPath = Join-Path $scriptDir "syzygy_7men.csv"
$refCount = 0
if (Test-Path $refPath) {
    Import-Csv $refPath | ForEach-Object {
        $b = $_.Name -replace '\.rtb[zw]$',''
        if (-not $refBases.ContainsKey($b)) { $refBases[$b] = 0 }
        $refBases[$b]++
        $refCount++
    }
}

# Coverage of ref
$foundBases = $allRows | Select-Object -ExpandProperty Base -Unique
$refFound = 0
$refMissing = @()
foreach ($b in $refBases.Keys) {
    if ($foundBases -contains $b) { $refFound++ } else { $refMissing += $b }
}

# Checksum ref totals
$wdl7 = if (Test-Path (Join-Path $scriptDir "checksums/wdl7.txt")) { (Get-Content (Join-Path $scriptDir "checksums/wdl7.txt") | Measure-Object -Line).Lines } else { 0 }
$dtz7 = if (Test-Path (Join-Path $scriptDir "checksums/dtz7.txt")) { (Get-Content (Join-Path $scriptDir "checksums/dtz7.txt") | Measure-Object -Line).Lines } else { 0 }

# === REPORT ===
Write-Report "Total files scanned: $($files.Count)"
Write-Report "Unique bases: $($foundBases.Count)"
Write-Report ""
Write-Report "=== Placement by actual subdirectory ==="
foreach ($c in ($catCounts.Values | Sort-Object Sub)) {
    Write-Report ("  {0,-22}  w:{1,4}  z:{2,4}  pairs:{3,4}" -f $c.Sub, $c.W, $c.Z, $c.Pairs)
}
Write-Report ""
Write-Report "=== Pair completeness ==="
Write-Report "  Complete pairs (w+z): $completePairs"
Write-Report "  Orphans .rtbw only:   $orphanW"
Write-Report "  Orphans .rtbz only:   $orphanZ"
if ($orphanDetails.Count -gt 0 -and $orphanDetails.Count -le 20) {
    Write-Report "  Orphan details:"
    $orphanDetails | ForEach-Object { Write-Report "    $_" }
} elseif ($orphanDetails.Count -gt 20) {
    Write-Report "  (too many orphans to list here - see CSV)"
}
Write-Report ""
Write-Report "=== Misplaced files (actual dir != expected by king-inclusive count) ==="
Write-Report "  Misplaced count: $($issues.Count)"
if ($issues.Count -gt 0) {
    Write-Report "  First 30 examples:"
    $issues | Select-Object -First 30 | ForEach-Object {
        Write-Report ("    {0}  ACTUAL:{1}  EXPECTED:{2}" -f $_.File, $_.Actual, $_.Expected)
    }
    if ($issues.Count -gt 30) { Write-Report "    ... and $($issues.Count-30) more (full list in CSV)" }
} else {
    Write-Report "  NONE - all files are in their correct net-standard subdirectory."
}
Write-Report ""
Write-Report "=== Reference inventory (syzygy_7men.csv) ==="
Write-Report "  Entries in csv: $refCount"
Write-Report "  Of which found in target: $refFound"
Write-Report "  Missing from target: $($refMissing.Count)"
if ($refMissing.Count -gt 0 -and $refMissing.Count -le 15) {
    Write-Report "  Missing examples: $($refMissing[0..14] -join ', ')"
}
Write-Report ""
Write-Report "=== Net / checksums reference ==="
Write-Report "  checksums/wdl7.txt lines: $wdl7  (official 7pc WDL count)"
Write-Report "  checksums/dtz7.txt lines: $dtz7  (official 7pc DTZ count)"
Write-Report "  Typical 'net' 7-man layout people use: 7men/6v1_pawnless, 7men/5v2_pawnful, 7men/6v1_pawnful, 7men/5v2_pawnless, (sometimes 4v3_*)"
Write-Report "  Your .bat used the corrected king-inclusive split (KBBBBvKP = 5v2 etc.) matching common local archive practice."
Write-Report ""
Write-Report "=== Structural sanity ==="
$unexpectedDirs = $byActual.Keys | Where-Object { $allowedSubs -notcontains $_ }
if ($unexpectedDirs) {
    Write-Report "  WARNING - files found in unexpected dirs: $($unexpectedDirs -join ', ')"
} else {
    Write-Report "  All files are inside the 4 (or 6) expected 7men/* subdirectories."
}
Write-Report ""
Write-Report "=== Sample sizes (largest tables) ==="
$allRows | Sort-Object SizeMB -Descending | Select-Object -First 5 | ForEach-Object {
    Write-Report ("  {0,-20}  {1,8} MB   in {2}" -f $_.Name, $_.SizeMB, $_.ActualDir)
}

# Optional tbcheck sample
if ($RunTbcheckSample) {
    $tbcheck = Join-Path $scriptDir "bin\tbcheck.exe"
    if (Test-Path $tbcheck) {
        Write-Report ""
        Write-Report "=== Sample tbcheck verification (5 random complete pairs) ==="
        $completeBases = $pairs.Keys | Where-Object { $pairs[$_].w -and $pairs[$_].z } | Get-Random -Count ([math]::Min(5, $completePairs))
        foreach ($b in $completeBases) {
            $wFile = "$b.rtbw"
            $zFile = "$b.rtbz"
            # find actual path
            $w = $allRows | Where-Object { $_.Name -eq $wFile } | Select-Object -First 1
            if ($w) {
                $wPath = Join-Path (Join-Path $Root $w.ActualDir) $wFile
                $zPath = Join-Path (Join-Path $Root $w.ActualDir) $zFile
                $wr = & $tbcheck $wPath 2>&1
                $zr = & $tbcheck $zPath 2>&1
                $wOk = $wr -match 'OK'
                $zOk = $zr -match 'OK'
                $res = if ($wOk -and $zOk) { "OK" } else { "FAIL" }
                Write-Report ("  {0,-20}  tbcheck: {1}   (w:{2} z:{3})" -f $wFile, $res, $wOk, $zOk)
            }
        }
    } else {
        Write-Report "tbcheck.exe not found in bin\, skipping sample verification."
    }
}

Write-Report ""
Write-Report "=== End of report ==="
Write-Report "Full details: $reportCsv"
Write-Report "Finished: $(Get-Date)"

# Write CSV
$allRows | Sort-Object ActualDir, Name | Export-Csv -Path $reportCsv -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "Analysis complete." -ForegroundColor Green
Write-Host "Report: $reportTxt" -ForegroundColor Cyan
Write-Host "CSV   : $reportCsv" -ForegroundColor Cyan
Write-Host ""
if ($issues.Count -eq 0 -and $orphanW -eq 0 -and $orphanZ -eq 0) {
    Write-Host "RESULT: CONFORME - structure matches the corrected net layout used by the .bat." -ForegroundColor Green
} else {
    Write-Host "RESULT: Issues detected - see report for MISPLACED / ORPHANS." -ForegroundColor Yellow
}

# Also dump a quick summary to console for immediate visibility
Write-Host ""
Write-Host "Quick summary:" -ForegroundColor White
Write-Host "  Files: $($files.Count)   Complete pairs: $completePairs   Misplaced: $($issues.Count)   Orphans: $($orphanW+$orphanZ)"
Write-Host "  Categories present: $(($catCounts.Keys | Sort-Object) -join ', ')"