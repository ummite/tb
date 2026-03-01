@echo off
REM =============================================================================
REM tb-1 Tablebase Status Script
REM =============================================================================
REM Shows generation progress for all expected tablebase combinations
REM =============================================================================

cd /d C:\Programmation\tb-1\src

set TOTAL=0
set GENERATED=0
set MISSING=0

echo ==========================================
echo Tablebase Generation Status
echo ==========================================
echo.

REM Expected combinations - 3 piece pawnless
echo 3-piece pawnless (K?vK):
for %%f in (KQvK KRvK KNvK KBvK) do (
    set /a TOTAL+=1
    if exist "%%f.rtbw" (
        set /a GENERATED+=1
    ) else (
        set /a MISSING+=1
        echo   MISSING: %%f.rtbw
    )
)

REM Expected combinations - 4 piece pawnless
echo 4-piece pawnless (K??vK):
for %%f in (KQQvK KQNvK KQBvK KQRvK KRRvK KRNvK KRBvK KNNvK KBNvK KBBvK) do (
    set /a TOTAL+=1
    if exist "%%f.rtbw" (
        set /a GENERATED+=1
    ) else (
        set /a MISSING+=1
        echo   MISSING: %%f.rtbw
    )
)

REM Expected combinations - 5 piece pawnless
echo 5-piece pawnless (K???vK):
for %%f in (KQQQvK KQQNvK KQQBvK KQQRvK KQRRvK KQNNvK KQNBvK KQBBvK KRRNvK KRRBvK KQRNvK KRNvK KNNvK KBBvK KBBNvK KBBBvK KBNvK KNNNvK) do (
    set /a TOTAL+=1
    if exist "%%f.rtbw" (
        set /a GENERATED+=1
    ) else (
        set /a MISSING+=1
        echo   MISSING: %%f.rtbw
    )
)

REM Pawnful combinations (sample)
echo Pawnful combinations (K?PvK, K??PvK, etc.):
for %%f in (KPvK KRPvK KNPvK KBPvK KQPvK KAPPvK KARPvK KANPvK KABPvK KQPPvK KQRPvK KQNPvK KQBPvK) do (
    set /a TOTAL+=1
    if exist "%%f.rtbw" (
        set /a GENERATED+=1
    ) else (
        set /a MISSING+=1
        echo   MISSING: %%f.rtbw
    )
)

echo.
echo ==========================================
echo Status: %GENERATED%/%TOTAL% generated (%MISSING% missing)
echo ==========================================

if !MISSING! EQU 0 (
    echo.
    echo All expected tablebases are present!
) else (
    echo.
    echo To generate missing tablebases, set RTBPATH and run:
    echo   cd src
    echo   rtbgen <combo>
)