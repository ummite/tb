# Reliable pawnful-only build for iteration loop (regular + all variants genp/verp)
$msbuild = "C:\Program Files\Microsoft Visual Studio\18\Insiders\MSBuild\Current\Bin\MSBuild.exe"
if (-not (Test-Path $msbuild)) {
    $msbuild = "C:\Program Files\Microsoft Visual Studio\18\Insiders\MSBuild\Current\Bin\amd64\MSBuild.exe"
}
if (-not (Test-Path $msbuild)) {
    Write-Error "MSBuild not found"
    exit 1
}

$log = "C:\Programmation\tb-1\iteration_build.log"
$targets = "tbgenp;tbverp;stbgenp;stbverp;gtbgenp;gtbverp;ltbgenp;ltbverp;atbgenp;atbverp;jtbgenp;jtbverp"

& $msbuild tbgen.sln /t:$targets /p:Configuration=Release /p:Platform=x64 /verbosity:minimal /nologo /fl /flp:"logfile=$log;verbosity=diagnostic" 2>&1 | Out-Null
$exit = $LASTEXITCODE
Write-Output "MSBuild exit code: $exit"
exit $exit
