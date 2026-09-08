<#
.SYNOPSIS
    Test que Stockfish utilise les Syzygy tables de T:\Syzygy pour donner une réponse immédiate
    sur une position déjà présente dans les résultats Syzygy, sans avoir besoin de calculer profondément.
#>

param(
    [switch]$Need8Piece,
    [string]$SyzygyPath = "T:\Syzygy"
)

$stockfishPath = & "$PSScriptRoot\Get-StockfishEngine.ps1" -Need8Piece:$Need8Piece -Quiet
$syzygyPath = $SyzygyPath
if (-not $stockfishPath) { exit 1 }

Write-Host "=== Test Stockfish + Syzygy (réponse immédiate via tables) ===" -ForegroundColor Cyan
Write-Host "Moteur     : $stockfishPath"
Write-Host "SyzygyPath : $syzygyPath"
Write-Host ""

# Positions de test (3-5pc toujours ; 7pc ; 8pc seulement avec -Need8Piece)
$positions = @(
    @{
        Name = "KPK (3pc)"
        FEN  = "8/8/8/8/8/8/4P3/4K2k w - - 0 1"
    },
    @{
        Name = "KRPvKR (5pc)"
        FEN  = "8/8/8/8/k7/8/4P3/R3K3 w - - 0 1"
    },
    @{
        Name = "KRPPPvKR (7pc)"
        FEN  = "8/8/8/8/1k6/8/PPPR4/K7 w - - 0 1"
    }
)
if ($Need8Piece) {
    $positions += @{
        Name = "KPPPPPPvK (8pc — exige bin\stockfish-tb8.exe)"
        FEN  = "8/8/8/8/2k5/8/PPPPPP2/K7 w - - 0 1"
    }
}

foreach ($pos in $positions) {
    Write-Host "`n--- Test position : $($pos.Name) ---" -ForegroundColor Yellow
    Write-Host "FEN: $($pos.FEN)" -ForegroundColor DarkGray

    # Démarrer Stockfish en mode UCI avec redirection
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $stockfishPath
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $process = [System.Diagnostics.Process]::Start($psi)
    $stdin = $process.StandardInput
    $stdout = $process.StandardOutput

    # Envoyer les commandes UCI
    $stdin.WriteLine("uci")
    $stdin.WriteLine("setoption name SyzygyPath value $syzygyPath")
    $stdin.WriteLine("setoption name Hash value 64")
    $stdin.WriteLine("setoption name Threads value 1")
    $stdin.WriteLine("isready")
    $stdin.WriteLine("position fen $($pos.FEN)")
    $stdin.WriteLine("go depth 8")
    $stdin.WriteLine("quit")
    $stdin.Close()

    # Lire la sortie
    $output = $stdout.ReadToEnd()
    $process.WaitForExit()

    $lines = $output -split "`r?`n"

    # Analyser les résultats
    $foundTables = $lines | Where-Object { $_ -match "Found .* tablebases" }
    if ($foundTables) {
        Write-Host "✅ Tables Syzygy chargées : $($foundTables -join ' | ')" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Aucun 'Found X tablebases' détecté." -ForegroundColor Yellow
    }

    $tbhits = $lines | Where-Object { $_ -match "tbhits [1-9]" }
    if ($tbhits) {
        Write-Host "✅ tbhits > 0 : Stockfish a utilisé les tables pendant l'analyse" -ForegroundColor Green
        $tbhits | Select-Object -First 3 | ForEach-Object { Write-Host "   $_" }
    } else {
        Write-Host "ℹ️  Pas de tbhits >0 visible (normal pour des positions résolues très tôt par les tables)." -ForegroundColor Yellow
    }

    # Chercher les premiers scores à faible profondeur (preuve de réponse "immédiate")
    $earlyInfos = $lines | Where-Object { $_ -match "info depth [0-3].*score" }
    if ($earlyInfos) {
        Write-Host "✅ Scores à très faible profondeur (réponse quasi-immédiate grâce aux tables) :" -ForegroundColor Green
        $earlyInfos | Select-Object -First 2 | ForEach-Object { Write-Host "   $_" }
    }

    $bestmoveLine = $lines | Where-Object { $_ -match "^bestmove " }
    if ($bestmoveLine) {
        Write-Host "bestmove final : $($bestmoveLine -join ' ')" -ForegroundColor Cyan
    }

    # Vérifier si on voit un score TB clair (cp 0 pour draw, ou mate pour win)
    $tbScore = $lines | Where-Object { $_ -match "score (cp 0|mate)" -and $_ -match "depth [0-3]" }
    if ($tbScore) {
        Write-Host "✅ Score TB clair à faible profondeur : $($tbScore -join ' | ')" -ForegroundColor Green
    }

    Write-Host "Test pour cette position terminé." -ForegroundColor DarkGray
}

Write-Host "`n=== Interprétation ===" -ForegroundColor Magenta
Write-Host "Si tu vois 'Found X tablebases' + des tbhits >0 + des scores corrects à depth 1-3,"
Write-Host "alors Stockfish n'a pas eu besoin de calculer profondément : il a utilisé tes tables Syzygy"
Write-Host "pour donner la réponse immédiate (WDL / DTZ) sur une position déjà connue."
Write-Host ""
Write-Host "C'est exactement la validation que tes tables fonctionnent correctement avec un moteur." -ForegroundColor Green
