# Full solution build (all 21+ projects: pawnless + pawnful, all variants)
# Uses the reliable pattern that finally made the pawnful subset clean.
# Auto-discovers MSBuild (same logic as build.bat) for VS 2026/2022/Insiders/Community etc.

$msbuild = $null
$msbuildVersion = $null

# Try VS 2026 first (newest) - includes Insiders version (18)
foreach ($v in @('18','2026','2022')) {
    if (-not $msbuild) {
        foreach ($e in @('Insiders','Community','Professional','Enterprise')) {
            if (-not $msbuild) {
                $candidate = "C:\Program Files\Microsoft Visual Studio\$v\$e\MSBuild\Current\Bin\MSBuild.exe"
                if (Test-Path $candidate) {
                    $msbuild = $candidate
                    $msbuildVersion = "$v ($e)"
                }
            }
        }
    }
}

# Try Build Tools
if (-not $msbuild) {
    foreach ($v in @('2026','2022')) {
        if (-not $msbuild) {
            $candidate = "C:\Program Files\Microsoft Visual Studio\BuildTools\MSBuild\$v.0\Bin\MSBuild.exe"
            if (Test-Path $candidate) {
                $msbuild = $candidate
                $msbuildVersion = "BuildTools $v"
            }
        }
    }
}

# Try PATH
if (-not $msbuild) {
    $cmd = Get-Command msbuild -ErrorAction SilentlyContinue
    if ($cmd) {
        $msbuild = $cmd.Source
        $msbuildVersion = 'from PATH'
    }
}

if (-not $msbuild) {
    Write-Error "MSBuild not found. Install VS 2022/2026 with C++ workload or add MSBuild to PATH."
    exit 1
}

Write-Host "MSBuild: $msbuildVersion"
Write-Host "Solution: tbgen.sln"
Write-Host "Full multi-target build (pawnless + pawnful, all 6 variants)..."

$log = "C:\Programmation\tb-1\full_solution_build.log"

# Complete list of all real projects in tbgen.sln (generators + verifiers, all variants)
$targets = "tbgen;tbver;stbgen;stbver;gtbgen;gtbver;ltbgen;ltbver;atbgen;atbver;jtbgen;jtbver;tbgenp;tbverp;stbgenp;stbverp;gtbgenp;gtbverp;ltbgenp;ltbverp;atbgenp;atbverp;jtbgenp;jtbverp"

Write-Host "Building with targets: $targets"
Write-Host "Logging detailed output to: $log"

& "$msbuild" tbgen.sln /t:$targets /p:Configuration=Release /p:Platform=x64 /verbosity:minimal /nologo /fl /flp:"logfile=$log;verbosity=minimal" 2>&1 | Out-Null

$exit = $LASTEXITCODE
Write-Output "Full solution MSBuild exit code: $exit"
exit $exit
