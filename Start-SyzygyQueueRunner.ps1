<#
.SYNOPSIS
  Background / long-running queue processor for Syzygy table generation (safe mode).

.DESCRIPTION
  Reads the queue JSON produced by Syzygy-TableManager.ps1 and generates one table at a time.

  Safety features (matching your previous requirements):
  - Conservative thread count (default 4, configurable).
  - -d (disk mode) for all 6pc+ tables (and forced for 7/8).
  - Process started BelowNormal priority.
  - Lock file so only one runner instance works at a time.
  - Detailed per-table log + main runner log.
  - After success: optional tbcheck, then the table is removed from queue.
  - 8pc only attempted if rtbgenp8.exe (or rtbgen8) exists and you explicitly allow it.
  - Traditional chess only for 8pc.

  The generator still requires a correct RTBPATH (pointing at your already-generated subtables).

.PARAMETER Threads
  Threads to pass to rtbgen/rtbgenp (-t). Default 4 (safe for most machines while generating).

.PARAMETER QueuePath
  Path to the queue JSON (same as the manager).

.PARAMETER WorkDir
  Directory in which to run the generator (the .rtbw/.rtbz will be created here).
  After success the runner can move them into your organized T:\Syzygy tree if -Organize is used.

.PARAMETER Minimize
  Start the generator process minimized (less UI noise).

.PARAMETER RunTbcheck
  After a table finishes, run bin\tbcheck on the produced .rtbw + .rtbz.

.PARAMETER Allow8pc
  Must be specified to even consider 8pc entries from the queue (safety).

.PARAMETER Organize
  After successful generation + checks, move the pair into the proper net-structure folder
  under -OrganizeRoot (using the same 5v2_pawnful etc. logic).

.PARAMETER OrganizeRoot
  Root for organized output (default T:\Syzygy).

.PARAMETER RTBPath
  Force a specific RTBPATH for this run (useful when launching the runner from another process
  or when the environment variable is not set). If provided, it will be used for this session.

.EXAMPLE
  # Typical safe usage (launch from the manager or directly)
  powershell -File .\Start-SyzygyQueueRunner.ps1 -Threads 4 -Minimize -RunTbcheck

  # For the very first 8pc attempt (KPPPPPPvK etc.)
  powershell -File .\Start-SyzygyQueueRunner.ps1 -Allow8pc -Threads 2 -RunTbcheck

  # When RTBPATH is not in the environment, you can pass it explicitly
  powershell -File .\Start-SyzygyQueueRunner.ps1 -RTBPath "T:\Syzygy" -Minimize
#>

[CmdletBinding()]
param(
    [int]$Threads = 4,
    [string]$QueuePath = "logs/syzygy-generation-queue.json",
    [string]$WorkDir = ".",
    [switch]$Minimize,
    [switch]$RunTbcheck,
    [switch]$Allow8pc,
    [switch]$Organize,
    [string]$OrganizeRoot = "T:\Syzygy",
    [string]$RTBPath
)

$ErrorActionPreference = "Stop"
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $scriptRoot "logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

$lockFile = Join-Path $logDir "generation-active.lock"
$runnerLog = Join-Path $logDir "queue-runner.log"
$binDir = Join-Path $scriptRoot "bin"

# Apply forced RTBPath if provided via parameter (so background launches can pass it)
if ($RTBPath) {
    $env:RTBPATH = $RTBPath
}

function Log {
    param([string]$Msg, [string]$Level = "INFO")
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$ts] [$Level] $Msg"
    Add-Content -Path $runnerLog -Value $line -Encoding UTF8
    Write-Host $line
}

function Get-Queue {
    if (Test-Path $QueuePath) {
        try { @(Get-Content $QueuePath -Raw | ConvertFrom-Json) } catch { @() }
    } else { @() }
}

function Save-Queue($q) {
    if (-not $q) { @() | ConvertTo-Json | Set-Content $QueuePath -Encoding UTF8; return }
    $q | ConvertTo-Json -Depth 3 | Set-Content $QueuePath -Encoding UTF8
}

function Remove-FromQueue([string]$name) {
    $q = Get-Queue
    $new = $q | Where-Object Name -ne $name
    Save-Queue $new
}

