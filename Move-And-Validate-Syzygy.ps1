<#
.SYNOPSIS
    Move Syzygy files to the canonical net structure on T:\Syzygy and validate each one with tbcheck.

.DESCRIPTION
    - Sorts files into 3-6men / 7men/xxx_pawnful etc. (same as on the net)
    - For every file, runs tbcheck.exe and only accepts it if it reports "OK!"
    - Logs everything
    - Safe with -WhatIf
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,

    [string]$DestinationRoot = "T:\Syzygy"
)

$ErrorActionPreference = "Continue"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$tbcheck = Join-Path $ScriptRoot "bin\tbcheck.exe"

if (-not (Test-Path $tbcheck)) {
    Write-Error "tbcheck.exe not found at $tbcheck"
    exit 1
}

function Get-SyzygyNetSubfolder {
    param([string]$BaseName)
    $name = $BaseName -replace '\.rtb[zw]$',''
    $letters = $name -replace 'v','' -replace '[^KQRBNP]',''
    $pieceCount = $letters.Length

    if ($pieceCount -le 6) { return "3-6men" }
    if ($pieceCount -ne 7) { return "7men/other" }

    $parts = $name -split 'v', 2
    if ($parts.Count -ne 2) { return "7men/other" }

    $left  = ($parts[0] -replace '[^KQRBNP]','').Length
    $right = ($parts[1] -replace '[^KQRBNP]','').Length
    $hasPawn = $name -match 'P'
    $pawnType = if ($hasPawn) { "pawnful" } else { "pawnless" }

    $split = switch ("$left`v$right") {
        "4v3" { "4v3" }; "3v4" { "4v3" }
        "5v2" { "5v2" }; "2v5" { "5v2" }
        "6v1" { "6v1" }; "1v6" { "6v1" }
        default { "other" }
    }
    if ($split -eq "other") { return "7men/other" }
    return "7men/${split}_$pawnType"
}

Write-Host "=== Move + Validate Syzygy to Net Structure ===" -ForegroundColor Cyan
Write-Host "Source      : $SourcePath"
Write-Host "Destination : $DestinationRoot"
Write-Host "Mode        : $(if ($WhatIf) { 'WHATIF' } else { 'REAL MOVE + VALIDATE' })"
Write-Host ""

if (-not (Test-Path $SourcePath)) {
    Write-Error "Source does not exist"; exit 1
}

# Ensure structure
$folders = @("3-6men","7men/4v3_pawnful","7men/4v3_pawnless","7men/5v2_pawnful","7men/5v2_pawnless","7men/6v1_pawnful","7men/6v1_pawnless","7men/other")
foreach ($f in $folders) {
    $p = Join-Path $DestinationRoot $f
    if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

$files = Get-ChildItem $SourcePath -Recurse -File -Include *.rtbw,*.rtbz

$stats = @{ Moved=0; Valid=0; Invalid=0; Skipped=0; Failed=0 }

foreach ($file in $files) {
    $sub = Get-SyzygyNetSubfolder $file.BaseName
    $destDir = Join-Path $DestinationRoot $sub
    $dest = Join-Path $destDir $file.Name

    if (Test-Path $dest) {
        Write-Host "SKIP (exists): $($file.Name)" -ForegroundColor DarkGray
        $stats.Skipped++
        continue
    }

    # Validate first with tbcheck
    $val = & $tbcheck $file.FullName 2>&1
    if ($val -notmatch "OK!") {
        Write-Warning "INVALID HASH : $($file.Name) -> $val"
        $stats.Invalid++
        continue
    }

    $action = "Move+Validate to $sub"
    if ($PSCmdlet.ShouldProcess($file.FullName, $action)) {
        try {
            # SAFE MODE ONLY: We never delete the source automatically.
            # Per your rule: deletion is only allowed for 100% safe moves when you explicitly request it.
            Copy-Item $file.FullName -Destination $dest -ErrorAction Stop
            Write-Host "COPIED + OK  : $($file.Name) -> $sub  (source left in place)" -ForegroundColor Green
            $stats.Copied++
            $stats.Valid++
        } catch {
            Write-Warning "COPY FAILED  : $($file.Name) - $_"
            $stats.Failed++
        }
    } else {
        Write-Host "WHATIF + OK  : $($file.Name) -> $sub"
        $stats.Moved++
        $stats.Valid++
    }
}

Write-Host ""
Write-Host "=== Final Report ===" -ForegroundColor Magenta
Write-Host "Total processed : $($files.Count)"
Write-Host "Copied & Valid   : $($stats.Valid)"
Write-Host "Invalid hash     : $($stats.Invalid)"
Write-Host "Already existed  : $($stats.Skipped)"
Write-Host "Copy errors      : $($stats.Failed)"
Write-Host ""
Write-Host "Reference now at: $DestinationRoot" -ForegroundColor Green