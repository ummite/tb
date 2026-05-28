<#
.SYNOPSIS
    Copie les fichiers Syzygy vers T:\Syzygy dès qu'il y a assez d'espace libre.
    Met en pause tant qu'il n'y a pas assez de place.

.DESCRIPTION
    Script "set and forget" pour prioriser le remplissage de T:\Syzygy.
    Il vérifie régulièrement l'espace libre sur T:.
    Quand l'espace est suffisant, il copie le prochain dossier source avec robocopy.
    Quand l'espace est insuffisant, il dort et réessaie plus tard.

    Modifie la variable $Sources en haut du script selon tes besoins.

.PARAMETER MinFreeTB
    Espace minimum à conserver sur T: (sécurité). Par défaut 1.5 To.

.PARAMETER SleepMinutes
    Temps d'attente quand il n'y a pas assez de place. Par défaut 10 minutes.

.PARAMETER Threads
    Nombre de threads robocopy. Par défaut 12.

.EXAMPLE
    .\Copy-Syzygy-SpaceAware.ps1 -MinFreeTB 1.0 -SleepMinutes 5 -Threads 16
#>

[CmdletBinding()]
param(
    [double]$MinFreeTB = 1.5,
    [int]$SleepMinutes = 10,
    [int]$Threads = 12
)

$Sources = @(
    # === Priorité haute (les splits S: que tu as mentionnés) ===
    "S:\6v1_pawnless",
    "S:\6v1_pawnful",
    "S:\5v2_pawnless",
    "S:\5v2_pawnful",
    "S:\4v3_pawnless_ManyMissing",
    "S:\Syzygy",                    # contient aussi 3-6men

    # === Autres gros dossiers ===
    "A:\Syzygy",
    "A:\Syzygy_A_Trier_FromOld_Ryzen7950"
)

$Target = "T:\Syzygy"
$LogDir = Join-Path $PSScriptRoot "logs"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

$StateFile = Join-Path $LogDir "Syzygy-Copy-SpaceAware.state.json"

function Get-FreeTB {
    try {
        return (Get-PSDrive -Name T -ErrorAction Stop).Free / 1TB
    } catch {
        return 0
    }
}

function Write-Log($Message) {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] $Message"
    Add-Content -Path (Join-Path $LogDir "Syzygy-Copy-SpaceAware.log") -Value $line
    Write-Host $line -ForegroundColor Cyan
}

function Load-State {
    if (Test-Path $StateFile) {
        return Get-Content $StateFile | ConvertFrom-Json
    }
    return @{}
}

function Save-State($State) {
    $State | ConvertTo-Json -Depth 5 | Set-Content -Path $StateFile -Encoding UTF8
}

Write-Log "=== Lancement du copieur Syzygy space-aware ==="
Write-Log "Objectif : T:\Syzygy | Seuil minimum : $MinFreeTB To | Sleep : $SleepMinutes min"

$State = Load-State

while ($true) {
    $free = Get-FreeTB
    Write-Log "Espace libre sur T: $([math]::Round($free,2)) To"

    if ($free -lt $MinFreeTB) {
        Write-Log "Pas assez d'espace (< $MinFreeTB To). Pause de $SleepMinutes minutes..."
        Start-Sleep -Seconds ($SleepMinutes * 60)
        continue
    }

    # Trouver le prochain source qui a encore des fichiers à copier
    $nextSource = $null
    foreach ($src in $Sources) {
        if (-not (Test-Path $src)) { continue }

        $done = $State[$src] -eq "done"
        if ($done) { continue }

        # Vérifie s'il reste des fichiers Syzygy dans la source
        $remaining = Get-ChildItem -Path $src -Recurse -Include *.rtbw,*.rtbz -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($remaining) {
            $nextSource = $src
            break
        } else {
            $State[$src] = "done"
            Save-State $State
            Write-Log "Source terminée (vide ou déjà copiée) : $src"
        }
    }

    if (-not $nextSource) {
        Write-Log "Tous les dossiers sources ont été traités. Fin du script."
        break
    }

    Write-Log "Espace OK ($([math]::Round($free,2)) To). Copie de : $nextSource"

    $folderName = Split-Path $nextSource -Leaf
    $logFile = Join-Path $LogDir "robocopy-$folderName-$(Get-Date -Format yyyyMMdd_HHmmss).log"

    $robocopyArgs = @(
        $nextSource,
        $Target,
        "*.rtbw",
        "*.rtbz",
        "/E",
        "/COPY:DAT",
        "/R:3",
        "/W:5",
        "/MT:$Threads",
        "/LOG+:$logFile",
        "/TEE"
    )

    $process = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow
    $exitCode = $process.ExitCode

    if ($exitCode -lt 8) {
        Write-Log "Copie terminée avec succès pour $nextSource (code $exitCode)"
        $State[$nextSource] = "done"
        Save-State $State
    } else {
        Write-Log "Erreur pendant la copie de $nextSource (code $exitCode). On réessaiera plus tard."
        Start-Sleep -Seconds 60
    }

    Write-Log "Vérification de l'espace avant le prochain dossier..."
    Start-Sleep -Seconds 30
}

Write-Log "=== Script terminé ==="
