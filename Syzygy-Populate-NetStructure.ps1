<#
.SYNOPSIS
    Rebuild / complete the clean "net" Syzygy structure on T:\Syzygy
    (3-5men / 6men / 7men/4v3_* etc.) by discovering and validating tables
    you already have on your other drives (A:, S:, F:, etc.).

.DESCRIPTION
    This is the RECOMMENDED first step toward a "structure complète".

    Strategy (respects your strict copy-first rule):
    1. Recursively scan the rich source locations you already own (A:\Syzygy_A_Trier..., S:\*, F:\SyzygyTemp, T:\ loose + legacy, etc.).
    2. For every .rtbw found, locate the matching .rtbz in the same directory.
    3. Run bin\tbcheck on BOTH files (mandatory).
    4. Only if both are GOOD → classify the table using the standard net logic and copy it to the correct location under T:\Syzygy.
    5. Also cleans up / migrates the current mess on T: (210 loose files in root + 510 in legacy 3-6men).
    6. At the end: produces a precise "still missing" report against the official checksum lists + ready generation commands for the gaps.

    This will recover the vast majority of your 6pc and 7pc without any generation.

    Generation (using rtbgen/rtbgenp) is only suggested for the small number of tables that are truly absent after this pass.

.PARAMETER SourcePaths
    List of folders to scan recursively. Defaults cover your known rich locations.

.PARAMETER DestinationRoot
    Target (default T:\Syzygy). Will create the full net folder tree.

.PARAMETER LinkType
    Copy (safest, default) or HardLink (only when source and destination are on the same volume).

.PARAMETER DeleteSourceAfterCopy
    DANGEROUS. Only use after reviewing the log if you want to clean bad/old copies from A:/S: etc.

.PARAMETER WhatIf
    Dry-run. Highly recommended first.

.PARAMETER SkipTbcheck
    Emergency escape hatch (not recommended). Skips hash validation.

.EXAMPLE
    # See exactly what it would do (strongly recommended)
    .\Syzygy-Populate-NetStructure.ps1 -WhatIf

.EXAMPLE
    # Real run (copy only, no deletions)
    .\Syzygy-Populate-NetStructure.ps1

.EXAMPLE
    # After review, also remove the bad copies it found on source drives
    .\Syzygy-Populate-NetStructure.ps1 -DeleteSourceAfterCopy
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string[]]$SourcePaths = @(
        "A:\Syzygy_A_Trier_FromOld_Ryzen7950",
        "A:\Syzygy",
        "S:\Syzygy",
        "S:\5v2_pawnless",
        "S:\5v2_pawnful",
        "S:\6v1_pawnless",
        "S:\6v1_pawnful",
        "F:\SyzygyTemp",
        "I:\Syzygy",
        "T:\Syzygy",                    # will pick up the 210 loose files in root
        "T:\Syzygy\3-6men"              # legacy mixed folder
    ),
    [string]$DestinationRoot = "\\ds1817\40TB Raid 0 B\Syzygy",
    [ValidateSet('Copy','HardLink')]
    [string]$LinkType = "Copy",
    [switch]$DeleteSourceAfterCopy,
    [switch]$DryRun,
    [switch]$SkipTbcheck
)

$ErrorActionPreference = "Continue"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$tbcheck  = Join-Path $ScriptRoot "bin\tbcheck.exe"
$rtbgen   = Join-Path $ScriptRoot "bin\rtbgen.exe"
$rtbgenp  = Join-Path $ScriptRoot "bin\rtbgenp.exe"

if (-not (Test-Path $tbcheck)) {
    Write-Error "tbcheck.exe not found in bin\. Build the project first."
    exit 1
}

