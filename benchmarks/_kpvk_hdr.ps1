$ErrorActionPreference = 'Stop'
$genW = 'C:\Programmation\tb-1\gen_3pc\KPvK.rtbw'
$refW = 'T:\Syzygy\3-4-5\KPvK.rtbw'
$genZ = 'C:\Programmation\tb-1\gen_3pc\KPvK.rtbz'
$refZ = 'T:\Syzygy\3-4-5\KPvK.rtbz'

function Dump($path, $n) {
  $b = [System.IO.File]::ReadAllBytes($path)
  $m = [Math]::Min($n, $b.Length)
  $hex = (($b[0..($m-1)] | ForEach-Object { '{0:x2}' -f [int]$_ }) -join ' ')
  Write-Host ('{0}  len={1}  [{2}]' -f $path, $b.Length, $hex)
}

Dump $genW 64
Dump $refW 64
Dump $genZ 64
Dump $refZ 64
