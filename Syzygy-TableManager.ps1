<#
.SYNOPSIS
  Syzygy Table Manager - Interactive UI + Queue for generation (traditional chess focus).

.DESCRIPTION
  Shows all "possible" Syzygy tables (from the official checksums published on the net: 1511 tables for 3-7pc).
  - Color/status for present vs missing (WDL + DTZ pair).
  - Click / multi-select missing rows in Out-GridView to add them to a background generation queue.
  - Launch / monitor a safe background queue runner (low priority, conservative threads + -d where appropriate).
  - Also exports a nice standalone HTML dashboard you can keep open in your browser.

  IMPORTANT (per your rules):
  - Traditional/regular chess only for anything >7pc.
  - 8pc is EXPERIMENTAL and only a tiny number of high-pawn low-material candidates are realistic even with disk-backed generation.
  - You MUST have RTBPATH pointing to your existing tables before launching any generation.
  - Generation of 6pc+ is extremely slow and RAM/disk hungry. The queue runner uses safe defaults.

.USAGE
  # 1. Open the interactive manager (recommended)
  powershell -ExecutionPolicy Bypass -File .\Syzygy-TableManager.ps1

  # 2. (Optional) Start background runner in its own window (minimized by default)
  powershell -ExecutionPolicy Bypass -File .\Start-SyzygyQueueRunner.ps1 -Minimized

  Inside the manager you can also choose the menu option to launch the runner.

  After adding things to the queue, start the runner once. It will process sequentially.

  Re-run the manager any time to see updated "Generated / Missing" status (it rescans your disks).

.PARAMETER SearchPaths
  Extra directories to scan for existing .rtbw / .rtbz (in addition to defaults + $env:RTBPATH / RTBWDIR / RTBZDIR).

.PARAMETER QueuePath
  Path to the JSON queue file (default: logs/syzygy-generation-queue.json).

.PARAMETER ExportHtmlOnly
  Just (re)generate the HTML dashboard and exit (no interactive GridView).

.NOTES
  If RTBPATH is not set when you start the manager, it will now ASK you for the path
  and offer a nice folder picker + option to make it permanent. This fixes the common
  "RTBPATH not configured" situation before generation or scanning.

.EXAMPLE
  powershell -File .\Syzygy-TableManager.ps1 -SearchPaths "T:\Syzygy","S:\SyzygyArchive"

.NOTES
  - Uses the same king-inclusive classification you validated earlier (KBBBBvKP = 5v2_pawnful etc.).
  - 8pc candidates are curated (smallest memory first). Full 8pc enumeration is not practical.
  - The queue runner is conservative: default 4 threads, -d for >=6pc, BelowNormal priority, lockfile.
  - After a successful generation the runner can optionally run tbcheck.
#>

[CmdletBinding()]
param(
    [string[]]$SearchPaths = @(),
    [string]$QueuePath = "logs/syzygy-generation-queue.json",
    [switch]$ExportHtmlOnly
)

$ErrorActionPreference = "Stop"
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDir = Join-Path $scriptRoot "logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

$queueDir = Split-Path -Parent $QueuePath
if ($queueDir -and -not (Test-Path $queueDir)) { New-Item -ItemType Directory -Path $queueDir -Force | Out-Null }

$binDir = Join-Path $scriptRoot "bin"

