@echo off
echo ========================================
echo Generating ALL 4-piece tablebases (pawnless)
echo ========================================
echo.
echo Format: K<2 pieces> vs K<1 piece> OR K<1 piece> vs K<2 pieces>
echo Total: 20 combinations (10 + 10)
echo.

cd /d "%~dp0"

echo Generating 4-piece tablebases...
echo.

REM White has 2 pieces, Black has 1 piece
echo White: 2 pieces vs Black: 1 piece
../bin/tbgen KQQvK 2>&1
../bin/tbgen KQRvK 2>&1
../bin/tbgen KQBvK 2>&1
../bin/tbgen KQNvK 2>&1
../bin/tbgen KRRvK 2>&1
../bin/tbgen KRBvK 2>&1
../bin/tbgen KRNvK 2>&1
../bin/tbgen KBBvK 2>&1
../bin/tbgen KBNvK 2>&1
../bin/tbgen KNNvK 2>&1

echo.
echo White: 1 piece vs Black: 2 pieces
../bin/tbgen KvKQQ 2>&1
../bin/tbgen KvKQR 2>&1
../bin/tbgen KvKQB 2>&1
../bin/tbgen KvKQN 2>&1
../bin/tbgen KvKRR 2>&1
../bin/tbgen KvKRB 2>&1
../bin/tbgen KvKRN 2>&1
../bin/tbgen KvKBB 2>&1
../bin/tbgen KvKBN 2>&1
../bin/tbgen KvKNN 2>&1

echo.
echo 4-piece generation complete!
echo Generated tablebases:
dir /b *.rtbw | find /c "."
pause