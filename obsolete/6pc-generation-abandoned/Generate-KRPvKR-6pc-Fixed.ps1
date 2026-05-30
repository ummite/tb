<#
.SYNOPSIS
    Safer version to generate KRPvKR (6-piece) with reduced crash risk.
.DESCRIPTION
    - Uses fewer threads (8 by default) to avoid overloading network storage.
    - Generates to a LOCAL fast temp folder first (much more stable) under 6men naming.
    - After successful generation, moves the two files to T:\Syzygy\6men\
    - Proper logging
#>

param(
    [int]$Threads = 8,
    [string]$LocalTempDir = "F:\SyzygyTemp\6men",   # Best available drive with lots of free space - using 6men naming as requested
    [string]$FinalOutputDir = "T:\Syzygy\6men"
)

$ErrorActionPreference = 'Continue'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# === Paths ===
$RTBPATH       = "T:\Syzygy\3-6men"
$LogDir        = Join-Path $ScriptDir "logs"
$LogFile       = Join-Path $LogDir "KRPvKR_6pc_FIXED.log"
$StatsDir      = Join-Path $ScriptDir "stats"

# === Prepare folders ===
@($LocalTempDir, $FinalOutputDir, $LogDir, $StatsDir) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

# === Environment ===
$env:RTBPATH     = $RTBPATH
$env:RTBWDIR     = $LocalTempDir
$env:RTBZDIR     = $LocalTempDir
$env:RTBSTATSDIR = $StatsDir

$exe = Join-Path $ScriptDir "bin\rtbgenp.exe"

Write-Host "=== SAFE 6-PIECE GENERATION ===" -ForegroundColor Cyan
Write-Host "Position       : KRPvKR"
Write-Host "Threads        : $Threads (reduced for stability)"
Write-Host "RTBPATH        : $env:RTBPATH"
Write-Host "Generate to    : $LocalTempDir (LOCAL - much safer)"
Write-Host "Final move to  : $FinalOutputDir"
Write-Host "Log            : $LogFile"
Write-Host ""

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"[$timestamp] === SAFE GENERATION START - KRPvKR ===" | Out-File $LogFile -Append
"[$timestamp] Threads=$Threads | LocalTemp=$LocalTempDir | Final=$FinalOutputDir" | Out-File $LogFile -Append

try {
    Write-Host "Launching generator... (this can take many hours)" -ForegroundColor Yellow
    
    $process = Start-Process -FilePath $exe `
                             -ArgumentList @("-t", $Threads, "-d", "KRPvKR") `
                             -WorkingDirectory $ScriptDir `
                             -RedirectStandardOutput "$LogFile.stdout.txt" `
                             -RedirectStandardError "$LogFile.stderr.txt" `
                             -PassThru

    Write-Host "Generator started with PID $($process.Id). Waiting for completion..." -ForegroundColor Green
    
    $process.WaitForExit()
    $exitCode = $process.ExitCode

} catch {
    $exitCode = 999
    "ERROR during launch: $_" | Out-File $LogFile -Append
}

$end = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"[$end] Generator exited with code $exitCode" | Out-File $LogFile -Append

# Check if both files were created in temp
$wdlTemp = Join-Path $LocalTempDir "KRPvKR.rtbw"
$dtzTemp = Join-Path $LocalTempDir "KRPvKR.rtbz"

if ($exitCode -eq 0 -and (Test-Path $wdlTemp) -and (Test-Path $dtzTemp)) {
    Write-Host "SUCCESS! Files generated in temp folder." -ForegroundColor Green
    
    # Move to final location
    Move-Item $wdlTemp -Destination (Join-Path $FinalOutputDir "KRPvKR.rtbw") -Force
    Move-Item $dtzTemp -Destination (Join-Path $FinalOutputDir "KRPvKR.rtbz") -Force
    
    Write-Host "Files moved to $FinalOutputDir" -ForegroundColor Green
    "SUCCESS - Files moved to final location" | Out-File $LogFile -Append
} else {
    Write-Host "GENERATION DID NOT COMPLETE SUCCESSFULLY (exit=$exitCode)" -ForegroundColor Red
    Write-Host "Check these files for details:"
    Write-Host "  $LogFile"
    Write-Host "  $LogFile.stdout.txt"
    Write-Host "  $LogFile.stderr.txt"
    "FAILED - exit=$exitCode" | Out-File $LogFile -Append
}

Write-Host "`nDone. Log: $LogFile"