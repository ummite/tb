@echo off
cd /d "C:\Programmation\tb-1\src"
call "C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Auxiliary\Build\vcvars64.bat"
cl /c /std:c11 /nologo test_mscver.c 2>&1
cl /link /nologo test_mscver.obj /out:test_mscver.exe 2>&1
test_mscver.exe
