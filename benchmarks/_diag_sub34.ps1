# Repartition par cardinalite + provenance de rtb_sub_34
$dir = 'C:\Programmation\tb-1\rtb_sub_34'
$files = Get-ChildItem $dir -File
Write-Host ("TOTAL " + $files.Count)
$g3 = $files | Where-Object { $_.BaseName -match '^(KQ|KR|KB|KN|KP)vK$' }
$g4 = $files | Where-Object { ($_.BaseName -split 'v')[0].Length -eq 3 }
$g5 = $files | Where-Object { ($_.BaseName -split 'v')[0].Length -eq 4 }
Write-Host ("3PC " + $g3.Count)
Write-Host ("4PC " + $g4.Count)
Write-Host ("5PC " + $g5.Count)
Write-Host "SAMPLE 4PC:"
$g4 | Select-Object -First 8 | ForEach-Object { Write-Host ("  " + $_.Name + " " + $_.Length) }
# Provenance de KRvKR.rtbw : compare vs T:\Syzygy et vs test_gen_4pc_full
$ref = 'T:\Syzygy\3-4-5\KRvKR.rtbw'
$our = 'C:\Programmation\tb-1\test_gen_4pc_full\KRvKR.rtbw'
$sub = (Join-Path $dir 'KRvKR.rtbw')
if (Test-Path $sub) {
  $hSub = (Get-FileHash $sub -Algorithm SHA256).Hash
  $hRef = (Get-FileHash $ref -Algorithm SHA256).Hash
  $hOur = (Get-FileHash $our -Algorithm SHA256).Hash
  Write-Host ("SUB  " + $hSub)
  Write-Host ("REF  " + $hRef)
  Write-Host ("OUR  " + $hOur)
  if ($hSub -eq $hRef) { Write-Host "PROVENANCE: sub34 KRvKR = OFFICIEL" }
  elseif ($hSub -eq $hOur) { Write-Host "PROVENANCE: sub34 KRvKR = NOTRE GENERATION" }
  else { Write-Host "PROVENANCE: sub34 KRvKR = AUCUN DES DEUX" }
} else {
  Write-Host "KRvKR.rtbw absent de rtb_sub_34"
}
