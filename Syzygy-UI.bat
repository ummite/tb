@echo off
REM Syzygy Table Manager launcher (the "petite interface")
REM 
REM NEW (per your request):
REM - Piece count navigation ("tabs"): choose 1=3-5pc, 2=6pc, 3=7pc, 4=8pc experimental
REM   Each opens a dedicated filtered list focused on that group.
REM - Direct "Generate" action: after selecting missing rows in a group view,
REM   choose B) "Add to queue + START BACKGROUND RUNNER NOW"  <-- this is your generate button.
REM - Also bulk "generate all missing in this group" options in the flow.
REM - The exported HTML (option E) now has real tabs (3-5 / 6 / 7 / 8) + per-tab copy.
REM
REM Old flat list still available as choice 5.
REM
REM Run, pick a piece count group, select missings, then use the Generate action.

powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0Syzygy-TableManager.ps1" %*
pause
