<#
.SYNOPSIS
Safe launcher for 8pc KPPPPPPvK generation on T: (or current drive) using disk-backed low-RAM mode.
Validates disk space and RAM before start, monitors during run to prevent crash, supports low threads.
Run this AFTER cd to a dir on T: with enough free space (e.g. cd T:\8pc_work).

Usage:
  cd T:\path\with\60TB+free
  .\Start-8pc-KPPPPPPvK-OnT-Safe.ps1 -Threads 1 -MonitorRAMGB 12

Requires the 8pc low-ram exe: bin\rtbgenp8.exe (or set -ExePath).
#>
param(
    [int]$Threads = 1,
    [double]$MonitorRAMGB = 12,   # Kill if process WS > this (leave headroom)
    [double]$MinDiskFreeTB = 55,  # Warn/fail if current drive free < this
    [string]$ExePath = "C:\Programmation\tb-1\bin\rtbgenp8.exe",
    [string]$TableName = "KPPPPPPvK",
    [switch]$DryRun,
    [int]$VTCacheGB = 32,          # RAM cache for VirtualTable (bounded, not full table)
    [string[]]$VTBackings = @("T:\8pc_backing1", "T:\8pc_backing2"),  # multiple for disk distribution / SAN
    [switch]$UseVT                       # Use the advanced VirtualTable instead of simple mapped
)

$ErrorActionPreference = "Stop"
$startDir = Get-Location
$drive = (Get-Item $startDir).PSDrive.Name
Write-Host "=== Safe 8pc KPPPPPPvK launch on drive $drive ===" -ForegroundColor Cyan
Write-Host "CWD: $startDir (temps will go here - ensure on T: or large volume)"
Write-Host "Using exe: $ExePath"
Write-Host "Threads: $Threads (low recommended for stability on disk)"
Write-Host "Monitor kill threshold: $MonitorRAMGB GB process WS"

# 1. Validate disk space - critical for T: (user target for large backing)
$driveInfo = Get-PSDrive $drive
$freeTB = [math]::Round($driveInfo.Free / 1TB, 2)
$totalTB = [math]::Round(($driveInfo.Used + $driveInfo.Free) / 1TB, 2)
Write-Host "Current drive $drive free: $freeTB TB / $totalTB TB total"

# Always also check T: (the large volume for 8pc temps)
try {
    $tInfo = Get-PSDrive T -ErrorAction Stop
    $tFreeTB = [math]::Round($tInfo.Free / 1TB, 2)
    Write-Host "T: free: $tFreeTB TB (primary target for ~53+ TB backing + stores)"
} catch {
    $tFreeTB = 0
    Write-Warning "Could not query T: - ensure it's mounted."
}

$backingTB = 52.78
$storesTB = 52.0   # rough for stores during compress phase
$minForThis = $backingTB + $storesTB + 5
if ($drive -eq 'T' -or $tFreeTB -gt 0) {
    $relevantFree = if ($drive -eq 'T') { $freeTB } else { $tFreeTB }
    if ($relevantFree -lt $MinDiskFreeTB) {
        Write-Warning "Only $relevantFree TB relevant free. 8pc KPPPPPPvK disk-backed needs ~$backingTB TB for the main temp analysis backing file (48 TiB) + temps for stores (~$storesTB TB) + final .rtb* + overhead."
        Write-Warning "You must have >$minForThis TB free on the volume where the generator runs (cwd) before starting. Free up space on T: first."
        if (-not $DryRun) {
            $resp = Read-Host "Continue anyway? Risk of running out mid-generation (y/N)"
            if ($resp -ne 'y') { exit 1 }
        }
    } else {
        Write-Host "Disk space on relevant volume looks OK for backing." -ForegroundColor Green
    }
}

# 2. Validate RAM
$os = Get-CimInstance Win32_OperatingSystem
$ramTotalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
$ramFreeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
Write-Host "System RAM: $ramTotalGB GB total, $ramFreeGB GB free"

if ($ramFreeGB -lt 30) {
    Write-Warning "Low free RAM ($ramFreeGB GB). With disk-mapping the generator itself should stay low (~active 1GB slices + small buffers), but OS cache may use free RAM. Consider closing other apps."
}

# 2b. VT / advanced disk-backed setup (for more disk + distributed)
if ($UseVT) {
    Write-Host "VT mode enabled: cache $VTCacheGB GB, backings: $($VTBackings -join ', ')" -ForegroundColor Cyan
    # TODO: call vt_drive_setup.exe or generate config file if the tool supports output
    # For now, document the paths; the generator will use VT with these when integrated
    $vtConfig = Join-Path $startDir "vt_config.txt"
    "cache_gb=$VTCacheGB`nbackings=$($VTBackings -join ';')" | Out-File $vtConfig -Encoding ascii
    Write-Host "Wrote $vtConfig for generator (future --vt-config support)"
    # Validate backing dirs exist or create
    foreach ($b in $VTBackings) {
        if (-not (Test-Path $b)) {
            New-Item -ItemType Directory -Path $b -Force | Out-Null
            Write-Host "Created backing dir $b"
        }
    }
}

# Check exe
if (-not (Test-Path $ExePath)) {
    Write-Error "8pc exe not found at $ExePath. Build with MAX_TBPIECES=8 or use bin\rtbgenp8.exe after updates."
    exit 1
}

