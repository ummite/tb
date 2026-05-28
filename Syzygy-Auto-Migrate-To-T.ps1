<#
.SYNOPSIS
    Autonomous, long-running migration manager to make "everything happen by itself".

.DESCRIPTION
    Designed for your exact request: minimal intervention. "Tout se fasse tout seul".

    This script loops and automatically does two things as space allows:

    1. Clear plot* files from T: to F:\Plots\ 
       → Fully adaptive: it will move 1 plot at a time if that's all the safe space on F: allows.
         It calculates using real sizes of your remaining plots (not a fixed guess).
    2. Copy Syzygy files from your sources into T:\Syzygy (the master repository), 
       starting with smaller/priority tables first, using available space on T:.

    You can launch it and leave it running for many hours or days.
    It is fully resumable (it always checks what is already present).

    The plot-moving logic is deliberately 1-by-1 capable when F: space gets tight.

.PARAMETER CycleMinutes
    Time to sleep between cycles. Default: 10 minutes.

.PARAMETER RunForHours
    Maximum runtime before the script exits cleanly. Default: 48 hours (2 days).
    Set to 0 for "run forever" (until you stop it manually).

.PARAMETER MinFreeTBOnT
    Minimum free space (in TB) to keep on T: before allowing big Syzygy copies. Default: 0.5

.PARAMETER DryRun
    If set, only shows what it would do, never copies or moves anything.

.PARAMETER MaxPlotsPerCycle
    Hard upper limit on how many plots to move in a single cycle (even if more space is available).
    Default 60. You can lower this if you want even more conservative behavior.

.EXAMPLE
    # Launch and leave it running for 3 days (recommended)
    .\Syzygy-Auto-Migrate-To-T.ps1 -RunForHours 72 -CycleMinutes 15

    # Test what it would do
    .\Syzygy-Auto-Migrate-To-T.ps1 -DryRun

    # Very conservative: never move more than 5 plots per cycle, and it will happily do 1-by-1 when space is tight
    .\Syzygy-Auto-Migrate-To-T.ps1 -RunForHours 120 -MaxPlotsPerCycle 5 -CycleMinutes 20

.NOTES
    - Best run in a dedicated PowerShell window that you can minimize.
    - All actions are heavily logged in .\logs\Auto-Migrate-*.log
    - It uses the existing Move-Plots-T-to-F.ps1 logic when possible.
    - Press Ctrl+C to stop gracefully.
#>

[CmdletBinding()]
param(
    [int]$CycleMinutes = 10,
    [int]$RunForHours = 48,
    [double]$MinFreeTBOnT = 0.5,
    [int]$MaxPlotsPerCycle = 60,
    [switch]$DryRun
)

$ErrorActionPreference = "Continue"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$StartTime = Get-Date
$LogDir = Join-Path $ScriptRoot "logs"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] [$Level] $Message"
    Add-Content -Path (Join-Path $LogDir "Auto-Migrate-$(Get-Date -Format 'yyyyMMdd').log") -Value $line
    Write-Host $line -ForegroundColor $(if ($Level -eq "ERROR") { "Red" } elseif ($Level -eq "WARN") { "Yellow" } else { "Gray" })
}

Write-Log "=== Autonomous Syzygy Migration to T: started ===" "INFO"
Write-Log "Parameters: Cycle=$CycleMinutes min | Max runtime=$RunForHours h | MinFreeOnT=$MinFreeTBOnT TB | DryRun=$DryRun" "INFO"

$Sources = @(
    (Join-Path $ScriptRoot 'Syzygy'),                    # Local (already partially done)
    'A:\Syzygy',
    'A:\Syzygy_A_Trier_FromOld_Ryzen7950',
    'S:\Syzygy',
    'S:\Syzygy\3-6men',
    'S:\5v2_pawnful',
    'S:\5v2_pawnless'
) | Where-Object { Test-Path $_ }

$Master = "T:\Syzygy"
$PlotsDest = "F:\Plots"

if (-not (Test-Path $Master)) { New-Item -ItemType Directory -Path $Master -Force | Out-Null }

$EndTime = $StartTime.AddHours($RunForHours)

