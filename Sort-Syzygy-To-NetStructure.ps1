<#
.SYNOPSIS
    Reorganize Syzygy .rtbw/.rtbz files into the standard "net" / chessdb.cn mirror structure.

.DESCRIPTION
    Takes a source folder (flat or messy) and moves/hardlinks the files into the canonical layout used on the internet for large Syzygy distributions:

    DestinationRoot/
    ├── 3-6men/                  (all <= 6 piece tables)
    └── 7men/
        ├── 4v3_pawnful/
        ├── 4v3_pawnless/
        ├── 5v2_pawnful/
        ├── 5v2_pawnless/
        ├── 6v1_pawnful/
        └── 6v1_pawnless/

    This matches the structure used by Bojun Guo (chessdb.cn) mirrors.

.PARAMETER SourcePath
    Folder containing the mixed .rtbw and .rtbz files (recursively scanned).

.PARAMETER DestinationRoot
    Root where the organized structure will be created (default: T:\Syzygy).

.PARAMETER LinkType
    HardLink (preferred when possible), Copy, or SymbolicLink.

.PARAMETER WhatIf
    Dry run - show what would be done without moving anything.
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,

    [string]$DestinationRoot = "T:\Syzygy",

    [ValidateSet('HardLink','Copy','SymbolicLink')]
    [string]$LinkType = 'HardLink',

    [switch]$WhatIf
)

$ErrorActionPreference = "Continue"

function Get-SyzygyNetSubfolder {
    param([string]$BaseName)

    $name = $BaseName -replace '\.rtb[zw]$',''

    # Count non-king pieces + kings (rough but reliable for classification)
    $letters = $name -replace 'v','' -replace '[^KQRBNP]',''
    $pieceCount = $letters.Length

    if ($pieceCount -le 6) {
        return "3-6men"
    }

    if ($pieceCount -ne 7) {
        return "7men/other"
    }

    # 7-piece file
    $parts = $name -split 'v', 2
    if ($parts.Count -ne 2) { return "7men/other" }

    $left  = ($parts[0] -replace '[^KQRBNP]','').Length
    $right = ($parts[1] -replace '[^KQRBNP]','').Length

    $hasPawn = $name -match 'P'
    $pawnType = if ($hasPawn) { "pawnful" } else { "pawnless" }

    $split = switch ("$left`v$right") {
        "4v3" { "4v3" }
        "3v4" { "4v3" }
        "5v2" { "5v2" }
        "2v5" { "5v2" }
        "6v1" { "6v1" }
        "1v6" { "6v1" }
        default { "other" }
    }

    if ($split -eq "other") { return "7men/other" }

    return "7men/${split}_$pawnType"
}

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Syzygy Net Structure Organizer                         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Source       : $SourcePath"
Write-Host "Destination  : $DestinationRoot"
Write-Host "LinkType     : $LinkType"
Write-Host "Mode         : $(if ($WhatIf) { 'WHATIF (dry-run)' } else { 'REAL' })"
Write-Host ""

if (-not (Test-Path $SourcePath)) {
    Write-Error "Source path does not exist: $SourcePath"
    exit 1
}

# Create destination structure
$structure = @(
    "3-6men",
    "7men/4v3_pawnful",
    "7men/4v3_pawnless",
    "7men/5v2_pawnful",
    "7men/5v2_pawnless",
    "7men/6v1_pawnful",
    "7men/6v1_pawnless",
    "7men/other"
)

foreach ($folder in $structure) {
    $full = Join-Path $DestinationRoot $folder
    if (-not (Test-Path $full)) {
        New-Item -ItemType Directory -Path $full -Force | Out-Null
    }
}

$files = Get-ChildItem -Path $SourcePath -Recurse -File -Include *.rtbw, *.rtbz -ErrorAction SilentlyContinue

Write-Host "Found $($files.Count) Syzygy files to process." -ForegroundColor Yellow
Write-Host ""

$stats = @{
    Moved   = 0
    Skipped = 0
    Failed  = 0
}

foreach ($file in $files) {
    $subfolder = Get-SyzygyNetSubfolder $file.BaseName
    $targetDir = Join-Path $DestinationRoot $subfolder
    $targetPath = Join-Path $targetDir $file.Name

    if (Test-Path $targetPath) {
        Write-Host "SKIP (exists)  : $($file.Name) → $subfolder" -ForegroundColor DarkGray
        $stats.Skipped++
        continue
    }

    $action = "Move to $subfolder"
    if ($PSCmdlet.ShouldProcess($file.FullName, $action)) {
        try {
            if ($LinkType -eq 'HardLink' -and (Get-Item $file.FullName).PSDrive.Name -eq (Get-Item $DestinationRoot).PSDrive.Name) {
                New-Item -ItemType HardLink -Path $targetPath -Value $file.FullName -ErrorAction Stop | Out-Null
                Write-Host "HARDLINK       : $($file.Name) → $subfolder" -ForegroundColor Green
            } elseif ($LinkType -eq 'SymbolicLink') {
                New-Item -ItemType SymbolicLink -Path $targetPath -Value $file.FullName -ErrorAction Stop | Out-Null
                Write-Host "SYMLINK        : $($file.Name) → $subfolder" -ForegroundColor Green
            } else {
                Move-Item -Path $file.FullName -Destination $targetPath -ErrorAction Stop
                Write-Host "MOVED          : $($file.Name) → $subfolder" -ForegroundColor Green
            }
            $stats.Moved++
        } catch {
            Write-Warning "FAILED         : $($file.Name) - $_"
            $stats.Failed++
        }
    } else {
        Write-Host "WHATIF         : $($file.Name) -> $subfolder"
        $stats.Moved++
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Magenta
Write-Host "Processed : $($files.Count)"
Write-Host "Moved     : $($stats.Moved)"
Write-Host "Skipped   : $($stats.Skipped)"
Write-Host "Failed    : $($stats.Failed)"
Write-Host ""
Write-Host "Your reference structure is now at: $DestinationRoot" -ForegroundColor Green