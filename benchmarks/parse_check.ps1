# parse_check.ps1 - PS 5.1 syntax (parse) check for tb_benchmark.ps1.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File C:\Programmation\tb-1\benchmarks\parse_check.ps1
$target = 'C:\Programmation\tb-1\benchmarks\tb_benchmark.ps1'
$tokens = $null
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile($target, [ref]$tokens, [ref]$errors) | Out-Null
if ($errors.Count -eq 0) {
  Write-Host ('PARSE_OK target={0} errors=0' -f $target)
  exit 0
}
foreach ($er in $errors) {
  Write-Host ('PARSE_ERR line={0} col={1} msg={2}' -f $er.Extent.StartLineNumber, $er.Extent.StartColumnNumber, $er.Message)
}
exit 1
