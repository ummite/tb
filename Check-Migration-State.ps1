<# 
.SYNOPSIS
    Quick status dashboard for the "All Syzygy to T:" migration project.
#>

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== Syzygy → T: Migration State ===" -ForegroundColor Magenta
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor DarkGray
Write-Host ""

# Space
$t = Get-PSDrive T
$f = Get-PSDrive F
Write-Host "SPACE" -ForegroundColor Cyan
Write-Host "  T:  $([math]::Round($t.Free/1TB,2)) TB free   /   $([math]::Round($t.Used/1TB,2)) TB used"
Write-Host "  F:  $([math]::Round($f.Free/1TB,2)) TB free"
Write-Host ""

# Plots
$plots = Get-ChildItem -Path T:\ -File -Filter "plot*" -ErrorAction SilentlyContinue
Write-Host "PLOTS ON T:" -ForegroundColor Cyan
Write-Host "  Remaining : $($plots.Count) files   (~$([math]::Round(($plots | Measure-Object Length -Sum).Sum / 1TB,2)) TB)"
Write-Host ""

# Master on T:\Syzygy
$master = "T:\Syzygy"
if (Test-Path $master) {
    $syz = Get-ChildItem -Path $master -File -Include *.rtbw,*.rtbz -ErrorAction SilentlyContinue
    Write-Host "MASTER REPOSITORY (T:\Syzygy)" -ForegroundColor Green
    Write-Host "  Files     : $($syz.Count)"
    Write-Host "  Size      : ~$([math]::Round(($syz | Measure-Object Length -Sum).Sum / 1TB,2)) TB"
} else {
    Write-Host "MASTER REPOSITORY (T:\Syzygy) : NOT CREATED YET" -ForegroundColor Yellow
}
Write-Host ""

# Quick source counts (fast)
Write-Host "MAIN SOURCES (approximate, top-level scan)" -ForegroundColor Cyan
$checks = @(
    'Syzygy',
    'A:\Syzygy',
    'A:\Syzygy_A_Trier_FromOld_Ryzen7950',
    'S:\Syzygy',
    'S:\Syzygy\3-6men'
)
foreach ($p in $checks) {
    if (Test-Path $p) {
        $c = (Get-ChildItem -Path $p -Recurse -File -Include *.rtbw -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-Host "  $p : ~$c tables"
    }
}

Write-Host ""
Write-Host "Next: Run .\Start-Syzygy-T-Master-Setup.ps1 for guided recommendations" -ForegroundColor DarkGray