# --- RTBPATH resolver with prompt + folder picker (new friendly behavior) ---
function Get-SyzygyRootPath {
    param([string[]]$ExtraPaths = @())

    # Compute effective RTBPATH (process > user > machine)
    $effective = $env:RTBPATH
    if (-not $effective) { $effective = [Environment]::GetEnvironmentVariable('RTBPATH', 'User') }
    if (-not $effective) { $effective = [Environment]::GetEnvironmentVariable('RTBPATH', 'Machine') }

    if ($effective) {
        Write-Host ("RTBPATH detecte : " + $effective) -ForegroundColor Green
        return $effective
    }

    # Not configured → ask the user (as requested)
    Write-Host ""
    Write-Host "=== RTBPATH n'est pas configure ===" -ForegroundColor Yellow
    Write-Host "Les generateurs ont besoin de savoir ou trouver les tables plus petites (sous-tables)." -ForegroundColor Yellow
    Write-Host "Indique le dossier racine principal de tes Syzygy (celui qui contient 3-5men, 6men, 7men\...)." -ForegroundColor Yellow
    Write-Host ""

    $suggestion = "T:\Syzygy"
    $hasSuggestion = Test-Path $suggestion

    Write-Host "Options de selection :" -ForegroundColor Cyan
    Write-Host "  1. Ouvrir un selecteur de dossier graphique (le plus pratique)"
    Write-Host "  2. Taper le chemin a la main"
    if ($hasSuggestion) {
        Write-Host "  3. Utiliser $suggestion (suggestion par defaut, dossier detecte)"
    }
    Write-Host "  4. Continuer sans (le scan sera limite et la generation ne marchera pas)"
    Write-Host ""

    $choice = Read-Host "Ton choix (1-4, ou Entree pour 1)"

    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }

    $chosen = $null

    switch ($choice) {
        "1" {
            try {
                Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
                $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
                $dialog.Description = "Choisis le dossier racine Syzygy (ex: T:\Syzygy avec les sous-dossiers 7men etc.)"
                $dialog.ShowNewFolderButton = $false
                if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK -and $dialog.SelectedPath) {
                    $chosen = $dialog.SelectedPath
                }
            } catch {
                Write-Host "Le selecteur graphique n'a pas pu s'ouvrir. Utilise l'option 2 pour taper le chemin." -ForegroundColor Red
            }
        }
        "2" {
            $typed = Read-Host "Chemin complet du dossier racine (ex: T:\Syzygy)"
            if ($typed) { $chosen = $typed.Trim() }
        }
        "3" {
            if ($hasSuggestion) { $chosen = $suggestion }
        }
        default {
            Write-Host "OK, on continue sans RTBPATH. Attention : scan partiel + generation impossible." -ForegroundColor Red
            return $null
        }
    }

    if ($chosen -and (Test-Path $chosen)) {
        Write-Host ("Chemin valide : " + $chosen) -ForegroundColor Green

        # Apply to current process so everything (scan + future launches) sees it
        $env:RTBPATH = $chosen
        Write-Host "RTBPATH defini pour cette session PowerShell." -ForegroundColor Green

        # Offer to make it permanent
        $persist = Read-Host "Veux-tu le rendre permanent pour cet utilisateur Windows ? (O/n)"
        if ($persist -match '^[oO]') {
            [Environment]::SetEnvironmentVariable("RTBPATH", $chosen, "User")
            Write-Host "Sauvegarde dans les variables d'environnement (ferme/re-ouvre PowerShell pour que d'autres sessions le voient automatiquement)." -ForegroundColor Green
        }

        return $chosen
    } elseif ($chosen) {
        Write-Host ("Le chemin indique n'existe pas : " + $chosen) -ForegroundColor Red
    }

    return $null
}

$defaultSearch = @(
    (Join-Path $scriptRoot "Syzygy"),
    "T:\Syzygy",
    "S:\Syzygy",
    "F:\Syzygy",
    "I:\Syzygy",
    "A:\Syzygy"
) + $SearchPaths

# Ask for RTBPATH root at startup if not configured (and use it for scanning)
$resolvedRTB = Get-SyzygyRootPath -ExtraPaths $SearchPaths
if ($resolvedRTB) {
    # Put the resolved root first so it is preferred for scanning
    $defaultSearch = @($resolvedRTB) + $defaultSearch | Select-Object -Unique
}