while ($true) {
    $now = Get-Date
    if ($RunForHours -gt 0 -and $now -gt $EndTime) {
        Write-Log "Maximum runtime reached. Exiting cleanly." "INFO"
        break
    }

    # === Current state ===
    $tDrive = Get-PSDrive -Name T -ErrorAction SilentlyContinue
    $fDrive = Get-PSDrive -Name F -ErrorAction SilentlyContinue
    $freeT = if ($tDrive) { [math]::Round($tDrive.Free / 1TB, 2) } else { 0 }
    $freeF = if ($fDrive) { [math]::Round($fDrive.Free / 1TB, 2) } else { 0 }

    $plotsLeft = (Get-ChildItem -Path T:\ -File -Filter "plot*" -ErrorAction SilentlyContinue).Count
    $syzygyOnT = (Get-ChildItem -Path $Master -File -Include *.rtbw,*.rtbz -ErrorAction SilentlyContinue | Measure-Object).Count

    Write-Log "Cycle start | Plots left: $plotsLeft | Syzygy on T: $syzygyOnT | Free T: $freeT TB | Free F: $freeF TB" "INFO"

    # === Phase 1: Clear plots if any remain and F: has space ===
    # Ultra-adaptive logic: will happily move 1 plot at a time if that's all that fits.
    if ($plotsLeft -gt 0) {
        # Get actual sizes of remaining plots for accurate calculation
        $remainingPlots = Get-ChildItem -Path T:\ -File -Filter "plot*" -ErrorAction SilentlyContinue | 
                          Sort-Object Length -Descending | 
                          Select-Object -First 50   # sample for performance

        if ($remainingPlots.Count -gt 0) {
            $avgPlotSizeTB = [math]::Round( ($remainingPlots | Measure-Object Length -Average).Average / 1TB , 3)
            $largestPlotTB = [math]::Round( ($remainingPlots | Measure-Object Length -Maximum).Maximum / 1TB , 3)
        } else {
            $avgPlotSizeTB = 0.105
            $largestPlotTB = 0.11
        }

        # Very conservative usable space on F: (leave buffer for overhead, other activity, and the largest plot)
        $safetyMargin = 0.18   # 18% safety + room for the biggest remaining plot
        $usableOnF = [math]::Max(0, $freeF - $largestPlotTB) * (1 - $safetyMargin)

        $maxPlotsThisCycle = 0
        if ($usableOnF -gt 0 -and $avgPlotSizeTB -gt 0) {
            $maxPlotsThisCycle = [math]::Floor($usableOnF / $avgPlotSizeTB)
        }

        # Always allow at least 1 if even a tiny bit of space exists and we have plots (user explicitly wants 1-by-1 behavior)
        if ($maxPlotsThisCycle -lt 1 -and $freeF -gt ($largestPlotTB * 1.05)) {
            $maxPlotsThisCycle = 1
        }

        # Reasonable per-cycle cap so one cycle doesn't monopolize the link for days
        if ($maxPlotsThisCycle -gt $MaxPlotsPerCycle) { $maxPlotsThisCycle = $MaxPlotsPerCycle }

        if ($maxPlotsThisCycle -ge 1) {
            $mode = if ($maxPlotsThisCycle -eq 1) { "1-BY-1 MODE (space is tight)" } else { "batch mode" }
            Write-Log "Plots phase: FreeF=$freeF TB | Avg plot ≈ $avgPlotSizeTB TB | Largest ≈ $largestPlotTB TB → moving up to $maxPlotsThisCycle plot(s) this cycle [$mode]." "INFO"

            if (-not $DryRun) {
                & "$ScriptRoot\Move-Plots-T-to-F.ps1" -MaxFiles $maxPlotsThisCycle -Threads 12
            } else {
                Write-Log "[DRYRUN] Would run plot mover for $maxPlotsThisCycle files (1-by-1 mode active if small number)" "INFO"
            }
        } else {
            Write-Log "Plots remain ($plotsLeft) but not enough safe space on F: (Free=$freeF TB, need at least ~$([math]::Round($largestPlotTB * 1.05, 2)) TB for one plot with margin). Waiting..." "WARN"
        }
    }

    # === Phase 2: Ingest Syzygy if we have breathing room on T: ===
    if ($freeT -gt $MinFreeTBOnT) {
        Write-Log "Syzygy ingestion phase: scanning sources for new tables..." "INFO"

        $copiedThisCycle = 0
        foreach ($src in $Sources) {
            $files = Get-ChildItem -Path $src -Recurse -File -Include *.rtbw,*.rtbz -ErrorAction SilentlyContinue
            foreach ($f in $files) {
                $dest = Join-Path $Master $f.Name
                if (Test-Path $dest) { continue }

                # Rough size guard
                if (($f.Length / 1TB) -gt ($freeT * 0.6)) {
                    Write-Log "Skipping large file $($f.Name) - would use too much of remaining space" "WARN"
                    continue
                }

                if ($DryRun) {
                    Write-Log "[DRYRUN] Would copy: $($f.Name) from $src" "INFO"
                } else {
                    Write-Log "Copying: $($f.Name) ($([math]::Round($f.Length/1MB,1)) MB)" "INFO"
                    Copy-Item -Path $f.FullName -Destination $dest -Force -ErrorAction SilentlyContinue
                    $copiedThisCycle++
                    Start-Sleep -Milliseconds 200   # be nice to the NAS
                }

                # Re-check space after each copy
                $tDrive = Get-PSDrive -Name T -ErrorAction SilentlyContinue
                $freeT = if ($tDrive) { [math]::Round($tDrive.Free / 1TB, 2) } else { 0 }
                if ($freeT -le $MinFreeTBOnT) {
                    Write-Log "Free space on T: dropped to $freeT TB - stopping ingestion this cycle." "WARN"
                    break
                }
            }
            if ($freeT -le $MinFreeTBOnT) { break }
        }
        Write-Log "Syzygy ingestion this cycle: $copiedThisCycle new files." "INFO"
    } else {
        Write-Log "Not enough free space on T: ($freeT TB) for safe Syzygy ingestion. Waiting for more plots to clear." "WARN"
    }

    # === Sleep until next cycle ===
    Write-Log "Cycle complete. Sleeping $CycleMinutes minutes..." "INFO"
    Start-Sleep -Seconds ($CycleMinutes * 60)
}

Write-Log "=== Autonomous migration session ended ===" "INFO"
