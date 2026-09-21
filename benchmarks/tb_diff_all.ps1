param(
  [string]$LocalDir,
  [string]$RefDir,
  [string]$Label = ''
)
# Fast whole-set byte-identity check: every *.rtbw/*.rtbz in LocalDir vs RefDir (SHA-256).
$ok = 0; $no = @(); $missing = @()
Get-ChildItem $LocalDir -Filter *.rtbw | ForEach-Object {
  $r = Join-Path $RefDir $_.Name
  if (-not (Test-Path $r)) { $missing += ($_.BaseName + '.rtbw'); return }
  $a = (Get-FileHash $_.FullName).Hash; $b = (Get-FileHash $r).Hash
  if ($a -eq $b) { $ok++ } else { $no += ($_.BaseName + '.rtbw') }
  $rz  = Join-Path (Split-Path $_.FullName) ($_.BaseName + '.rtbz')
  $rzz = Join-Path (Split-Path $r) ($_.BaseName + '.rtbz')
  if ((Test-Path $rz) -and (Test-Path $rzz)) {
    $ca = (Get-FileHash $rz).Hash; $cb = (Get-FileHash $rzz).Hash
    if ($ca -ne $cb) { $no += ($_.BaseName + '.rtbz') } else { $ok++ }
  } elseif (Test-Path $rz) {
    $missing += ($_.BaseName + '.rtbz (in ref)')
  }
}
"=== {0} : OK={1} DIFF={2} ===" -f $Label, $ok, $no.Count
if ($no.Count) { 'DIFF:'; $no | ForEach-Object { "  $_" } }
if ($missing.Count) { 'MISSING:'; $missing | ForEach-Object { "  $_" } }
