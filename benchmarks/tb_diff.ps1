<#
.SYNOPSIS
  Compare un fichier de tablebase local contre la reference officielle et
  caracteriser la difference : tailles, 1er offset differant, contexte hex.

.DESCRIPTION
  Outil de diagnostic byte-identity. Pour chaque table et chaque extension
  (rtbw/rtbz par defaut), rapporte :
    IDENTICAL  si les octets sont egaux,
    DIFF       sinon, avec les tailles, le 1er offset differant et 24 octets
               de contexte (local vs ref) autour de cet offset.

  Ne modifie rien : lecture seule.

.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File C:\Programmation\tb-1\benchmarks\tb_diff.ps1 `
    -LocalDir C:\Programmation\tb-1\test_gen_5pc_full -RefDir T:\Syzygy\3-4-5 -Table KBBPvK KBPvKB
#>
param(
  [Parameter(Mandatory = $true)][string]$LocalDir,
  [Parameter(Mandatory = $true)][string]$RefDir,
  [Parameter(Mandatory = $true)][string[]]$Table,
  [string[]]$Ext = @('rtbw', 'rtbz'),
  [int]$Dump = 24
)

function HexDump([byte[]]$buf, [int]$start, [int]$len) {
  $out = ''
  for ($i = 0; $i -lt $len; $i++) {
    if ($i -gt 0) { $out += ' ' }
    $out += ('{0:x2}' -f $buf[$start + $i])
  }
  return $out
}

foreach ($t in $Table) {
  foreach ($e in $Ext) {
    $l = Join-Path $LocalDir ($t + '.' + $e)
    $r = Join-Path $RefDir  ($t + '.' + $e)
    if (-not (Test-Path $l)) { Write-Host ('{0}.{1}  LOCAL MISSING' -f $t, $e); continue }
    if (-not (Test-Path $r)) { Write-Host ('{0}.{1}  REF   MISSING' -f $t, $e); continue }

    $lb = [IO.File]::ReadAllBytes($l)
    $rb = [IO.File]::ReadAllBytes($r)
    $n  = [Math]::Min($lb.Length, $rb.Length)
    $d  = -1
    for ($i = 0; $i -lt $n; $i++) {
      if ($lb[$i] -ne $rb[$i]) { $d = $i; break }
    }

    if ($d -lt 0 -and $lb.Length -eq $rb.Length) {
      Write-Host ('{0}.{1}  IDENTICAL  ({2} bytes)' -f $t, $e, $lb.Length)
    }
    else {
      Write-Host ('{0}.{1}  DIFF  local={2} ref={3} firstdiff={4}' -f $t, $e, $lb.Length, $rb.Length, $d)
      if ($d -ge 0) {
        $s = [Math]::Max(0, $d - 8)
        $len = [Math]::Min($Dump, $n - $s)
        if ($len -gt 0) {
          Write-Host ('    off {0,9} local: {1}' -f $s, (HexDump $lb $s $len))
          Write-Host ('    off {0,9} ref  : {1}' -f $s, (HexDump $rb $s $len))
        }
      }
    }
  }
}
