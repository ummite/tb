<#
.SYNOPSIS
    Mécanisme robuste "lance et laisse tourner" pour consolider tous les Syzygy sur T:\Syzygy (flat master).

.DESCRIPTION
    Ce script est conçu pour être lancé avant de partir le soir et laissé tourner toute la nuit.

    Il fait :
    1. (Optionnel) Aplatit la structure actuelle de T:\Syzygy (3-6men/, 7men/, etc.) vers la racine plate.
    2. Copie de façon incrémentale et résumable tous les fichiers manquants depuis les sources S: et A:.
    3. Priorise les gros splits 7 pièces (4v3, 5v2, 6v1).
    4. Gère l'espace disque, les verrous NAS, et les redémarrages.

    Cible finale recommandée : T:\Syzygy (dossier plat, sans sous-dossiers).

.PARAMETER WhatIf
    Mode simulation (recommandé la première fois).

.PARAMETER FlattenFirst
    Aplatit automatiquement les sous-dossiers existants sur T:\Syzygy vers la racine (sans confirmation).

.PARAMETER MinFreeTB
    Espace minimum à garder libre sur T: avant de copier (défaut 2 To).

.EXAMPLE
    # Test
    .\Syzygy-Overnight-To-T.ps1 -WhatIf

    # Lancement réel pour la nuit
    .\Syzygy-Overnight-To-T.ps1
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$WhatIf,
    [switch]$FlattenFirst,
    [double]$MinFreeTB = 2.0
)

$ErrorActionPreference = "Continue"
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$Target = "T:\Syzygy"
$LogDir = Join-Path $ScriptRoot "logs"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

$StateFile = Join-Path $LogDir "Syzygy-Overnight-To-T.state.json"
$MainLog   = Join-Path $LogDir "Syzygy-Overnight-To-T.log"

function Write-Log($Message, $Color = "Cyan") {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] $Message"
    Add-Content -Path $MainLog -Value $line -Encoding UTF8
    Write-Host $line -ForegroundColor $Color
}

function Get-FreeTB {
    try { return (Get-PSDrive -Name T -ErrorAction Stop).Free / 1TB } catch { return 0 }
}

function Load-State {
    if (Test-Path $StateFile) {
        return Get-Content $StateFile -Raw | ConvertFrom-Json -AsHashtable
    }
    return @{}
}

function Save-State($State) {
    $State | ConvertTo-Json -Depth 10 | Set-Content -Path $StateFile -Encoding UTF8
}

# =============================================================================
# 1. APPLATISSEMENT DE LA STRUCTURE ACTUELLE (si demandé)
# =============================================================================

if ($FlattenFirst -or (-not $WhatIf -and (Read-Host "Voulez-vous d'abord aplatir les sous-dossiers actuels de T:\Syzygy vers la racine ? (o/N)") -eq 'o')) {
    Write-Log "=== Phase 1 : Aplatissement de T:\Syzygy ===" "Magenta"

    $subfolders = Get-ChildItem -Path $Target -Directory -ErrorAction SilentlyContinue
    foreach ($folder in $subfolders) {
        Write-Log "Aplatissement de $($folder.FullName) vers $Target ..."
        if ($WhatIf) {
            Write-Log "[WHATIF] robocopy $($folder.FullName) $Target *.rtbw *.rtbz /MOV /E /MT:8" "DarkGray"
        } else {
            robocopy $folder.FullName $Target *.rtbw *.rtbz /MOV /E /MT:8 /R:2 /W:5 /NFL /NDL /NJH /NJS | Out-Null
            if ($LASTEXITCODE -lt 8) {
                Write-Log "  -> OK (dossier aplati)"
            } else {
                Write-Log "  -> Attention : code robocopy $LASTEXITCODE" "Yellow"
            }
        }
    }
    Write-Log "Aplatissement terminé." "Green"
}

# =============================================================================
# 2. SOURCES PRIORITAIRES (les plus importants d'abord)
# =============================================================================

