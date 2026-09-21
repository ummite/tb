# Premier octet qui differe : genere vs reference officielle (sortie compacte)
$pairs = @(
  @('C:\Programmation\tb-1\test_gen_4pc_full\KRvKR.rtbw', 'T:\Syzygy\3-4-5\KRvKR.rtbw'),
  @('C:\Programmation\tb-1\test_gen_4pc_full\KRvKR.rtbz', 'T:\Syzygy\3-4-5\KRvKR.rtbz'),
  @('C:\Programmation\tb-1\test_gen_4pc_full\KQvKB.rtbw', 'T:\Syzygy\3-4-5\KQvKB.rtbw'),
  @('C:\Programmation\tb-1\test_gen_4pc_full\KQvKR.rtbz', 'T:\Syzygy\3-4-5\KQvKR.rtbz'),
  @('C:\Programmation\tb-1\test_gen_5pc_full\KRRvKR.rtbw', 'T:\Syzygy\3-4-5\KRRvKR.rtbw'),
  @('C:\Programmation\tb-1\test_gen_5pc_full\KRRvKR.rtbz', 'T:\Syzygy\3-4-5\KRRvKR.rtbz'),
  @('C:\Programmation\tb-1\test_gen_4pc_full\KBvKP.rtbw', 'T:\Syzygy\3-4-5\KBvKP.rtbw')
)
function HexWin([byte[]]$b, [int]$start, [int]$len) {
  if ($start -lt 0) { $start = 0 }
  if ($start + $len -gt $b.Count) { $len = $b.Count - $start }
  $s = ''
  for ($i = 0; $i -lt $len; $i++) { $s += ('{0:x2}' -f $b[$start + $i]) }
  return $s
}
foreach ($p in $pairs) {
  $name = [System.IO.Path]::GetFileName($p[0])
  if (-not (Test-Path $p[0])) { Write-Host ("{0} : MANQUANT (genere)" -f $name); continue }
  if (-not (Test-Path $p[1])) { Write-Host ("{0} : MANQUANT (ref)" -f $name); continue }
  $a = [System.IO.File]::ReadAllBytes($p[0])
  $b = [System.IO.File]::ReadAllBytes($p[1])
  $n = [Math]::Min($a.Count, $b.Count)
  $d = -1
  for ($i = 0; $i -lt $n; $i++) { if ($a[$i] -ne $b[$i]) { $d = $i; break } }
  if ($a.Count -ne $b.Count -and $d -eq -1) { $d = $n }
  if ($d -eq -1) {
    Write-Host ("{0} : IDENTICAL ({1} o)" -f $name, $a.Count)
  } else {
    $st = $d - 12
    Write-Host ("{0} : gen={1} ref={2} premier-diff @{3} (0x{4:x})" -f $name, $a.Count, $b.Count, $d, $d)
    Write-Host ("  gen: " + (HexWin $a $st 32))
    Write-Host ("  ref: " + (HexWin $b $st 32))
    # trailer (8 derniers octets = checksum)
    $tg = (HexWin $a ($a.Count - 8) 8)
    $tr = (HexWin $b ($b.Count - 8) 8)
    if ($tg -ne $tr) { Write-Host "  trailer8: DIFFERENT (gen=$tg ref=$tr)" } else { Write-Host "  trailer8: identical" }
  }
}
# Entete 64 octets de KRvKR.rtbw (gen vs ref) pour decodage metadonnees
$ha = [System.IO.File]::ReadAllBytes('C:\Programmation\tb-1\test_gen_4pc_full\KRvKR.rtbw')
$hb = [System.IO.File]::ReadAllBytes('T:\Syzygy\3-4-5\KRvKR.rtbw')
Write-Host "KRvKR.rtbw header 64o gen:"
Write-Host ("  " + (HexWin $ha 0 64))
Write-Host "KRvKR.rtbw header 64o ref:"
Write-Host ("  " + (HexWin $hb 0 64))
