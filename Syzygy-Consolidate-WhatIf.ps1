<# 
.SYNOPSIS
    Clean WhatIf analyzer for consolidating Syzygy to T:\Syzygy (Master Plan Phase 3).
    This is a fresh, minimal, syntax-clean version focused on simulation and reporting.
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$WorkingDir = "T:\Syzygy",
    [switch]$WhatIf = $true
)

$ErrorActionPreference = "Continue"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║   SYZYGY CONSOLIDATION WHATIF → T:\Syzygy (Master Repository)   ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""
Write-Host "Target    : $WorkingDir" -ForegroundColor Cyan
Write-Host "Mode      : WHATIF / DRY-RUN (simulation only)" -ForegroundColor Yellow
Write-Host ""

# Pre-flight space
$t = Get-PSDrive T -ErrorAction SilentlyContinue
if ($t) {
    Write-Host ("T: free = {0:N2} TB" -f ($t.Free / 1TB)) -ForegroundColor $(if ($t.Free -gt 20TB) { "Green" } else { "Yellow" })
}

# Sources (same as the main consolidate script)
$Sources = @(
    (Join-Path $ScriptRoot 'Syzygy'),
    'A:\Syzygy',
    'A:\Syzygy_A_Trier_FromOld_Ryzen7950',
    'S:\Syzygy',
    'S:\Syzygy\3-6men',
    'S:\5v2_pawnful',
    'S:\5v2_pawnless',
    'S:\6v1_pawnful',
    'S:\6v1_pawnless',
    'S:\4v3_pawnless_ManyMissing',
    'F:\Plots',
    'F:\Syzygy',
    'T:\Syzygy',
    'T:\Syzygy-Working',
    'T:\Syzygy-Flat',
    'T:\3-6men',
    'T:\7men'
) | Select-Object -Unique | Where-Object { Test-Path $_ }

Write-Host "`nActive sources that exist:" -ForegroundColor Green
$Sources | ForEach-Object { Write-Host "  $_" }

Write-Host "`nScanning all sources (this can take a while for large folders)..." -ForegroundColor Cyan

$plan = @()
$seen = @{}

foreach ($src in $Sources) {
    Write-Host "  Scanning $src ..." -ForegroundColor DarkGray
    $files = Get-ChildItem -Path $src -Recurse -File -Include *.rtbw,*.rtbz -ErrorAction SilentlyContinue
    foreach ($f in $files) {
        $name = $f.Name
        if ($seen.ContainsKey($name)) {
            # keep the first occurrence for now (simple policy)
            continue
        }
        $seen[$name] = $true
        $plan += [pscustomobject]@{
            Source = $src
            Name   = $name
            SizeGB = [math]::Round($f.Length / 1GB, 2)
            Path   = $f.FullName
        }
    }
}

Write-Host "`n=== CONSOLIDATION WHATIF SUMMARY ===" -ForegroundColor Magenta
Write-Host "Total unique tables that would be copied to T:\Syzygy : $($plan.Count)" -ForegroundColor Green

# Group by rough piece count for visibility (simpler method to avoid quote issues)
$byPc = $plan | ForEach-Object {
    $n = $_.Name
    $pc = if ($n -match 'vK') { 
        ($n -replace '[^KQBNRPkqbnrp]','').Length 
    } else { 99 }
    [pscustomobject]@{ PC = $pc; Item = $_ }
} | Group-Object PC | Sort-Object Name

Write-Host "`nBy approximate piece count:" -ForegroundColor Cyan
$byPc | ForEach-Object {
    $pc = if ($_.Name -eq 99) { "?" } else { $_.Name }
    Write-Host ("  {0,2} pieces : {1,5} tables" -f $pc, $_.Count)
}

# Show a sample of what would move
Write-Host "`nSample of tables that would be brought in (first 30):" -ForegroundColor DarkGray
$plan | Select-Object -First 30 | ForEach-Object {
    Write-Host ("  [{0,6} GB] {1}  (from {2})" -f $_.SizeGB, $_.Name, $_.Source)
}

Write-Host "`n... (truncated)"

Write-Host "`nNext real steps:" -ForegroundColor Yellow
Write-Host "  1. Review this plan"
Write-Host "  2. Run the full Syzygy-Consolidate-To-T.ps1 (once it is clean) or a production copy script"
Write-Host "  3. After copy: set RTBPATH=T:\Syzygy and test with rtbver / tbcheck on key tables"
Write-Host ""
Write-Host "This WhatIf script is clean and safe to re-run anytime." -ForegroundColor DarkGray
