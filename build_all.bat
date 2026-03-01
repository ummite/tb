@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Building all tablebase tools
echo ========================================
echo.

REM Find Visual Studio installation
set "VS_BAT="
if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat" (
    set "VS_BAT=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
) else if exist "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat" (
    set "VS_BAT=C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat"
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat" (
    set "VS_BAT=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"
)

REM Check for MinGW
where gcc >nul 2>&1
set "MINGW_AVAILABLE=%errorlevel%"

if "!VS_BAT!"=="" (
    if "!MINGW_AVAILABLE!"=="0" (
        echo No Visual Studio found. Using MinGW.
        goto mingw_build
    ) else (
        echo ERROR: No build tools found (Visual Studio or MinGW).
        echo Please install Visual Studio Build Tools or MinGW.
        pause
        exit /b 1
    )
)

echo Build tools: Visual Studio
call "!VS_BAT!"
if errorlevel 1 (
    echo ERROR: Failed to initialize Visual Studio environment.
    goto mingw_build
)

echo.
echo Building with MSBuild...
if exist tbgen.sln (
    msbuild tbgen.sln /p:Configuration=Release /p:Platform=x64 /v:minimal /nologo
    if errorlevel 1 (
        echo ERROR: MSBuild failed.
        goto mingw_build
    )
    echo.
    echo Build completed with MSBuild!
) else (
    echo WARNING: tbgen.sln not found. Using MinGW.
    goto mingw_build
)
goto end

:mingw_build
echo.
echo Building with MinGW...
cd src
if errorlevel 1 (
    echo ERROR: Cannot change to src directory.
    cd ..
    pause
    exit /b 1
)

REM Only clean if makefile exists
if exist Makefile.regular (
    make clean 2>nul || echo Note: make clean not available
)

make all
if errorlevel 1 (
    echo ERROR: MinGW build failed.
    cd ..
    pause
    exit /b 1
)

REM Copy binaries with proper error checking
copy /y ..\bin\tbgen.exe ..\bin\rtbgen.exe >nul 2>&1 || echo WARNING: Failed to copy tbgen.exe
copy /y ..\bin\tbgenp.exe ..\bin\rtbgenp.exe >nul 2>&1 || echo WARNING: Failed to copy tbgenp.exe
copy /y ..\bin\tbver.exe ..\bin\tbver.exe >nul 2>&1 || echo WARNING: Failed to copy tbver.exe
copy /y ..\bin\tbverp.exe ..\bin\tbverp.exe >nul 2>&1 || echo WARNING: Failed to copy tbverp.exe

cd ..

:end
echo.
echo ========================================
echo Build Summary
echo ========================================
if exist bin\rtbgen.exe (
    echo [OK] rtbgen.exe
) else (
    echo [MISSING] rtbgen.exe
)
if exist bin\rtbgenp.exe (
    echo [OK] rtbgenp.exe
) else (
    echo [MISSING] rtbgenp.exe
)
if exist bin\rtbver.exe (
    echo [OK] rtbver.exe
) else (
    echo [MISSING] rtbver.exe
)
if exist bin\rtbverp.exe (
    echo [OK] rtbverp.exe
) else (
    echo [MISSING] rtbverp.exe
)
echo.
pause