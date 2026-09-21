# Test: 5pc pawnless in RTBPATH vs adding pawnful 5pc
$ErrorActionPreference = 'Continue'
$bin = 'C:\Programmation\tb-1\bin\tbgen.exe'
$refH = (Get-FileHash 'T:\Syzygy\3-4-5\KQvKB.rtbw' -Algorithm SHA256).Hash
$src = 'C:\Programmation\tb-1\rtb_sub_34'
$t345 = 'T:\Syzygy\3-4-5'
$root = 'C:\Programmation\tb-1\kqkb_5pc'
if (Test-Path $root) { Remove-Item $root -Recurse -Force }
New-Item -ItemType Directory -Path $root | Out-Null

$pc3 = @('KQvK','KRvK','KBvK','KNvK','KPvK')
$all = Get-ChildItem $src -Filter '*.rtbw' | ForEach-Object { $_.BaseName }
$pc5 = $all | Where-Object { $_.Length -eq 6 }
$pc5pf = Get-ChildItem $t345 -Filter '*.rtbw' | ForEach-Object { $_.BaseName } | Where-Object { $_.Length -eq 6 -and $_ -match 'P' -and ($pc5 -notcontains $_) }

function New-Subset($name, $bases, $from) {
  $d = Join-Path $root $name
  New-Item -ItemType Directory -Path $d | Out-Null
  foreach ($b in $bases) {
    foreach ($e in 'rtbw','rtbz') {
      $f = Join-Path $from "$b.$e"
      if (Test-Path $f) { Copy-Item $f $d }
    }
  }
  return $d
}

Write-Host "5pc pawnless in rtb_sub_34: $($pc5.Count)"
Write-Host "5pc pawnful extra in T: $($pc5pf.Count)"

$cases = @(
  @{ Name='3plus5pl'; Dir = New-Subset '3plus5pl' ($pc3 + $pc5) $src },
  @{ Name='full95';   Dir = $src },
  @{ Name='95plus5pf'; Dir = $( $d = New-Subset '95plus5pf' $all $src; foreach ($b in $pc5pf) { foreach ($e in 'rtbw','rtbz') { $f = Join-Path $t345 "$b.$e"; if (Test-Path $f) { Copy-Item $f $d } } }; $d ) }
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
    Write-Host "$($c.Name) exit=$($p.ExitCode) $found $eq sha=$($h.Substring(0,16)) size=$((Get-Item $f).Length) nfiles=$((Get-ChildItem $c.Dir -File).Count)"
  } else {
    Write-Host "$($c.Name) MISSING exit=$($p.ExitCode)"
    Get-Content (Join-Path $out 'err.txt') | Select-Object -Last 8
  }
}
Write-Host 'FIVEPC_DONE'
