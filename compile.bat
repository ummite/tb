@echo off
echo Building chess tablebase generator for Windows...

REM Create output directory
if not exist bin mkdir bin

echo Compiling with MinGW...
REM Try compiling a single file first to see what we get
gcc -O3 -march=native -pipe -D_GNU_SOURCE -Wall -std=c11 -DREGULAR -DMAGIC -DUSE_POPCNT -DTBPIECES=7 -I. -I.. -c rtbgen.c -o rtbgen.o

if %errorlevel% equ 0 (
    echo Successfully compiled rtbgen.o
) else (
    echo Failed to compile rtbgen.o
    echo This is likely due to missing standard headers or other dependencies.
    echo The project requires proper C standard headers for uint8_t, uint64_t, etc.
    echo You may need to install a complete MinGW distribution with all headers.
    exit /b 1
)

echo Compilation completed successfully.