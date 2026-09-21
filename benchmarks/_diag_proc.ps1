tasklist /FI "IMAGENAME eq tbgenp.exe"
tasklist /FI "IMAGENAME eq rtbgenp.exe"
Get-CimInstance Win32_Process -Filter "name like '%tbgen%'" | Select-Object ProcessId, Name, CreationDate | Format-Table -AutoSize | Out-String