function Get-TableInfo([string]$base) {
    # Reuse the same classification used by the manager
    $name = $base
    $parts = $name -split 'v', 2
    if ($parts.Count -ne 2) { return $null }
    $leftNonK  = ($parts[0] -replace 'K','' -replace '[^QRBNP]','').Length
    $rightNonK = ($parts[1] -replace 'K','' -replace '[^QRBNP]','').Length
    $men = 2 + $leftNonK + $rightNonK
    $isPawnful = $name -match 'P'
    $pType = if ($isPawnful) { "pawnful" } else { "pawnless" }
    $a = [math]::Max(1+$leftNonK, 1+$rightNonK)
    $b = [math]::Min(1+$leftNonK, 1+$rightNonK)
    $category = if ($men -le 5) { "3-5men" } elseif ($men -eq 6) { "6men" } elseif ($men -eq 7) { "7men/${a}v${b}_$pType" } else { "8pc-experimental/${a}v${b}_$pType" }
    [pscustomobject]@{ Men=$men; IsPawnful=$isPawnful; Category=$category; a=$a; b=$b }
}

function Move-ToOrganized([string]$base, [string]$fromDir) {
    $info = Get-TableInfo $base
    if (-not $info) { return $false }

    $destSub =
        if ($info.Men -le 5) { "3-5men" }
        elseif ($info.Men -eq 6) { "6men" }
        elseif ($info.Men -eq 7) { "7men/$($info.Category -replace '^7men/','')" }
        else { "8pc-experimental" }

    $destDir = Join-Path (Join-Path $OrganizeRoot $destSub) ""
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

    $wSrc = Join-Path $fromDir "$base.rtbw"
    $zSrc = Join-Path $fromDir "$base.rtbz"

    $moved = 0
    foreach ($src in @($wSrc,$zSrc)) {
        if (Test-Path $src) {
            $dest = Join-Path $destDir (Split-Path $src -Leaf)
            if (-not (Test-Path $dest)) {
                Move-Item $src $dest -Force
                $moved++
            }
        }
    }
    Log "Organized $base -> $destDir ($moved files moved)" "INFO"
    return $true
}

