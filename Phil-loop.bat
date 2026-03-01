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
set MAX_THINKING_TOKENS=3072
set CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=72
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

call claude -p "@loop_prompt.md" ^
  --continue ^
  --dangerously-skip-permissions ^
  --model Qwen35-Q8-MaxSpeed ^
  --debug "api,tools,compact,context" ^
  --verbose

echo.
echo Cycle %LOOP_COUNT% terminé.
echo Relance dans 2 secondes...
timeout /t 2 /nobreak >nul
goto loop