$Sources = @(
    # === Priorité MAX : les plus gros et les plus incomplets ===
    @{ Name = "4v3_pawnless_ManyMissing"; Path = "S:\4v3_pawnless_ManyMissing" },
    @{ Name = "5v2_pawnful";              Path = "S:\5v2_pawnful" },
    @{ Name = "5v2_pawnless";             Path = "S:\5v2_pawnless" },
    @{ Name = "6v1_pawnful";              Path = "S:\6v1_pawnful" },
    @{ Name = "6v1_pawnless";             Path = "S:\6v1_pawnless" },

    # === Autres sources importantes ===
    @{ Name = "S_Syzygy";                 Path = "S:\Syzygy" },
    @{ Name = "A_Syzygy";                 Path = "A:\Syzygy" },
    @{ Name = "A_OldRyzen";               Path = "A:\Syzygy_A_Trier_FromOld_Ryzen7950" },

    # === Local (petits tableaux générés) ===
    @{ Name = "Local_Syzygy";             Path = (Join-Path $ScriptRoot "Syzygy") }
)

# =============================================================================
# 3. BOUCLE PRINCIPALE DE COPIE RÉSUMABLE
# =============================================================================

$State = Load-State

Write-Log "=== Lancement Syzygy Overnight Consolidate vers $Target ===" "Magenta"
Write-Log "MinFreeTB = $MinFreeTB To | WhatIf = $WhatIf"
Write-Host ""

while ($true) {
    $free = Get-FreeTB
    Write-Log "Espace libre sur T: $([math]::Round($free,1)) To"

    if ($free -lt $MinFreeTB) {
        Write-Log "Pas assez d'espace (< $MinFreeTB To). Pause 15 min..." "Yellow"
        Start-Sleep -Seconds (15 * 60)
        continue
    }

    $workDone = $false

    foreach ($src in $Sources) {
        if (-not (Test-Path $src.Path)) {
            Write-Log "Source introuvable : $($src.Path)" "Red"
            continue
        }

        $srcState = $State[$src.Name]
        if ($srcState -eq "done") {
            continue
        }

        Write-Log ">>> Traitement de $($src.Name) ($($src.Path))" "Yellow"

        $logFile = Join-Path $LogDir "Overnight-$($src.Name).log"

        if ($WhatIf) {
            Write-Log "[WHATIF] robocopy $($src.Path) $Target *.rtbw *.rtbz /S /E /XO /MT:12" "DarkGray"
            $workDone = $true
            continue
        }

        # Robocopy robuste + reprise
        $rcArgs = @(
            $src.Path,
            $Target,
            "*.rtbw", "*.rtbz",
            "/S", "/E",
            "/XO",                    # ne copie que les plus récents / manquants
            "/MT:12",
            "/R:3", "/W:5",
            "/FFT",                   # tolérance horloge NAS
            "/NFL", "/NDL", "/NJH", "/NJS",
            "/LOG+:$logFile"
        )

        $result = robocopy @rcArgs
        $code = $LASTEXITCODE

        if ($code -lt 8) {
            Write-Log "  -> $($src.Name) terminé ou à jour (code $code)" "Green"
            $State[$src.Name] = "done"
            Save-State $State
            $workDone = $true
        } else {
            Write-Log "  -> $($src.Name) partiellement copié (code robocopy $code). On réessaiera plus tard." "Yellow"
            $workDone = $true
        }
    }

    if (-not $workDone) {
        Write-Log "Tous les sources connus sont marqués 'done'. Rien de plus à faire pour l'instant." "Green"
        Write-Log "Tu peux relancer plus tard si de nouveaux fichiers arrivent sur S: ou A:." "Green"
        break
    }

    Write-Log "Cycle terminé. Pause 5 minutes avant prochaine vérification..."
    Start-Sleep -Seconds (5 * 60)
}

Write-Log "=== Script terminé ===" "Magenta"
Write-Host ""
Write-Host "Consulte les logs dans : $LogDir" -ForegroundColor Cyan
Write-Host "État de reprise     : $StateFile" -ForegroundColor Cyan
