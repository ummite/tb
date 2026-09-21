# Diagnostic: is wrapper 9376 spinning? what is it doing? any crash in event log?
$ErrorActionPreference = 'Continue'
$p = Get-Process -Id 9376 -ErrorAction SilentlyContinue
if ($null -eq $p) { Write-Host 'WRAP 9376 GONE'; exit 0 }
$c1 = $p.CPU
$t1 = $p.Threads.Count
$ws1 = $p.WorkingSet64
Start-Sleep -Seconds 6
$p.Refresh()
$c2 = $p.CPU
Write-Host ("wrapper 9376: CPU {0} -> {1} (delta {2} s over 6 s), threads={3}, WS={4} MB" -f [math]::Round($c1,1), [math]::Round($c2,1), [math]::Round($c2-$c1,2), $t1, [math]::Round($ws1/1MB,1))
Write-Host '=== wrapper threads (top CPU) ==='
$p.Threads | Sort-Object TotalProcessorTime -Descending | Select-Object -First 5 Id, @{n='CPU_s';e={[math]::Round($_.TotalProcessorTime.TotalSeconds,2)}}, ThreadState | Format-Table -AutoSize | Out-String
Write-Host '=== system uptime / last boot ==='
Get-CimInstance Win32_OperatingSystem | Select-Object LastBootUpTime | Format-List
Write-Host '=== last 15 Application errors (crashes) ==='
Get-WinEvent -FilterHashtable @{LogName='Application'; Id=1000; StartTime=(Get-Date '2026-09-13')} -MaxEvents 15 -ErrorAction SilentlyContinue |
  Select-Object TimeCreated, @{n='Msg';e={($_.Message -split "`n")[0]}} | Format-List | Out-String
Write-Host '=== power events (sleep/resume) last 2 days ==='
Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-Power-Troubleshooter'; StartTime=(Get-Date '2026-09-12')} -MaxEvents 10 -ErrorAction SilentlyContinue |
  Select-Object TimeCreated, Id, @{n='Msg';e={($_.Message -split "`n")[0]}} | Format-List | Out-String
Write-Host '=== KNPvKR partials detail ==='
Get-ChildItem 'C:\Programmation\tb-1\test_gen_5pc_full\KNPvKR.*' -File -ErrorAction SilentlyContinue | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize | Out-String