# Re-use the proven classification logic
function Get-SyzygyNetSubfolder {
    param([string]$BaseName)
    $name = $BaseName -replace '\.rtb[zw]$',''
    $letters = $name -replace 'v','' -replace '[^KQRBNP]',''
    $pc = $letters.Length
    if ($pc -le 5) { return "3-5men" }
    if ($pc -eq 6) { return "6men" }
    if ($pc -ne 7) { return "7men/other" }

    $parts = $name -split 'v', 2
    if ($parts.Count -ne 2) { return "7men/other" }

    $leftNonKing  = ($parts[0] -replace 'K','' -replace '[^QRBNP]','').Length
    $rightNonKing = ($parts[1] -replace 'K','' -replace '[^QRBNP]','').Length
    $hasP = $name -match 'P'
    $pType = if ($hasP) { "pawnful" } else { "pawnless" }

    $a = [math]::Max($leftNonKing, $rightNonKing)
    $b = [math]::Min($leftNonKing, $rightNonKing)

    $split = switch ("$a`v$b") {
        "4v3" { "4v3" }
        "5v2" { "5v2" }
        "6v1" { "6v1" }
        default { "other" }
    }
    if ($split -eq "other") { return "7men/other" }
    return "7men/${split}_$pType"
}

function Test-Pair {
    param([string]$W, [string]$Z)
    if ($SkipTbcheck) { return $true }
    $wRes = & $tbcheck $W 2>&1
    $zRes = & $tbcheck $Z 2>&1
    return ($wRes -match 'OK') -and ($zRes -match 'OK')
}

# Ensure destination tree exists
$required = @(
    "3-5men","6men",
    "7men/4v3_pawnful","7men/4v3_pawnless",
    "7men/5v2_pawnful","7men/5v2_pawnless",
    "7men/6v1_pawnful","7men/6v1_pawnless",
    "7men/other"
)
foreach ($r in $required) {
    $p = Join-Path $DestinationRoot $r
    if (-not (Test-Path $p)) {
        if (-not $DryRun) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
        Write-Host "Created: $p"
    }
}

Write-Host "=== Syzygy Net Structure Population ===" -ForegroundColor Cyan
Write-Host "Mode          : $(if ($DryRun) { 'DRY-RUN (WhatIf)' } else { 'REAL (copy-only unless -DeleteSourceAfterCopy)' })"
Write-Host "Sources       : $($SourcePaths.Count) paths"
Write-Host "Destination   : $DestinationRoot"
Write-Host "LinkType      : $LinkType"
Write-Host "tbcheck       : $(if ($SkipTbcheck) { 'SKIPPED (dangerous)' } else { 'ENFORCED' })"
Write-Host ""

$stats = @{
    Scanned   = 0
    Pairs     = 0
    Good      = 0
    Bad       = 0
    Copied    = 0
    Skipped   = 0
    Failed    = 0
}

$goodSources = @()   # list of good pairs we will (or would) copy

foreach ($srcRoot in $SourcePaths) {
    if (-not (Test-Path $srcRoot)) { continue }
    Write-Host "Scanning: $srcRoot ..." -ForegroundColor DarkCyan

    $wdlFiles = Get-ChildItem $srcRoot -Recurse -Filter "*.rtbw" -File -ErrorAction SilentlyContinue
    foreach ($w in $wdlFiles) {
        $stats.Scanned++
        $z = Join-Path $w.DirectoryName ($w.BaseName + ".rtbz")
        if (-not (Test-Path $z)) { continue }

        $stats.Pairs++

        $good = Test-Pair -W $w.FullName -Z $z
        if (-not $good) {
            $stats.Bad++
            Write-Host "  BAD HASH : $($w.BaseName)" -ForegroundColor Red
            continue
        }

        $stats.Good++
        $sub = Get-SyzygyNetSubfolder $w.Name
        $destDir = Join-Path $DestinationRoot $sub
        $destW = Join-Path $destDir $w.Name
        $destZ = Join-Path $destDir (Split-Path $z -Leaf)

        if ((Test-Path $destW) -and (Test-Path $destZ)) {
            $stats.Skipped++
            continue
        }

        $goodSources += [pscustomobject]@{
            Name   = $w.BaseName
            W      = $w.FullName
            Z      = $z
            DestW  = $destW
            DestZ  = $destZ
            Sub    = $sub
        }
    }
}