# 3. Set env (adjust RTBPATH to your lower tables location on T: or elsewhere)
$env:RTBPATH = "T:\Syzygy"  # <-- CHANGE to your actual path with 3-7pc regular tables
$env:RTBSTATSDIR = Join-Path $startDir "stats"
if (-not (Test-Path $env:RTBSTATSDIR)) { New-Item -ItemType Directory -Path $env:RTBSTATSDIR -Force | Out-Null }

Write-Host "RTBPATH: $($env:RTBPATH)"
Write-Host "Stats dir: $($env:RTBSTATSDIR)"

$log = Join-Path $startDir "$TableName-8pc-run.log"
$errlog = Join-Path $startDir "$TableName-8pc-run.err"

if ($DryRun) {
    Write-Host "DRY RUN - would launch:" -ForegroundColor Yellow
    Write-Host "$ExePath $TableName -d -t $Threads --stats"
    Write-Host "With monitoring, low priority, space/RAM checks."
    exit 0
}

# 4. Launch with monitoring (similar to previous safe wrappers)
Write-Host "Launching (this will take a LONG time - disk I/O bound). Monitor every 10s for RAM/disk."
$argsList = @($TableName, "-d", "-t", $Threads, "--stats")
if ($UseVT) {
    $argsList += "--use-vt"
    # future: --vt-cache-gb $VTCacheGB --vt-backings ...
}
$p = Start-Process -FilePath $ExePath -ArgumentList $argsList `
    -WorkingDirectory $startDir -RedirectStandardOutput $log -RedirectStandardError $errlog -PassThru
if ($p) {
    $p.PriorityClass = 'BelowNormal'
    Write-Host "Started PID $($p.Id), BelowNormal priority. Logging to $log"
}

$start = Get-Date
$maxHours = 72  # safety, kill after long if needed
try {
    while (-not $p.HasExited) {
        Start-Sleep -Seconds 10
        $elapsedMin = [math]::Round( ((Get-Date) - $start).TotalMinutes , 1)
        if ($p.HasExited) { break }

        # RAM check
        $wsGB = if ($p -and -not $p.HasExited) { [math]::Round($p.WorkingSet64 / 1GB, 2) } else { 0 }
        $os2 = Get-CimInstance Win32_OperatingSystem
        $freeRAM = [math]::Round($os2.FreePhysicalMemory / 1MB, 1)
        $drive2 = Get-PSDrive $drive
        $freeDiskNow = [math]::Round($drive2.Free / 1TB, 2)

        Write-Host ("[{0}m] ProcWS={1}GB | SysFreeRAM={2}GB | Drive{3}Free={4}TB" -f $elapsedMin, $wsGB, $freeRAM, $drive, $freeDiskNow)

        if ($wsGB -gt $MonitorRAMGB) {
            Write-Warning "SAFETY: Process WS $wsGB GB > $MonitorRAMGB GB limit - killing."
            $p.Kill()
            break
        }
        if ($freeRAM -lt 15) {
            Write-Warning "SAFETY: System free RAM low ($freeRAM GB) - killing to protect PC."
            $p.Kill()
            break
        }
        if ($freeDiskNow -lt 5) {
            Write-Warning "SAFETY: Drive $drive free space critical ($freeDiskNow TB) - killing."
            $p.Kill()
            break
        }
        if ( ((Get-Date) - $start).TotalHours -gt $maxHours) {
            Write-Warning "SAFETY: Run exceeded $maxHours hours - killing."
            $p.Kill()
            break
        }
    }
} finally {
    if (-not $p.HasExited) { $p.Kill() }
    Start-Sleep 2
}

$exit = $p.ExitCode
Write-Host "=== Run finished (exit $exit) ===" -ForegroundColor $(if ($exit -eq 0) { 'Green' } else { 'Red' })
if (Test-Path $log) {
    Write-Host "Last 30 lines of log:"
    Get-Content $log -Tail 30
}
if (Test-Path $errlog) {
    $e = Get-Content $errlog -Tail 10
    if ($e) { Write-Host "Stderr tail:"; $e }
}

# Post-run: check if output appeared
$w = "$TableName.rtbw"
$z = "$TableName.rtbz"
if ( (Test-Path $w) -and (Test-Path $z) ) {
    Write-Host "SUCCESS: $w and $z created!" -ForegroundColor Green
    $wsize = (Get-Item $w).Length / 1GB
    $zsize = (Get-Item $z).Length / 1GB
    Write-Host "Final sizes: WDL ~$([math]::Round($wsize,2)) GB, DTZ ~$([math]::Round($zsize,2)) GB"
} else {
    Write-Host "No final .rtbw/.rtbz yet (may be partial or failed). Check logs and temps on $drive."
}

# Cleanup any leftover .tmp* if wanted
$tmps = Get-ChildItem -Path $startDir -Filter "*.tmp*.table" -ErrorAction SilentlyContinue
if ($tmps) {
    Write-Host "Leftover temp backing files (delete manually if not needed): $($tmps.Name -join ', ')"
}

Write-Host "Drive $drive free after: $(([math]::Round((Get-PSDrive $drive).Free / 1TB,2))) TB"
Write-Host "Done. If interrupted, resumption is limited - see comments in script for tips."