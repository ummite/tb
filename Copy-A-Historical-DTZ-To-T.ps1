<#
.SYNOPSIS
    Ultra-simple, clean robocopy wrapper to bring the A: historical 6/7pc DTZ goldmine to T:\Syzygy.

.USAGE
    1. .\Copy-A-Historical-DTZ-To-T.ps1 -WhatIf
    2. .\Copy-A-Historical-DTZ-To-T.ps1 -MaxFiles 50
    3. Run multiple times until done.
#>

param(
    [int]$MaxFiles = 0,
    [int]$Threads = 12,
    [switch]$WhatIf,
    [switch]$Log
)

$src  = "A:\Syzygy_A_Trier_FromOld_Ryzen7950"
$dest = "T:\Syzygy\A_Historical_DTZ"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logDir = ".\logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = Join-Path $logDir "Copy-A-Historical-DTZ_$timestamp.log"

if ($Log) {
    function Write-Log($msg) { 
        $line = "[$(Get-Date -Format 'HH:mm:ss')] $msg"
        Add-Content $logFile -Value $line -Encoding UTF8
        Write-Host $line
    }
} else {
    function Write-Log($msg) { Write-Host $msg }
}

if (-not (Test-Path $src)) { Write-Error "Source not found: $src"; exit 1 }
if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }

Write-Host "=== COPY A: Historical DTZ 6/7pc → T:\Syzygy ===" -ForegroundColor Magenta
Write-Host "Source : $src"
Write-Host "Dest   : $dest"
Write-Host "MaxFiles: $(if ($MaxFiles -gt 0) { $MaxFiles } else { 'All' })"
if ($Log) { Write-Host "Log    : $logFile" }
Write-Host ""

$files = Get-ChildItem $src -Recurse -File -Include *.rtbz | Sort-Object Length -Descending

$toCopy = if ($MaxFiles -gt 0) { $files | Select-Object -First $MaxFiles } else { $files }

$copied = 0
foreach ($f in $toCopy) {
    $destFile = Join-Path $dest $f.Name
    if (Test-Path $destFile) {
        if ((Get-Item $destFile).Length -eq $f.Length) {
            Write-Host "SKIP (exists) $($f.Name)" -ForegroundColor DarkGray
            continue
        }
    }

    if ($WhatIf) {
        Write-Log "[WHATIF] $($f.Name)  ($([math]::Round($f.Length/1GB,1)) GB)"
        $copied++
        continue
    }

    Write-Log "Copying $($f.Name) ($([math]::Round($f.Length/1GB,1)) GB)..."
    robocopy (Split-Path $f.FullName -Parent) $dest $f.Name /COPY:DAT /R:2 /W:3 /MT:$Threads /NFL /NDL | Out-Null
    if ($LASTEXITCODE -lt 8) {
        $copied++
        Write-Log "  OK"
    } else {
        Write-Log "  FAILED (robocopy exit $LASTEXITCODE)"
    }
}

Write-Host ""
Write-Log "=== PASS FINISHED ==="
Write-Log "Copied this pass: $copied files"
Write-Log "Log file: $logFile"

Write-Host "`nRe-run the same command later — it will automatically skip files already present with matching size." -ForegroundColor Cyan
Write-Host "When ready for bigger volume: remove -MaxFiles or increase it." -ForegroundColor Yellow
