@echo off
setlocal

:: Set up Visual Studio 2022 build environment
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

:: Create bin directory
if not exist "..\bin" mkdir ..\bin

:: Build all source files
cd src

echo Building tbgen.c...
cl /c /O2 /DNDEBUG /D_HAS_EXCEPTIONS=0 /std:c++17 /I. /DREGULAR /DMAGIC /DUSE_POPCNT /DTBPIECES=7 /D"COMPRESSION_THREADS=6" tbgen.c

echo Building permute.c...
cl /c /O2 /DNDEBUG /D_HAS_EXCEPTIONS=0 /std:c++17 /I. /DREGULAR /DMAGIC /DUSE_POPCNT /DTBPIECES=7 /D"COMPRESSION_THREADS=6" permute.c

echo Building compress.c...
cl /c /O2 /DNDEBUG /D_HAS_EXCEPTIONS=0 /std:c++17 /I. /DREGULAR /DMAGIC /DUSE_POPCNT /DTBPIECES=7 /D"COMPRESSION_THREADS=6" compress.c

echo Building huffman.c...
cl /c /O2 /DNDEBUG /D_HAS_EXCEPTIONS=0 /std:c++17 /I. /DREGULAR /DMAGIC /DUSE_POPCNT /DTBPIECES=7 /D"COMPRESSION_THREADS=6" huffman.c

echo Building threads.c...
cl /c /O2 /DNDEBUG /D_HAS_EXCEPTIONS=0 /std:c++17 /I. /DREGULAR /DMAGIC /DUSE_POPCNT /DTBPIECES=7 /D"COMPRESSION_THREADS=6" threads.c

echo Building lz4.c...
cl /c /O2 /DNDEBUG /D_HAS_EXCEPTIONS=0 /std:c++17 /I. /DREGULAR /DMAGIC /DUSE_POPCNT /DTBPIECES=7 /D"COMPRESSION_THREADS=6" lz4.c

echo Building checksum.c...
cl /c /O2 /DNDEBUG /D_HAS_EXCEPTIONS=0 /std:c++17 /I. /DREGULAR /DMAGIC /DUSE_POPCNT /DTBPIECES=7 /D"COMPRESSION_THREADS=6" checksum.c

echo Building city-c.c...
cl /c /O2 /DNDEBUG /D_HAS_EXCEPTIONS=0 /std:c++17 /I. /DREGULAR /DMAGIC /DUSE_POPCNT /DTBPIECES=7 /D"COMPRESSION_THREADS=6" city-c.c

echo Building util.c...
cl /c /O2 /DNDEBUG /D_HAS_EXCEPTIONS=0 /std:c++17 /I. /DREGULAR /DMAGIC /DUSE_POPCNT /DTBPIECES=7 /D"COMPRESSION_THREADS=6" util.c

:: Link tbgen
echo Linking tbgen.exe...
link /OUT:..\bin\tbgen.exe tbgen.obj permute.obj compress.obj huffman.obj threads.obj lz4.obj checksum.obj city-c.obj util.obj /SUBSYSTEM:CONSOLE

echo.
echo Building tbgenp.c...
cl /c /O2 /DNDEBUG /D_HAS_EXCEPTIONS=0 /std:c++17 /I. /DREGULAR /DMAGIC /DUSE_POPCNT /DTBPIECES=7 /D"COMPRESSION_THREADS=6" /DHAS_PAWNS tbgenp.c

:: Link tbgenp (reuse same object files)
echo Linking tbgenp.exe...
link /OUT:..\bin\tbgenp.exe tbgenp.obj permute.obj compress.obj huffman.obj threads.obj lz4.obj checksum.obj city-c.obj util.obj /SUBSYSTEM:CONSOLE

echo.
echo Building tbver.c...
cl /c /O2 /DNDEBUG /D_HAS_EXCEPTIONS=0 /std:c++17 /I. /DREGULAR /DMAGIC /DUSE_POPCNT /DTBPIECES=7 /D"COMPRESSION_THREADS=6" tbver.c

echo Building decompress.c...
cl /c /O2 /DNDEBUG /D_HAS_EXCEPTIONS=0 /std:c++17 /I. /DREGULAR /DMAGIC /DUSE_POPCNT /DTBPIECES=7 /D"COMPRESSION_THREADS=6" decompress.c

:: Link tbver
echo Linking tbver.exe...
link /OUT:..\bin\tbver.exe tbver.obj decompress.obj threads.obj checksum.obj city-c.obj util.obj lz4.obj /SUBSYSTEM:CONSOLE

echo.
echo Building tbverp.c...
cl /c /O2 /DNDEBUG /D_HAS_EXCEPTIONS=0 /std:c++17 /I. /DREGULAR /DMAGIC /DUSE_POPCNT /DTBPIECES=7 /D"COMPRESSION_THREADS=6" /DHAS_PAWNS tbverp.c

:: Link tbverp
echo Linking tbverp.exe...
link /OUT:..\bin\tbverp.exe tbverp.obj decompress.obj threads.obj checksum.obj city-c.obj util.obj lz4.obj /SUBSYSTEM:CONSOLE

echo.
echo Building tbcheck.c...
cl /c /O2 /DNDEBUG /D_HAS_EXCEPTIONS=0 /std:c++17 /I. /DREGULAR /DMAGIC /DUSE_POPCNT /DTBPIECES=7 /D"COMPRESSION_THREADS=6" tbcheck.c

:: Link tbcheck
echo Linking tbcheck.exe...
link /OUT:..\bin\tbcheck.exe tbcheck.obj threads.obj checksum.obj city-c.obj lz4.obj util.obj /SUBSYSTEM:CONSOLE

echo.
echo Build complete!
endlocal