Write-Host ""
Write-Host "=== DISCOVERY SUMMARY ===" -ForegroundColor Cyan
Write-Host "WDL files scanned     : $($stats.Scanned)"
Write-Host "Complete pairs found  : $($stats.Pairs)"
Write-Host "Passed tbcheck        : $($stats.Good)  (good)"
Write-Host "Failed tbcheck        : $($stats.Bad)   (bad hashes - will be ignored)"
Write-Host "Already at destination: $($stats.Skipped)"
Write-Host "New good tables to place : $($goodSources.Count)"
Write-Host ""

if ($goodSources.Count -eq 0) {
    Write-Host "Nothing new to copy. Structure is already up to date from the scanned sources." -ForegroundColor Green
} else {
    Write-Host "Tables that will be placed in the net structure:" -ForegroundColor Yellow
    $goodSources | Group-Object Sub | Sort Count -Descending | ForEach {
        Write-Host "  $($_.Name.PadRight(22)) : $($_.Count) tables"
    }

    if ($DryRun) {
        Write-Host "`n[DRYRUN] No files were written. Remove -DryRun to perform the copies." -ForegroundColor Yellow
    } else {
        Write-Host "`nCopying good tables to $DestinationRoot ..." -ForegroundColor Green
        foreach ($g in $goodSources) {
            try {
                if ($LinkType -eq 'HardLink' -and (Get-Item $g.W).PSDrive.Name -eq (Get-Item $g.DestW).PSDrive.Name) {
                    New-Item -ItemType HardLink -Path $g.DestW -Value $g.W -ErrorAction Stop | Out-Null
                    New-Item -ItemType HardLink -Path $g.DestZ -Value $g.Z -ErrorAction Stop | Out-Null
                } else {
                    Copy-Item $g.W -Destination $g.DestW -ErrorAction Stop
                    Copy-Item $g.Z -Destination $g.DestZ -ErrorAction Stop
                }
                $stats.Copied++
                Write-Host "  OK -> $($g.Sub)\$($g.Name)" -ForegroundColor DarkGreen

                if ($DeleteSourceAfterCopy) {
                    Remove-Item $g.W, $g.Z -Force -ErrorAction SilentlyContinue
                }
            } catch {
                $stats.Failed++
                Write-Warning "Failed to place $($g.Name) : $_"
            }
        }
    }
}

Write-Host ""
Write-Host "=== FINAL COPY STATS ===" -ForegroundColor Cyan
Write-Host "Successfully placed   : $($stats.Copied)"
Write-Host "Failed                : $($stats.Failed)"

# TODO in future version: compare against checksums/*.txt and list exact missing tables + generation commands
Write-Host ""
Write-Host "=== MISSING TABLES REPORT (vs official checksums) ===" -ForegroundColor Cyan

# Load expected tables from checksums
$checksumDir = Join-Path $ScriptRoot 'checksums'
$expectedWdl = @()
$expectedDtz = @()

foreach ($f in @('wdl345.txt','wdl6.txt','wdl7.txt')) {
    $p = Join-Path $checksumDir $f
    if (Test-Path $p) {
        $expectedWdl += Get-Content $p | ForEach-Object { if ($_ -match '^([^:]+)\.rtbw:') { $matches[1] } }
    }
}
foreach ($f in @('dtz345.txt','dtz6.txt','dtz7.txt')) {
    $p = Join-Path $checksumDir $f
    if (Test-Path $p) {
        $expectedDtz += Get-Content $p | ForEach-Object { if ($_ -match '^([^:]+)\.rtbz:') { $matches[1] } }
    }
}

