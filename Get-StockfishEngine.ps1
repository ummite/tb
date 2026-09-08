<#
.SYNOPSIS
    Resolve the Stockfish binary used for Syzygy probe tests (7-piece official, 8-piece patched).

.DESCRIPTION
    Preference order:
      1. $env:STOCKFISH (explicit override)
      2. bin\stockfish-tb8.exe  (only with -Need8Piece)
      3. bin\stockfish.exe      (local PGO build from StockfishSrc)
      4. StockfishSrc\src\stockfish.exe
      5. C:\Stockfish\stockfish.exe (official download fallback)

    Official Stockfish hardcodes TBPIECES=7. 8-piece probing requires
    .\Build-Stockfish.ps1 -Enable8Piece  -> bin\stockfish-tb8.exe

    Prints the absolute path on stdout. Warnings go to the host.
#>
param(
    [switch]$Need8Piece,
    [switch]$Quiet
)

$Root = $PSScriptRoot
if (-not $Root) { $Root = (Get-Location).Path }

function Test-EngineFile([string]$Path) {
    return ($Path -and (Test-Path -LiteralPath $Path -PathType Leaf))
}

$candidates = New-Object System.Collections.Generic.List[string]
if ($env:STOCKFISH) { [void]$candidates.Add($env:STOCKFISH) }
if ($Need8Piece) {
    [void]$candidates.Add((Join-Path $Root "bin\stockfish-tb8.exe"))
}
[void]$candidates.Add((Join-Path $Root "bin\stockfish.exe"))
[void]$candidates.Add((Join-Path $Root "StockfishSrc\src\stockfish.exe"))
[void]$candidates.Add("C:\Stockfish\stockfish.exe")
[void]$candidates.Add("C:\Stockfish\stockfish\stockfish-windows-x86-64-avx2.exe")

$resolved = $null
foreach ($c in $candidates) {
    if (Test-EngineFile $c) {
        $resolved = (Resolve-Path -LiteralPath $c).Path
        break
    }
}

if (-not $resolved) {
    throw "Stockfish introuvable. Lancez : .\Build-Stockfish.ps1  (et -Enable8Piece pour le probing 8pc)"
}

if ($Need8Piece -and ($resolved -notmatch 'stockfish-tb8')) {
    if (-not $Quiet) {
        Write-Warning "Moteur 8pc (bin\stockfish-tb8.exe) absent. Fallback : $resolved — Stockfish officiel refuse les tables a 8 pieces (TBPIECES=7). Relancez .\Build-Stockfish.ps1 -Enable8Piece"
    }
}

if (-not $Quiet) {
    Write-Host "Stockfish : $resolved" -ForegroundColor DarkGray
}

Write-Output $resolved
