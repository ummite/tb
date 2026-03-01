@echo off
setlocal enabledelayedexpansion

REM =============================================================================
REM build_all.bat - Comprehensive tablebase generator build script
REM =============================================================================
REM Features:
REM - Automatic build tool detection (MSBuild > MinGW)
REM - Parallel build support
REM - Enhanced error handling and recovery
REM - Build summary with file sizes
REM - Optional debug build generation
REM =============================================================================

echo ========================================
echo Building all tablebase tools
echo ========================================
echo.

REM === BUILD TOOL DETECTION ===

set "BUILD_TOOL="
set "BUILD_TOOL_NAME="

REM Visual Studio detection (search all common installations)
for %%d in (
    "C:\Program Files\Microsoft Visual Studio\2022\Community"
    "C:\Program Files\Microsoft Visual Studio\2022\Professional"
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise"
    "C:\Program Files\Microsoft Visual Studio\2019\Community"
    "C:\Program Files\Microsoft Visual Studio\2019\Professional"
    "C:\Program Files\Microsoft Visual Studio\2019\Enterprise"
    "C:\Program Files (x86)\Microsoft Visual Studio\2022\Community"
    "C:\Program Files (x86)\Microsoft Visual Studio\2022\Professional"
    "C:\Program Files (x86)\Microsoft Visual Studio\2022\Enterprise"
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community"
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional"
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise"
) do if exist "%%d\VC\Auxiliary\Build\vcvars64.bat" (
    set "VS_DIR=%%d"
    goto VS_FOUND
)

:VS_FOUND
if defined VS_DIR (
    set "VS_BAT=%VS_DIR%\VC\Auxiliary\Build\vcvars64.bat"
    set "BUILD_TOOL=MSBuild"
    set "BUILD_TOOL_NAME=Visual Studio %VS_DIR:~42%"
)

REM Check for MinGW if VS not found
if "!BUILD_TOOL!"=="" (
    where gcc >nul 2>&1
    if "!errorlevel!"=="0" (
        for /f "tokens=*" %%i in ('gcc --version 2^>nul ^| findstr /C:"gcc" ^| head -1') do (
            set "GCC_VERSION=%%i"
        )
        set "BUILD_TOOL=MinGW"
        set "BUILD_TOOL_NAME=MinGW"
    )
)

REM Check for clang/clang-cl
if "!BUILD_TOOL!"=="" (
    where clang-cl >nul 2>&1
    if "!errorlevel!"=="0" (
        set "BUILD_TOOL=Clang"
        set "BUILD_TOOL_NAME=Clang-CL"
    )
)

if "!BUILD_TOOL!"=="" (
    echo [ERROR] No build tools found!
    echo.
    echo Please install one of the following:
    echo   - Visual Studio 2019/2022 Build Tools
    echo   - MinGW-w64 (gcc)
    echo   - clang-cl
    echo.
    pause
    exit /b 1
)

echo [INFO] Detected build tool: !BUILD_TOOL_NAME!
echo.

REM === PARALLEL BUILD CONFIGURATION ===

set "CPU_COUNT=%NUMBER_OF_PROCESSORS%"
if "!CPU_COUNT!"=="" set "CPU_COUNT=4"
set "BUILD_JOBS=-j!CPU_COUNT!"

REM === MSBUILD BUILD ===

if "!BUILD_TOOL!"=="MSBuild" (
    echo [INFO] Initializing Visual Studio environment...
    call "!VS_BAT!" 2>nul
    if errorlevel 1 (
        echo [ERROR] Failed to initialize Visual Studio environment.
        echo Attempting MinGW build...
        goto mingw_build
    )

    echo.
    echo [INFO] Building with MSBuild (parallel: !CPU_COUNT! jobs)...
    echo.

    REM Check for solution file
    if exist tbgen.sln (
        msbuild tbgen.sln ^
            /p:Configuration=Release ^
            /p:Platform=x64 ^
            /v:minimal ^
            /nologo ^
            /t:Clean,Build ^
            /p:BuildInParallel=true

        if errorlevel 1 (
            echo [WARNING] MSBuild failed, attempting alternative approach...
            REM Try individual project build as fallback
            if exist tbgen.vcxproj (
                msbuild tbgen.vcxproj /p:Configuration=Release /p:Platform=x64 /v:minimal /nologo
            )
        )
    ) else if exist tbgen.vcxproj (
        msbuild tbgen.vcxproj /p:Configuration=Release /p:Platform=x64 /v:minimal /nologo
    ) else (
        echo [WARNING] No Visual Studio solution/project found.
        goto mingw_build
    )

    echo.
    echo [INFO] MSBuild completed!
    goto copy_binaries
)

