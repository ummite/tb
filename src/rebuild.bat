@echo off
echo Rebuilding all tablebase binaries...

REM Clean old binaries
del /f ..\bin\*.exe >nul 2>&1

REM Clean object files - only objsr and Makefile.pawn objects
del /f objsr\*.o >nul 2>&1
del /f tbgenp.o >nul 2>&1
del /f permute.o >nul 2>&1
del /f compress.o >nul 2>&1
del /f huffman.o >nul 2>&1
del /f threads.o >nul 2>&1
del /f lz4.o >nul 2>&1
del /f checksum.o >nul 2>&1
del /f city-c.o >nul 2>&1
del /f util.o >nul 2>&1

REM Build tbgenp with -O0 for pawnful support FIRST using Makefile.pawn
echo.
echo Building tbgenp with -O0 for pawnful support...
make -f Makefile.pawn all 2>nul

REM Rebuild regular tools only (without tbgenp)
cd src
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -flto=auto -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -DCOMPRESSION_THREADS=6 -DREGULAR -c tbgen.c -o objsr/tbgen.o 2>nul
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -flto=auto -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -DCOMPRESSION_THREADS=6 -DREGULAR -c tbver.c -o objsr/tbver.o 2>nul
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -flto=auto -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -DCOMPRESSION_THREADS=6 -DREGULAR -c tbverp.c -o objsr/tbverp.o 2>nul
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -flto=auto -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -DCOMPRESSION_THREADS=6 -DREGULAR -c tbcheck.c -o objsr/tbcheck.o 2>nul
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -flto=auto -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -DCOMPRESSION_THREADS=6 -DREGULAR -c permute.c -o objsr/permute.o 2>nul
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -flto=auto -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -DCOMPRESSION_THREADS=6 -DREGULAR -c compress.c -o objsr/compress.o 2>nul
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -flto=auto -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -DCOMPRESSION_THREADS=6 -DREGULAR -c huffman.c -o objsr/huffman.o 2>nul
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -flto=auto -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -DCOMPRESSION_THREADS=6 -DREGULAR -c threads.c -o objsr/threads.o 2>nul
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -flto=auto -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -DCOMPRESSION_THREADS=6 -DREGULAR -c lz4.c -o objsr/lz4.o 2>nul
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -flto=auto -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -DCOMPRESSION_THREADS=6 -DREGULAR -c decompress.c -o objsr/decompress.o 2>nul
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -flto=auto -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -DCOMPRESSION_THREADS=6 -DREGULAR -c checksum.c -o objsr/checksum.o 2>nul
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -flto=auto -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -DCOMPRESSION_THREADS=6 -DREGULAR -c city-c.c -o objsr/city-c.o 2>nul
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -flto=auto -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -DCOMPRESSION_THREADS=6 -DREGULAR -c util.c -o objsr/util.o 2>nul

gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -flto=auto -o ../bin/tbgen.exe objsr/tbgen.o objsr/permute.o objsr/compress.o objsr/huffman.o objsr/threads.o objsr/lz4.o objsr/checksum.o objsr/city-c.o objsr/util.o 2>nul
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -flto=auto -o ../bin/tbver.exe objsr/tbver.o objsr/decompress.o objsr/threads.o objsr/checksum.o objsr/city-c.o objsr/util.o 2>nul
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -flto=auto -o ../bin/tbverp.exe objsr/tbverp.o objsr/decompress.o objsr/threads.o objsr/checksum.o objsr/city-c.o objsr/util.o 2>nul
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -flto=auto -o tbcheck objsr/tbcheck.o objsr/threads.o objsr/checksum.o objsr/city-c.o objsr/lz4.o objsr/util.o 2>nul

copy /y ..\bin\tbgen.exe ..\bin\rtbgen.exe
copy /y ..\bin\tbver.exe ..\bin\rtbver.exe
copy /y ..\bin\tbverp.exe ..\bin\rtbverp.exe
copy /y ..\bin\tbgenp.exe ..\bin\rtbgenp.exe

cd ..

echo.
echo Build complete!
echo Binaries in ..\bin\
pause