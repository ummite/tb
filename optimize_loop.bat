@echo off
REM Ralph Loop - Automated Code Optimization for Chess Tablebase Generator
REM Windows batch version

cd /d C:\Programmation\tb-1\src

set LOG_FILE=optimize_log.txt
set MAX_ITERATIONS=50
set ITERATION=0

echo ==========================================
echo Ralph Loop - Automated Code Optimization
echo ==========================================
echo Source: C:\Programmation\tb-1\src
echo Max iterations: %MAX_ITERATIONS%
echo ==========================================
echo.

:loop
set /a ITERATION+=1
echo ==========================================
echo Iteration %ITERATION%
echo ==========================================

REM Compile and capture output
make clean >nul 2>&1
make all 2>&1 | tee %LOG_FILE%

REM Check for warnings
findstr /c:"warning:" %LOG_FILE% >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Found warning(s)
    findstr /c:"warning:" %LOG_FILE% | findstr /n "^" | more

    echo.
    echo Press Ctrl+C to stop, or wait for next iteration...
    echo.
    timeout /t 2 /nobreak >nul
    goto loop
) else (
    echo No warnings found!
    echo.
    echo ==========================================
    echo Optimization complete - no warnings!
    echo ==========================================
    echo.
    echo Generated binaries:
    dir ..\bin\*.exe
    exit /b 0
)