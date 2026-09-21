$tokens = $null
$errs = $null
[void][System.Management.Automation.Language.Parser]::ParseFile('C:\Programmation\tb-1\benchmarks\run_6pc.ps1', [ref]$tokens, [ref]$errs)
if ($errs.Count -eq 0) { Write-Output 'SYNTAX OK' } else { $errs | ForEach-Object { Write-Output ('ERR line ' + $_.Extent.StartLineNumber + ': ' + $_.Message) } }
