<#
.SYNOPSIS
    Setup / aggregate Syzygy tablebases from multiple sources (local folders + network UNC paths)
    into a single clean working directory.

.DESCRIPTION
    This script solves the common situation where you have Syzygy files scattered across:
    - Different network shares (\\nas\tb\3-4pc, \\server\Syzygy5, etc.)
    - Local disks
    - The project's own Syzygy\ folder

    It creates (or updates) one canonical "Working" folder that contains all your tables
    using hardlinks when possible (zero extra space) or symbolic links / copies as fallback.

    After running this, you can safely point:
    - RTBPATH to this working folder
    - Your chess engine / probing code to this folder
    - Syzygy-Generate.ps1 -Destination <this folder>

.PARAMETER Sources
    Array of paths (local or UNC) that contain .rtbw / .rtbz files.
    You edit this at the top of the script.

.PARAMETER WorkingDir
    The single destination folder that will become your canonical Syzygy collection.
    Recommended: a fast local SSD folder, e.g. D:\Syzygy or E:\Chess\Syzygy

.PARAMETER LinkType
    HardLink (preferred, same volume only), SymbolicLink, or Copy.

.EXAMPLE
    # Edit the $Sources array at the top, then run:
    .\Syzygy-Setup.ps1 -WorkingDir D:\Syzygy -LinkType HardLink

.NOTES
    - Run as Administrator if you want to create symbolic links.
    - Hardlinks only work when source and destination are on the SAME volume.
    - After setup, use:
        $env:RTBPATH = "D:\Syzygy"
        .\Syzygy-Generate.ps1 -FiveOnly -Destination D:\Syzygy -Disk
#>

[CmdletBinding()]
param(
    [string]$WorkingDir = "Syzygy-Working",

    [ValidateSet('HardLink','SymbolicLink','Copy')]
    [string]$LinkType = 'HardLink',

    [switch]$WhatIf,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# =============================================================================
# >>>> EDIT THIS SECTION <<<<
# List ALL your Syzygy locations here (local folders + network UNC paths)
# The script will scan them all and consolidate into $WorkingDir
# Updated with T: (user reported additional Syzygy on T: drive)
# =============================================================================
$Sources = @(
    # === Local project folder ===
    (Join-Path $ScriptRoot 'Syzygy'),

    # === A: drive (\\ds1817\IA) ===
    'A:\Syzygy',
    'A:\Syzygy_A_Trier_FromOld_Ryzen7950',               # Very large collection with many 6pc + 7pc

    # === S: drive (\\ds1821\2x10TB RAID0) - "plein de syzygy" ===
    'S:\Syzygy',                                         # Main structured collection (strong 5pc + 6pc)
    'S:\5v2_pawnful',
    'S:\5v2_pawnless',
    'S:\6v1_pawnful',
    'S:\6v1_pawnless',
    'S:\4v3_pawnless_ManyMissing',

    # === T: drive (user added) ===
    'T:\Syzygy',                                         # Currently only contains 3-6men (1020 files, ~150 GB)
    'T:\Syzygy\3-6men',                                  # Duplicate of S:\Syzygy\3-6men ? (same count & breakdown)
    # Add any other Syzygy folders on T: here if they exist (e.g. 7pc collections)

    # Add other paths if needed (F:, I:, etc.)
)
    # '\\192.168.1.50\data\tablebases\Syzygy'
)

# =============================================================================

