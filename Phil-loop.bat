@echo off
chcp 65001 >nul

:: Initialisation du compteur de loops (Phil's Loop)
set /a LOOP_COUNT=0

title Claude Code - Phil's Loop (Local LLM - Zero Cost)

echo =============================================
echo     Claude Code - Phil's Loop
echo     Autonomous Agent Loop (Local LLM - Zero Cost)
echo =============================================
echo.

:: === INITIAL QUESTION ===
set /p CREATE_BRANCH="Do you want to create a dedicated branch (claude-autonomous) for Phil's Loop? (Y/N): "

if /I "%CREATE_BRANCH%"=="Y" (
    git checkout claude-autonomous 2>nul || (
        echo [INFO] Creating branch claude-autonomous for Phil's Loop...
        git checkout -b claude-autonomous
    )
    echo [INFO] Phil's Loop is now running on branch: claude-autonomous
) else (
    echo [INFO] Phil's Loop is running directly on the current branch.
    git branch --show-current
)

echo.
echo Phil's Loop started (Local LLM - max-turns 400)
echo Press Ctrl+C to stop at any time.
echo =============================================
echo.

:loop
set /a LOOP_COUNT+=1
title Claude Code - Phil's Loop - Cycle %LOOP_COUNT% (Local LLM)

echo [%date% %time%] === PHIL'S LOOP - CYCLE %LOOP_COUNT% ===

claude -p "@loop_prompt.md" --continue --allowedTools "Read,Write,Edit,Bash,Glob,Grep" --dangerously-skip-permissions --max-turns 400 > cycle.log 2>&1

:: Detect completion
findstr /C:"PROJECT COMPLETE" completed.txt >nul
if %errorlevel% == 0 (
    echo.
    echo =============================================
    echo PROJECT COMPLETE DETECTED - Phil's Loop finished after %LOOP_COUNT% cycles!
    echo =============================================
    echo.
    echo Current file status:
    git status --short
    echo.

    set /p SATISFIED="Are you satisfied with Phil's Loop results? Do you want to commit now? (Y/N): "

    if /I "%SATISFIED%"=="Y" (
        echo.
        echo Committing Phil's Loop results...
        git add .
        git commit -m "Phil's Loop - Cycle %LOOP_COUNT% - Project Complete [Local LLM]"
        echo ✅ Phil's Loop commit completed successfully!

        if /I "%CREATE_BRANCH%"=="Y" (
            set /p MERGE="Do you want to merge claude-autonomous into main now? (Y/N): "
            if /I "%MERGE%"=="Y" (
                git checkout main
                git merge claude-autonomous --no-ff -m "Merge Phil's Loop - Cycle %LOOP_COUNT% - Project Complete"
                echo ✅ Merge of Phil's Loop into main completed!
            )
        )
    ) else (
        echo No commit was made. All Phil's Loop changes remain uncommitted.
    )
    pause
    exit
)

echo Phil's Loop cycle %LOOP_COUNT% completed. Starting new cycle in 2 seconds...
timeout /t 2 /nobreak >nul
goto loop