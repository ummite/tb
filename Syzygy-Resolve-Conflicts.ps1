<#
.SYNOPSIS
    Resolves the conflicts found on T:\Syzygy by keeping the largest version
    and safely moving the smaller/conflicting duplicates to a review folder.

.DESCRIPTION
    Uses the output of Syzygy-Conflict-Analyzer.ps1 (Conflicts-Keep-These.csv)
    as the list of files to preserve.

    For every conflicting base name, all other versions (smaller or duplicates)
    are moved to T:\Syzygy\duplicates-to-review\ (never deleted directly).

    This is the safest way to clean the 40 conflicts currently on your master.

.EXAMPLE
    # Simulation (highly recommended first)
    .\Syzygy-Resolve-Conflicts.ps1 -WhatIf

    # Real execution - limited for safety
    .\Syzygy-Resolve-Conflicts.ps1 -MaxFiles 20

    # Full run
    .\Syzygy-Resolve-Conflicts.ps1
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$KeepListCsv = "logs\Conflicts-Keep-These.csv",
    [string]$MasterPath = "T:\Syzygy",
    [string]$ReviewFolder = "T:\Syzygy-duplicates-to-review",
    [int]$MaxFiles = 0
)

if (-not (Test-Path $KeepListCsv)) {
    Write-Error "Keep list not found: $KeepListCsv"
    Write-Host "Run first: .\Syzygy-Conflict-Analyzer.ps1"
    exit 1
}

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logDir = "logs"
$logFile = Join-Path $logDir "Resolve-Conflicts_$timestamp.log"

function Write-Log($msg) {
    $line = "[$(Get-Date -Format 'HH:mm:ss')] $msg"
    Add-Content -Path $logFile -Value $line -Encoding UTF8
    Write-Host $line
}

Write-Host "=== Syzygy Conflict Resolver ===" -ForegroundColor Magenta
Write-Host "Keep list : $KeepListCsv"
Write-Host "Master    : $MasterPath"
Write-Host "Review to : $ReviewFolder"
Write-Host "Log       : $logFile"
Write-Host ""

$keepEntries = Import-Csv $KeepListCsv
$keepPaths = $keepEntries.KeepPath | ForEach-Object { $_.Trim() }

# Group by BaseName to know what we need to protect
$keepByBase = $keepEntries | Group-Object BaseName

if (-not (Test-Path $ReviewFolder)) {
    New-Item -ItemType Directory -Path $ReviewFolder -Force | Out-Null
    Write-Log "Created review folder: $ReviewFolder"
}

$moved = 0
$skipped = 0
$errors = 0

foreach ($group in $keepByBase) {
    $base = $group.Name
    $keepForThisBase = $group.Group.KeepPath

    # Find all actual files on disk for this base name
    $candidates = Get-ChildItem -Path $MasterPath -Recurse -File -Filter "*$base*" -ErrorAction SilentlyContinue |
                  Where-Object { $_.Name -match "^$base\.(rtbw|rtbz)$" }

    foreach ($file in $candidates) {
        if ($keepPaths -contains $file.FullName) {
            continue  # This is one of the versions we want to keep
        }

        # This is a duplicate / smaller version → move to review folder
        if ($MaxFiles -gt 0 -and $moved -ge $MaxFiles) {
            break
        }

        $destPath = Join-Path $ReviewFolder $file.Name

        # Avoid name collision in review folder
        $i = 1
        while (Test-Path $destPath) {
            $destPath = Join-Path $ReviewFolder ("{0}_{1}{2}" -f $file.BaseName, $i, $file.Extension)
            $i++
        }

        try {
            if ($PSCmdlet.ShouldProcess($file.FullName, "Move to review folder")) {
                Move-Item -Path $file.FullName -Destination $destPath -Force -ErrorAction Stop
                Write-Log "Moved: $($file.Name) → duplicates-to-review\"
                $moved++
            }
        }
        catch {
            Write-Log "ERROR moving $($file.FullName): $_"
            $errors++
        }
    }
}

Write-Host ""
Write-Log "=== RESOLUTION PASS FINISHED ==="
Write-Log "Files moved to review folder : $moved"
Write-Log "Errors                       : $errors"
Write-Log "Log file                     : $logFile"

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Check the files moved to '$ReviewFolder'"
Write-Host "  2. Run tbcheck on a few of them if you want extra safety"
Write-Host "  3. When you're comfortable, you can delete the review folder (or keep it as backup)"
Write-Host "  4. Re-run .\Syzygy-Quick-Status.ps1 to see the cleaned state"