# --- Classification (king-inclusive, matches your corrected .bat + conformance analyzer) ---
function Get-SyzygyTableInfo {
    param([Parameter(Mandatory)][string]$BaseName)
    $name = $BaseName -replace '\.rtb[zw]$',''
    if ($name -notmatch 'v') { return $null }

    $parts = $name -split 'v', 2
    $left  = $parts[0]
    $right = $parts[1]

    $leftNonK  = ($left  -replace 'K','' -replace '[^QRBNP]','').Length
    $rightNonK = ($right -replace 'K','' -replace '[^QRBNP]','').Length

    $men = 2 + $leftNonK + $rightNonK
    $isPawnful = $name -match 'P'
    $pType = if ($isPawnful) { "pawnful" } else { "pawnless" }

    $leftT  = 1 + $leftNonK
    $rightT = 1 + $rightNonK
    $a = [math]::Max($leftT, $rightT)
    $b = [math]::Min($leftT, $rightT)

    $category =
        if     ($men -le 5) { "3-5men" }
        elseif ($men -eq 6) { "6men" }
        elseif ($men -eq 7) { "7men/${a}v${b}_$pType" }
        else                { "8pc-experimental/${a}v${b}_$pType" }

    [pscustomobject]@{
        Base      = $name
        Men       = $men
        IsPawnful = $isPawnful
        Split     = "${a}v${b}"
        PType     = $pType
        Category  = $category
    }
}

# --- Load canonical "all possible" from the net checksums (the reference you care about) ---
function Get-AllCanonicalTables {
    $list = @()
    $checksumDir = Join-Path $scriptRoot "checksums"
    $wdlFiles = Get-ChildItem $checksumDir -Filter "wdl*.txt" -ErrorAction SilentlyContinue

    foreach ($f in $wdlFiles) {
        foreach ($line in (Get-Content $f.FullName)) {
            if ($line -match "^(K[^:]+)\.rtbw:") {
                $base = $matches[1]
                $info = Get-SyzygyTableInfo $base
                if ($info) {
                    $list += [pscustomobject]@{
                        Base     = $info.Base
                        Men      = $info.Men
                        Split    = $info.Split
                        PType    = $info.PType
                        Category = $info.Category
                        Source   = "checksum"
                    }
                }
            }
        }
    }

    # 8pc experimental candidates (traditional chess only, smallest memory first)
    # These are NOT in the published checksums. Only attempt if you really want 8pc.
    $eightPcCandidates = @(
        "KPPPPPPvK",   # 8pc, 7v1_pawnful - the one we targeted earlier (very high pawn, smallest RAM footprint)
        "KPPPPPvKP",
        "KPPPPvKPP",
        "KPPPvKPPP",
        "KPPvKPPPP",
        "KPvKPPPPP",
        "KPPPPPPvKP",
        "KQQQQQvKP",   # a few with heavy material + 1 pawn to keep it "reasonable"
        "KRRRRRvKP",
        "KQQQQPvK",
        "KRRRRPvK",
        "KBBBBBvKP",
        "KNNNNNvKP"
    )

    foreach ($b in $eightPcCandidates) {
        $info = Get-SyzygyTableInfo $b
        if ($info -and $info.Men -eq 8) {
            $list += [pscustomobject]@{
                Base     = $info.Base
                Men      = 8
                Split    = $info.Split
                PType    = $info.PType
                Category = $info.Category
                Source   = "experimental8"
            }
        }
    }

    $list | Sort-Object Men, Base -Unique
}

