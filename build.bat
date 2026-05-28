@echo off
REM =============================================================================
REM tb-1 Tablebase Generator Build Script (Visual Studio)
REM =============================================================================
REM This script provides an easy way to build the tablebase generator
REM using Visual Studio MSBuild.
REM
REM Usage: build.bat [target]
REM   target: all (default), clean, debug, release, verify, info
REM
REM Prerequisites:
REM   - Visual Studio 2022/2026 with C++ workload installed
REM   - MSBuild available in PATH or Visual Studio installed
REM =============================================================================

cd /d "%~dp0"
set "BUILD_TARGET=%~1"
if not defined BUILD_TARGET set BUILD_TARGET=all
if "%BUILD_TARGET%"=="" set BUILD_TARGET=all

echo ==========================================
echo tb-1 Tablebase Generator Build
echo ==========================================
echo Target: %BUILD_TARGET%
echo.

REM Check for MSBuild - try multiple locations
set MSBUILD=
set MSBUILD_VERSION=

REM Try VS 2026 first (newest) - includes Insiders version (18)
for %%V in (18 2026 2022) do (
    if not defined MSBUILD (
        for %%E in (Insiders Community Professional Enterprise) do (
            if not defined MSBUILD (
                if exist "C:\Program Files\Microsoft Visual Studio\%%V\%%E\MSBuild\Current\Bin\MSBuild.exe" (
                    set MSBUILD="C:\Program Files\Microsoft Visual Studio\%%V\%%E\MSBuild\Current\Bin\MSBuild.exe"
                    set MSBUILD_VERSION=%%V (%%E)
                )
            )
        )
    )
)

REM Try Build Tools
if not defined MSBUILD (
    for %%V in (2026 2022) do (
        if not defined MSBUILD (
            if exist "C:\Program Files\Microsoft Visual Studio\BuildTools\MSBuild\%%V.0\Bin\MSBuild.exe" (
                set MSBUILD="C:\Program Files\Microsoft Visual Studio\BuildTools\MSBuild\%%V.0\Bin\MSBuild.exe"
                set MSBUILD_VERSION=BuildTools %%V
            )
        )
    )
)

REM Try PATH
if not defined MSBUILD (
    where msbuild >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        set MSBUILD=msbuild
        set MSBUILD_VERSION=from PATH
    )
)

REM Check if MSBuild found
if not defined MSBUILD (
    echo ERROR: MSBuild not found!
    echo.
    echo Please install Visual Studio 2022 or later with C++ workload,
    echo or add MSBuild to your PATH.
    echo.
    echo Download: https://visualstudio.microsoft.com/downloads/
    exit /b 1
)

echo MSBuild: %MSBUILD_VERSION%
echo Solution: tbgen.sln
echo Projects: 25 (5 regular + 4 atomic + 4 suicide + 4 giveaway + 4 shatranj + 4 loser)
echo.

REM Show configuration info
if "%BUILD_TARGET%"=="info" (
    echo Platform: Windows x64
    echo Compiler: MSVC (Microsoft Visual C++)
    echo C Standard: C11
    echo.
    echo Available targets:
    echo   all      - Build Release configuration (default)
    echo   release  - Build Release configuration
    echo   debug    - Build Debug configuration
    echo   clean    - Clean build artifacts
    echo   verify   - Build and verify executables (25 total incl. loser)
echo   6/7 test - See docs\TESTING_SYZYGY_6_7.md + test_syzygy67.bat for 6-piece and 7-piece testing sequence
    echo   info     - Show this info
    goto :eof
)

REM Clean target
if "%BUILD_TARGET%"=="clean" (
    echo Cleaning build artifacts...
    if exist "bin\" rd /s /q "bin"
    if exist "objsr\" rd /s /q "objsr"
    "%MSBUILD%" "tbgen.sln" /t:Clean /p:Configuration=Release /p:Platform=x64 /verbosity:minimal 2>nul
    "%MSBUILD%" "tbgen.sln" /t:Clean /p:Configuration=Debug /p:Platform=x64 /verbosity:minimal 2>nul
    echo Clean complete.
    goto :eof
)

REM Verify target - build and check executables
if "%BUILD_TARGET%"=="verify" (
    echo Building Release configuration...
    "%MSBUILD%" "tbgen.sln" /p:Configuration=Release /p:Platform=x64 /verbosity:minimal
    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo Build failed with error %ERRORLEVEL%
        exit /b %ERRORLEVEL%
    )
    goto :verify_check
)

REM Debug target
if "%BUILD_TARGET%"=="debug" (
    echo Building Debug configuration...
    "%MSBUILD%" "tbgen.sln" /p:Configuration=Debug /p:Platform=x64 /verbosity:minimal
    if %ERRORLEVEL% EQU 0 (
        echo.
        echo ==========================================
        echo Build complete!
        echo Debug executables in: bin\
        echo ==========================================
    ) else (
        echo.
        echo Build failed with error %ERRORLEVEL%
        exit /b %ERRORLEVEL%
    )
    goto :eof
)

REM Release target
if "%BUILD_TARGET%"=="release" (
    echo Building Release configuration...
    "%MSBUILD%" "tbgen.sln" /p:Configuration=Release /p:Platform=x64 /verbosity:minimal
    if %ERRORLEVEL% EQU 0 (
        echo.
        echo ==========================================
        echo Build complete!
        echo Release executables in: bin\
        echo ==========================================
    ) else (
        echo.
        echo Build failed with error %ERRORLEVEL%
        exit /b %ERRORLEVEL%
    )
    goto :eof
)

REM Default: all target (Release build)
echo Building Release configuration...
"%MSBUILD%" "tbgen.sln" /p:Configuration=Release /p:Platform=x64 /verbosity:minimal
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Build failed with error %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)

:verify_check
echo.
echo ==========================================
echo Verifying build output...
echo ==========================================

REM Create bin directory if it doesn't exist
if not exist "bin\" mkdir "bin"

REM Count expected executables
set EXPECTED=25
set FOUND=0

for %%f in (bin\*.exe) do set /a FOUND+=1

echo Found %FOUND% executables in bin\
echo Expected: %EXPECTED%

if %FOUND% LSS %EXPECTED% (
    echo.
    echo WARNING: Some executables may be missing!
    echo.
    echo Generated executables:
    dir /b bin\*.exe 2>nul
    exit /b 1
)

echo.
echo ==========================================
echo Build complete and verified!
echo ==========================================
echo.
echo Available executables:
dir /b bin\*.exe 2>nul | findstr /v /i "jq"
echo.
echo Total: %FOUND% executables