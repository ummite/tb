@echo off
echo Building chess tablebase generator...
mkdir bin

REM Try to compile with explicit headers
echo Compiling rtbgen.c...
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -DREGULAR -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -I. -I.. -c rtbgen.c -o rtbgen.o

if %errorlevel% equ 0 (
    echo rtbgen.o compiled successfully
) else (
    echo Failed to compile rtbgen.c
    exit /b 1
)

echo Compiling other components...
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -DREGULAR -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -I. -I.. -c tbgen.c -o tbgen.o
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -DREGULAR -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -I. -I.. -c permute.c -o permute.o
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -DREGULAR -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -I. -I.. -c compress.c -o compress.o
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -DREGULAR -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -I. -I.. -c huffman.c -o huffman.o
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -DREGULAR -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -I. -I.. -c threads.c -o threads.o
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -DREGULAR -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -I. -I.. -c lz4.c -o lz4.o
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -DREGULAR -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -I. -I.. -c checksum.c -o checksum.o
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -DREGULAR -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -I. -I.. -c city-c.c -o city-c.o
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -DREGULAR -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -I. -I.. -c util.c -o util.o

echo Linking rtbgen.exe...
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -DREGULAR -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -I. -I.. -o rtbgen.exe rtbgen.o tbgen.o permute.o compress.o huffman.o threads.o lz4.o checksum.o city-c.o util.o

if %errorlevel% equ 0 (
    echo rtbgen.exe built successfully
) else (
    echo Failed to build rtbgen.exe
    exit /b 1
)

echo Build completed successfully!