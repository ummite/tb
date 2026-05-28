@echo off
setlocal EnableDelayedExpansion

REM ============================================================
REM  Generate_Syzygy.bat
REM  Generate Syzygy tablebases (with and without pawns)
REM
REM  Options (default value in parentheses):
REM    --threads N       Number of CPU threads       (auto-detect)
REM    --max N           Max piece count              (5)
REM    --min N           Min piece count              (3)
REM    --wdl-only        Generate only WDL files      (off)
REM    --dtz-only        Generate only DTZ files      (off)
REM    --stats           Save generation statistics   (on)
REM    --no-stats        Disable statistics           (off)
REM    --disk            Reduce RAM usage (-d flag)   (off)
REM    --ply-accurate    Ply-accurate DTZ (-p flag)   (on)
REM    --no-ply-accurate Disable ply-accurate DTZ     (off)
REM    --verify          Verify after generation      (off)
REM    --force           Regenerate even if exists    (off)
REM    --dry-run         Show plan only, do not run   (off)
REM    --help            Show this help message
REM ============================================================

REM --- Defaults ---
set "THREADS="
set "MAX_PIECES=5"
set "MIN_PIECES=3"
set "WDL_ONLY=off"
set "DTZ_ONLY=off"
set "STATS=on"
set "DISK=off"
set "PLY_ACCURATE=on"
set "VERIFY=off"
set "FORCE=off"
set "DRY_RUN=off"

REM --- Parse arguments ---
:argloop
if "%~1"=="" goto argsdone
if /i "%~1"=="--help" goto showhelp
if /i "%~1"=="--threads" set "THREADS=%~2" & shift & shift & goto argloop
if /i "%~1"=="--max" set "MAX_PIECES=%~2" & shift & shift & goto argloop
if /i "%~1"=="--min" set "MIN_PIECES=%~2" & shift & shift & goto argloop
if /i "%~1"=="--wdl-only" set "WDL_ONLY=on" & shift & goto argloop
if /i "%~1"=="--dtz-only" set "DTZ_ONLY=on" & shift & goto argloop
if /i "%~1"=="--stats" set "STATS=on" & shift & goto argloop
if /i "%~1"=="--no-stats" set "STATS=off" & shift & goto argloop
if /i "%~1"=="--disk" set "DISK=on" & shift & goto argloop
if /i "%~1"=="--ply-accurate" set "PLY_ACCURATE=on" & shift & goto argloop
if /i "%~1"=="--no-ply-accurate" set "PLY_ACCURATE=off" & shift & goto argloop
if /i "%~1"=="--verify" set "VERIFY=on" & shift & goto argloop
if /i "%~1"=="--force" set "FORCE=on" & shift & goto argloop
if /i "%~1"=="--dry-run" set "DRY_RUN=on" & shift & goto argloop
echo Unknown option: %~1
shift
goto argloop
:argsdone

REM --- Auto-detect threads if not set ---
if "%THREADS%"=="" set "THREADS=%NUMBER_OF_PROCESSORS%"

REM --- Build generator extra flags ---
set "EXTRA_FLAGS="
if "%PLY_ACCURATE%"=="on" set "EXTRA_FLAGS=-p"
if "%STATS%"=="on" (
    if "%EXTRA_FLAGS%"=="" (
        set "EXTRA_FLAGS=--stats"
    ) else (
        set "EXTRA_FLAGS=%EXTRA_FLAGS% --stats"
    )
)
if "%WDL_ONLY%"=="on" (
    if "%EXTRA_FLAGS%"=="" (
        set "EXTRA_FLAGS=--wdl"
    ) else (
        set "EXTRA_FLAGS=%EXTRA_FLAGS% --wdl"
    )
)
if "%DTZ_ONLY%"=="on" (
    if "%EXTRA_FLAGS%"=="" (
        set "EXTRA_FLAGS=--dtz"
    ) else (
        set "EXTRA_FLAGS=%EXTRA_FLAGS% --dtz"
    )
)

