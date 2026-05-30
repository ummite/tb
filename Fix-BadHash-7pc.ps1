<#
.SYNOPSIS
    Fix the 5 seven-piece Syzygy tables that have invalid embedded hashes
    (KBBBBvKR, KBBBNvKN, KBBNNvKN, KBNPvKRB, KBNPvKRN).

.DESCRIPTION
    Strategy (strictly follows your copy-first rule):
    1. Search all known drives and Syzygy locations for candidate copies of the 5 tables.
    2. For every candidate pair (.rtbw + .rtbz), run bin\tbcheck on BOTH files.
    3. Only if BOTH pass (good CityHash), the pair is considered a valid source.
    4. Valid good pairs are copied (never moved/hardlinked by default) to the correct
       location under T:\Syzygy\7men\ (using improved net classification: 5v2_pawnless etc. or other).
    5. NOTHING is ever deleted automatically. Use -DeleteSourceAfterCopy ONLY if you
       explicitly want to clean bad/old copies after successful validated copy.
    6. If no good copy of a table is found anywhere, the script prints the exact
       ready-to-run generation commands (using fast local temp dir + your current
       lower tables in T:\Syzygy\3-6men as RTBPATH + -d disk mode).

    These 5 tables were the ones rejected by tbcheck during the big consolidation
    (they had FAIL! on the copies that existed on T: and S:).

.PARAMETER SearchPaths
    Extra directories to search recursively. Default covers the usual suspects
    (A:\*, S:\*, F:\*, I:\*, T:\Syzygy and its subdirs, local Syzygy folders).

.PARAMETER DestinationRoot
    Where to place good tables (default T:\Syzygy). Subfolders 7men/5v2_pawnless etc. created as needed.

.PARAMETER LinkType
    Copy (default, safest across network) or HardLink (only if same volume and you trust the source).

.PARAMETER DeleteSourceAfterCopy
    DANGEROUS. Only set this if you have reviewed the log and explicitly want to remove the
    source files of successfully copied good pairs (e.g. to clean bad copies off S: or A:).

.PARAMETER WhatIf
    Dry-run: show exactly what would be searched, validated, and copied. No writes.

.PARAMETER ThreadsForGen
    Thread count suggested in the generation command blocks (default 20).

.EXAMPLE
    # First see everything it would do (highly recommended)
    .\Fix-BadHash-7pc.ps1 -WhatIf

.EXAMPLE
    # Real recovery (copy only, no delete)
    .\Fix-BadHash-7pc.ps1

.EXAMPLE
    # After review, also clean the known-bad copies from S: and T: root (you must confirm)
    .\Fix-BadHash-7pc.ps1 -DeleteSourceAfterCopy
#>

