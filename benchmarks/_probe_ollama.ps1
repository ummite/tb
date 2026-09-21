$r1 = try { (Invoke-WebRequest -UseBasicParsing -TimeoutSec 6 http://192.168.1.112:11434/v1/models -ErrorAction Stop).StatusCode } catch { "FAIL:$($_.Exception.Message)" }
$r2 = try { (Invoke-WebRequest -UseBasicParsing -TimeoutSec 6 http://192.168.1.112:21434/v1/models -ErrorAction Stop).StatusCode } catch { "FAIL:$($_.Exception.Message)" }
Write-Output "5090(11434)=$r1"
Write-Output "3090(21434)=$r2"
$cs = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfCores,NumberOfLogicalProcessors -Sum
Write-Output ("RAM_GB={0} CoresPhys={1} CoresLog={2}" -f [math]::Round($cs.TotalPhysicalMemory/1GB), $cpu.Sum.NumberOfCores, $cpu.Sum.NumberOfLogicalProcessors)
