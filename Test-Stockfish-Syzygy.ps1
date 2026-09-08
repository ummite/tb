<#
.SYNOPSIS
    Petit test pour vérifier que Stockfish utilise bien tes tablebases Syzygy sur T:\Syzygy.
#>

param(
    [switch]$Need8Piece,
    [string]$SyzygyPath = "T:\Syzygy"
)

$stockfish = & "$PSScriptRoot\Get-StockfishEngine.ps1" -Need8Piece:$Need8Piece -Quiet
if (-not $stockfish) { exit 1 }

Write-Host "=== Test Stockfish + Tes Syzygy ===" -ForegroundColor Cyan
Write-Host "Moteur : $stockfish"
Write-Host "Syzygy : $SyzygyPath"
Write-Host ""

# Créer les commandes UCI
$commands = @(
    "uci",
    "setoption name SyzygyPath value $SyzygyPath",
    "isready",
    "position fen 8/8/8/8/8/8/4P3/4K2k w - - 0 1",
    "go depth 12",
    "quit"
)

$inputFile  = "$env:TEMP\stockfish_test_input.txt"
$outputFile = "$env:TEMP\stockfish_test_output.txt"

$commands | Out-File $inputFile -Encoding ASCII

Write-Host "Lancement de Stockfish..." -ForegroundColor Yellow
& $stockfish < $inputFile > $outputFile 2>&1

Write-Host ""
Write-Host "=== Résultat du test ===" -ForegroundColor Cyan

if (Test-Path $outputFile) {
    $lines = Get-Content $outputFile

    # Afficher les lignes importantes
    $important = $lines | Select-String -Pattern "uciok|readyok|Syzygy|tablebases|tbhits|info string Found"
    if ($important) {
        Write-Host "Lignes clés :" -ForegroundColor Green
        $important | ForEach-Object { Write-Host "  $($_.Line)" }
    } else {
        Write-Host "Aucune ligne clé trouvée (problème de capture ?)" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "=== Vérification de l'utilisation des tablebases ===" -ForegroundColor Cyan

    $foundLine = $lines | Select-String "Found .* tablebases"
    if ($foundLine) {
        Write-Host "✅ Stockfish a chargé tes tablebases :" -ForegroundColor Green
        Write-Host "   $($foundLine.Line)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Aucun message 'Found X tablebases' détecté." -ForegroundColor Yellow
    }

    $tbhits = $lines | Select-String "tbhits [1-9]"
    if ($tbhits) {
        Write-Host ""
        Write-Host "✅ Stockfish a utilisé les tablebases pendant la recherche (tbhits > 0) :" -ForegroundColor Green
        $tbhits | Select-Object -First 5 | ForEach-Object { Write-Host "   $($_.Line)" }
    } else {
        Write-Host ""
        Write-Host "ℹ️  Aucun 'tbhits > 0' détecté dans cette recherche courte (normal si la position ne descend pas assez dans les tables)." -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Test terminé. Fichier de log complet : $outputFile" -ForegroundColor DarkGray
} else {
    Write-Host "Aucun fichier de sortie généré." -ForegroundColor Red
}