@echo off
setlocal enabledelayedexpansion

echo =============================================================================
echo tb-1 Build & Test Validation
echo =============================================================================
echo.

REM 1. Find MSBuild
set MSBUILD=
for %%V in (18 2026 2022) do (
    if not defined MSBUILD (
        for %%E in (Insiders Community Professional Enterprise) do (
            if not defined MSBUILD (
                if exist "C:\Program Files\Microsoft Visual Studio\%%V\%%E\MSBuild\Current\Bin\MSBuild.exe" (
                    set MSBUILD="C:\Program Files\Microsoft Visual Studio\%%V\%%E\MSBuild\Current\Bin\MSBuild.exe"
                )
            )
        )
    )
)

if not defined MSBuild (
    echo ERROR: MSBuild not found. Please install Visual Studio with C++ workload.
    exit /b 1
)
echo Found MSBuild: %MSBuild%
echo.

REM 2. Build
echo Building...
%MSBuild% tbgen.sln /p:Configuration=Release /p:Platform=x64 /verbosity:minimal
if %ERRORLEVEL% neq 0 (
    echo.
    echo ❌ BUILD FAILED with error %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)
echo ✅ Build successful
echo.

REM 3. Test generation
set TEST_DIR=test_tbs
if not exist "%TEST_DIR%" mkdir "%TEST_DIR%"
set RTBPATH=%CD%\%TEST_DIR%

echo Generating test tablebase (KQvK)...
bin\rtbgen.exe -t 1 --stats KQvKR > test_output.txt 2>&1
if %ERRORLEVEL% neq 0 (
    echo.
    echo ❌ Generation failed:
    type test_output.txt
    exit /b %ERRORLEVEL%
)
echo ✅ Generation successful
echo.

REM 4. Verify output
if not exist "%TEST_DIR%\KQvKR.rtbw" (
    echo ❌ ERROR: Output file KQvKR.rtbw not created
    exit /b 1
)
echo ✅ Output file KQvKR.rtbw exists

echo.
echo =============================================================================
echo ALL TESTS PASSED — Build is functional!
echo =============================================================================
echo.
