@echo off
echo ========================================
echo Generating ALL 3 and 4 piece PAWNFUL tablebases
echo ========================================
echo.
echo Format: K<blanc>pions_vK<noir>pions
echo.

cd /d "%~dp0"

echo Generating 3-piece pawnful tablebases...
echo.

REM White 1 pawn, Black 0 pawns
echo White: 1 pawn
../bin/tbgenp KPvK 2>&1

REM White 0 pawns, Black 1 pawn
echo Black: 1 pawn
../bin/tbgenp KvKP 2>&1

echo.
echo Generating 4-piece pawnful tablebases...
echo.

REM White 2 pawns, Black 0 pawns
echo White: 2 pawns
../bin/tbgenp KPPvK 2>&1

REM White 1 pawn, Black 1 pawn
echo White: 1 pawn, Black: 1 pawn
../bin/tbgenp KPvKP 2>&1

REM White 0 pawns, Black 2 pawns
echo Black: 2 pawns
../bin/tbgenp KvKPP 2>&1

echo.
echo Pawnful generation complete!
echo Generated tablebases:
dir /b *.rtbw | find /c "."
pause