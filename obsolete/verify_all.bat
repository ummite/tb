@echo off
REM =============================================================================
REM tb-1 Tablebase Verification Script
REM =============================================================================
REM Verifies all generated tablebases using tbcheck
REM =============================================================================

cd /d C:\Programmation\tb-1

set PASS=0
set FAIL=0
set TOTAL=0

echo ==========================================
echo Tablebase Verification
echo ==========================================
echo.

REM Verify all WDL files
echo Checking WDL files...
for %%f in (src\*.rtbw) do (
    set /a TOTAL+=1
    bin\tbcheck "%%f" >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        set /a PASS+=1
    ) else (
        set /a FAIL+=1
        echo   FAIL: %%f
    )
)

echo.
echo Checking DTZ files...
for %%f in (src\*.rtbz) do (
    set /a TOTAL+=1
    bin\tbcheck "%%f" >nul 2>&1
    if !ERRORLEVEL! EQU 0 (
        set /a PASS+=1
    ) else (
        set /a FAIL+=1
        echo   FAIL: %%f
    )
)

echo.
echo ==========================================
echo Summary: %PASS% passed, %FAIL% failed out of %TOTAL% files
echo ==========================================

if !FAIL! EQU 0 (
    echo.
    echo All tablebases verified successfully!
    exit /b 0
) else (
    echo.
    echo Some tablebases failed verification.
    exit /b 1
)