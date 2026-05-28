<#
.SYNOPSIS
    Déplace (copy + suppression source) les fichiers Syzygy vers T:\Syzygy
    dès qu'il y a assez d'espace. Met en pause sinon.

.DESCRIPTION
    Version "move" du script space-aware.
    Pour chaque source :
    1. Copie vers T:\Syzygy avec robocopy
    2. Si la copie réussit complètement → supprime le dossier source

    ATTENTION : Version destructive. Utilise-la seulement quand tu es sûr
    que les fichiers sont bien arrivés sur T:\Syzygy.

    Modifie $Sources selon tes besoins.

.PARAMETER MinFreeTB
    Espace minimum à garder sur T: (sécurité).

.PARAMETER SleepMinutes
    Temps d'attente quand il n'y a pas assez de place.

.PARAMETER Threads
    Threads robocopy.

.EXAMPLE
    .\Move-Syzygy-SpaceAware.ps1 -MinFreeTB 1.2 -SleepMinutes 15
#>

[CmdletBinding()]
param(
    [double]$MinFreeTB = 1.5,
    [int]$SleepMinutes = 10,
    [int]$Threads = 12
)

$Sources = @(
    "S:\6v1_pawnless",
    "S:\6v1_pawnful",
    "S:\5v2_pawnless",
    "S:\5v2_pawnful",
    "S:\4v3_pawnless_ManyMissing",
    "S:\Syzygy",
    "A:\Syzygy"
)

$Target = "T:\Syzygy"
$LogDir = Join-Path $PSScriptRoot "logs"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

$StateFile = Join-Path $LogDir "Syzygy-Move-SpaceAware.state.json"

function Get-FreeTB {
    try { return (Get-PSDrive -Name T -ErrorAction Stop).Free / 1TB } catch { return 0 }
}

function Write-Log($Message) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] $Message"
    Add-Content -Path (Join-Path $LogDir "Syzygy-Move-SpaceAware.log") -Value $line
    Write-Host $line -ForegroundColor Yellow
}

function Load-State {
    if (Test-Path $StateFile) { return Get-Content $StateFile | ConvertFrom-Json }
    return @{}
}

function Save-State($State) {
    $State | ConvertTo-Json -Depth 5 | Set-Content -Path $StateFile -Encoding UTF8
}

Write-Log "=== Lancement du déplaceur Syzygy space-aware (MODE DESTRUCTIF) ==="
Write-Log "Seuil minimum : $MinFreeTB To"

$State = Load-State

while ($true) {
    $free = Get-FreeTB
    Write-Log "Espace libre sur T: $([math]::Round($free,2)) To"

    if ($free -lt $MinFreeTB) {
        Write-Log "Pas assez d'espace. Pause $SleepMinutes min..."
        Start-Sleep -Seconds ($SleepMinutes * 60)
        continue
    }

    $nextSource = $null
    foreach ($src in $Sources) {
        if (-not (Test-Path $src)) { continue }
        if ($State[$src] -eq "done") { continue }

        $hasFiles = Get-ChildItem $src -Recurse -Include *.rtbw,*.rtbz -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hasFiles) {
            $nextSource = $src
            break
        } else {
            $State[$src] = "done"
            Save-State $State
        }
    }

    if (-not $nextSource) {
        Write-Log "Tous les dossiers ont été déplacés. Terminé."
        break
    }

    Write-Log "Espace OK. Copie + déplacement de : $nextSource"

    $folderName = Split-Path $nextSource -Leaf
    $logFile = Join-Path $LogDir "robocopy-move-$folderName-$(Get-Date -Format yyyyMMdd_HHmmss).log"

    $robocopyArgs = @(
        $nextSource, $Target, "*.rtbw", "*.rtbz",
        "/E", "/COPY:DAT", "/R:3", "/W:5", "/MT:$Threads",
        "/LOG+:$logFile", "/TEE"
    )

    $p = Start-Process robocopy -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow
    $code = $p.ExitCode

    if ($code -lt 8) {
        Write-Log "Copie réussie pour $nextSource (code $code). Suppression de la source..."

        try {
            Remove-Item -Path $nextSource -Recurse -Force -ErrorAction Stop
            Write-Log "Dossier source supprimé : $nextSource"
            $State[$nextSource] = "done"
            Save-State $State
        } catch {
            Write-Log "ERREUR lors de la suppression de $nextSource : $_"
            Write-Log "Le dossier source est toujours présent. Vérifie manuellement."
        }
    } else {
        Write-Log "Échec de la copie de $nextSource (code $code). On réessaiera plus tard."
    }

    Start-Sleep -Seconds 30
}

Write-Log "=== Script Move terminé ==="
