<#
.SYNOPSIS
    Reclassify files currently in T:\Syzygy\7men\other into the proper 4v3/5v2/6v1 subfolders using improved logic + hash validation.

.DESCRIPTION
    Safe by default: only copies. No deletion of source unless you explicitly use -DeleteSourceAfterCopy (and even then only after successful copy + validation).
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$SourceDir = "T:\Syzygy\7men\other",
    [string]$DestinationRoot = "T:\Syzygy",
    [ValidateSet('HardLink','Copy')]
    [string]$LinkType = "Copy",
    [switch]$DeleteSourceAfterCopy,   # DANGEROUS - only use if you explicitly want to clean the source after successful copy
    [switch]$WhatIf
)

$ErrorActionPreference = "Continue"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$tbcheck = Join-Path $ScriptRoot "bin\tbcheck.exe"

if (-not (Test-Path $tbcheck)) {
    Write-Error "tbcheck.exe not found!"
    exit 1
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

Write-Host "=== Reclassify 7men/other into proper splits ===" -ForegroundColor Cyan
Write-Host "Source      : $SourceDir"
Write-Host "Destination : $DestinationRoot"
Write-Host "LinkType    : $LinkType"
Write-Host "DeleteSourceAfterCopy : $DeleteSourceAfterCopy  (DANGEROUS if true)"
Write-Host "Mode        : $(if ($WhatIf) { 'WHATIF' } else { 'REAL' })"
Write-Host ""

if (-not (Test-Path $SourceDir)) {
    Write-Error "Source directory not found: $SourceDir"
    exit 1
}

# Ensure all target folders exist
$required = @(
    "3-5men", "6men",
    "7men/4v3_pawnful","7men/4v3_pawnless",
    "7men/5v2_pawnful","7men/5v2_pawnless",
    "7men/6v1_pawnful","7men/6v1_pawnless",
    "7men/other"
)
foreach ($r in $required) {
    $p = Join-Path $DestinationRoot $r
    if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

$files = Get-ChildItem $SourceDir -File -Include *.rtbw,*.rtbz -ErrorAction SilentlyContinue
Write-Host "Found $($files.Count) files in 7men/other to reclassify." -ForegroundColor Yellow

$stats = @{ Moved=0; Copied=0; Valid=0; Invalid=0; Skipped=0; Failed=0 }

foreach ($file in $files) {
    $sub = Get-SyzygyNetSubfolder $file.BaseName
    $destDir = Join-Path $DestinationRoot $sub
    $dest = Join-Path $destDir $file.Name

    if (Test-Path $dest) {
        Write-Host "SKIP (exists): $($file.Name) -> $sub" -ForegroundColor DarkGray
        $stats.Skipped++
        continue
    }

    # Always validate first
    $result = & $tbcheck $file.FullName 2>&1
    if ($result -notmatch "OK!") {
        Write-Warning "INVALID HASH: $($file.Name)"
        $stats.Invalid++
        continue
    }
    $stats.Valid++

    $action = "Copy+Validate to $sub"
    if ($PSCmdlet.ShouldProcess($file.FullName, $action)) {
        try {
            if ($LinkType -eq 'HardLink' -and (Get-Item $file.FullName).PSDrive.Name -eq (Get-Item $DestinationRoot).PSDrive.Name) {
                New-Item -ItemType HardLink -Path $dest -Value $file.FullName -ErrorAction Stop | Out-Null
            } else {
                Copy-Item $file.FullName -Destination $dest -ErrorAction Stop
            }

            $stats.Copied++

            if ($DeleteSourceAfterCopy) {
                # Only delete after successful copy + validation (your strict rule)
                Remove-Item $file.FullName -Force -ErrorAction Stop
                Write-Host "COPIED+OK + DELETED SOURCE: $($file.Name) -> $sub" -ForegroundColor Green
                $stats.Moved++
            } else {
                Write-Host "COPIED+OK : $($file.Name) -> $sub" -ForegroundColor Green
            }
        } catch {
            Write-Warning "FAILED: $($file.Name) - $_"
            $stats.Failed++
        }
    } else {
        Write-Host "WHATIF+OK : $($file.Name) -> $sub"
        $stats.Copied++
    }
}

Write-Host ""
Write-Host "=== Reclassification Report ===" -ForegroundColor Magenta
Write-Host "Processed from other : $($files.Count)"
Write-Host "Valid hash           : $($stats.Valid)"
Write-Host "Copied               : $($stats.Copied)"
Write-Host "Moved (copied + deleted source) : $($stats.Moved)"
Write-Host "Invalid hash         : $($stats.Invalid)"
Write-Host "Already existed      : $($stats.Skipped)"
Write-Host "Errors               : $($stats.Failed)"
Write-Host ""
Write-Host "Done. Your reference is at: $DestinationRoot" -ForegroundColor Green
