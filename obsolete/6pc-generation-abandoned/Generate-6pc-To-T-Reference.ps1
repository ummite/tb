<#
.SYNOPSIS
    Generate 6-piece Syzygy tables directly into T:\Syzygy\6men (your reference).
.DESCRIPTION
    - RTBPATH is set to T:\Syzygy\3-6men (your reference collection)
    - Output goes directly to T:\Syzygy\6men
    - Conservative defaults for stability on large RAID/network storage
    - Good logging
#>

param(
    [string]$Table = "KRPvKR",
    [int]$Threads = 4,                    # Very conservative for stability on T:
    [switch]$NoDiskMode                   # Add -NoDiskMode if you have enough RAM and want to try without -d
)

$ErrorActionPreference = 'Continue'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# === Your reference paths ===
$RTBPATH       = "T:\Syzygy\3-6men"       # Your reference for lower tables
$OutputDir     = "T:\Syzygy\6men"         # Your reference 6men folder
$LogDir        = Join-Path $ScriptDir "logs"
$LogFile       = Join-Path $LogDir "Generate-6pc-To-T-Reference.log"
$StatsDir      = Join-Path $ScriptDir "stats"

# === Prepare folders ===
@($OutputDir, $LogDir, $StatsDir) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

# === Environment ===
$env:RTBPATH     = $RTBPATH
$env:RTBWDIR     = $OutputDir
$env:RTBZDIR     = $OutputDir
$env:RTBSTATSDIR = $StatsDir

$exe = Join-Path $ScriptDir "bin\rtbgenp.exe"

Write-Host "=== GENERATE 6-PIECE INTO YOUR T:\Syzygy REFERENCE ===" -ForegroundColor Cyan
Write-Host "Table          : $Table"
Write-Host "Threads        : $Threads (conservative for T: stability)"
Write-Host "RTBPATH        : $env:RTBPATH"
Write-Host "Output         : $OutputDir (directly into your reference)"
Write-Host "Disk mode (-d) : $(if ($NoDiskMode) { 'OFF' } else { 'ON' })"
Write-Host "Log            : $LogFile"
Write-Host ""

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"[$timestamp] === Starting 6pc generation into T:\Syzygy reference ===" | Out-File $LogFile -Append
"[$timestamp] Table=$Table | Threads=$Threads | NoDiskMode=$NoDiskMode" | Out-File $LogFile -Append

$diskOpt = if ($NoDiskMode) { "" } else { "-d " }

try {
    Write-Host "Launching generator..." -ForegroundColor Yellow

    $process = Start-Process -FilePath $exe `
                             -ArgumentList @("-t", $Threads, "-d", $Table) `
                             -WorkingDirectory $ScriptDir `
                             -RedirectStandardOutput "$LogFile.stdout.txt" `
                             -RedirectStandardError "$LogFile.stderr.txt" `
                             -PassThru

    Write-Host "Generator running (PID $($process.Id)). This can take many hours..." -ForegroundColor Green

    $process.WaitForExit()
    $exitCode = $process.ExitCode

} catch {
    $exitCode = 999
    "[$timestamp] ERROR: $_" | Out-File $LogFile -Append
}

$end = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"[$end] Generator finished with exit code $exitCode" | Out-File $LogFile -Append

# Check results
$wdl = Join-Path $OutputDir "$Table.rtbw"
$dtz = Join-Path $OutputDir "$Table.rtbz"

if ($exitCode -eq 0 -and (Test-Path $wdl) -and (Test-Path $dtz)) {
    Write-Host "SUCCESS! $Table generated and saved to $OutputDir" -ForegroundColor Green
    "SUCCESS - Files created in T:\Syzygy\6men" | Out-File $LogFile -Append
} else {
    Write-Host "Generation ended (exit=$exitCode). Check logs:" -ForegroundColor Yellow
    Write-Host "  $LogFile"
    Write-Host "  $LogFile.stdout.txt"
    Write-Host "  $LogFile.stderr.txt"
    "FAILED or incomplete - exit=$exitCode" | Out-File $LogFile -Append
}

Write-Host "`nDone. Main log: $LogFile"