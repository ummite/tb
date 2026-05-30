# Automated build feedback loop for tbgenp (regular pawnful)
# Keeps cleaning + building until success or max iterations

$msbuild = "C:\Program Files\Microsoft Visual Studio\18\Insiders\MSBuild\Current\Bin\amd64\MSBuild.exe"
$sln = "tbgen.sln"
$target = "tbgenp"
$maxIterations = 20
$logBase = "loop_build"

Write-Host "=== Starting automated build fix loop for $target ===" -ForegroundColor Cyan

for ($i = 1; $i -le $maxIterations; $i++) {
    Write-Host "`n--- Iteration $i / $maxIterations ---" -ForegroundColor Yellow
    
    # Clean
    Write-Host "Cleaning..." -ForegroundColor Gray
    & $msbuild $sln /p:Configuration=Release /p:Platform=x64 /target:Clean /m /v:quiet 2>&1 | Out-Null
    
    # Build
    $log = "$logBase_$i.log"
    Write-Host "Building $target..." -ForegroundColor Gray
    & $msbuild $sln /p:Configuration=Release /p:Platform=x64 /target:$target /m /v:minimal /fl /flp:logfile=$log 2>&1 | Out-Null
    
    # Analyze
    if (Test-Path $log) {
        $lnkErrors = Get-Content $log | Select-String -Pattern "tbgenp.obj : error LNK2001|fatal error LNK1120"
        if ($lnkErrors.Count -eq 0) {
            Write-Host "SUCCESS! $target built cleanly on iteration $i" -ForegroundColor Green
            Write-Host "Log: $log"
            exit 0
        } else {
            Write-Host "Still failing with $($lnkErrors.Count) linker errors." -ForegroundColor Red
            # Log the top errors for analysis
            $lnkErrors | Select -First 5 | ForEach-Object { Write-Host $_.Line }
        }
    } else {
        Write-Host "No log produced." -ForegroundColor Red
    }
    
    Start-Sleep -Seconds 2
}

Write-Host "Reached max iterations without success." -ForegroundColor Red
exit 1
