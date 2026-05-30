<#
.SYNOPSIS
    Consolidate all your Syzygy files from known sources into ONE clean reference folder on T:\Syzygy,
    organized exactly like on the net (3-6men + 7men splits), with hash validation.

.DESCRIPTION
    - Scans all your known sources (A:, S:, F:, local, T: leftovers...)
    - Classifies files into the standard net structure:
        3-6men/
        7men/4v3_pawnful, 4v3_pawnless, 5v2_*, 6v1_*
    - Copies (or hardlinks when possible) only files that pass tbcheck validation
    - Target is always your single reference: T:\Syzygy
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$Destination = "T:\Syzygy",
    [ValidateSet('HardLink','Copy')]
    [string]$LinkType = "Copy"   # Copy is safer across NAS
)

$ErrorActionPreference = "Continue"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$tbcheck = Join-Path $ScriptRoot "bin\tbcheck.exe"

if (-not (Test-Path $tbcheck)) {
    Write-Error "tbcheck.exe not found!"
    exit 1
}

# Your known sources (add/remove as needed)
$Sources = @(
    'A:\Syzygy',
    'A:\Syzygy_A_Trier_FromOld_Ryzen7950',
    'S:\Syzygy',
    'S:\Syzygy\3-6men',
    'S:\5v2_pawnful',
    'S:\5v2_pawnless',
    'S:\6v1_pawnful',
    'S:\6v1_pawnless',
    'S:\4v3_pawnless_ManyMissing',
    'F:\Syzygy',
    (Join-Path $ScriptRoot 'Syzygy'),
    'T:\Syzygy',
    'T:\Syzygy-Working'
)

function Get-SyzygyNetSubfolder {
    param([string]$BaseName)
    $name = $BaseName -replace '\.rtb[zw]$',''
    $letters = $name -replace 'v','' -replace '[^KQRBNP]',''
    $pc = $letters.Length

    if ($pc -le 5) {
        return "3-5men"
    }
    if ($pc -eq 6) {
        return "6men"
    }

    if ($pc -ne 7) {
        return "7men/other"
    }

    # 7-piece: better split detection (non-king pieces)
    $parts = $name -split 'v', 2
    if ($parts.Count -ne 2) { return "7men/other" }

    $leftNonKing  = ($parts[0] -replace 'K','' -replace '[^QRBNP]','').Length
    $rightNonKing = ($parts[1] -replace 'K','' -replace '[^QRBNP]','').Length

    $hasP = $name -match 'P'
    $pType = if ($hasP) { "pawnful" } else { "pawnless" }

    # Normalize to larger vs smaller
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

Write-Host "=== CONSOLIDATE TO T:\Syzygy - NET STRUCTURE ===" -ForegroundColor Cyan
Write-Host "Destination : $Destination"
Write-Host "LinkType    : $LinkType"
Write-Host "Mode        : $(if ($WhatIf) { 'WHATIF' } else { 'REAL' })"
Write-Host ""

# Ensure full net structure exists
$required = @(
    "3-5men",
    "6men",
    "7men/4v3_pawnful","7men/4v3_pawnless",
    "7men/5v2_pawnful","7men/5v2_pawnless",
    "7men/6v1_pawnful","7men/6v1_pawnless",
    "7men/other"
)
foreach ($r in $required) {
    $p = Join-Path $Destination $r
    if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

$stats = @{ Found=0; Valid=0; Copied=0; Skipped=0; Invalid=0; Failed=0 }

foreach ($src in $Sources) {
    if (-not (Test-Path $src)) { continue }
    Write-Host "Scanning: $src" -ForegroundColor Yellow

    $files = Get-ChildItem $src -Recurse -File -Include *.rtbw,*.rtbz -ErrorAction SilentlyContinue
    $stats.Found += $files.Count

    foreach ($f in $files) {
        $sub = Get-SyzygyNetSubfolder $f.BaseName
        $destDir = Join-Path $Destination $sub
        $dest = Join-Path $destDir $f.Name

        if (Test-Path $dest) {
            $stats.Skipped++
            continue
        }

        # Validate hash first
        $result = & $tbcheck $f.FullName 2>&1
        if ($result -notmatch "OK!") {
            Write-Warning "INVALID: $($f.Name)"
            $stats.Invalid++
            continue
        }
        $stats.Valid++

        $action = "Copy+Validate to $sub"
        if ($PSCmdlet.ShouldProcess($f.FullName, $action)) {
            try {
                if ($LinkType -eq 'HardLink' -and (Get-Item $f.FullName).PSDrive.Name -eq (Get-Item $Destination).PSDrive.Name) {
                    New-Item -ItemType HardLink -Path $dest -Value $f.FullName -ErrorAction Stop | Out-Null
                } else {
                    Copy-Item $f.FullName -Destination $dest -ErrorAction Stop
                }
                Write-Host "COPIED+OK : $($f.Name) -> $sub" -ForegroundColor Green
                $stats.Copied++
            } catch {
                Write-Warning "FAILED: $($f.Name) - $_"
                $stats.Failed++
            }
        } else {
            Write-Host "WHATIF+OK : $($f.Name) -> $sub"
            $stats.Copied++
        }
    }
}

Write-Host ""
Write-Host "=== FINAL REPORT ===" -ForegroundColor Magenta
Write-Host "Files found     : $($stats.Found)"
Write-Host "Valid hash      : $($stats.Valid)"
Write-Host "Copied to T:    : $($stats.Copied)"
Write-Host "Already existed : $($stats.Skipped)"
Write-Host "Invalid hash    : $($stats.Invalid)"
Write-Host "Errors          : $($stats.Failed)"
Write-Host ""
Write-Host "Your single clean reference is now at: $Destination" -ForegroundColor Green
Write-Host "Structure: 3-6men + 7men/4v3_* + 5v2_* + 6v1_*" -ForegroundColor Green