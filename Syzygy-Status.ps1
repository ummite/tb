<#
.SYNOPSIS
    Status report for the Syzygy tablebase collection (destination-aware).
#>
param(
    [string]$Path = "Syzygy"
)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$dir = Join-Path $root $Path

if (-not (Test-Path $dir)) {
    Write-Error "Syzygy folder not found: $dir"
    exit 1
}

Push-Location $dir
try {
    $wdl = Get-ChildItem *.rtbw -ErrorAction SilentlyContinue
    $dtz = Get-ChildItem *.rtbz -ErrorAction SilentlyContinue

    Write-Host "=== Syzygy Collection Status ===" -ForegroundColor Magenta
    Write-Host "Location : $dir"
    Write-Host "WDL files (.rtbw) : $($wdl.Count)"
    Write-Host "DTZ files (.rtbz) : $($dtz.Count)"
    Write-Host ""

    # Quick completeness against the reference (if available)
    $ref = Join-Path $root 'checksums\wdl345.txt'
    if (Test-Path $ref) {
        $expected = (Get-Content $ref | Measure-Object).Count
        $present = $wdl.Count
        $pct = [math]::Round(($present / $expected) * 100, 1)
        Write-Host "Reference (3-5pc) : $expected tables"
        Write-Host "Present in folder : $present WDL  ($pct%)"
        if ($present -ge $expected) {
            Write-Host "Status: COMPLETE for 3-5 pieces (regular chess)" -ForegroundColor Green
        } else {
            $missing = $expected - $present
            Write-Host "Missing : ~$missing tables (run Syzygy-Generate.ps1 to complete)" -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host "To (re)generate missing tables into this folder:"
    Write-Host "  .\Syzygy-Generate.ps1 -Complete -Threads 8 -Disk"
    Write-Host ""
    Write-Host "If your files live on multiple network shares, run first:"
    Write-Host "  .\Syzygy-Setup.ps1   (configure your paths at the top of the script)"
    Write-Host ""
    Write-Host "Point your engine / Syzygy probing code to this folder:"
    Write-Host "  $dir"

} finally {
    Pop-Location
}
