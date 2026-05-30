$ErrorActionPreference = "Continue"

$msbuild = "C:\Program Files\Microsoft Visual Studio\18\Insiders\MSBuild\Current\Bin\MSBuild.exe"
$log = "C:\Programmation\tb-1\iteration_build.log"
if (Test-Path $log) { Remove-Item $log -Force -ErrorAction SilentlyContinue }

$pawnful = @(
    "tbgenp","tbverp",
    "stbgenp","stbverp",
    "gtbgenp","gtbverp",
    "ltbgenp","ltbverp",
    "atbgenp","atbverp",
    "jtbgenp","jtbverp"
)

Write-Host "=== Pawnful iteration build starting ==="
Write-Host "Targeting: $($pawnful -join ', ')"

$targets = ($pawnful -join ";")
$args = @(
    "tbgen.sln",
    "/t:$targets",
    "/p:Configuration=Release",
    "/p:Platform=x64",
    "/verbosity:minimal",
    "/nologo",
    "/fl",
    "/flp:logfile=$log;verbosity=diagnostic"
)

& $msbuild @args
$code = $LASTEXITCODE

Write-Host ""
Write-Host "=== MSBuild finished with exit code $code ==="
Write-Host "Full log: $log"

if (Test-Path $log) {
    $errors = Get-Content $log | Select-String -Pattern "error C" | Select-Object -First 50
    if ($errors) {
        Write-Host ""
        Write-Host "=== First errors (Cxxxx) ==="
        $errors | ForEach-Object { $_.Line }
    } else {
        Write-Host "No 'error C' lines found in log (good sign or only warnings)."
    }
} else {
    Write-Host "No log file produced."
}

exit $code