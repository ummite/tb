<#
.SYNOPSIS
    Trouve la ligne de mat la plus courte pour la position KRK en utilisant Stockfish + tes tables Syzygy.
    Méthode : play-out en demandant "go mate 30" à chaque coup et en suivant le bestmove jusqu'à mat.
    Affiche la ligne UCI (fiable) et une version SAN simple.

.EXAMPLE
    .\Find-KRK-Mate-Line.ps1
#>

$stockfishPath = "C:\Stockfish\stockfish.exe"
$syzygyPath = "T:\Syzygy"
$startFen = "k7/8/8/8/8/8/8/1K5R w - - 0 1"

if (-not (Test-Path $stockfishPath)) {
    Write-Error "Stockfish non trouvé à $stockfishPath"
    exit 1
}

Write-Host "=== Recherche du plus court mat forcé (KRK) ===" -ForegroundColor Cyan
Write-Host "FEN de départ : $startFen"
Write-Host "SyzygyPath    : $syzygyPath"
Write-Host "Méthode       : Play-out avec 'go mate 30' répété (le moteur choisit le coup qui mate le plus vite contre la meilleure défense)"
Write-Host ""

# Démarrer un seul processus Stockfish pour toute la session (plus fiable)
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $stockfishPath
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true

$process = [System.Diagnostics.Process]::Start($psi)
$stdin = $process.StandardInput
$stdout = $process.StandardOutput

function Send-UCI([string[]]$cmds) {
    foreach ($c in $cmds) { $stdin.WriteLine($c) }
    $stdin.WriteLine("isready")   # pour synchroniser
    # Lire jusqu'à readyok
    $lines = @()
    while ($true) {
        $line = $stdout.ReadLine()
        if ($null -eq $line) { break }
        $lines += $line
        if ($line -eq "readyok") { break }
    }
    return $lines
}

# Initialisation
Send-UCI @("uci", "setoption name SyzygyPath value $syzygyPath", "setoption name Hash value 256", "setoption name Threads value 1") | Out-Null

$moves = @()   # liste des coups UCI
$halfMove = 0

while ($halfMove -lt 60) {
    $posCmd = "position fen $startFen"
    if ($moves.Count -gt 0) {
        $posCmd += " moves $($moves -join ' ')"
    }

    $cmds = @($posCmd, "go mate 30")
    $output = Send-UCI $cmds

    $bestLine = $output | Where-Object { $_ -match '^bestmove ' } | Select-Object -First 1
    if (-not $bestLine) {
        Write-Host "Pas de bestmove trouvé, arrêt."
        break
    }

    $best = ($bestLine -split ' ')[1]

    if ($best -eq '0000' -or $best -eq '(none)') {
        Write-Host "Mat ! Le camp à jouer n'a plus de coup légal." -ForegroundColor Green
        break
    }

    $moves += $best
    $side = if ($halfMove % 2 -eq 0) { "Blanc" } else { "Noir" }
    Write-Host "Coup $halfMove ($side): $best"

    # Vérifie si après ce coup l'adversaire est maté
    $posAfter = "position fen $startFen moves $($moves -join ' ')"
    $checkOut = Send-UCI @($posAfter, "go depth 1")
    $bestAfter = ($checkOut | Where-Object { $_ -match '^bestmove ' } | Select-Object -First 1) -split ' ' | Select-Object -Last 1

    if ($bestAfter -eq '0000' -or $bestAfter -eq '(none)') {
        Write-Host "Mat livré par le coup $best !" -ForegroundColor Green
        break
    }

    $halfMove++
}

$process.Kill() | Out-Null

Write-Host ""
Write-Host "=== Ligne complète (UCI) ===" -ForegroundColor Green
Write-Host ($moves -join " ")
Write-Host "Longueur : $halfMove demi-coups (~ $([math]::Ceiling($halfMove / 2)) coups)"

Write-Host ""
Write-Host "Pour voir la ligne en notation algébrique (Rc1, Ka7...) + les échiquiers coup par coup :" -ForegroundColor Yellow
Write-Host "1. Colle la ligne UCI ci-dessus dans Lichess (Analysis board) ou Arena Chess GUI."
Write-Host "2. Active les tablebases Syzygy en pointant sur T:\Syzygy."
Write-Host "3. Le GUI te montrera la ligne complète avec les boards."

Write-Host ""
Write-Host "Script terminé. Tu peux le relancer ou l'adapter facilement." -ForegroundColor DarkGray