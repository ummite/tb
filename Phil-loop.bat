@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ====================== CONFIG FINALE ======================
set ANTHROPIC_BASE_URL=http://127.0.0.1:11434
set ANTHROPIC_API_KEY=ollama

echo.
echo [DEBUG ENV] ANTHROPIC_BASE_URL = %ANTHROPIC_BASE_URL%
echo [DEBUG ENV] ANTHROPIC_API_KEY  = ollama   ← C'EST ÇA QUI MARCHE POUR TOI
echo [DEBUG ENV] Model              = Qwen35-Q8-MaxSpeed
echo.

set CLAUDE_CODE_MAX_OUTPUT_TOKENS=12288
set MAX_THINKING_TOKENS=32768
set CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=70
set CLAUDE_CODE_DISABLE_1M_CONTEXT=1

set /a LOOP_COUNT=0
title Claude Code - Phil's Loop v14 (Sans max-turns)

echo =============================================
echo Claude Code - Phil's Loop v14
echo Mode "un gros cycle puis stop" • Batch relance
echo =============================================
echo.

:loop
set /a LOOP_COUNT+=1
title Claude Code - Phil's Loop v14 - Cycle %LOOP_COUNT%

echo.
echo [%date% %time%] === PHIL'S LOOP - CYCLE %LOOP_COUNT% ===

:: Record start time in seconds since midnight
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "start_datetime=%%a"
set "start_hour=!start_datetime:~8,2!"
set "start_min=!start_datetime:~10,2!"
set "start_sec=!start_datetime:~12,2!"
set /a start_total_sec=(10#%start_hour% * 3600) + (10#%start_min% * 60) + 10#%start_sec%

call claude -p "@loop_prompt.md" ^
  --continue --max-turns 400 ^
  --dangerously-skip-permissions ^
  --model Qwen35-Q8-MaxSpeed ^
  --debug "api,tools,compact,context" ^
  --verbose

:: Record end time and calculate duration
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "end_datetime=%%a"
set "end_hour=!end_datetime:~8,2!"
set "end_min=!end_datetime:~10,2!"
set "end_sec=!end_datetime:~12,2!"
set /a end_total_sec=(10#%end_hour% * 3600) + (10#%end_min% * 60) + 10#%end_sec%
set /a duration_sec=end_total_sec - start_total_sec

:: Convert to minutes and seconds
set /a duration_min=duration_sec / 60
set /a duration_sec=duration_sec %% 60

echo.
echo Cycle %LOOP_COUNT% completed in !duration_min! minute(s) !duration_sec! second(s).
echo Relaunching in 2 seconds...
timeout /t 2 /nobreak >nul
goto loop