@echo off
set MSBUILD="C:\Program Files\Microsoft Visual Studio\18\Insiders\MSBuild\Current\Bin\amd64\MSBuild.exe"
%MSBUILD% tbgen.vcxproj /p:Configuration=Release /p:Platform=x64 /v:minimal