# --- Scan disks for presence of .rtbw + .rtbz ---
function Get-PresentTables {
    param([string[]]$Roots)

    $present = @{}
    $rootsToScan = ($Roots | Where-Object { $_ }) + $defaultSearch | Select-Object -Unique

    # Also add anything from RTBPATH / RTBWDIR / RTBZDIR
    $envRoots = @()
    if ($env:RTBPATH)  { $envRoots += ($env:RTBPATH -split '[;:]' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
    if ($env:RTBWDIR)  { $envRoots += $env:RTBWDIR.Trim() }
    if ($env:RTBZDIR)  { $envRoots += $env:RTBZDIR.Trim() }
    $rootsToScan += $envRoots

    foreach ($root in ($rootsToScan | Select-Object -Unique)) {
        if (-not (Test-Path $root)) { continue }
        try {
            $files = Get-ChildItem -Path $root -Recurse -File -Include *.rtbw,*.rtbz -ErrorAction SilentlyContinue
            foreach ($f in $files) {
                $base = $f.BaseName
                if (-not $present.ContainsKey($base)) {
                    $present[$base] = [pscustomobject]@{ WDL=$false; DTZ=$false; Path=$f.DirectoryName }
                }
                if ($f.Extension -eq ".rtbw") { $present[$base].WDL = $true }
                if ($f.Extension -eq ".rtbz") { $present[$base].DTZ = $true }
            }
        } catch { }
    }
    $present
}

# --- Build the master view model ---
function Build-TableView {
    param($Canonical, $PresentMap)

    $view = foreach ($t in $Canonical) {
        $p = $PresentMap[$t.Base]
        $hasW = [bool]$p.WDL
        $hasZ = [bool]$p.DTZ

        $status =
            if ($hasW -and $hasZ) { "Complete" }
            elseif ($hasW)        { "WDL only" }
            elseif ($hasZ)        { "DTZ only" }
            else                  { "Missing" }

        $isExperimental = $t.Source -eq "experimental8"

        [pscustomobject]@{
            Name        = $t.Base
            Men         = $t.Men
            Split       = $t.Split
            Pawnful     = if ($t.IsPawnful) { "Yes" } else { "No" }
            Category    = $t.Category
            Status      = $status
            HasWDL      = $hasW
            HasDTZ      = $hasZ
            Experimental= $isExperimental
            Location    = if ($p) { $p.Path } else { "" }
            Source      = $t.Source
        }
    }
    $view | Sort-Object Men, Name
}

# --- Queue helpers (JSON array of objects) ---
function Get-Queue {
    if (Test-Path $QueuePath) {
        try { return Get-Content $QueuePath -Raw | ConvertFrom-Json -ErrorAction Stop }
        catch { return @() }
    }
    @()
}

function Add-ToQueue {
    param([string[]]$Names)
    $current = @(Get-Queue)
    $existing = @($current | ForEach-Object { $_.Name })
    $added = 0
    $now = (Get-Date).ToString("yyyy-MM-dd HH:mm")
    foreach ($n in $Names) {
        if ($existing -notcontains $n) {
            $current += [pscustomobject]@{ Name=$n; Added=$now; Priority=5 }
            $added++
        }
    }
    $current | ConvertTo-Json -Depth 3 | Set-Content -Path $QueuePath -Encoding UTF8
    Write-Host "Added $added new table(s) to queue." -ForegroundColor Green
}

function Show-Queue {
    $q = Get-Queue
    if (-not $q -or $q.Count -eq 0) {
        Write-Host "Queue is empty." -ForegroundColor Yellow
        return
    }
    $q | Sort-Object Priority -Descending | Format-Table -AutoSize | Out-String | Write-Host
    Write-Host "Total in queue: $($q.Count)" -ForegroundColor Cyan
}

function Clear-Queue {
    if (Test-Path $QueuePath) {
        Remove-Item $QueuePath -Force
        Write-Host "Queue cleared." -ForegroundColor Yellow
    }
}

# --- New: Per-category (piece count) navigation + direct "Generate" action ---
function Show-CategoryView {
    param(
        [int]$MinMen,
        [int]$MaxMen,
        [string]$Label
    )

    $groupView = $view | Where-Object { $_.Men -ge $MinMen -and $_.Men -le $MaxMen }
    if (-not $groupView) {
        Write-Host "No tables in $Label range." -ForegroundColor Yellow
        return
    }

    $missCount = ($groupView | Where-Object Status -eq "Missing").Count
    $title = "Syzygy $Label - $missCount missing | Filter e.g. 'Missing' or material (KRP) | Select then OK"

    Write-Host "Opening $Label view ($($groupView.Count) tables, $missCount missing)." -ForegroundColor Gray
    Write-Host "Tip: Type 'Missing' in the filter box at top to see only the ones you can generate." -ForegroundColor Gray

    $selected = $groupView | Out-GridView -Title $title -PassThru

    if (-not $selected) { return }

    $toAdd = $selected | Where-Object Status -ne "Complete" | Select-Object -ExpandProperty Name | Select-Object -Unique
    if (-not $toAdd) {
        Write-Host "No missing tables in your selection." -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "Selected missing tables for $Label ($($toAdd.Count)):" -ForegroundColor Cyan
    $toAdd | ForEach-Object { Write-Host "  $_" }

    Write-Host ""
    Write-Host "Generate actions:" -ForegroundColor Yellow
    Write-Host "  A) Add to queue only (safe, runner will pick them up later)"
    Write-Host "  B) Add to queue + START BACKGROUND RUNNER NOW  <-- 'Generate' button"
    Write-Host "  C) Cancel / do nothing"
    if ($MaxMen -le 5) {
        Write-Host "  D) Generate immediately (foreground, only for small 3-5pc tables - not recommended for big ones)"
    }

    $act = Read-Host "Choice (A/B/C" + $(if ($MaxMen -le 5) { "/D" } else { "" }) + ")"

    switch ($act.ToUpper()) {
        "A" {
            Add-ToQueue -Names $toAdd
        }
        "B" {
            Add-ToQueue -Names $toAdd
            Write-Host "Queue updated. Launching runner in new window for these..." -ForegroundColor Green
            Start-QueueRunner   # will use current env RTBPATH
        }
        "D" {
            if ($MaxMen -le 5) {
                Write-Host "Immediate foreground generation for small tables (use with caution)..." -ForegroundColor Yellow
                foreach ($name in $toAdd) {
                    $isP = $name -match 'P'
                    $exe = if ($isP) { "rtbgenp.exe" } else { "rtbgen.exe" }
                    $full = Join-Path $binDir $exe
                    if (Test-Path $full) {
                        Write-Host "Running $exe for $name ..."
                        & $full -t 2 --stats $name   # very conservative for immediate
                    } else {
                        Write-Host "Missing $full - falling back to queue."
                        Add-ToQueue -Names @($name)
                    }
                }
            } else {
                Write-Host "Immediate foreground only offered for 3-5pc." -ForegroundColor Red
            }
        }
        default {
            Write-Host "Cancelled. Tables remain in the list." -ForegroundColor Gray
        }
    }
}

function Show-GroupSummary {
    $g35 = $view | Where-Object Men -le 5
    $g6  = $view | Where-Object Men -eq 6
    $g7  = $view | Where-Object Men -eq 7
    $g8  = $view | Where-Object Men -ge 8

    Write-Host ""
    Write-Host "=== Tables by Piece Count (easy navigation) ===" -ForegroundColor Cyan
    Write-Host ("  3-5pc : {0,4} total  |  {1,3} missing" -f $g35.Count, (($g35 | Where Status -eq 'Missing').Count))
    Write-Host ("  6pc   : {0,4} total  |  {1,3} missing" -f $g6.Count,  (($g6  | Where Status -eq 'Missing').Count))
    Write-Host ("  7pc   : {0,4} total  |  {1,3} missing" -f $g7.Count,  (($g7  | Where Status -eq 'Missing').Count))
    Write-Host ("  8pc*  : {0,4} total  |  {1,3} missing   (experimental - traditional only)" -f $g8.Count, (($g8 | Where Status -eq 'Missing').Count))
}

# --- Launch background runner (new window) ---
function Start-QueueRunner {
    $runner = Join-Path $scriptRoot "Start-SyzygyQueueRunner.ps1"
    if (-not (Test-Path $runner)) {
        Write-Error "Runner script not found: $runner"
        return
    }
    Write-Host "Launching queue runner in a new minimized window..." -ForegroundColor Cyan

    $rtbArg = ""
    if ($env:RTBPATH) {
        # Pass the current RTBPATH so the background process sees the correct root
        $rtbArg = " -RTBPath `"$($env:RTBPATH)`""
    }

    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$runner`" -Minimized$rtbArg" `
        -WindowStyle Minimized -WorkingDirectory $scriptRoot

    Write-Host "Runner started. It will process the queue one table at a time with safe/low-priority settings." -ForegroundColor Green
    if ($env:RTBPATH) {
        Write-Host ("RTBPATH passed to runner: " + $env:RTBPATH) -ForegroundColor Gray
    }
    Write-Host "You can tail logs\queue-runner.log or re-run this manager to see progress." -ForegroundColor Gray
}

# --- Export a standalone HTML dashboard (now with real tabs by piece count + per-group actions) ---
function Export-HtmlDashboard {
    param($View)

    $htmlPath = Join-Path $scriptRoot "syzygy-dashboard.html"
    $now = Get-Date

    # Group by men for tabs (3-5, 6, 7, 8)
    $groups = @{}
    $groups['3-5'] = $View | Where-Object Men -le 5
    $groups['6']   = $View | Where-Object Men -eq 6
    $groups['7']   = $View | Where-Object Men -eq 7
    $groups['8']   = $View | Where-Object Men -ge 8

    function MakeTableRows($items) {
        $items | ForEach-Object {
            $cls = switch ($_.Status) {
                "Complete"  { "ok" }
                "Missing"   { "missing" }
                default     { "partial" }
            }
            $exp = if ($_.Experimental) { " <span class='exp'>EXP8</span>" } else { "" }
            "<tr class='$cls'>
                <td>$($_.Name)$exp</td>
                <td>$($_.Men)</td>
                <td>$($_.Split)</td>
                <td>$($_.Pawnful)</td>
                <td class='status'>$($_.Status)</td>
                <td>$($_.Category)</td>
                <td>$($_.Location)</td>
             </tr>"
        } | Out-String
    }

    $tab3_5 = MakeTableRows $groups['3-5']
    $tab6   = MakeTableRows $groups['6']
    $tab7   = MakeTableRows $groups['7']
    $tab8   = MakeTableRows $groups['8']

    $m35 = ($groups['3-5'] | Where Status -eq 'Missing').Count
    $m6  = ($groups['6']   | Where Status -eq 'Missing').Count
    $m7  = ($groups['7']   | Where Status -eq 'Missing').Count
    $m8  = ($groups['8']   | Where Status -eq 'Missing').Count

    $html = @"
<!DOCTYPE html>
<html><head>
<meta charset="utf-8">
<title>Syzygy Tables - Dashboard (Tabs by Piece Count)</title>
<style>
body { font-family: system-ui, sans-serif; margin: 1rem; background:#111; color:#ddd; }
h1 { color:#0af; }
.tabbar { margin: 12px 0; }
.tab { background:#222; color:#0af; border:1px solid #444; padding:6px 14px; margin-right:4px; cursor:pointer; border-radius:4px 4px 0 0; }
.tab.active { background:#0af; color:#000; font-weight:600; }
.tabcontent { display:none; }
.tabcontent.active { display:block; }
table { border-collapse: collapse; width: 100%; font-size: 13px; }
th, td { border:1px solid #444; padding:3px 6px; text-align:left; }
th { background:#222; position:sticky; top:0; }
tr.ok      { background:#0a2; color:#fff; }
tr.missing { background:#300; }
tr.partial { background:#420; }
.status { font-weight:600; }
.exp { background:#f80; color:#000; padding:1px 4px; border-radius:3px; font-size:10px; }
.filter { width:280px; padding:5px; font-size:14px; margin-bottom:6px; }
.summary { margin: 6px 0; color:#0af; font-size:14px; }
.hint { color:#888; font-size:12px; }
button { background:#0af; color:#000; border:none; padding:4px 10px; border-radius:3px; cursor:pointer; }
</style>
<script>
let currentTab = 'all';
function showTab(tab) {
  document.querySelectorAll('.tabcontent').forEach(c => c.classList.remove('active'));
  document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
  document.getElementById('tab-' + tab).classList.add('active');
  document.getElementById(tab).classList.add('active');
  currentTab = tab;
}
function filterCurrent() {
  const q = document.getElementById('filter').value.toLowerCase();
  const activePane = document.querySelector('.tabcontent.active');
  if (!activePane) return;
  activePane.querySelectorAll('tbody tr').forEach(r => {
    r.style.display = r.textContent.toLowerCase().includes(q) ? '' : 'none';
  });
}
function copyMissing(tabId) {
  const pane = document.getElementById(tabId);
  const names = [];
  pane.querySelectorAll('tr.missing td:first-child').forEach(td => {
    names.push(td.textContent.trim().replace('EXP8','').trim());
  });
  if (names.length === 0) { alert('No missing in this tab'); return; }
  navigator.clipboard.writeText(names.join('\n')).then(() => {
    alert(names.length + ' missing names copied. Paste into Syzygy-TableManager or run the queue.');
  });
}
function showAllMissing() {
  document.getElementById('filter').value = 'missing';
  filterCurrent();
}
</script>
</head><body>
<h1>Syzygy Table Status — $( $now.ToString("yyyy-MM-dd HH:mm") )</h1>
<div class="summary">
  Total: $(($View|Measure-Object).Count) &nbsp;|&nbsp;
  Complete: $(($View | Where Status -eq "Complete" | Measure-Object).Count) &nbsp;|&nbsp;
  Missing: $(($View | Where Status -eq "Missing" | Measure-Object).Count)
</div>

<div class="tabbar">
  <span class="tab active" onclick="showTab('all')">All</span>
  <span class="tab" onclick="showTab('35')">3-5pc ($m35 missing)</span>
  <span class="tab" onclick="showTab('6')">6pc ($m6 missing)</span>
  <span class="tab" onclick="showTab('7')">7pc ($m7 missing)</span>
  <span class="tab" onclick="showTab('8')">8pc exp ($m8 missing)</span>
</div>

<input id="filter" class="filter" placeholder="Filter (e.g. missing KRP 7)" onkeyup="filterCurrent()">
<button onclick="showAllMissing()">Show only Missing</button>
<button onclick="copyMissing(currentTab === 'all' ? 'all' : currentTab)">Copy missing in current tab</button>

<p class="hint">Use the PowerShell Syzygy-TableManager.ps1 (or Syzygy-UI.bat) for the real interactive list with "Generate" actions and queue. This HTML is a fast browsable view with tabs by piece count.</p>

<div id="all" class="tabcontent active">
  <table><thead><tr>
    <th>Name</th><th>Men</th><th>Split</th><th>Pawnful</th><th>Status</th><th>Category</th><th>Location</th>
  </tr></thead><tbody>
  $(MakeTableRows $View)
  </tbody></table>
</div>

<div id="35" class="tabcontent">
  <table><thead><tr>
    <th>Name</th><th>Men</th><th>Split</th><th>Pawnful</th><th>Status</th><th>Category</th><th>Location</th>
  </tr></thead><tbody>
  $tab3_5
  </tbody></table>
</div>

<div id="6" class="tabcontent">
  <table><thead><tr>
    <th>Name</th><th>Men</th><th>Split</th><th>Pawnful</th><th>Status</th><th>Category</th><th>Location</th>
  </tr></thead><tbody>
  $tab6
  </tbody></table>
</div>

<div id="7" class="tabcontent">
  <table><thead><tr>
    <th>Name</th><th>Men</th><th>Split</th><th>Pawnful</th><th>Status</th><th>Category</th><th>Location</th>
  </tr></thead><tbody>
  $tab7
  </tbody></table>
</div>

<div id="8" class="tabcontent">
  <table><thead><tr>
    <th>Name</th><th>Men</th><th>Split</th><th>Pawnful</th><th>Status</th><th>Category</th><th>Location</th>
  </tr></thead><tbody>
  $tab8
  </tbody></table>
  <p class="hint"><strong>8pc is experimental</strong> — only traditional chess, very high pawn counts recommended for memory reasons. Use the PS manager + runner with -Allow8pc.</p>
</div>

<script>
// show first tab by default (already active via class)
document.getElementById('filter').addEventListener('input', filterCurrent);
</script>
</body></html>
"@
    $html | Set-Content -Path $htmlPath -Encoding UTF8
    Write-Host "HTML dashboard (with tabs!) written to: $htmlPath" -ForegroundColor Green
    Write-Host "Open it in your browser. Click the piece-count tabs (3-5 / 6 / 7 / 8). Use filter + copy buttons per tab." -ForegroundColor Cyan
    return $htmlPath
}

# ==================== MAIN ====================

Write-Host "=== Syzygy Table Manager (traditional chess) ===" -ForegroundColor Cyan
Write-Host "Loading canonical list from checksums/ (the published set)..." -ForegroundColor Gray

$canonical = Get-AllCanonicalTables
Write-Host "  Canonical tables: $($canonical.Count) (3-7pc from net + selected 8pc experimental)" -ForegroundColor Green

Write-Host "Scanning for existing files (this can take a moment on big trees)..." -ForegroundColor Gray
$present = Get-PresentTables -Roots $defaultSearch
Write-Host "  Found presence info for $($present.Count) bases" -ForegroundColor Green

$view = Build-TableView -Canonical $canonical -PresentMap $present

if ($ExportHtmlOnly) {
    Export-HtmlDashboard -View $view | Out-Null
    return
}

# Quick stats + per-piece-count summary for easy navigation
$complete = ($view | Where-Object Status -eq "Complete").Count
$missing  = ($view | Where-Object Status -eq "Missing").Count
Write-Host "Status: $complete Complete  |  $missing Missing  |  $(($view|Measure-Object).Count) total" -ForegroundColor White
Show-GroupSummary

# Menu (now with piece-count "tabs" for better navigation + direct Generate actions)
while ($true) {
    Write-Host ""
    Write-Host "Menu (use piece count groups for easy navigation):" -ForegroundColor Yellow
    Write-Host "  1. 3-5 pieces   (manage missing, direct Generate button)"
    Write-Host "  2. 6 pieces     (manage missing, direct Generate button)"
    Write-Host "  3. 7 pieces     (manage missing, direct Generate button)"
    Write-Host "  4. 8pc experimental (traditional only - curated small-memory candidates)"
    Write-Host "  5. All tables (flat GridView - power user / cross-group filter)"
    Write-Host ""
    Write-Host "  Q. Show current queue"
    Write-Host "  W. Clear queue"
    Write-Host "  E. Export / open HTML dashboard (now with tabs!)"
    Write-Host "  R. Launch background queue runner (new minimized window)"
    Write-Host "  L. Open logs folder"
    Write-Host "  X. Quit"

    $choice = Read-Host "Choice (1-5 or Q/W/E/R/L/X)"

    switch ($choice.ToUpper()) {
        "1" { Show-CategoryView -MinMen 3 -MaxMen 5 -Label "3-5pc" }
        "2" { Show-CategoryView -MinMen 6 -MaxMen 6 -Label "6pc" }
        "3" { Show-CategoryView -MinMen 7 -MaxMen 7 -Label "7pc" }
        "4" { Show-CategoryView -MinMen 8 -MaxMen 8 -Label "8pc-experimental" }
        "5" {
            Write-Host "Opening full flat list (use the top filter box heavily: 'Missing 7' etc.)." -ForegroundColor Gray
            $selected = $view | Out-GridView -Title "Syzygy - All tables (filter: Missing 7 P etc.) - select then OK" -PassThru
            if ($selected) {
                $toAdd = $selected | Where-Object Status -ne "Complete" | Select-Object -ExpandProperty Name | Select-Object -Unique
                if ($toAdd) {
                    Add-ToQueue -Names $toAdd
                    Write-Host "Added to queue. Use 'R' to start runner if desired." -ForegroundColor Green
                }
            }
        }
        "Q" { Show-Queue }
        "W" { Clear-Queue }
        "E" {
            $path = Export-HtmlDashboard -View $view
            Start-Process $path
        }
        "R" { Start-QueueRunner }
        "L" { Invoke-Item $logDir }
        "X" { return }
        default { Write-Host "Unknown choice" -ForegroundColor Red }
    }
}