REM ============================================================
REM  DISPLAY OPTIONS
REM ============================================================
echo.
echo ================================================================
echo   Syzygy Tablebase Generator
echo ================================================================
echo.
echo   Threads          : %THREADS%
echo   Piece range      : %MIN_PIECES% to %MAX_PIECES%
echo   WDL only         : %WDL_ONLY%
echo   DTZ only         : %DTZ_ONLY%
echo   Statistics       : %STATS%
echo   Disk mode (-d)   : %DISK%
echo   Ply-accurate DTZ : %PLY_ACCURATE%
echo   Verify after     : %VERIFY%
echo   Force regenerate : %FORCE%
echo   Dry run          : %DRY_RUN%
echo.
echo   RTBPATH          : %RTBPATH%
echo   RTBSTATSDIR      : %RTBSTATSDIR% (empty = .)
echo.
echo   Generator (no pawns) : %~dp0bin\rtbgen.exe
echo   Generator (pawns)    : %~dp0bin\rtbgenp.exe
echo   Verifier (no pawns)  : %~dp0bin\rtbver.exe
echo   Verifier (pawns)     : %~dp0bin\rtbverp.exe
echo.
echo   Extra flags    : %EXTRA_FLAGS%
echo ================================================================
echo.

REM --- Verify executables exist ---
if not exist "%~dp0bin\rtbgen.exe" (
    echo ERROR: rtbgen.exe not found in bin\
    echo Run build.bat first.
    pause
    exit /b 1
)
if not exist "%~dp0bin\rtbgenp.exe" (
    echo ERROR: rtbgenp.exe not found in bin\
    echo Run build.bat first.
    pause
    exit /b 1
)

REM --- Verify RTBPATH ---
if "%RTBPATH%"=="" (
    echo WARNING: RTBPATH is not set.
    echo Sub-tablebases are required for generation.
    echo Set RTBPATH to the directory containing smaller tablebases.
    echo.
    echo Example: set RTBPATH=C:\tablebases
    echo.
    pause
    exit /b 1
)

REM --- Dry run? ---
if "%DRY_RUN%"=="on" (
    echo [DRY RUN] No generation performed.
    echo.
    pause
    exit /b 0
)

REM --- Add bin\ to PATH so generators find each other ---
set "PATH=%~dp0bin;%PATH%"

REM ============================================================
REM  ENUMERATE AND GENERATE TABLEBASES
REM ============================================================
REM Piece types: Q R B N P
REM We generate all combinations for each piece count.
REM Format: K{attacker_pieces}vK{defender_pieces}
REM Total pieces = 2 (kings) + attacker + defender

set "ERRORS=0"
set "GENERATED=0"

REM --- Helper: generate a single tablebase ---
REM Usage: call :gen {name} {has_pawn}
REM We inline the logic below for each piece count

echo ================================================================
echo  Starting generation
echo ================================================================
echo.

REM ============================================================
REM  3 PIECES (KvK only - trivial, usually already exists)
REM ============================================================
if %MIN_PIECES% LEQ 3 (
    call :gen_table "KvK" 0
)

REM ============================================================
REM  4 PIECES (1 attacker, 0 defender - no pawns)
REM ============================================================
if %MIN_PIECES% LEQ 4 (
    call :gen_table "KQvK" 0
    call :gen_table "KRvK" 0
    call :gen_table "KBvK" 0
    call :gen_table "KNvK" 0
)

REM ============================================================
REM  5 PIECES
REM    2 attackers vs 0 defenders (no pawns)
REM    1 attacker vs 1 defender (no pawns)
REM ============================================================
if %MIN_PIECES% LEQ 5 (
    REM 2 attackers, 0 defenders (no pawns)
    call :gen_table "KQQvK" 0
    call :gen_table "KQRvK" 0
    call :gen_table "KQBvK" 0
    call :gen_table "KQNvK" 0
    call :gen_table "KRRvK" 0
    call :gen_table "KRBvK" 0
    call :gen_table "KRNvK" 0
    call :gen_table "KBBvK" 0
    call :gen_table "KBNvK" 0
    call :gen_table "KNNvK" 0

    REM 1 attacker, 1 defender (no pawns)
    call :gen_table "KQvKR" 0
    call :gen_table "KQvKB" 0
    call :gen_table "KQvKN" 0
    call :gen_table "KRvKB" 0
    call :gen_table "KRvKN" 0
    call :gen_table "KBvKN" 0

    REM 1 attacker, 1 defender (with pawns)
    call :gen_table "KQvKP" 1
    call :gen_table "KRvKP" 1
    call :gen_table "KBvKP" 1
    call :gen_table "KNvKP" 1

    REM 2 attackers, 0 defenders (with pawns)
    call :gen_table "KQPvK" 1
    call :gen_table "KRPvK" 1
    call :gen_table "KBPvK" 1
    call :gen_table "KNPvK" 1
    call :gen_table "KPPvK" 1
)

