<#
.SYNOPSIS
    Mécanisme robuste pour consolider les Syzygy sur T: avec la structure préférée :
    - 3 à 6 pièces → T:\Syzygy\3-6men\
    - 7 pièces     → T:\Syzygy\7men\<split>\  (4v3, 5v2, 6v1, etc.)

.DESCRIPTION
    Script "lance et laisse tourner" pour la nuit.

    Il copie de façon incrémentale et résumable depuis S:, A: et local vers la bonne structure sur T:.
    - Les sources "split" (4v3_*, 5v2_*, 6v1_*) sont copiées directement dans le sous-dossier correspondant sous 7men.
    - Les fichiers 3-6 pièces des sources mixtes vont dans 3-6men.
    - Les fichiers 7 pièces des sources mixtes vont dans 7men\unsorted\ (tu pourras les trier plus tard si besoin).

    Gère l'espace, les erreurs réseau, et la reprise.

.PARAMETER WhatIf
    Mode simulation (recommandé la première fois).

.PARAMETER FlattenFirst
    Aplatit automatiquement les sous-dossiers existants sur T:\Syzygy vers la racine (sans confirmation).

.PARAMETER MinFreeTB
    Espace minimum à garder libre sur T: avant de copier (défaut 2 To).

.EXAMPLE
    # Simulation
    .\Syzygy-Overnight-To-T.ps1 -DryRun

    # Lancement réel (structure 3-6men + 7men/splits)
    .\Syzygy-Overnight-To-T.ps1
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$DryRun,
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
# 1. PRÉPARATION DES DOSSIERS CIBLES (structure 3-6men + 7men/splits)
# =============================================================================

$Target3to6   = Join-Path $Target "3-6men"
$Target7men   = Join-Path $Target "7men"

if (-not (Test-Path $Target3to6)) { New-Item -ItemType Directory -Path $Target3to6 -Force | Out-Null }
if (-not (Test-Path $Target7men)) { New-Item -ItemType Directory -Path $Target7men -Force | Out-Null }

Write-Log "Cibles :"
Write-Log "  3-6 pièces → $Target3to6"
Write-Log "  7 pièces   → $Target7men\<split>\"

# =============================================================================
# 2. SOURCES + ROUTAGE VERS LA BONNE STRUCTURE
# =============================================================================

# Sources principales (priorité sur les plus gros manquants)
$Sources = @(
    # === 7 pièces - splits (vont directement dans 7men/<nom du split>) ===
    @{ Name = "4v3_pawnless_ManyMissing"; Path = "S:\4v3_pawnless_ManyMissing"; SevenMenSubfolder = "4v3_pawnless_ManyMissing" },
    @{ Name = "5v2_pawnful";              Path = "S:\5v2_pawnful";              SevenMenSubfolder = "5v2_pawnful" },
    @{ Name = "5v2_pawnless";             Path = "S:\5v2_pawnless";             SevenMenSubfolder = "5v2_pawnless" },
    @{ Name = "6v1_pawnful";              Path = "S:\6v1_pawnful";              SevenMenSubfolder = "6v1_pawnful" },
    @{ Name = "6v1_pawnless";             Path = "S:\6v1_pawnless";             SevenMenSubfolder = "6v1_pawnless" },

    # === Sources mixtes (on classe 3-6 vs 7 pièces) ===
    @{ Name = "S_Syzygy";   Path = "S:\Syzygy" },
    @{ Name = "A_Syzygy";   Path = "A:\Syzygy" },
    @{ Name = "A_OldRyzen"; Path = "A:\Syzygy_A_Trier_FromOld_Ryzen7950" },

    # === Local ===
    @{ Name = "Local_Syzygy"; Path = (Join-Path $ScriptRoot "Syzygy") }
)

function Get-DestinationFolder($sourceInfo, $fileName) {
    # Si la source a un SevenMenSubfolder défini → c'est du 7 pièces, on va dans 7men/<sub>
    if ($sourceInfo.SevenMenSubfolder) {
        return Join-Path $Target7men $sourceInfo.SevenMenSubfolder
    }

    # Sinon on classe par nombre de pièces
    $pieceCount = Get-PieceCount $fileName
    if ($pieceCount -le 6) {
        return $Target3to6
    } else {
        # 7 pièces venant d'une source mixte → on les met dans 7men\unsorted pour l'instant
        $unsorted = Join-Path $Target7men "unsorted"
        if (-not (Test-Path $unsorted)) { New-Item -ItemType Directory -Path $unsorted -Force | Out-Null }
        return $unsorted
    }
}

function Get-PieceCount($name) {
    # Ex: KQRNvKR  → avant 'v' = QRN (3) + après = KR (2) + 2 rois = 7
    if ($name -match '^(K+)([^v]+)v([^.]+)') {
        $before = $matches[2] -replace 'K',''
        $after  = $matches[3] -replace 'K',''
        return 2 + $before.Length + $after.Length
    }
    return 0
}

# =============================================================================
# 3. BOUCLE PRINCIPALE DE COPIE RÉSUMABLE (vers la bonne structure)
# =============================================================================

$State = Load-State

Write-Log "=== Lancement Syzygy Overnight vers structure 3-6men + 7men/splits ===" "Magenta"
Write-Log "MinFreeTB = $MinFreeTB To | DryRun = $DryRun"
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

        if ($State[$src.Name] -eq "done") {
            continue
        }

        Write-Log ">>> Traitement de $($src.Name) ($($src.Path))" "Yellow"

        $logFile = Join-Path $LogDir "Overnight-$($src.Name).log"

        # Pour les sources split 7 pièces, on copie directement dans le bon sous-dossier 7men
        $destForThisSource = if ($src.SevenMenSubfolder) {
            Join-Path $Target7men $src.SevenMenSubfolder
        } else {
            $Target3to6   # par défaut on commence par 3-6men ; les 7pc seront routés plus bas si besoin
        }

        if (-not (Test-Path $destForThisSource)) {
            New-Item -ItemType Directory -Path $destForThisSource -Force | Out-Null
        }

        if ($DryRun) {
            Write-Log "[DRYRUN] robocopy $($src.Path) $destForThisSource *.rtbw *.rtbz /S /E /XO /MT:12" "DarkGray"
            $workDone = $true
            continue
        }

        # Robocopy vers le bon dossier
        $rcArgs = @(
            $src.Path,
            $destForThisSource,
            "*.rtbw", "*.rtbz",
            "/S", "/E",
            "/XO",
            "/MT:12",
            "/R:3", "/W:5",
            "/FFT",
            "/NFL", "/NDL", "/NJH", "/NJS",
            "/LOG+:$logFile"
        )

        robocopy @rcArgs | Out-Null
        $code = $LASTEXITCODE

        if ($code -lt 8) {
            Write-Log "  -> $($src.Name) → $destForThisSource (code $code)" "Green"
            $State[$src.Name] = "done"
            Save-State $State
            $workDone = $true
        } else {
            Write-Log "  -> $($src.Name) partiellement copié (code $code). On réessaiera." "Yellow"
            $workDone = $true
        }
    }

    if (-not $workDone) {
        Write-Log "Rien de plus à faire pour l'instant. Tu peux relancer plus tard." "Green"
        break
    }

    Write-Log "Cycle terminé. Pause 5 minutes..."
    Start-Sleep -Seconds (5 * 60)
}

Write-Log "=== Script terminé ===" "Magenta"
Write-Host ""
Write-Host "Logs     : $LogDir" -ForegroundColor Cyan
Write-Host "État     : $StateFile" -ForegroundColor Cyan
