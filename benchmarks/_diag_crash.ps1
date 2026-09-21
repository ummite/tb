# Full crash details for tbgen* / rtbgen* / tbver* on 9/13
$ErrorActionPreference = 'Continue'
$ev = Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=(Get-Date '2026-09-13 16:00:00')} -ErrorAction SilentlyContinue
foreach ($e in $ev) {
  $m = $e.Message
  $app = ''
  if ($m -match 'Faulting application name:\s*(\S+)') { $app = $Matches[1] }
  $exc = ''
  if ($m -match 'Exception code:\s*(\S+)') { $exc = $Matches[1] }
  $off = ''
  if ($m -match 'Exception offset:\s*(\S+)') { $off = $Matches[1] }
  $mod = ''
  if ($m -match 'Faulting module name:\s*(\S+)') { $mod = $Matches[1] }
  Write-Host ('{0}  app={1}  exc={2}  off={3}  module={4}' -f $e.TimeCreated, $app, $exc, $off, $mod)
}
Write-Host '=== first full message (most recent tbgenp) ==='
$first = $ev | Where-Object { $_.Message -match 'tbgenp' } | Select-Object -First 1
if ($first) { $first.Message }
