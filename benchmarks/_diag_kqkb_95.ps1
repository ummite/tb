# rtb_sub_34 minus one group at a time
$ErrorActionPreference = 'Continue'
$bin = 'C:\Programmation\tb-1\bin\tbgen.exe'
$refH = (Get-FileHash 'T:\Syzygy\3-4-5\KQvKB.rtbw' -Algorithm SHA256).Hash
$src = 'C:\Programmation\tb-1\rtb_sub_34'
$root = 'C:\Programmation\tb-1\kqkb_95'
if (Test-Path $root) { Remove-Item $root -Recurse -Force }
New-Item -ItemType Directory -Path $root | Out-Null

$all = Get-ChildItem $src -Filter '*.rtbw' | ForEach-Object { $_.BaseName }
$pc3 = $all | Where-Object { $_.Length -eq 4 }
$pc4 = $all | Where-Object { $_.Length -eq 5 }
$pc5 = $all | Where-Object { $_.Length -eq 6 }

function New-Subset($name, $bases) {
  $d = Join-Path $root $name
  New-Item -ItemType Directory -Path $d | Out-Null
  foreach ($b in $bases) {
    foreach ($e in 'rtbw','rtbz') {
      $f = Join-Path $src "$b.$e"
      if (Test-Path $f) { Copy-Item $f $d }
    }
  }
  return $d
}

$cases = @(
  @{ Name='3plus4'; Dir = New-Subset '3plus4' ($pc3 + $pc4) },
  @{ Name='95minusKQKB'; Dir = New-Subset '95minusKQKB' ($all | Where-Object { $_ -ne 'KQvKB' }) },
  @{ Name='95minus1_5pc'; Dir = New-Subset '95minus1_5pc' ($all | Where-Object { $_ -ne 'KQBvKN' }) }
)

foreach ($c in $cases) {
  $out = Join-Path $root ("out_" + $c.Name)
  New-Item -ItemType Directory -Path $out | Out-Null
  $env:RTBPATH = $c.Dir
  $env:RTBSTATSDIR = $out
  $p = Start-Process -FilePath $bin -ArgumentList @('-t','12','KQvKB') -WorkingDirectory $out -Wait -PassThru -NoNewWindow -RedirectStandardOutput (Join-Path $out 'out.txt') -RedirectStandardError (Join-Path $out 'err.txt')
  $f = Join-Path $out 'KQvKB.rtbw'
  $h = (Get-FileHash $f -Algorithm SHA256).Hash
  $eq = if ($h -eq $refH) { 'IDENTIQUE' } else { 'DIFF' }
  $found = (Select-String -Path (Join-Path $out 'out.txt') -Pattern 'Found \d+' | Select-Object -First 1).Line
  Write-Host "$($c.Name) $found $eq sha=$($h.Substring(0,16)) nfiles=$((Get-ChildItem $c.Dir -File).Count)"
}
Write-Host 'NINETY5_DONE'
