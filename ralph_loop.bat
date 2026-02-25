@echo off
REM Ralph Loop - Fully Automated Code Optimization (Windows Version)
REM Continuously compiles, analyzes warnings, fixes one issue, and repeats

cd /d C:\Programmation\tb-1\src

set LOG_FILE=optimize_log.txt
set MAX_ITERATIONS=100
set ITERATION=0

echo ==========================================
echo Ralph Loop - Fully Automated Optimization
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

REM Compile
echo Compiling...
make clean >nul 2>&1 || true
make all 2>&1 | tee %LOG_FILE% >nul

REM Check for warnings
findstr /c:"warning:" %LOG_FILE% > temp_warnings.txt 2>&1
set /a WARNING_COUNT=0
for /l %%i in (1,1,100) do (
    for /f %%w in ('findstr /c:"warning:" %LOG_FILE%') do (
        set /a WARNING_COUNT+=1
    )
)

REM Count warnings properly
set WARNING_COUNT=0
for /f %%a in ('findstr /c:"warning:" %LOG_FILE% 2^>nul') do set /a WARNING_COUNT+=1

if %WARNING_COUNT% EQU 0 (
    echo.
    echo ==========================================
    echo Compilation clean - no warnings!
    echo ==========================================
    echo.
    echo Generated binaries:
    dir ..\bin\*.exe
    exit /b 0
)

echo Found %WARNING_COUNT% warning(s)

REM Get first warning
for /f "tokens=1,2 delims=:" %%a in ('findstr /c:"warning:" %LOG_FILE% | findstr /n "^" | head -1') do (
    set FIRST_LINE=%%a:%%b
)

echo First warning: %FIRST_LINE%

REM Apply simple fixes
REM Check for shift warning
findstr /c:"left shift count" %LOG_FILE% >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Fixing shift warning...
    PowerShell -Command "(Get-Content util.c) -replace '\(\(size_t\)sizeHigh', '(((uint64_t)sizeHigh' | Set-Content util.c"
)

REM Check for max macro warning
findstr /c:"redefined" %LOG_FILE% >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Fixing macro redefined warning...
    PowerShell -Command "(Get-Content compress.c) -replace '#define max\(a,b\)', 'static inline int max_int(int a, int b) { return a > b ? a : b; }' -replace '\bmax\(', 'max_int(' | Set-Content compress.c"
)

echo.
echo Waiting 2 seconds before next iteration...
echo.
timeout /t 2 /nobreak >nul
goto loop