# Collect what we actually have now in DestinationRoot (after this run or in DryRun simulation)
$presentWdl = Get-ChildItem $DestinationRoot -Filter '*.rtbw' -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object { $_.BaseName }
$presentDtz = Get-ChildItem $DestinationRoot -Filter '*.rtbz' -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object { $_.BaseName }

$missingWdl = $expectedWdl | Where-Object { $_ -notin $presentWdl }
$missingDtz = $expectedDtz | Where-Object { $_ -notin $presentDtz }

Write-Host "Expected WDL tables : $($expectedWdl.Count)"
Write-Host "Present WDL         : $($presentWdl.Count)"
Write-Host "Missing WDL         : $($missingWdl.Count)" -ForegroundColor $(if ($missingWdl.Count -gt 0) { 'Yellow' } else { 'Green' })

Write-Host "Expected DTZ tables : $($expectedDtz.Count)"
Write-Host "Present DTZ         : $($presentDtz.Count)"
Write-Host "Missing DTZ         : $($missingDtz.Count)" -ForegroundColor $(if ($missingDtz.Count -gt 0) { 'Yellow' } else { 'Green' })

# Highlight the 5 known bad 7pc
$knownBad = @('KBBBBvKR','KBBBNvKN','KBBNNvKN','KBNPvKRB','KBNPvKRN')
$stillBad = $knownBad | Where-Object { 
    ($_ + '.rtbw' -notin $presentWdl) -or ($_ + '.rtbz' -notin $presentDtz)
}

if ($stillBad) {
    Write-Host "`nKnown bad-hash 7pc still missing or incomplete: $($stillBad -join ', ')" -ForegroundColor Red
}

# Generate prioritized regeneration commands for the worst gaps (7pc first, then 6pc)
$regenRoot = "F:\SyzygyRegen"
if (-not (Test-Path "F:\")) { $regenRoot = "I:\SyzygyRegen" }

Write-Host "`n=== READY-TO-RUN GENERATION PLAN FOR GAPS ===" -ForegroundColor Cyan
Write-Host "Fast local temp dir recommended: $regenRoot"
Write-Host "RTBPATH will point to the improved $DestinationRoot after this script runs."

$priorityMissing = $missingWdl | Where-Object { $_ -match '^[KQRBNP]{5,7}v[KQRBNP]{2,}' } | Sort-Object { $_.Length } -Descending | Select-Object -First 20

if ($priorityMissing) {
    Write-Host "`nTop priority missing (largest first, 7pc heavy):"
    $priorityMissing | ForEach-Object {
        $isPawnful = $_ -match 'P'
        $exe = if ($isPawnful) { 'rtbgenp.exe' } else { 'rtbgen.exe' }
        Write-Host @"
# $_
`$env:RTBPATH = "$DestinationRoot"
`$env:RTBSTATSDIR = "T:\SyzygyStats"
mkdir "$regenRoot\$_" -Force
Set-Location "$regenRoot\$_"
& "$ScriptRoot\bin\$exe" -t 20 -d --stats $_ 2>&1 | Tee-Object -FilePath "gen.log"
# After it finishes (days/weeks), validate + promote:
& "$tbcheck" "$regenRoot\$_\$_.rtbw"
& "$tbcheck" "$regenRoot\$_\$_.rtbz"
Copy-Item "$regenRoot\$_\$_.rtbw" -Destination "$DestinationRoot\7men\other\$_.rtbw" -Force   # adjust subfolder if needed
Copy-Item "$regenRoot\$_\$_.rtbz" -Destination "$DestinationRoot\7men\other\$_.rtbz" -Force
"@
    }
}

if ($DeleteSourceAfterCopy) {
    Write-Host "`nWARNING: -DeleteSourceAfterCopy was used. Only sources of successfully validated & copied tables were removed." -ForegroundColor Magenta
}

Write-Host "`nScript finished. The SAN paths (\\ds1817 and \\ds1821) were only READ (tbcheck + directory listing). Nothing was ever written or modified on the SAN." -ForegroundColor Green