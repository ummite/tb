# Isolate KQvKB divergence: RTBPATH x threads. Do not overwrite gen_4pc / test_qr_new.
$ErrorActionPreference = 'Continue'
$bin = 'C:\Programmation\tb-1\bin\tbgen.exe'
$ref = 'T:\Syzygy\3-4-5\KQvKB.rtbw'
$refH = (Get-FileHash $ref -Algorithm SHA256).Hash
Write-Host "REF T: KQvKB.rtbw $refH size=$((Get-Item $ref).Length)"

$cases = @(
  @{ Name='A_sub34_t12'; Path='C:\Programmation\tb-1\rtb_sub_34'; T=12 },
  @{ Name='B_sub34_t24'; Path='C:\Programmation\tb-1\rtb_sub_34'; T=24 },
  @{ Name='C_gen3_t12';  Path='C:\Programmation\tb-1\gen_3pc';    T=12 },
  @{ Name='D_T345_t12';  Path='T:\Syzygy\3-4-5';                  T=12 }
)

foreach ($c in $cases) {
  $dir = Join-Path 'C:\Programmation\tb-1' ("kqkb_" + $c.Name)
  if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
  New-Item -ItemType Directory -Path $dir | Out-Null
  $env:RTBPATH = $c.Path
  $env:RTBSTATSDIR = $dir
  Write-Host "=== $($c.Name) RTBPATH=$($c.Path) -t $($c.T) ==="
  $sw = [Diagnostics.Stopwatch]::StartNew()
  $p = Start-Process -FilePath $bin -ArgumentList @('-t', [string]$c.T, 'KQvKB') -WorkingDirectory $dir -Wait -PassThru -NoNewWindow -RedirectStandardOutput (Join-Path $dir 'out.txt') -RedirectStandardError (Join-Path $dir 'err.txt')
  $sw.Stop()
  $f = Join-Path $dir 'KQvKB.rtbw'
  if (Test-Path $f) {
    $h = (Get-FileHash $f -Algorithm SHA256).Hash
    $sz = (Get-Item $f).Length
    $eq = if ($h -eq $refH) { 'IDENTIQUE' } else { 'DIFF' }
    Write-Host "$($c.Name) exit=$($p.ExitCode) wall=$([math]::Round($sw.Elapsed.TotalSeconds,1))s size=$sz $eq sha=$($h.Substring(0,16))"
  } else {
    Write-Host "$($c.Name) exit=$($p.ExitCode) MISSING FILE"
    Get-Content (Join-Path $dir 'err.txt') -ErrorAction SilentlyContinue | Select-Object -Last 8
  }
  $found = (Select-String -Path (Join-Path $dir 'out.txt') -Pattern 'Found \d+ tablebases|best permutation|calc_size' | ForEach-Object { $_.Line }) -join ' | '
  Write-Host "  $found"
}
Write-Host 'MATRIX_DONE'
