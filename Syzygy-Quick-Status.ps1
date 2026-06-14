<#
.SYNOPSIS
    Fast daily status check for the Syzygy T: Master Consolidation (Phase 3).

.DESCRIPTION
    Run this anytime to see:
    - Space on T: and F:
    - How many tables are currently on T:\Syzygy (recursive)
    - Rough breakdown of what remains in the big external sources
    - Quick recommendation for the next action

.EXAMPLE
    .\Syzygy-Quick-Status.ps1
#>

$ErrorActionPreference = 'Continue'

Write-Host "=== SYZYGY T: MASTER STATUS ===" -ForegroundColor Magenta
Write-Host "Generated: $(Get-Date)" 
Write-Host ""

# === Drives ===
$t = Get-PSDrive T -ErrorAction SilentlyContinue
$f = Get-PSDrive F -ErrorAction SilentlyContinue

if ($t) {
    $freeT = [math]::Round($t.Free / 1TB, 2)
    $usedT = [math]::Round($t.Used / 1TB, 2)
    Write-Host ("T:  {0,6:N2} TB used / {1,6:N2} TB free" -f $usedT, $freeT) -ForegroundColor $(if ($freeT -gt 25) { "Green" } elseif ($freeT -gt 10) { "Yellow" } else { "Red" })
}
if ($f) {
    $freeF = [math]::Round($f.Free / 1TB, 2)
    Write-Host ("F:  {0,6:N2} TB free" -f $freeF) -ForegroundColor Cyan
}

# === Current Master on T ===
$masterPath = "T:\Syzygy"
$masterCount = 0
$masterDTZ = 0
$masterWDL = 0

if (Test-Path $masterPath) {
    $all = Get-ChildItem $masterPath -Recurse -File -Include *.rtbw,*.rtbz -ErrorAction SilentlyContinue
    $masterCount = $all.Count
    $masterDTZ   = ($all | Where-Object Name -like '*.rtbz').Count
    $masterWDL   = ($all | Where-Object Name -like '*.rtbw').Count
}

Write-Host ""
Write-Host "T:\Syzygy current content:" -ForegroundColor Green
Write-Host ("  Total files : {0}" -f $masterCount)
Write-Host ("  DTZ (.rtbz) : {0}" -f $masterDTZ)
Write-Host ("  WDL (.rtbw) : {0}" -f $masterWDL)

# === Quick remaining potential from key sources ===
$keySources = @(
    'A:\Syzygy_A_Trier_FromOld_Ryzen7950',
    'A:\Syzygy',
    'S:\5v2_pawnful',
    'S:\6v1_pawnful',
    'S:\4v3_pawnless_ManyMissing'
)

Write-Host ""
Write-Host "Quick external inventory (top level count):" -ForegroundColor Cyan

foreach ($path in $keySources) {
    if (Test-Path $path) {
        $c = (Get-ChildItem $path -Recurse -File -Include *.rtbw,*.rtbz -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-Host ("  {0,-40} : {1,5} tables" -f $path, $c)
    }
}

Write-Host ""
Write-Host "=== RECOMMENDED NEXT ACTION ===" -ForegroundColor Magenta

if ($masterCount -lt 2000) {
    Write-Host "Continue copying from A:\Syzygy_A_Trier_FromOld_Ryzen7950 (biggest remaining value)." -ForegroundColor Yellow
    Write-Host "Command:  .\Copy-A-Historical-DTZ-To-T.ps1 -MaxFiles 100 -Threads 16" -ForegroundColor White
} else {
    Write-Host "Master is getting substantial. Consider moving to S: 5v2/6v1 splits or full dedup pass." -ForegroundColor Green
}

Write-Host ""
Write-Host "Run this script regularly: .\Syzygy-Quick-Status.ps1" -ForegroundColor DarkGray