REM ============================================================
REM  VERIFY (optional)
REM ============================================================
if "%VERIFY%"=="on" (
    echo.
    echo ================================================================
    echo  Phase 3: Verification
    echo ================================================================
    echo.
    call :verify_range %MIN_PIECES% %MAX_PIECES%
)

REM ============================================================
REM  SUMMARY
REM ================================================================
echo.
echo ================================================================
echo  Generation complete
echo ================================================================
echo.
echo  Generated : %GENERATED% tablebases
echo  Errors    : %ERRORS%
echo.
if %ERRORS% equ 0 (
    echo  All tablebases generated successfully.
) else (
    echo  Some tablebases failed. Check the output above.
)
echo.
pause
exit /b 0

REM ============================================================
REM  SUBROUTINES
REM ============================================================

:gen_table
REM Args: %1=table name, %2=has_pawn (0=no, 1=yes)
set "TBNAME=%~1"
set "HASPAWN=%~2"

REM Check if already exists (skip unless --force)
if "%FORCE%"=="off" (
    if exist "%TBNAME%.rtbz" (
        echo  [SKIP] %TBNAME% (already exists)
        goto :eof
    )
)

REM Select generator
if "%HASPAWN%"=="0" (
    set "GEN=rtbgen"
) else (
    set "GEN=rtbgenp"
)

REM Build command
set "CMD=%~dp0bin\%GEN%.exe -t %THREADS% %EXTRA_FLAGS%"
if "%DISK%"=="on" set "CMD=%CMD% -d"
set "CMD=%CMD% %TBNAME%"

echo  [GEN] %TBNAME% (%GEN%)
echo        %CMD%
"%CMD%"
if errorlevel 1 (
    echo  [ERROR] Failed: %TBNAME%
    set /a ERRORS+=1
) else (
    set /a GENERATED+=1
)
goto :eof

:verify_range
REM Verify all tablebases in the given piece range
echo  Running verification for %1 to %2 pieces...
REM We use tbcheck for quick checksum verification
for %%F in (*.rtbw *.rtbz) do (
    echo  [CHECK] %%F
    "%~dp0bin\tbcheck.exe" "%%F"
)
goto :eof

:showhelp
echo.
echo Generate_Syzygy.bat - Generate Syzygy tablebases
echo.
echo Usage: Generate_Syzygy.bat [OPTIONS]
echo.
echo Options:
echo   --threads N       Number of CPU threads       (default: auto-detect)
echo   --max N           Max piece count              (default: 5)
echo   --min N           Min piece count              (default: 3)
echo   --wdl-only        Generate only WDL files      (default: off)
echo   --dtz-only        Generate only DTZ files      (default: off)
echo   --stats           Save generation statistics   (default: on)
echo   --no-stats        Disable statistics
echo   --disk            Reduce RAM usage (-d flag)   (default: off)
echo   --ply-accurate    Ply-accurate DTZ (-p flag)   (default: on)
echo   --no-ply-accurate Disable ply-accurate DTZ
echo   --verify          Verify after generation      (default: off)
echo   --force           Regenerate even if exists    (default: off)
echo   --dry-run         Show plan only, do not run   (default: off)
echo   --help            Show this help message
echo.
echo Environment variables:
echo   RTBPATH           Sub-tablebase directory (required)
echo   RTBSTATSDIR       Statistics output directory (default: .)
echo.
echo Examples:
echo   Generate_Syzygy.bat                          Generate 3-5 pieces, all defaults
echo   Generate_Syzygy.bat --threads 16 --max 6     Generate up to 6 pieces, 16 threads
echo   Generate_Syzygy.bat --dry-run                Show what would be done
echo   Generate_Syzygy.bat --wdl-only --no-stats    WDL only, no stats
echo.
pause
exit /b 0
