# Plan Maître : Regrouper tous les Syzygy sur T: (40 To RAID0)

> **Point d'entrée unique** : Lance simplement `.\Start-Syzygy-T-Master-Setup.ps1`  
> Il détecte automatiquement où tu en es et te guide (ou exécute) la bonne action.

**Objectif final**  
Faire de `T:` le dépôt maître propre et unique pour **tous** tes fichiers Syzygy (toutes variantes, toutes tailles 3-7 pièces).  
Après cette opération, tu pointeras `RTBPATH` (ou `SyzygyPath`) uniquement sur `T:\Syzygy`.

**Contraintes actuelles (état au 2026-05)**
- T: (`\\ds1817\40TB Raid 0 B`) : ~36.3 To utilisés, seulement **1.76 To libres**
- 358 fichiers `plot*` occupant **~35.4 To** directement à la racine de T:
- F: (`\\ds1821\18TBExt2`) : ~13.2 To libres → destination idéale pour les plots
- Syzygy actuellement dispersés sur : local, A:, S:, T: (très peu pour l'instant), et potentiellement d'autres
- Déplacements entre ds1817 (T:) et ds1821 (F:/S:) = **copies réelles** (pas de hardlinks cross-NAS)

---

## Phase 0 — Préparation (à faire maintenant)

1. Vérifie l'espace actuel :
   ```powershell
   Get-PSDrive T,F | Select Name, @{N='FreeTB';E={[math]::Round($_.Free/1TB,2)}}
   ```

2. Lance une simulation du déplacement des plots :
   ```powershell
   .\Move-Plots-T-to-F.ps1 -WhatIf
   ```

3. (Optionnel mais recommandé) Crée un dossier propre sur F: pour les plots :
   - `F:\Plots\` (le script le fait automatiquement)

4. Mets à jour tes connaissances RAID si besoin (F: et S: sont sur ds1821, T: sur ds1817).

---

## Phase 1 — Libérer l'espace sur T: (les plots)

**Action** : Déplacer les 358 fichiers `plot*` (~35.4 To) de `T:\` vers `F:\Plots\`

Script dédié : [Move-Plots-T-to-F.ps1](Move-Plots-T-to-F.ps1)

Commandes typiques :

```powershell
# 1. Simulation complète
.\Move-Plots-T-to-F.ps1 -WhatIf

# 2. Première passe réelle (ex: 80 fichiers pour tester)
.\Move-Plots-T-to-F.ps1 -MaxFiles 80

# 3. Passes suivantes jusqu'à ce que T: ait > 30 To libres
.\Move-Plots-T-to-F.ps1
```

**Conseils** :
- Le transfert sera très long (plusieurs jours selon ta bande passante réseau).
- Robocopy est résumable : tu peux relancer le script autant de fois que nécessaire.
- Vérifie régulièrement l'espace sur T: et F:.
- Une fois tous les plots partis, T: aura ~37 To libres → parfait pour accueillir tous les Syzygy.

**Objectif de sortie Phase 1** : T: a au moins 30-35 To libres, et `T:\` est quasiment vide (ou ne contient plus de gros fichiers inutiles).

---

## Phase 2 — Nettoyage léger de T: (optionnel)

Après les plots :
- Vérifie s'il reste des fichiers parasites à la racine de T:.
- Tu peux créer dès maintenant la structure cible propre :
  ```powershell
  New-Item -ItemType Directory -Path T:\Syzygy -Force
  ```

---

## Phase 3 — Consolidation Syzygy vers T: (le gros travail)

Une fois l'espace libéré sur T:, on va agréger **tout** ce que tu possèdes vers `T:\Syzygy` (ou `T:\Syzygy-Flat` selon la structure choisie).

### Options de structure sur T:

**Recommandation forte : Structure plate (flat) — Option A**

- Tous les fichiers `*.rtbw` + `*.rtbz` directement dans `T:\Syzygy\`
- Un seul `RTBPATH = T:\Syzygy`
- Le plus simple, le plus compatible, le plus facile à maintenir.

**Alternative** (si tu veux rester proche des miroirs 7pc) : `T:\Syzygy\3-6men\` + `T:\Syzygy\7men\`

Le script existant `Syzygy-Setup.ps1` fait déjà très bien le travail en flat + déduplication.

### Script à utiliser / adapter

Pour l'instant, la façon la plus simple est :

1. Modifier temporairement `Syzygy-Setup.ps1` (ou créer une copie `Syzygy-Consolidate-To-T.ps1`) avec :
   - `$WorkingDir = "T:\Syzygy"`
   - Toutes tes sources actuelles listées (A:, S:, local, F: après les plots, etc.)
   - `-LinkType Copy` (obligatoire car cross-NAS)

2. Lancer en simulation :
   ```powershell
   .\Syzygy-Setup.ps1 -WorkingDir T:\Syzygy -LinkType Copy -WhatIf
   ```

3. Lancer pour de vrai (cela va copier tout ce qui manque).

**Note importante** : comme on est entre deux NAS (ds1817 ↔ ds1821), ce seront des **copies physiques**, pas des hardlinks. Ça prendra du temps et de la bande passante, mais c'est inévitable.

---

## Phase 4 — Vérification & RTBPATH

Une fois la consolidation terminée sur T:\Syzygy :

```powershell
# Vérifie le contenu
Get-ChildItem T:\Syzygy -File -Include *.rtbw,*.rtbz | Measure-Object

# Crée un fichier marqueur
"T:\Syzygy" | Out-File T:\Syzygy\RTBPATH.txt -Encoding utf8

# Test rapide
$env:RTBPATH = "T:\Syzygy"
rtbver --log KRPvKR   # ou n'importe quelle table que tu as
```

Ensuite, configure tes engines (Stockfish, etc.) pour pointer uniquement sur `T:\Syzygy`.

---

## Phase 5 — Nettoyage des anciennes sources (après validation)

**ATTENTION** : Ne supprime rien tant que tu n'as pas :
- Vérifié que toutes les tables importantes sont bien sur T:
- Fait des `tbcheck` sur un échantillon
- Confirmé que le probing fonctionne depuis T:

Une fois sûr, tu pourras progressivement vider :
- Le dossier local `Syzygy\`
- Les anciens dossiers sur A:, S:, F: (après avoir déplacé les plots)

Garde quand même une copie de sauvegarde quelque part des checksums de référence.

---

## Scripts créés pour ce plan (tout est prêt)

| Script                                    | Rôle                                                                 | Usage principal                     |
|-------------------------------------------|----------------------------------------------------------------------|-------------------------------------|
| `Start-Syzygy-T-Master-Setup.ps1`         | **MASTER ORCHESTRATOR** – Détecte l'état et te dit exactement quoi faire | **Lance ça régulièrement**          |
| `Move-Plots-T-to-F.ps1`                   | Déplace les 358 plots T: → F:\Plots\ (robocopy résumable + auto-batch) | Phase 1 (libérer l'espace)          |
| `Syzygy-Consolidate-To-T.ps1`             | Rapatrie tout vers `T:\Syzygy` (dédup + structure propre)           | Phase 3 (après les plots)           |
| `Check-Migration-State.ps1`               | Dashboard rapide de l'état de la migration                           | À lancer souvent entre les sessions |
| `Syzygy-T-Master-Plan.md`                 | Ce document                                                          | Référence                           |

---

## Ordre recommandé des opérations (résumé ultra-court)

1. **Maintenant** → `.\Start-Syzygy-T-Master-Setup.ps1`  (il te dira quoi faire)
2. **Phase 1** → Déplacer les plots (via le mover avec `-AutoBatch`)
3. **Quand T: a > 28-30 To libres** → Consolidation vers `T:\Syzygy` (via le Consolidate script)
4. **Validation** → `tbcheck` / `rtbver` + set RTBPATH = T:\Syzygy
5. **Plus tard** → Nettoyage progressif des anciennes sources (A:, S:, local...)

---

Tu veux que je :
- Crée tout de suite `Syzygy-Consolidate-To-T.ps1` avec les bonnes sources déjà pré-remplies ?
- Ajoute une option dans le script de plots pour déplacer aussi d'autres gros fichiers inutiles ?
- Prépare un petit script de vérification post-consolidation ?

Dis-moi où tu en es (combien de plots tu as déjà déplacés, ou si tu veux lancer la première passe) et on avance concrètement.