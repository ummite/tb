# Post-UAF-fix: KQvKB must match T: with RTBPATH=gen_3pc only (5 tables).
$ErrorActionPreference = 'Continue'
$bin = 'C:\Programmation\tb-1\bin\tbgen.exe'
$refw = 'T:\Syzygy\3-4-5\KQvKB.rtbw'
$refz = 'T:\Syzygy\3-4-5\KQvKB.rtbz'
$refHw = (Get-FileHash $refw -Algorithm SHA256).Hash
$refHz = (Get-FileHash $refz -Algorithm SHA256).Hash
$dir = 'C:\Programmation\tb-1\kqkb_postfix'
if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
New-Item -ItemType Directory -Path $dir | Out-Null
$env:RTBPATH = 'C:\Programmation\tb-1\gen_3pc'
$env:RTBSTATSDIR = $dir
Write-Host "tbgen.exe $((Get-Item $bin).LastWriteTime) size=$((Get-Item $bin).Length)"
$p = Start-Process -FilePath $bin -ArgumentList @('-t','12','KQvKB') -WorkingDirectory $dir -Wait -PassThru -NoNewWindow -RedirectStandardOutput (Join-Path $dir 'out.txt') -RedirectStandardError (Join-Path $dir 'err.txt')
Write-Host "exit=$($p.ExitCode)"
Get-Content (Join-Path $dir 'out.txt') | Select-Object -First 3
foreach ($pair in @(@('rtbw',$refHw), @('rtbz',$refHz))) {
  $f = Join-Path $dir ("KQvKB." + $pair[0])
  $h = (Get-FileHash $f -Algorithm SHA256).Hash
  $eq = if ($h -eq $pair[1]) { 'IDENTIQUE' } else { 'DIFF' }
  Write-Host ("KQvKB.{0} {1} size={2} sha={3}" -f $pair[0], $eq, (Get-Item $f).Length, $h.Substring(0,16))
}
Write-Host 'POSTFIX_DONE'
