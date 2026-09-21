# Analyze per-table failures in 4pc and 5pc benchmark JSON
param([string]$Which = 'both')
function Show-Set {
  param([string]$Set, [string]$Path)
  if (-not (Test-Path $Path)) { Write-Host "MISSING $Path"; return }
  $j = Get-Content $Path -Raw | ConvertFrom-Json
  Write-Host ("==== {0} ====" -f $Set)
  foreach ($e in $j.entries) {
    $bad = @($e.files | Where-Object { -not $_.identical_to_ref })
    $tb = @($e.files | Where-Object { $_.tbcheck -ne 'OK' })
    if ($bad.Count -gt 0 -or $tb.Count -gt 0) {
      $sizes = ($e.files | ForEach-Object { ('{0}:{1}/{2}' -f $_.ext, $_.gen_bytes, $_.ref_bytes) }) -join ' '
      Write-Host ('{0,-10} kind={1,-9} exit={2} bad=[{3}] tbcheck_bad=[{4}]  {5}' -f $e.table, $e.kind, $e.exit_code, (($bad | ForEach-Object { $_.ext }) -join ','), (($tb | ForEach-Object { $_.ext }) -join ','), $sizes)
    }
  }
}
if ($Which -in @('both','4')) { Show-Set '4pc' 'C:\Programmation\tb-1\benchmarks\4pc.benchmark.json' }
if ($Which -in @('both','5')) { Show-Set '5pc' 'C:\Programmation\tb-1\benchmarks\5pc.benchmark.json' }
