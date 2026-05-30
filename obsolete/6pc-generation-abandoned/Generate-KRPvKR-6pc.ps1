<#
.SYNOPSIS
    Launch generation of one 6-piece Syzygy table (KRPvKR) into a separate 6men folder.
.DESCRIPTION
    - Outputs only to T:\Syzygy\6men\
    - Reads 3-5pc from T:\Syzygy\3-6men\
    - Uses all 24 cores + disk mode (-d)
    - Logs everything to logs\KRPvKR_6pc_generation.log
#>

$ErrorActionPreference = 'Continue'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# === Configuration ===
$RTBPATH     = "T:\Syzygy\3-6men"          # Where to read 3-5pc tables from
$OutputDir   = "T:\Syzygy\6men"            # Dedicated folder for 6pc only
$LogDir      = Join-Path $ScriptDir "logs"
$LogFile     = Join-Path $LogDir "KRPvKR_6pc_generation.log"
$StatsDir    = Join-Path $ScriptDir "stats"

# === Prepare folders ===
foreach ($dir in @($OutputDir, $LogDir, $StatsDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# === Set environment for the generator ===
$env:RTBPATH     = $RTBPATH
$env:RTBWDIR     = $OutputDir
$env:RTBZDIR     = $OutputDir
$env:RTBSTATSDIR = $StatsDir

# === Build command ===
$exe = Join-Path $ScriptDir "bin\rtbgenp.exe"
$arguments = @("-t", "24", "-d", "KRPvKR")

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting 6-piece generation: KRPvKR" -ForegroundColor Cyan
Write-Host "RTBPATH     : $env:RTBPATH" -ForegroundColor Yellow
Write-Host "Output dir  : $OutputDir" -ForegroundColor Yellow
Write-Host "Log file    : $LogFile" -ForegroundColor Yellow
Write-Host "Threads     : 24" -ForegroundColor Yellow
Write-Host "Disk mode   : ON (-d)" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

# Ensure log header
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"[$timestamp] === Starting KRPvKR 6-piece generation ===" | Out-File -FilePath $LogFile -Append -Encoding UTF8
"[$timestamp] RTBPATH=$env:RTBPATH" | Out-File -FilePath $LogFile -Append -Encoding UTF8
"[$timestamp] Output=$OutputDir" | Out-File -FilePath $LogFile -Append -Encoding UTF8

# === Launch the generator with live logging ===
try {
    & $exe @arguments 2>&1 | Tee-Object -FilePath $LogFile -Append
    $exitCode = $LASTEXITCODE
} catch {
    $exitCode = 999
    "[$timestamp] ERROR: $_" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

$endTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"[$endTime] === Generation finished with exit code $exitCode ===" | Out-File -FilePath $LogFile -Append -Encoding UTF8

if ($exitCode -eq 0 -and (Test-Path "$OutputDir\KRPvKR.rtbw") -and (Test-Path "$OutputDir\KRPvKR.rtbz")) {
    Write-Host "SUCCESS: KRPvKR 6-piece table generated successfully!" -ForegroundColor Green
    "SUCCESS: Both .rtbw and .rtbz created." | Out-File -FilePath $LogFile -Append -Encoding UTF8
} else {
    Write-Host "GENERATION ENDED (exit=$exitCode). Check the log for details." -ForegroundColor Yellow
}

Write-Host "Log file: $LogFile"
Write-Host "Output folder: $OutputDir"