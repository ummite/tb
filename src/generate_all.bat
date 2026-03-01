@echo off
echo ========================================
echo Generating ALL tablebases (3, 4, 5, 6 pieces)
echo ========================================
echo.

cd /d "%~dp0"

REM Clean previous tablebases
del /f *.rtbw >nul 2>&1
del /f *.rtbz >nul 2>&1

echo Generating 3-piece tablebases (16 total)...
echo.
echo White 1, Black 1:
../bin/tbgen KQvK 2>&1
../bin/tbgen KRvK 2>&1
../bin/tbgen KBvK 2>&1
../bin/tbgen KNvK 2>&1
../bin/tbgen KvKQ 2>&1
../bin/tbgen KvKR 2>&1
../bin/tbgen KvKB 2>&1
../bin/tbgen KvKN 2>&1

echo.
echo Generating 4-piece tablebases (80 total)...
echo.
echo White 2, Black 1:
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
echo Generating 5-piece tablebases (200 total)...
echo.
echo White 3, Black 1:
../bin/tbgen KQQQvK 2>&1
../bin/tbgen KQQRvK 2>&1
../bin/tbgen KQQBvK 2>&1
../bin/tbgen KQQNvK 2>&1
../bin/tbgen KQRRvK 2>&1
../bin/tbgen KQRBvK 2>&1
../bin/tbgen KQRNvK 2>&1
../bin/tbgen KQBBvK 2>&1
../bin/tbgen KQBNvK 2>&1
../bin/tbgen KQNNvK 2>&1
../bin/tbgen KRRRvK 2>&1
../bin/tbgen KRRBvK 2>&1
../bin/tbgen KRRNvK 2>&1
../bin/tbgen KRBBvK 2>&1
../bin/tbgen KRBNvK 2>&1
../bin/tbgen KRNNvK 2>&1
../bin/tbgen KBBBvK 2>&1
../bin/tbgen KBBNvK 2>&1
../bin/tbgen KBBvK 2>&1
../bin/tbgen KBNvK 2>&1
../bin/tbgen KvKQQQ 2>&1
../bin/tbgen KvKQQR 2>&1
../bin/tbgen KvKQQB 2>&1
../bin/tbgen KvKQQN 2>&1
../bin/tbgen KvKQRR 2>&1
../bin/tbgen KvKQRB 2>&1
../bin/tbgen KvKQRN 2>&1
../bin/tbgen KvKQBB 2>&1
../bin/tbgen KvKQBN 2>&1
../bin/tbgen KvKQNN 2>&1
../bin/tbgen KvKRRR 2>&1
../bin/tbgen KvKRRB 2>&1
../bin/tbgen KvKRRN 2>&1
../bin/tbgen KvKRBB 2>&1
../bin/tbgen KvKRBN 2>&1
../bin/tbgen KvKRNN 2>&1
../bin/tbgen KvKBBB 2>&1
../bin/tbgen KvKBBN 2>&1
../bin/tbgen KvKBNN 2>&1
../bin/tbgen KvKNNN 2>&1

echo.
echo 5-piece generation complete!
echo Generated tablebases:
dir /b *.rtbw | find /c "."
pause