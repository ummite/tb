@echo off
REM Syzygy Table Manager launcher (the "petite interface")
REM 
REM Quality improvements:
REM - Piece count navigation (1-4 groups as "tabs"): 3-5pc / 6 / 7 / 8 experimental. Each has dedicated GridView + SizeMB column.
REM - Direct "Generate": in group view, "G" for bulk ALL missing (queue + auto runner), or after manual select use B for "Generate button".
REM - Flat view (5) also supports generate choice + SizeMB.
REM - HTML (E): real tabs, clickable column sort, "Export generate script for missing" (produces ready PS snippet to clipboard for save/run).
REM - Data quality: sizes captured and shown for completed tables.
REM
REM Run the .bat, use groups for focused "see missing + generate", HTML for overview + export actions.
REM Runner still handles background safely.

powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0Syzygy-TableManager.ps1" %*
pause
