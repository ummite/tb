# Pre-flight checks pour generation 6pc single-PC (2026-09-15)
Write-Output "=== CPU / HT ==="
$p = Get-CimInstance Win32_Processor
Write-Output ("Model: " + $p.Name)
Write-Output ("Cores=" + $p.NumberOfCores + " Logical=" + $p.NumberOfLogicalProcessors)
$cs = Get-CimInstance Win32_ComputerSystem
Write-Output ("RAM_GB=" + [math]::Round($cs.TotalPhysicalMemory/1GB) + " HT_enabled=" + $cs.Manufactured + " " + $cs.Model)
Write-Output "=== Power plan ==="
powercfg /getactivescheme
Write-Output "=== Disks ==="
Get-PhysicalDisk | Select-Object FriendlyName,MediaType,BusType,@{n='SizeGB';e={[math]::Round($_.Size/1GB)}} | Format-Table -AutoSize | Out-String
Get-Volume | Where-Object DriveLetter | Select-Object DriveLetter,FileSystemLabel,@{n='FreeGB';e={[math]::Round($_.SizeRemaining/1GB)}},@{n='TotalGB';e={[math]::Round($_.Size/1GB)}} | Format-Table -AutoSize | Out-String
Write-Output "=== Binaires ==="
Get-ChildItem 'C:\Programmation\tb-1\bin' -Filter '*.exe' | Select-Object Name,Length,LastWriteTime | Format-Table -AutoSize | Out-String
Write-Output "=== RTBPATH candidates (5pc) ==="
$dirs = @('C:\Programmation\tb-1\Syzygy','C:\Programmation\tb-1\rtb_sub_34','T:\Syzygy\3-4-5')
foreach ($d in $dirs) {
  if (Test-Path $d) {
    $f = Get-ChildItem $d -File -ErrorAction SilentlyContinue
    $w = @($f | Where-Object {$_.Extension -eq '.rtbw'}).Count
    $z = @($f | Where-Object {$_.Extension -eq '.rtbz'}).Count
    Write-Output ($d + " : " + $f.Count + " fichiers (" + $w + " wdl / " + $z + " dtz)")
  } else {
    Write-Output ($d + " : ABSENT")
  }
}
Write-Output "=== Sleep/hibernate policy ==="
powercfg /query SCHEME_CURRENT SUB_SLEEP 0012df10-8550-4f79-9b70-62be1394b822 | Select-String 'Power Setting State'
Write-Output "=== Auto-restart on crash ==="
$bcd = bcdedit /enum {current} | Select-String 'bootstatuspolicy'
Write-Output ("bootstatuspolicy: " + $bcd)
