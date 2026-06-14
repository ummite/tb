@echo off
REM =============================================================================
REM tb-1 Tablebase Generator - All Combinations
REM =============================================================================
REM Generates all 3-5 piece tablebase combinations systematically
REM
REM Requirements:
REM   - RTBPATH environment variable must be set
REM   - Executables (rtbgen.exe, rtbgenp.exe) in current directory
REM =============================================================================

cd /d C:\Programmation\tb-1\bin

REM Check for required executables
if not exist "rtbgen.exe" (
    echo ERROR: rtbgen.exe not found in bin/
    echo Please build the project first: build.bat
    exit /b 1
)

if not exist "rtbgenp.exe" (
    echo ERROR: rtbgenp.exe not found in bin/
    echo Please build the project first: build.bat
    exit /b 1
)

REM Check RTBPATH (required for generation)
if "%RTBPATH%"=="" (
    echo WARNING: RTBPATH not set.
    echo Setting default: C:\Programmation\tb-1\src
    set RTBPATH=C:\Programmation\tb-1\src
)

echo ==========================================
echo Tablebase Generator - All Combinations
echo ==========================================
echo RTBPATH: %RTBPATH%
echo.

REM Counter
set /a PASS=0
set /a SKIP=0
set /a FAIL=0

REM Function to generate combinations
call :generate_pieces 3 0
call :generate_pieces 3 1
call :generate_pieces 4 0
call :generate_pieces 4 1
call :generate_pieces 5 0

echo.
echo ==========================================
echo Generation Complete!
echo Passed: %PASS%, Skipped: %SKIP%, Failed: %FAIL%
echo ==========================================
goto :eof

REM Generate all combinations for N pieces
REM Usage: call :generate_pieces number_of_pieces use_pawns
:generate_pieces
set N=%1
set PAWN=%2

echo Generating %N% pieces (pawns: %PAWN%)...
echo.

if %N% EQU 3 (
    if %PAWN% EQU 0 (
        REM 3-piece pawnless: 2 pieces + King vs King
        echo 3-piece pawnless...
        call :gen_3p KQvK
        call :gen_3p KRvK
        call :gen_3p KNvK
        call :gen_3p KBvK
    ) else (
        REM 3-piece with pawns: 1 piece + 1 pawn + King vs King
        echo 3-piece with pawns...
        call :gen_3p_pawn KPvK
        call :gen_3p_pawn KAPvK
        call :gen_3p_pawn KRPvK
        call :gen_3p_pawn KNPvK
        call :gen_3p_pawn KBPvK
        call :gen_3p_pawn KQPvK
    )
)

if %N% EQU 4 (
    if %PAWN% EQU 0 (
        REM 4-piece pawnless: 3 pieces + King vs King
        echo 4-piece pawnless...
        call :gen_4p KQQvK
        call :gen_4p KQNvK
        call :gen_4p KQBvK
        call :gen_4p KQRvK
        call :gen_4p KRRvK
        call :gen_4p KRNvK
        call :gen_4p KRBvK
        call :gen_4p KNNvK
        call :gen_4p KBNvK
        call :gen_4p KBBvK
    ) else (
        REM 4-piece with pawns: 2 pieces + 1 pawn + King vs King
        echo 4-piece with pawns...
        call :gen_4p_pawn KAPvK
        call :gen_4p_pawn KRPvK
        call :gen_4p_pawn KNPvK
        call :gen_4p_pawn KBPvK
        call :gen_4p_pawn QPvK
        call :gen_4p_pawn RPvK
        call :gen_4p_pawn NPvK
        call :gen_4p_pawn BPvK
        call :gen_4p_pawn KAPPvK
        call :gen_4p_pawn KARPvK
        call :gen_4p_pawn KANPvK
        call :gen_4p_pawn KABPvK
        call :gen_4p_pawn KQPPvK
        call :gen_4p_pawn KQRPvK
        call :gen_4p_pawn KQNPvK
        call :gen_4p_pawn KQBPvK
    )
)

if %N% EQU 5 (
    if %PAWN% EQU 0 (
        REM 5-piece pawnless: 4 pieces + King vs King
        echo 5-piece pawnless...
        call :gen_5p KQQQvK
        call :gen_5p KQQNvK
        call :gen_5p KQQBvK
        call :gen_5p KQQRvK
        call :gen_5p KQRRvK
        call :gen_5p KQNNvK
        call :gen_5p KQNBvK
        call :gen_5p KQBBvK
        call :gen_5p KQNNvK
        call :gen_5p KQBNvK
        call :gen_5p KQBBvK
        call :gen_5p KRRNvK
        call :gen_5p KRRBvK
        call :gen_5p KRNvK
        call :gen_5p KNNvK
        call :gen_5p KBBvK
    ) else (
        REM 5-piece with pawns: 3 pieces + 1 pawn + King vs King
        echo 5-piece with pawns...
        call :gen_5p_pawn KQPPvK
        call :gen_5p_pawn KQRPvK
        call :gen_5p_pawn KQNPvK
        call :gen_5p_pawn KQBPvK
        call :gen_5p_pawn KRRPvK
        call :gen_5p_pawn KRRBPvK
    )
)

goto :eof

REM Helper to run rtbgen
:gen_3p
echo   %1...
rtbgen.exe %1 >nul 2>&1
goto :eof

:gen_4p
echo   %1...
rtbgen.exe %1 >nul 2>&1
goto :eof

:gen_5p
echo   %1...
rtbgen.exe %1 >nul 2>&1
goto :eof

REM Helper to run rtbgenp (with pawns)
:gen_3p_pawn
echo   %1...
rtbgenp.exe %1 >nul 2>&1
goto :eof

:gen_4p_pawn
echo   %1...
rtbgenp.exe %1 >nul 2>&1
goto :eof

:gen_5p_pawn
echo   %1...
rtbgenp.exe %1 >nul 2>&1
goto :eof