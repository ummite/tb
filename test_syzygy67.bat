@echo off
REM =============================================================================
REM test_syzygy67.bat - Test sequence for Syzygy 6-piece and 7-piece tablebases
REM
REM Usage:
REM   test_syzygy67.bat [path\to\6-7-piece\files]
REM
REM If no path is given, looks for files in current directory + Syzygy\
REM Requires: RTBPATH set (or will default to Syzygy\)
REM =============================================================================

setlocal enabledelayedexpansion

set TEST_DIR=%~1
if "%TEST_DIR%"=="" set TEST_DIR=.

set BIN_DIR=bin
set CHECKSUM_DIR=checksums

echo.
echo ============================================
echo   Syzygy 6-Piece / 7-Piece Test Sequence
echo ============================================
echo Test directory : %TEST_DIR%
echo Binaries       : %BIN_DIR%
echo.

REM --- 1. Basic tool presence check ---
echo [1/6] Checking built tools...
if not exist "%BIN_DIR%\tbcheck.exe" (
    echo ERROR: tbcheck.exe not found. Run "build.bat verify" first.
    exit /b 1
)
if not exist "%BIN_DIR%\rtbver.exe" (
    echo WARNING: rtbver.exe not found. 6/7 verification will be limited.
)
if not exist "%BIN_DIR%\rtbverp.exe" (
    echo WARNING: rtbverp.exe not found.
)
echo   Tools present: OK

REM --- 2. RTBPATH sanity ---
echo.
echo [2/6] RTBPATH check...
if "%RTBPATH%"=="" (
    if exist "Syzygy" (
        set RTBPATH=%CD%\Syzygy
        echo   RTBPATH not set - defaulting to %RTBPATH%
    ) else (
        echo   WARNING: RTBPATH not set and no Syzygy\ dir found.
        echo   6/7 generation will fail without lower-piece subbases.
    )
) else (
    echo   RTBPATH=%RTBPATH%
)
echo   (Lower piece bases 3-5 are REQUIRED for any 6/7 generation)

REM --- 3. Report available 6/7-piece candidates in TEST_DIR ---
echo.
echo [3/6] Scanning for 6-piece and 7-piece files...
set /a COUNT6=0
set /a COUNT7=0

for %%f in ("%TEST_DIR%\*.rtbw" "%TEST_DIR%\*.rtbz") do (
    set "name=%%~nf"
    set "ext=%%~xf"
    REM Rough piece count: length of name - 1 (K...vK...)
    set "len=0"
    for /l %%i in (0,1,40) do if not "!name:~%%i,1!"=="" set /a len+=1
    set /a pieces=!len!-1

    if !pieces! GEQ 5 (
        if !pieces! EQU 5 (
            set /a COUNT6+=1
            echo   [6pc] !name!!ext!
        )
        if !pieces! GEQ 6 (
            set /a COUNT7+=1
            echo   [7pc] !name!!ext!
        )
    )
)

echo   6-piece candidates found: !COUNT6!
echo   7-piece candidates found: !COUNT7!

if !COUNT6! EQU 0 if !COUNT7! EQU 0 (
    echo.
    echo   No 6+ piece files found in %TEST_DIR%
    echo   Place your .rtbw/.rtbz files here or pass a directory as argument.
    echo   Example: test_syzygy67.bat C:\Syzygy6
)

REM --- 4. Checksum verification (tbcheck) ---
echo.
echo [4/6] Running tbcheck on 6/7-piece files...
for %%f in ("%TEST_DIR%\*.rtbw" "%TEST_DIR%\*.rtbz") do (
    set "name=%%~nf"
    set "ext=%%~xf"
    set "len=0"
    for /l %%i in (0,1,40) do if not "!name:~%%i,1!"=="" set /a len+=1
    set /a pieces=!len!-1

    if !pieces! GEQ 5 (
        echo.
        echo   Verifying %%~nxf ...
        "%BIN_DIR%\tbcheck.exe" "%%f"
        if errorlevel 1 (
            echo   *** FAILED CHECKSUM: %%~nxf ***
        ) else (
            echo   PASS: %%~nxf
        )
    )
)

REM --- 5. Logical verification with rtbver / rtbverp (if present) ---
echo.
echo [5/6] Logical verification (rtbver / rtbverp --log)...
if exist "%BIN_DIR%\rtbver.exe" (
    for %%f in ("%TEST_DIR%\*.rtbw") do (
        set "name=%%~nf"
        set "len=0"
        for /l %%i in (0,1,40) do if not "!name:~%%i,1!"=="" set /a len+=1
        set /a pieces=!len!-1

        if !pieces! GEQ 5 (
            echo.
            echo   Running rtbver on %%~nxf ...
            "%BIN_DIR%\rtbver.exe" -t 4 --log "%%~nf"
        )
    )
) else (
    echo   rtbver.exe not present - skipping full verification.
)

if exist "%BIN_DIR%\rtbverp.exe" (
    for %%f in ("%TEST_DIR%\*.rtbw") do (
        set "name=%%~nf"
        if "!name:P=!" NEQ "!name!" (
            set "len=0"
            for /l %%i in (0,1,40) do if not "!name:~%%i,1!"=="" set /a len+=1
            set /a pieces=!len!-1
            if !pieces! GEQ 5 (
                echo.
                echo   Running rtbverp on %%~nxf ^(pawnful^) ...
                "%BIN_DIR%\rtbverp.exe" -t 2 --log "%%~nf"
            )
        )
    )
)

REM --- 6. Summary + hints for generation ---
echo.
echo [6/6] Summary + Generation hints for 6/7
echo.
echo   Reference checksums live in: %CHECKSUM_DIR%\wdl6.txt, dtz6.txt, wdl7.txt, dtz7.txt
echo.
echo   To attempt a minimal 6-piece generation (USE WITH CAUTION):
echo     set RTBPATH=Syzygy
echo     %BIN_DIR%\rtbgen.exe -t 8 -d --stats KQvKQR
echo     %BIN_DIR%\rtbgenp.exe -t 4 -d --stats KRPvKRP
echo.
echo   7-piece generation is extremely heavy - only do this on servers with 512GB+ RAM
echo   or using advanced disk mode + patience.
echo.
echo   See docs\TESTING_SYZYGY_6_7.md for the full recommended sequence,
echo   hardware requirements, and probing test ideas.
echo.
echo   Engine probe (Stockfish local PGO, pas un substitut de tbcheck/rtbver) :
echo     powershell -NoProfile -File Test-Syzygy-Probe-Immediate.ps1
echo     powershell -NoProfile -File Test-Syzygy-Probe-Immediate.ps1 -Need8Piece
echo     powershell -NoProfile -File Build-Stockfish.ps1 -Enable8Piece
echo.
echo ============================================
echo   Syzygy 6/7 Test Sequence Complete
echo ============================================
echo.

endlocal
pause
