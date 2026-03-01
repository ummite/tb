@echo off
REM =============================================================================
REM tb-1 Tablebase Generator Build Script (VS2026)
REM =============================================================================
REM This script provides an easy way to build the tablebase generator
REM using Visual Studio 2026 (MSBuild).
REM
REM Usage: build.bat [target]
REM   target: all (default), clean, debug, release, info
REM
REM Prerequisites:
REM   - Visual Studio 2026 with C++ workload installed
REM   - MSBuild available in PATH or Visual Studio installed
REM =============================================================================

cd /d "%~dp0"
set BUILD_TARGET="%~1"
if "%BUILD_TARGET%"=="" set BUILD_TARGET=all

echo ==========================================
echo tb-1 Tablebase Generator Build
echo ==========================================
echo Target: %BUILD_TARGET%
echo.

REM Check for MSBuild
set MSBUILD="C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
if not exist "%MSBUILD%" (
    set MSBUILD="C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe"
)
if not exist "%MSBUILD%" (
    set MSBUILD="C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
)
if not exist "%MSBUILD%" (
    set MSBUILD="C:\Program Files\Microsoft Visual Studio\2026\Community\MSBuild\Current\Bin\MSBuild.exe"
)
if not exist "%MSBUILD%" (
    set MSBUILD="C:\Program Files\Microsoft Visual Studio\2026\Professional\MSBuild\Current\Bin\MSBuild.exe"
)
if not exist "%MSBUILD%" (
    REM Try to find MSBuild via VS Developer Command Prompt
    set MSBUILD=msbuild
)

REM Show configuration info
if "%BUILD_TARGET%"=="info" (
    echo Platform: Windows x64
    echo Compiler: MSBuild (Visual Studio)
    echo Solution: tbgen.sln
    echo.
    echo To build, run: build.bat all
    echo To clean, run: build.bat clean
    goto :eof
)

REM Clean target
if "%BUILD_TARGET%"=="clean" (
    echo Cleaning...
    "%MSBUILD%" "tbgen.sln" /t:Clean /p:Configuration=Release /p:Platform=x64 /verbosity:minimal
    echo Clean complete.
    goto :eof
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
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ==========================================
    echo Build complete!
    echo Executables in: bin\
    echo ==========================================
    echo.
    echo Available executables:
    dir /b bin\*.exe 2>nul | findstr /v jq.exe
) else (
    echo.
    echo Build failed with error %ERRORLEVEL%
    exit /b %ERRORLEVEL%
)