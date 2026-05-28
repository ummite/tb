@echo off
REM Get the MSVC compiler path
call "C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Auxiliary\Build\vcvars64.bat"
cl /c /std:c11 /nologo test_msvc.c 2>&1
cl /link /nologo test_msvc.obj /out:test_msvc.exe 2>&1
test_msvc.exe
