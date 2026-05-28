@echo off
cd /d "C:\Programmation\tb-1\src"
call "C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Auxiliary\Build\vcvars64.bat"
cl /c /std:c11 /nologo test_macro.c 2>&1 > test_macro_compile.txt
if errorlevel 1 (
    echo Compilation failed
    type test_macro_compile.txt
    exit /b 1
)
cl /link /nologo test_macro.obj /out:test_macro.exe 2>&1 > test_macro_link.txt
if errorlevel 1 (
    echo Linking failed
    type test_macro_link.txt
    exit /b 1
)
test_macro.exe > test_macro_run.txt 2>&1
type test_macro_run.txt
