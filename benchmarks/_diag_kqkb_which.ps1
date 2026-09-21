# Which extra tables in rtb_sub_34 make KQvKB match T:?
$ErrorActionPreference = 'Continue'
$bin = 'C:\Programmation\tb-1\bin\tbgen.exe'
$refH = (Get-FileHash 'T:\Syzygy\3-4-5\KQvKB.rtbw' -Algorithm SHA256).Hash
$src = 'C:\Programmation\tb-1\rtb_sub_34'
$root = 'C:\Programmation\tb-1\kqkb_which'
if (Test-Path $root) { Remove-Item $root -Recurse -Force }
New-Item -ItemType Directory -Path $root | Out-Null

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

$pc3 = @('KQvK','KRvK','KBvK','KNvK','KPvK')
$vK4 = @('KBBvK','KBNvK','KNNvK','KQBvK','KQNvK','KQQvK','KQRvK','KRBvK','KRNvK','KRRvK')
$both4 = @('KBvKB','KBvKN','KNvKN','KQvKB','KQvKN','KQvKQ','KQvKR','KRvKB','KRvKN','KRvKR')

$cases = @(
  @{ Name='only3';    Dir = New-Subset 'only3' $pc3 },
  @{ Name='3plusVK';  Dir = New-Subset '3plusVK' ($pc3 + $vK4) },
  @{ Name='3noSelf';  Dir = New-Subset '3noSelf' ($pc3 + $vK4 + ($both4 | Where-Object { $_ -ne 'KQvKB' })) },
  @{ Name='3plusSelf';Dir = New-Subset '3plusSelf' ($pc3 + @('KQvKB')) }
)

foreach ($c in $cases) {
  $out = Join-Path $root ("out_" + $c.Name)
  New-Item -ItemType Directory -Path $out | Out-Null
  $env:RTBPATH = $c.Dir
  $env:RTBSTATSDIR = $out
  $p = Start-Process -FilePath $bin -ArgumentList @('-t','12','KQvKB') -WorkingDirectory $out -Wait -PassThru -NoNewWindow -RedirectStandardOutput (Join-Path $out 'out.txt') -RedirectStandardError (Join-Path $out 'err.txt')
  $f = Join-Path $out 'KQvKB.rtbw'
  if (Test-Path $f) {
    $h = (Get-FileHash $f -Algorithm SHA256).Hash
    $eq = if ($h -eq $refH) { 'IDENTIQUE' } else { 'DIFF' }
    $found = (Select-String -Path (Join-Path $out 'out.txt') -Pattern 'Found \d+' | Select-Object -First 1).Line
    Write-Host "$($c.Name) exit=$($p.ExitCode) $found $eq sha=$($h.Substring(0,16)) size=$((Get-Item $f).Length)"
  } else {
    Write-Host "$($c.Name) MISSING exit=$($p.ExitCode)"
    Get-Content (Join-Path $out 'err.txt') | Select-Object -Last 6
  }
}
Write-Host 'WHICH_DONE'
