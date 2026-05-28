@echo off
cd /d "C:\Programmation\tb-1\src"
call "C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Auxiliary\Build\vcvars64.bat"
cl /c /std:c11 /nologo "C:\Programmation\tb-1\src\test_macro2.c" 2>&1 > test_macro2_compile.txt
if errorlevel 1 (
    echo Compilation failed
    type test_macro2_compile.txt
    exit /b 1
)
cl /link /nologo test_macro2.obj /out:test_macro2.exe 2>&1 > test_macro2_link.txt
if errorlevel 1 (
    echo Linking failed
    type test_macro2_link.txt
    exit /b 1
)
test_macro2.exe > test_macro2_run.txt 2>&1
type test_macro2_run.txt
