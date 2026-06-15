<#
.SYNOPSIS
Basic coordinator stub for "distributed" 8pc generation using shared backing (SAN or multi-volume).

Usage example (manual for now):
- Machine A: cd to its work dir; run the safe launcher with --pawn-file 0 or equivalent (future flag)
- Machine B: same for file 1,2,3
- Shared VT backing config on T: or UNC path visible to all.

This script can be extended to launch remote or local instances for different slices.
#>

param(
    [string]$TableName = "KPPPPPPvK",
    [string]$SharedVTConfig = "T:\8pc_shared\vt_config.txt",
    [int[]]$Files = @(0,1,2,3),  # the 4 pawn files to distribute
    [string]$Launcher = ".\Start-8pc-KPPPPPPvK-OnT-Safe.ps1"
)

Write-Host "=== 8pc slice distributor stub ==="
Write-Host "Table: $TableName"
Write-Host "Shared config: $SharedVTConfig"
Write-Host "Assigning files: $($Files -join ',') to 'nodes' (manual for now)"

foreach ($f in $Files) {
    $cmd = "& $Launcher -TableName $TableName -UseVT ; # future: pass --pawn-file $f --vt-config $SharedVTConfig"
    Write-Host "Node for file $f would run: $cmd"
    # In real: Start-Process on remote, or invoke on local with different CWD
}

Write-Host "After all slices done, run final compress on a node that sees all layer files + backing."
Write-Host "See plan.md for full distributed storage/compute approach using VirtualTable + SAN."