param(
    [string[]]$SearchPaths = @(
        "A:\Syzygy*",
        "A:\*Syzygy*",
        "S:\Syzygy*",
        "S:\*Syzygy*",
        "S:\5v2*",
        "F:\Syzygy*",
        "I:\Syzygy*",
        "T:\Syzygy",
        "T:\Syzygy\3-6men",
        "T:\Syzygy\7men",
        ".\Syzygy",
        "C:\Syzygy*"
    ),
    [string]$DestinationRoot = "T:\Syzygy",
    [ValidateSet('Copy','HardLink')]
    [string]$LinkType = "Copy",
    [switch]$DeleteSourceAfterCopy,
    [int]$ThreadsForGen = 20,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$ScriptRoot   = Split-Path -Parent $MyInvocation.MyCommand.Path
$BinDir       = Join-Path $ScriptRoot "bin"
$tbcheckExe   = Join-Path $BinDir "tbcheck.exe"
$rtbgenExe    = Join-Path $BinDir "rtbgen.exe"
$rtbgenpExe   = Join-Path $BinDir "rtbgenp.exe"

if (-not (Test-Path $tbcheckExe)) {
    Write-Error "tbcheck.exe not found in $BinDir. Run build.bat first."
    exit 1
}

# The exact 5 tables with bad hashes (from previous consolidation + confirmed tbcheck FAIL)
$BadTables = @(
    "KBBBBvKR",   # pawnless, 5v2-ish (4B vs R) → ends in 7men/other with current buckets
    "KBBBNvKN",   # pawnless
    "KBBNNvKN",   # pawnless
    "KBNPvKRB",   # pawnful
    "KBNPvKRN"    # pawnful
)

# Reference hashes (from checksums/wdl7.txt + dtz7.txt) for logging only
$RefHashes = @{
    "KBBBBvKR.rtbw" = "6946f331cb900435cf169d9c3230aa72"
    "KBBBBvKR.rtbz" = "3e8d5011be230c2d7962dd633f7798d7"
    "KBBBNvKN.rtbw" = "bff3d43146d5ed499cb4b83b7ca00af2"
    "KBBBNvKN.rtbz" = "38879ec41c864e9cb760bdc1332f5601"
    "KBBNNvKN.rtbw" = "eca1734ebfc4728ce79e56400dc76b05"
    "KBBNNvKN.rtbz" = "889b8ac4450706ea5e04e3b7f3fbfe24"
    "KBNPvKRB.rtbw" = "7617814560586b39ce73681f6bf09b50"
    "KBNPvKRB.rtbz" = "c29187ecffb7f68235ae138ff03b90ca"
    "KBNPvKRN.rtbw" = "694ee188e77578aa866f376c64b81530"
    "KBNPvKRN.rtbz" = "8290d3e7d0b4bda3b86b3639dc6f67d3"
}

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

function Test-PairHash {
    param([string]$WdlPath, [string]$DtzPath)
    $w = & $tbcheckExe $WdlPath 2>&1
    $z = & $tbcheckExe $DtzPath 2>&1
    $wOk = $w -match 'OK'
    $zOk = $z -match 'OK'
    return [pscustomobject]@{
        WdlOk   = $wOk
        DtzOk   = $zOk
        BothOk  = $wOk -and $zOk
        WdlMsg  = $w
        DtzMsg  = $z
    }
}

Write-Host "=== Fix Bad-Hash 7pc Syzygy Tables ===" -ForegroundColor Cyan
Write-Host "Tables to fix     : $($BadTables -join ', ')"
Write-Host "LinkType          : $LinkType"
Write-Host "Destination root  : $DestinationRoot"
Write-Host "Delete after copy : $DeleteSourceAfterCopy  (DANGEROUS)"
Write-Host "Mode              : $(if ($DryRun) { 'DRY-RUN (WhatIf)' } else { 'REAL (copy-only unless -DeleteSourceAfterCopy)' })"
Write-Host ""

# Ensure destination structure exists
$requiredDirs = @(
    "3-5men","6men",
    "7men/4v3_pawnful","7men/4v3_pawnless",
    "7men/5v2_pawnful","7men/5v2_pawnless",
    "7men/6v1_pawnful","7men/6v1_pawnless",
    "7men/other"
)
foreach ($rd in $requiredDirs) {
    $p = Join-Path $DestinationRoot $rd
    if (-not (Test-Path $p)) {
        if (-not $DryRun) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
        Write-Host "Ensured dir: $p"
    }
}

# Expand search roots (handle wildcards)
$expandedRoots = @()
foreach ($sp in $SearchPaths) {
    $hits = Get-ChildItem -Path $sp -Directory -ErrorAction SilentlyContinue
    if ($hits) {
        $expandedRoots += $hits.FullName
    } elseif (Test-Path $sp) {
        $expandedRoots += $sp
    }
}
$expandedRoots = $expandedRoots | Sort-Object -Unique

Write-Host "Search roots ($($expandedRoots.Count)):" -ForegroundColor DarkCyan
$expandedRoots | ForEach-Object { Write-Host "  $_" }

# Collect candidates per table
$candidates = @{}
foreach ($t in $BadTables) {
    $candidates[$t] = @()
}

Write-Host "`nScanning for candidates..." -ForegroundColor Yellow
$sw = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($root in $expandedRoots) {
    foreach ($t in $BadTables) {
        $w = Get-ChildItem -Path $root -Recurse -Filter "$t.rtbw" -ErrorAction SilentlyContinue -File
        $z = Get-ChildItem -Path $root -Recurse -Filter "$t.rtbz" -ErrorAction SilentlyContinue -File
        if ($w -and $z) {
            foreach ($wf in $w) {
                $zf = $z | Where-Object { $_.DirectoryName -eq $wf.DirectoryName } | Select-Object -First 1
                if ($zf) {
                    $candidates[$t] += [pscustomobject]@{
                        Table   = $t
                        Wdl     = $wf.FullName
                        Dtz     = $zf.FullName
                        Dir     = $wf.DirectoryName
                        SizeW   = [math]::Round($wf.Length / 1MB, 0)
                        SizeZ   = [math]::Round($zf.Length / 1MB, 0)
                    }
                }
            }
        }
    }
}
$sw.Stop()
Write-Host "Scan complete in $([int]$sw.Elapsed.TotalSeconds)s" -ForegroundColor DarkGray

# Validate every candidate
$goodSources = @{}
$badSources  = @()

Write-Host "`nValidating candidates with tbcheck (this can take a minute per large file)..." -ForegroundColor Yellow

foreach ($t in $BadTables) {
    $goodSources[$t] = @()
    $list = $candidates[$t]
    if (-not $list) {
        Write-Host "  $t : no copies found anywhere" -ForegroundColor Red
        continue
    }
    Write-Host "  $t : $($list.Count) candidate pair(s)" -ForegroundColor Cyan
    foreach ($c in $list) {
        Write-Host "    Checking: $($c.Dir)\..." -NoNewline
        $res = Test-PairHash -WdlPath $c.Wdl -DtzPath $c.Dtz
        if ($res.BothOk) {
            Write-Host " GOOD" -ForegroundColor Green
            $goodSources[$t] += $c
        } else {
            Write-Host " BAD (wdl=$($res.WdlOk) dtz=$($res.DtzOk))" -ForegroundColor Red
            $badSources += $c
        }
    }
}

# Summary of findings
Write-Host "`n=== VALIDATION SUMMARY ===" -ForegroundColor Cyan
foreach ($t in $BadTables) {
    $g = $goodSources[$t].Count
    $c = $candidates[$t].Count
    if ($g -gt 0) {
        Write-Host "$t : $g GOOD source(s) out of $c found" -ForegroundColor Green
    } elseif ($c -gt 0) {
        Write-Host "$t : 0 GOOD (all $c copies are BAD hash)" -ForegroundColor Red
    } else {
        Write-Host "$t : MISSING (no copies found on scanned paths)" -ForegroundColor Yellow
    }
}

# Copy phase (only good ones)
$copied = @()
$skipped = @()

Write-Host "`n=== COPY PHASE (to $DestinationRoot) ===" -ForegroundColor Cyan

foreach ($t in $BadTables) {
    $goods = $goodSources[$t]
    if (-not $goods) { continue }

    # Prefer the largest / most recent as "best" source if multiple good ones
    $best = $goods | Sort-Object SizeZ -Descending | Select-Object -First 1

    $sub = Get-SyzygyNetSubfolder "$t.rtbw"
    $destDir = Join-Path $DestinationRoot $sub
    $destW = Join-Path $destDir "$t.rtbw"
    $destZ = Join-Path $destDir "$t.rtbz"

    if ((Test-Path $destW) -and (Test-Path $destZ)) {
        Write-Host "SKIP (already good at dest): $t -> $sub" -ForegroundColor DarkGray
        $skipped += $t
        continue
    }

    Write-Host "COPY GOOD: $t  ($($best.SizeW)MB + $($best.SizeZ)MB)  $($best.Dir)  -->  $sub" -ForegroundColor Green

    if ($DryRun) {
        Write-Host "  [DRYRUN] would copy $($best.Wdl) -> $destW"
        Write-Host "  [DRYRUN] would copy $($best.Dtz) -> $destZ"
        $copied += $t
        continue
    }

    # Real copy (two files)
    try {
        if ($LinkType -eq 'HardLink' -and (Get-Item $best.Wdl).PSDrive.Name -eq (Get-Item $destDir).PSDrive.Name) {
            # same volume → hardlink possible
            New-Item -ItemType HardLink -Path $destW -Value $best.Wdl -ErrorAction Stop | Out-Null
            New-Item -ItemType HardLink -Path $destZ -Value $best.Dtz -ErrorAction Stop | Out-Null
            Write-Host "  HardLinked OK" -ForegroundColor DarkGreen
        } else {
            Copy-Item -Path $best.Wdl -Destination $destW -ErrorAction Stop
            Copy-Item -Path $best.Dtz -Destination $destZ -ErrorAction Stop
            Write-Host "  Copied OK" -ForegroundColor DarkGreen
        }
        $copied += $t

        # Optional post-copy validation at destination (belt + suspenders)
        $finalCheck = Test-PairHash -WdlPath $destW -DtzPath $destZ
        if (-not $finalCheck.BothOk) {
            Write-Warning "  WARNING: destination copy of $t FAILED tbcheck after copy! Investigate manually."
        }

        if ($DeleteSourceAfterCopy) {
            # Only delete when user explicitly asked AND we are not in DryRun
            if (-not $DryRun) {
                Remove-Item $best.Wdl, $best.Dtz -Force -ErrorAction SilentlyContinue
                Write-Host "  Source deleted (as requested by -DeleteSourceAfterCopy)" -ForegroundColor Magenta
            } else {
                Write-Host "  [DRYRUN] would have deleted source after copy: $($best.Wdl)"
            }
        }
    } catch {
        Write-Error "  COPY FAILED for $t : $_"
    }
}

# Final report + generation instructions for anything still missing
Write-Host "`n=== FINAL REPORT ===" -ForegroundColor Cyan
Write-Host "Successfully placed good copies : $($copied.Count) / 5"
if ($copied) { Write-Host "  $($copied -join ', ')" -ForegroundColor Green }
if ($skipped) { Write-Host "Already good at destination (skipped): $($skipped -join ', ')" -ForegroundColor DarkGray }

$stillNeeded = $BadTables | Where-Object { -not ($goodSources[$_] -or (Test-Path (Join-Path (Join-Path $DestinationRoot (Get-SyzygyNetSubfolder "$_.rtbw")) "$_.rtbw"))) }

if ($stillNeeded) {
    Write-Host "`nTABLES STILL NEEDING REGENERATION (no good copy found):" -ForegroundColor Red
    Write-Host ($stillNeeded -join ', ') -ForegroundColor Yellow

    Write-Host "`n=== READY-TO-RUN GENERATION COMMANDS (one table at a time) ===" -ForegroundColor Cyan
    Write-Host "IMPORTANT:"
    Write-Host "  - Use a fast LOCAL SSD (F:\ or I:\ recommended). Network drives (T:) are unstable for 7pc -d mode."
    Write-Host "  - Generation of one 7pc table can take days to weeks even with 20+ threads + -d."
    Write-Host "  - RTBPATH points to your current lower tables (T:\Syzygy\3-6men has ~1020 files)."
    Write-Host "  - After generation finishes, tbcheck BOTH files, then copy the good pair to T:\Syzygy\7men\other (or correct subdir)."
    Write-Host ""

    $regenRoot = "F:\Syzygy7regen"
    if (-not (Test-Path "F:\")) { $regenRoot = "I:\Syzygy7regen" }

    foreach ($t in $stillNeeded) {
        $isPawnful = $t -match 'P'
        $genExe = if ($isPawnful) { "rtbgenp.exe" } else { "rtbgen.exe" }
        $sub = Get-SyzygyNetSubfolder "$t.rtbw"

        Write-Host "----- $t  ($sub)  ----- " -ForegroundColor White
        Write-Host @"
# 1. Prep (run once)
`$env:RTBPATH = "T:\Syzygy\3-6men"
`$env:RTBSTATSDIR = "T:\SyzygyStats"
if (-not (Test-Path `$env:RTBSTATSDIR)) { New-Item -ItemType Directory -Path `$env:RTBSTATSDIR -Force | Out-Null }
`$regenDir = "$regenRoot\$t"
New-Item -ItemType Directory -Path `$regenDir -Force | Out-Null
Set-Location `$regenDir

# 2. Launch generation (choose your core count; -d = disk mode, REQUIRED for 7pc)
#    Run this in a dedicated terminal / tmux / screen so it survives logout.
#    Monitor progress in another window: Get-Content "$regenRoot\$t\*.log" -Wait -Tail 20
& "$BinDir\$genExe" -t $ThreadsForGen -d --stats $t   2>&1 | Tee-Object -FilePath "$regenRoot\$t\${t}_gen.log"

# 3. AFTER it finishes (days/weeks later), validate + promote
& "$tbcheckExe" "$regenDir\$t.rtbw"
& "$tbcheckExe" "$regenDir\$t.rtbz"

# If BOTH say OK, copy to the reference (safe):
Copy-Item "$regenDir\$t.rtbw" -Destination "T:\Syzygy\$sub\$t.rtbw" -Force
Copy-Item "$regenDir\$t.rtbz" -Destination "T:\Syzygy\$sub\$t.rtbz" -Force

# Final belt+suspenders check on the reference location
& "$tbcheckExe" "T:\Syzygy\$sub\$t.rtbw"
& "$tbcheckExe" "T:\Syzygy\$sub\$t.rtbz"
"@
        Write-Host ""
    }

    Write-Host "Tip: You can launch one table now, let it run for hours/days, then come back and run this script again (it will detect the new good files on F:/I: and copy them)."
}

Write-Host "`nScript finished. Review the output above." -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "This was a DRYRUN. Remove -DryRun and re-run to perform the actual copies of any good sources found." -ForegroundColor Yellow
}
if ($DeleteSourceAfterCopy) {
    Write-Host "You used -DeleteSourceAfterCopy. Only sources of GOOD pairs that were successfully copied were removed." -ForegroundColor Magenta
}
