$names = @("KBPPPvK","KNPPPvK","KNPvKPP","KPPPPvK","KPPPvKB","KPPPvKN","KPPPvKP","KPPPvKQ","KPPPvKR","KPPvKPP","KQPPPvK","KRPPPvK")
foreach ($dir in @("6-WDL","6-DTZ")) {
  $ext = if ($dir -eq "6-WDL") { "rtbw" } else { "rtbz" }
  Write-Output "=== $dir ($ext) ==="
  foreach ($n in $names) {
    $f = Get-Item "T:\Syzygy\$dir\$n.$ext" -ErrorAction SilentlyContinue
    if ($f) { Write-Output ("{0} {1:N0} MB" -f $n, ($f.Length/1MB)) } else { Write-Output "$n MANQUANT" }
  }
}