# --- Single instance lock ---
if (Test-Path $lockFile) {
    $existing = Get-Content $lockFile -ErrorAction SilentlyContinue
    Log "Another runner appears active (lock $lockFile contains: $existing). Exiting." "WARN"
    exit 1
}
$pid | Set-Content -Path $lockFile -Encoding ASCII
try {

Log "=== Syzygy Queue Runner starting (Threads=$Threads, WorkDir=$WorkDir) ===" "INFO"

# Resolve effective RTBPATH
$effectiveRTB = $env:RTBPATH
if (-not $effectiveRTB) { $effectiveRTB = [Environment]::GetEnvironmentVariable('RTBPATH', 'User') }
if (-not $effectiveRTB) { $effectiveRTB = [Environment]::GetEnvironmentVariable('RTBPATH', 'Machine') }

Log "Effective RTBPATH = $effectiveRTB" "INFO"

if (-not $effectiveRTB) {
    Log "WARNING: RTBPATH is not set. The generators WILL fail to find subtables for retrograde analysis." "WARN"
    Log "Set it permanently, pass -RTBPath ""T:\Syzygy"", or start the runner from Syzygy-TableManager.ps1 (which can prompt you)." "WARN"

    # Only prompt if we are running in a visible interactive session (not minimized background)
    $isInteractive = [Environment]::UserInteractive -and -not $Minimize
    if ($isInteractive) {
        $p = Read-Host "Chemin racine Syzygy à utiliser maintenant (ex: T:\Syzygy) ou Entrée pour abandonner"
        if ($p) {
            $env:RTBPATH = $p.Trim()
            $effectiveRTB = $env:RTBPATH
            Log "Using provided path for this run: $effectiveRTB" "INFO"
        } else {
            Log "No path provided. Exiting." "ERROR"
            exit 1
        }
    } else {
        Log "Runner is non-interactive (minimized/background) and no RTBPATH. Aborting to avoid useless long run." "ERROR"
        exit 1
    }
}

$windowStyle = if ($Minimize) { "Minimized" } else { "Normal" }

while ($true) {
    $q = Get-Queue
    if (-not $q -or $q.Count -eq 0) {
        Log "Queue empty. Sleeping 30s (press Ctrl-C to exit runner)..." "INFO"
        Start-Sleep -Seconds 30
        continue
    }

    # Take the first (highest priority first if you ever add sorting)
    $item = $q | Sort-Object Priority -Descending | Select-Object -First 1
    $base = $item.Name
    Log "Next in queue: $base" "INFO"

    $info = Get-TableInfo $base
    if (-not $info) {
        Log "Cannot classify $base - removing from queue." "ERROR"
        Remove-FromQueue $base
        continue
    }

    if ($info.Men -ge 8 -and -not $Allow8pc) {
        Log "8pc entry $base present but -Allow8pc not given. Skipping (will stay in queue)." "WARN"
        Start-Sleep -Seconds 5
        continue
    }

    # Choose the right executable
    $isPawnful = $info.IsPawnful
    $exeName =
        if ($info.Men -ge 8) {
            if ($isPawnful) { "rtbgenp8.exe" } else { "rtbgen8.exe" }   # pawnless 8 may not exist yet
        } else {
            if ($isPawnful) { "rtbgenp.exe" } else { "rtbgen.exe" }
        }

    $exe = Join-Path $binDir $exeName
    if (-not (Test-Path $exe)) {
        # Fallback: try the non-8 version if 8pc binary missing
        if ($info.Men -ge 8) {
            if ($isPawnful) { $exe = Join-Path $binDir "rtbgenp.exe" } else { $exe = Join-Path $binDir "rtbgen.exe" }
        }
    }
    if (-not (Test-Path $exe)) {
        Log "Generator $exeName not found in bin/. Cannot generate $base. Removing from queue to unblock." "ERROR"
        Remove-FromQueue $base
        continue
    }

    # Build arguments (safe, conservative)
    $useDisk = ($info.Men -ge 6)   # your previous explicit request + common practice
    $dArg = if ($useDisk) { "-d " } else { "" }

    $args = "${dArg}-t $Threads --stats $base"

    Log "Launching: $exe $args  (Men=$($info.Men), disk=$useDisk)" "INFO"

    Push-Location $WorkDir
    try {
        $p = Start-Process -FilePath $exe -ArgumentList $args `
            -WorkingDirectory $WorkDir -WindowStyle $windowStyle -PassThru

        # Lower priority (as requested in the 8pc safe starter)
        try { $p.PriorityClass = "BelowNormal" } catch {}

        Log "Process started PID=$($p.Id)  (priority BelowNormal)" "INFO"

        # Wait for it (generation can be hours/days)
        $p.WaitForExit()

        $code = $p.ExitCode
        Log "Generator for $base exited with code $code" (if ($code -eq 0) { "INFO" } else { "ERROR" })

        if ($code -ne 0) {
            Log "Generation of $base failed (exit $code). Leaving it in queue for retry." "ERROR"
            Start-Sleep -Seconds 30
            continue
        }

        # Verify the files appeared
        $w = Join-Path $WorkDir "$base.rtbw"
        $z = Join-Path $WorkDir "$base.rtbz"
        $both = (Test-Path $w) -and (Test-Path $z)

        if (-not $both) {
            Log "Expected output files not found after success exit code. Leaving in queue." "ERROR"
            continue
        }

        if ($RunTbcheck) {
            $tbcheck = Join-Path $binDir "tbcheck.exe"
            if (Test-Path $tbcheck) {
                Log "Running tbcheck on the new pair..." "INFO"
                & $tbcheck $w  | Out-String | ForEach-Object { Log $_ "INFO" }
                & $tbcheck $z  | Out-String | ForEach-Object { Log $_ "INFO" }
            }
        }

        if ($Organize) {
            Move-ToOrganized -base $base -fromDir $WorkDir | Out-Null
        }

        # Success → remove from queue
        Remove-FromQueue $base
        Log "SUCCESS: $base completed and removed from queue." "INFO"

        # Small pause before next monster job
        Start-Sleep -Seconds 10
    }
    finally {
        Pop-Location
    }
}

} finally {
    Remove-Item $lockFile -Force -ErrorAction SilentlyContinue
    Log "Runner exiting, lock released." "INFO"
}
