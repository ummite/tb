@echo off
set PATH=C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Tools\MSVC\14.50.35717\bin\Hostx64\x64;%PATH%
set VCINSTALLDIR=C:\Program Files\Microsoft Visual Studio\18\Insiders\VC

echo Building tbgen.exe with VS2026...
cl /O2 /DNDEBUG /DMAGIC /DUSE_POPCNT /DTBPIECES=7 /DCOMPRESSION_THREADS=6 /DREGULAR /I. /Fe:tbgen.exe tbgen.c permute.c compress.c huffman.c threads.c lz4.c checksum.c city-c.c util.c

if %errorlevel% equ 0 (
    echo tbgen.exe built successfully!
) else (
    echo tbgen.exe build failed!
)

echo Building tbgenp.exe with VS2026...
cl /O2 /DNDEBUG /DMAGIC /DUSE_POPCNT /DTBPIECES=7 /DCOMPRESSION_THREADS=6 /DREGULAR /DHAS_PAWNS /I. /Fe:tbgenp.exe tbgenp.c permute.c compress.c huffman.c threads.c lz4.c checksum.c city-c.c util.c

if %errorlevel% equ 0 (
    echo tbgenp.exe built successfully!
) else (
    echo tbgenp.exe build failed!
)

echo Building tbver.exe with VS2026...
cl /O2 /DNDEBUG /DMAGIC /DUSE_POPCNT /DTBPIECES=7 /DCOMPRESSION_THREADS=6 /DREGULAR /I. /Fe:tbver.exe tbver.c decompress.c threads.c checksum.c city-c.c util.c

if %errorlevel% equ 0 (
    echo tbver.exe built successfully!
) else (
    echo tbver.exe build failed!
)

echo Building tbverp.exe with VS2026...
cl /O2 /DNDEBUG /DMAGIC /DUSE_POPCNT /DTBPIECES=7 /DCOMPRESSION_THREADS=6 /DREGULAR /DHAS_PAWNS /I. /Fe:tbverp.exe tbverp.c decompress.c threads.c checksum.c city-c.c util.c

if %errorlevel% equ 0 (
    echo tbverp.exe built successfully!
) else (
    echo tbverp.exe build failed!
)

echo Building tbcheck.exe with VS2026...
cl /O2 /DNDEBUG /DMAGIC /DUSE_POPCNT /DTBPIECES=7 /DCOMPRESSION_THREADS=6 /DREGULAR /I. /Fe:..\bin\tbcheck.exe tbcheck.c threads.c checksum.c city-c.c lz4.c util.c

if %errorlevel% equ 0 (
    echo tbcheck.exe built successfully!
) else (
    echo tbcheck.exe build failed!
)

echo All builds completed!