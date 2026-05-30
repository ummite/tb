@echo off
set CL="C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Tools\MSVC\14.51.36231\bin\Hostx64\x64\cl.exe"
set SRC=src\tbgenp.c
set OUT=tbgenp.i

echo Preprocessing %SRC% to %OUT% ...

%CL% /P /Fi%OUT% /nologo ^
/I "src" ^
/D NDEBUG /D _CRT_SECURE_NO_WARNINGS /D _CRT_NONSTDC_NO_DEPRECATE /D _CONSOLE ^
/D HAS_PAWNS /D MAGIC /D USE_POPCNT /D BMI2 /D TBPIECES=7 /D COMPRESSION_THREADS=6 /D REGULAR /D LZ4 ^
/D _WIN64 /D WIN32 /D NDEBUG /D _WINDOWS /D _CRT_SECURE_NO_DEPRECATE ^
/std:c11 ^
/W3 /WX- /wd4244 /wd4267 /wd4018 ^
/EHs-c- /GR- ^
%SRC%

if exist %OUT% (
  echo Preprocessed file created: %OUT% (size: 
  dir %OUT% | findstr %OUT%
  echo )
  echo Searching for key function definitions from rtbgenp.c ...
  findstr /n /c:"void set_tbl_to_wdl" %OUT%
  findstr /n /c:"void iterate" %OUT%
  findstr /n /c:"void calc_pawn_moves_w" %OUT%
  echo.
  echo If the above found lines, then include succeeded in preprocessor.
) else (
  echo ERROR: no %OUT% produced
)
echo Done.