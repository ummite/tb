# Temporary diagnostic: process state + generated files + reference info
$ErrorActionPreference = 'Continue'
Get-Process -Name rtbgenp,rtbgen,rtbverp,rtbver,tbcheck,powershell -ErrorAction SilentlyContinue |
  Select-Object Id, ProcessName, StartTime, @{n='CPU_s';e={[math]::Round($_.CPU,1)}}, @{n='WS_MB';e={[math]::Round($_.WorkingSet64/1MB,1)}} |
  Format-Table -AutoSize | Out-String
Write-Host '=== log dir (per-table logs) ==='
Get-ChildItem 'C:\Programmation\tb-1\benchmarks\logs\5pc_pawnful' -File -ErrorAction SilentlyContinue |
  Sort-Object LastWriteTime | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize | Out-String
Write-Host '=== generated files ==='
Get-ChildItem 'C:\Programmation\tb-1\test_gen_5pc_full' -File -ErrorAction SilentlyContinue |
  Sort-Object LastWriteTime | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize | Out-String
Write-Host '=== reference files (T: share) for first 5 tables ==='
foreach ($t in @('KBBPvK','KBBvKP','KBNPvK','KBNvKP','KBPvKB')) {
  foreach ($e in @('rtbw','rtbz')) {
    $g = "C:\Programmation\tb-1\test_gen_5pc_full\$t.$e"
    $r = "T:\Syzygy\3-4-5\$t.$e"
    $gl = if (Test-Path $g) { (Get-Item $g).Length } else { -1 }
    $rl = if (Test-Path $r) { (Get-Item $r).Length } else { -1 }
    $rt = if (Test-Path $r) { (Get-Item $r).LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss') } else { 'MISSING' }
    Write-Host ("{0}.{1}  gen={2,12}  ref={3,12}  ref_mtime={4}" -f $t, $e, $gl, $rl, $rt)
  }
}