$WorkingDir = Join-Path $ScriptRoot $WorkingDir
if (-not (Test-Path $WorkingDir)) {
    New-Item -ItemType Directory -Path $WorkingDir -Force | Out-Null
    Write-Host "Created working directory: $WorkingDir" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Syzygy Multi-Source Setup ===" -ForegroundColor Magenta
Write-Host "Working folder : $WorkingDir"
Write-Host "Link type      : $LinkType"
Write-Host "Sources        : $($Sources.Count)"
$Sources | ForEach-Object { Write-Host "                 $_" }
Write-Host ""

$stats = @{
    TotalFound   = 0
    Linked       = 0
    Skipped      = 0
    Failed       = 0
    ByPieceCount = @{}
}

$seen = @{}   # filename -> source path (to detect duplicates)

foreach ($src in $Sources) {
    if (-not (Test-Path $src)) {
        Write-Warning "Source not found, skipping: $src"
        continue
    }

    Write-Host "Scanning: $src" -ForegroundColor Cyan

    $files = Get-ChildItem -Path $src -Filter *.rtb* -File -ErrorAction SilentlyContinue

    foreach ($file in $files) {
        $stats.TotalFound++

        $name = $file.Name
        $dest = Join-Path $WorkingDir $name

        if ($seen.ContainsKey($name)) {
            Write-Host "  DUPLICATE: $name (already from $($seen[$name]))" -ForegroundColor DarkYellow
            $stats.Skipped++
            continue
        }

        $pieceCount = $file.BaseName.Length - 1
        if (-not $stats.ByPieceCount.ContainsKey($pieceCount)) { $stats.ByPieceCount[$pieceCount] = 0 }
        $stats.ByPieceCount[$pieceCount]++

        if (Test-Path $dest) {
            # Already present in working dir (from previous run or manual copy)
            $seen[$name] = $src
            $stats.Skipped++
            continue
        }

        $success = $false

        if ($LinkType -eq 'HardLink' -and -not $WhatIf) {
            try {
                # New-Item -ItemType HardLink works in modern PowerShell
                New-Item -ItemType HardLink -Path $dest -Target $file.FullName -ErrorAction Stop | Out-Null
                $success = $true
            } catch {
                Write-Warning "HardLink failed for $name (different volume?). Falling back..."
            }
        }

        if (-not $success -and $LinkType -eq 'SymbolicLink' -and -not $WhatIf) {
            try {
                New-Item -ItemType SymbolicLink -Path $dest -Target $file.FullName -ErrorAction Stop | Out-Null
                $success = $true
            } catch {
                Write-Warning "SymbolicLink failed (try running as Administrator)"
            }
        }

        if (-not $success -and -not $WhatIf) {
            # Fallback to copy (or forced by user)
            try {
                Copy-Item -Path $file.FullName -Destination $dest -ErrorAction Stop
                $success = $true
                if ($LinkType -eq 'HardLink' -or $LinkType -eq 'SymbolicLink') {
                    Write-Host "  Copied (fallback): $name" -ForegroundColor Yellow
                }
            } catch {
                Write-Error "Failed to place $name : $_"
                $stats.Failed++
                continue
            }
        }

        if ($WhatIf) {
            Write-Host "  [WHATIF] Would link/copy: $name <- $($file.FullName)"
            $success = $true
        }

        if ($success) {
            $seen[$name] = $src
            $stats.Linked++
            if ($stats.Linked % 20 -eq 0) {
                Write-Host "  ... $stats.Linked files processed so far" -ForegroundColor DarkGray
            }
        }
    }
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Magenta
Write-Host "Total tablebase files found across sources : $($stats.TotalFound)"
Write-Host "New links/copies created                   : $($stats.Linked)"
Write-Host "Already present or duplicates              : $($stats.Skipped)"
Write-Host "Failures                                   : $($stats.Failed)"
Write-Host ""

if ($stats.ByPieceCount.Count -gt 0) {
    Write-Host "Breakdown by piece count (in working folder):"
    $stats.ByPieceCount.GetEnumerator() | Sort-Object Name | ForEach-Object {
        Write-Host ("  {0,2}-piece : {1}" -f $_.Key, $_.Value)
    }
    Write-Host ""
}

Write-Host "Your canonical Syzygy folder is now:"
Write-Host "  $WorkingDir" -ForegroundColor Green
Write-Host ""

Write-Host "Recommended next steps:" -ForegroundColor Yellow
Write-Host "  # 1. Set RTBPATH for this session"
Write-Host "  `$env:RTBPATH = `"$WorkingDir`""
Write-Host ""
Write-Host "  # 2. Finish your 5-piece set (or start 6/7 if you want)"
Write-Host "  .\Syzygy-Generate.ps1 -FiveOnly -Destination `"$WorkingDir`" -Threads 12 -Disk -Verify"
Write-Host "  # Or for 6-piece:  -Min 6 -Max 6"
Write-Host ""
Write-Host "  # 3. (Optional) Update your engine config to point to $WorkingDir"
Write-Host ""

# Create a small helper file so you don't have to remember the path
$envFile = Join-Path $WorkingDir 'RTBPATH.txt'
Set-Content -Path $envFile -Value $WorkingDir -Encoding UTF8
Write-Host "A file 'RTBPATH.txt' was created inside the working folder for reference." -ForegroundColor DarkGray
