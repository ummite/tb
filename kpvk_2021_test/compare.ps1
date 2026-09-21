$ErrorActionPreference = 'Continue'
$files = @(
  'T:\Syzygy\3-4-5\KPvK.rtbw',
  'T:\Syzygy\3-4-5\KPvK.rtbz',
  'C:\Programmation\tb-1\kpvk_2021_test\KPvK.rtbw',
  'C:\Programmation\tb-1\kpvk_2021_test\KPvK.rtbz',
  'C:\Programmation\tb-1\gen_3pc\KPvK.rtbw',
  'C:\Programmation\tb-1\gen_3pc\KPvK.rtbz'
)
foreach ($f in $files) {
  if (Test-Path -LiteralPath $f) {
    $h = (Get-FileHash -Algorithm SHA256 -LiteralPath $f).Hash
    $l = (Get-Item -LiteralPath $f).Length
    $tail = [System.BitConverter]::ToString((Get-Content -LiteralPath $f -Encoding Byte -Tail 16)).Replace('-','').ToLower()
    Write-Output ("{0} | size={1} | sha256={2} | trailer={3}" -f $f, $l, $h, $tail)
  } else {
    Write-Output ("MISSING: " + $f)
  }
}
