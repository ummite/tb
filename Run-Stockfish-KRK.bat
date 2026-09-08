@echo off
echo === Lancement Stockfish pour la position KRK avec tes tables Syzygy ===
echo.
set "SF=%~dp0bin\stockfish.exe"
if not exist "%SF%" set "SF=%~dp0StockfishSrc\src\stockfish.exe"
if not exist "%SF%" set "SF=C:\Stockfish\stockfish.exe"
echo Stockfish : %SF%
echo SyzygyPath : T:\Syzygy
echo Position   : k7/8/8/8/8/8/8/1K5R w - - 0 1
echo.
echo Tape les commandes suivantes dans Stockfish (ou colle le bloc) :
echo.
echo uci
echo setoption name SyzygyPath value T:\Syzygy
echo isready
echo position fen k7/8/8/8/8/8/8/1K5R w - - 0 1
echo go mate 30
echo.
echo Pour quitter : quit
echo.
echo Pour reconstruire la ligne complète (play-out) :
echo   - Note le bestmove
echo   - position fen k7/8/8/8/8/8/8/1K5R w - - 0 1 moves [liste des coups]
echo   - go mate 30
echo   - Répète jusqu'à bestmove 0000 (mat)
echo.
pause
"%SF%"
echo.
echo Stockfish fermé.
pause