$p = Get-CimInstance Win32_Processor
Write-Output $p.Name
Write-Output ("Cores=" + $p.NumberOfCores + " Log=" + $p.NumberOfLogicalProcessors + " MaxMHz=" + $p.MaxClockSpeed)
$os = Get-CimInstance Win32_OperatingSystem
Write-Output ("OS=" + $os.Caption.Trim() + " FreeGB=" + [math]::Round($os.FreePhysicalMemory/1MB,1))
