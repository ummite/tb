@echo off
rem Build of 2018 rtbgenp (commit 1f5a2e2) with MSVC, for the KPvK experiment.
call "C:\Program Files\Microsoft Visual Studio\18\Insiders\Common7\Tools\VsDevCmd.bat" -arch=x64 -no_logo
cd /d C:\Programmation\tb-1\.wt-kpvk2021
if not exist obj2021 mkdir obj2021
cl /nologo /std:c11 /O2 /Ob2 /GS- /arch:AVX2 /GL /LTCG /DNDEBUG /DUSE_POPCNT /DBMI2 /DTBPIECES=7 /D__WIN32__ /D__SSE_4_2__ /I"C:\Programmation\tb-1\kpvk_2021_test\shim" /FI"C:\Programmation\tb-1\kpvk_2021_test\shim\msvcshim.h" /Fo"obj2021\\" src\tbgenp.c src\compress.c src\permute.c src\util.c src\threads.c src\lz4.c src\huffman.c src\checksum.c src\city-c.c "C:\Programmation\tb-1\kpvk_2021_test\shim\getopt.c" "C:\Programmation\tb-1\kpvk_2021_test\shim\gettimeofday.c" /link /LTCG /OUT:rtbgenp2021.exe
exit /b %errorlevel%
