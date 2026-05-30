$ErrorActionPreference = "Stop"
$msbuild = "C:\Program Files\Microsoft Visual Studio\18\Insiders\MSBuild\Current\Bin\MSBuild.exe"
$log = "C:\Programmation\tb-1\tbgenp_detailed.log"
if (Test-Path $log) { Remove-Item $log -Force -ErrorAction SilentlyContinue }
Write-Host "=== Starting detailed build of tbgenp project ==="
Write-Host "MSBuild: $msbuild"
Write-Host "Log: $log"
& $msbuild "C:\Programmation\tb-1\tbgen.sln" /t:tbgenp /p:Configuration=Release /p:Platform=x64 /verbosity:minimal /nologo /fl /flp:"logfile=$log;verbosity=detailed" /nr:false
$code = $LASTEXITCODE
Write-Host "=== tbgenp build finished with exit code $code ==="
exit $code