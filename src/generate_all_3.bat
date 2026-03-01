@echo off
echo ========================================
echo Generating ALL 3-piece tablebases
echo ========================================

echo.
echo 3-piece combinations (15 total):
echo - KvKQ
echo - KvKR
echo - KvKB
echo - KvKN
echo - KVvKQ
echo - KVvKR
echo - KVvKB
echo - KVvKN
echo - KRvKQ
echo - KRvKB
echo - KRvKN
echo - KBvKQ
echo - KBvKR
echo - KBvKB
echo - KBvKN
echo.

cd /d "%~dp0"

echo Generating...
../bin/tbgen KvKQ 2>&1
../bin/tbgen KvKR 2>&1
../bin/tbgen KvKB 2>&1
../bin/tbgen KvKN 2>&1
../bin/tbgen KVvKQ 2>&1
../bin/tbgen KVvKR 2>&1
../bin/tbgen KVvKB 2>&1
../bin/tbgen KVvKN 2>&1
../bin/tbgen KRvKQ 2>&1
../bin/tbgen KRvKB 2>&1
../bin/tbgen KRvKN 2>&1
../bin/tbgen KBvKQ 2>&1
../bin/tbgen KBvKR 2>&1
../bin/tbgen KBvKB 2>&1
../bin/tbgen KBvKN 2>&1

echo.
echo 3-piece generation complete!
echo Generated tablebases:
dir /b *.rtbw | find /c "."
pause