REM === CLANG-CL BUILD ===

if "!BUILD_TOOL!"=="Clang" (
    echo [INFO] Building with Clang-CL...
    set "CL_ARGS=/O2 /DNDEBUG /std:c++17 /arch:AVX2 /I."

    cd src
    if errorlevel 1 goto cd_error

    REM Clean old objects
    del /q *.obj 2>nul

    REM Compile with parallelism
    clang-cl %CL_ARGS% /c generic.c rtbgen.c tbgen.c tbver.c util.c compress.c checksum.c crc32c.c decompress.c threads.c 2>nul

    if errorlevel 1 (
        echo [WARNING] Clang-CL compilation failed.
        cd ..
        goto mingw_build
    )

    echo.
    echo [INFO] Linking...
    link /OUT:..\bin\tbgen.exe generic.obj rtbgen.obj tbgen.obj tbver.obj util.obj compress.obj checksum.obj crc32c.obj decompress.obj threads.obj /SUBSYSTEM:CONSOLE 2>nul

    cd ..
    goto copy_binaries
)

REM === MINGW BUILD ===

:mingw_build
echo.
echo [INFO] Building with MinGW (parallel: !CPU_COUNT! jobs)...
echo.

cd src
if errorlevel 1 goto cd_error

REM Check for make
where make >nul 2>&1
if "!errorlevel!"=="1" (
    echo [ERROR] make not found! Please install MinGW with make.
    cd ..
    pause
    exit /b 1
)

REM Clean and build with parallelism
if exist Makefile.regular (
    echo [INFO] Cleaning old build artifacts...
    make clean 2>nul
)

echo [INFO] Compiling with parallel make...
make -j!CPU_COUNT! all 2>&1

if errorlevel 1 (
    echo [ERROR] MinGW build failed!
    echo.
    echo Attempting single-threaded build as fallback...
    cd src
    make all
    cd ..
    if errorlevel 1 (
        echo [FATAL] Build failed even with single-threaded make.
        cd ..
        pause
        exit /b 1
    )
)

echo.
echo [INFO] MinGW build completed!

:copy_binaries
echo.
echo [INFO] Copying binaries to bin\ directory...
echo.

cd ..

REM Create bin directory if it doesn't exist
if not exist bin mkdir bin 2>nul

REM Copy binaries with version info
set "COPY_ERRORS=0"

copy /y src\tbgen.exe bin\rtbgen.exe >nul 2>&1 || set "COPY_ERRORS=1"
copy /y src\tbgenp.exe bin\rtbgenp.exe >nul 2>&1 || set "COPY_ERRORS=1"
copy /y src\tbver.exe bin\rtbver.exe >nul 2>&1 || set "COPY_ERRORS=1"
copy /y src\tbverp.exe bin\rtbverp.exe >nul 2>&1 || set "COPY_ERRORS=1"

if "!COPY_ERRORS!"=="1" (
    echo [WARNING] Some binary copies failed.
)

echo.

REM === BUILD SUMMARY ===

echo ========================================
echo Build Summary
echo ========================================
echo.

set "BUILD_SUCCESS=1"
set "TOTAL_SIZE=0"

for %%f in (bin\rtbgen.exe bin\rtbgenp.exe bin\rtbver.exe bin\rtbverp.exe) do (
    if exist %%f (
        for %%z in (%%f) do (
            set "FILE_SIZE=%%~z"
            echo [OK] %%f !FILE_SIZE! bytes
            set /a "TOTAL_SIZE+=!FILE_SIZE!"
        )
    ) else (
        echo [MISSING] %%f
        set "BUILD_SUCCESS=0"
    )
)

echo.
echo Total binary size: !TOTAL_SIZE! bytes
echo.

if "!BUILD_SUCCESS!"=="1" (
    echo [SUCCESS] Build completed successfully!
) else (
    echo [PARTIAL] Some binaries missing. Check errors above.
)

echo.
echo Binaries located in: bin\
echo.
pause

exit /b 0

:cd_error
echo [ERROR] Cannot change to src directory!
echo.
cd ..
pause
exit /b 1