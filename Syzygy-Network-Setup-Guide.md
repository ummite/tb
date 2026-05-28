# Guide : Organiser tes fichiers Syzygy sur réseau

Tu as plusieurs répertoires Syzygy (local + réseau). Ce guide t'explique comment tout mettre proprement en place.

---

## Ce que disent les conventions sur le net (recherche 2026)

J'ai cherché les pratiques réelles dans l'écosystème Syzygy (Lichess, Stockfish, Fishnet, python-chess, chessprogramming.org, miroirs chessdb.cn, forums).

### 1. Le standard de facto : dossier plat (flat)

**C'est de très loin l'organisation la plus courante et recommandée.**

- "Unzip everything into the same directory"
- Exemples typiques : `C:\Tablebases\Syzygy`, `D:\Syzygy`, `/mnt/syzygy`
- Tous les fichiers `*.rtbw` et `*.rtbz` directement dedans, **sans sous-dossiers**.
- Avantages : un seul chemin `RTBPATH` / `SyzygyPath`, zéro erreur, scripts simples, compatible avec presque tous les engines et GUIs.

### 2. Support natif de plusieurs dossiers (très répandu)

Presque tous les bons probers acceptent **plusieurs répertoires** :

- **Stockfish** (et dérivés) : `SyzygyPath` accepte plusieurs chemins séparés par `;` (Windows) ou `:` (Linux).
  Exemple officiel : `C:\tb\wdl345;C:\tb\wdl6;D:\tb\dtz345;D:\tb\dtz6`
- **Fishnet** (bot Lichess) : même syntaxe que Stockfish.
- **python-chess** : `chess.syzygy.open_tablebase(dir1)` puis `.add_directory(dir2)`.

Cas d'usage classiques :
- WDL sur SSD rapide + DTZ sur HDD (gros gain de perf).
- Séparer les 3-6 pièces des 7 pièces (très gros volumes).
- Splits WDL/DTZ.

### 3. D'où viennent tes splits (5v2_pawnful, 4v3_..., 3-6men) ?

**Ce sont des artefacts de distribution des gros miroirs**, pas une structure runtime recommandée.

Le principal miroir pour les 7 pièces (Bojun Guo, auteur des 7pc Syzygy) sur chessdb.cn organise les releases comme ça :

- `3-6men/`
- `7men/4v3_pawnful/` (environ 12 To !)
- `7men/4v3_pawnless/`
- `7men/5v2_pawnful/`
- `7men/5v2_pawnless/`
- `7men/6v1_pawnful/`
- `7men/6v1_pawnless/`

C'est exactement la structure que tu vois sur S: (5v2_pawnful, 5v2_pawnless, 4v3_pawnless_ManyMissing, 6v1_*, 3-6men).

**Pourquoi ?** Pour rendre les downloads de ~17 To gérables en chunks séparés. Ce n'est **pas** une structure conçue pour le probing.

**Important** : le code de probing Syzygy ne scanne **pas** récursivement les sous-dossiers. Si tu gardes ces splits, il faut lister **explicitement** chaque sous-dossier dans `SyzygyPath`.

### 4. Structures "3-6men" + "7men" (courantes pour les grosses collections)

Lichess et les outils qui l'utilisent (Fishnet, etc.) distribuent souvent :
- Les 3-6 pièces comme un bloc "3-6men".
- Les 7 pièces séparément (volume énorme).

Beaucoup d'utilisateurs ont alors :
- `Syzygy/3-6men/`
- `Syzygy/7men/`
- `SyzygyPath = D:\Syzygy\3-6men;D:\Syzygy\7men`

C'est une bonne pratique quand on a des milliers de 7pc.

---

## Recommandation pour toi (avec 2000+ fichiers dispersés)

### Options de structure cible

**Option A (recommandée pour commencer)** : **WorkingDir plat + dédup par nom de fichier**

- Tous les fichiers uniques dans un seul dossier (ex: `D:\Syzygy\`).
- Le script `Syzygy-Setup.ps1` fait exactement ça (hardlinks, déduplication par nom).
- Avantages : un seul `RTBPATH`, simplicité maximale, facile à générer dedans, compatible partout.
- C'est l'approche majoritaire chez les utilisateurs qui veulent "juste que ça marche".

**Option B** : Structure style Lichess / gros miroirs (`3-6men/` + `7men/`)

- `D:\Syzygy\3-6men\` (tous tes 3-6pc)
- `D:\Syzygy\7men\` (tous tes 7pc, ou sous-splits si tu veux)
- Puis `SyzygyPath = D:\Syzygy\3-6men;D:\Syzygy\7men`
- Avantage : plus proche des miroirs officiels, plus facile à synchroniser plus tard avec de nouveaux 7pc.
- Un peu plus de complexité pour le probing.

**Option C** : Split WDL / DTZ (perf avancée)

- `D:\Syzygy\WDL\` + `D:\Syzygy\DTZ\`
- `SyzygyPath = D:\Syzygy\WDL;D:\Syzygy\DTZ`
- Utile si tu veux mettre les WDL sur un SSD rapide et les DTZ sur un gros HDD.

---

### Recommandation concrète

Pour l'instant, **choisis Option A** (plat). C'est ce que le script fait déjà, c'est le plus simple, et tu pourras toujours restructurer plus tard.

Le script `Syzygy-Setup.ps1` va agréger tout via des liens (idéalement HardLink) dans ton dossier de travail.

### Situation actuelle (détectée sur ta machine)

- **A:** → `\\ds1817\IA`
  - `A:\Syzygy` (dossier principal)
  - `A:\Syzygy_A_Trier_FromOld_Ryzen7950` → **1751 fichiers** (beaucoup de 6pc et 7pc !)

- **F:** → `\\ds1821\18TBExt2`
- **I:** → `\\ds1817\Important`
- **S:** → `\\ds1821\2x10TB RAID0` (plein de Syzygy : 3-6men/, 5v2_*, 6v1_*, 4v3_*)
- **T:** → `T:\Syzygy\3-6men` (1020 fichiers, ~150 GB, même contenu que S:\Syzygy\3-6men — probablement une copie)
  - Si tu as d'autres dossiers Syzygy sur T: (surtout 7pc), dis-le-moi pour les ajouter.
- Dossier local du projet : `Syzygy\` (contient surtout des 3-5pc)

### Étape 1 : Choisir ton disque cible + lancer le setup

1. Choisis un bon `WorkingDir` sur un disque **rapide** (SSD/NVMe idéalement) :
   - `D:\Syzygy`
   - `E:\Chess\Syzygy`
   - `F:\Syzygy` (si F: est rapide chez toi)
2. Ouvre `Syzygy-Setup.ps1` (j'ai déjà pré-rempli tous tes chemins A:, S:, local, etc.).
3. Lance (en PowerShell **en tant qu'administrateur** pour les liens symboliques) :

```powershell
.\Syzygy-Setup.ps1 -WorkingDir D:\Syzygy -LinkType HardLink
```

Ou en mode simulation d'abord (recommandé pour voir ce qui va se passer) :

```powershell
.\Syzygy-Setup.ps1 -WorkingDir D:\Syzygy -LinkType HardLink -WhatIf
```

### Recommandation de LinkType

- **HardLink** (défaut) : idéal si tout est sur le même volume. Zéro espace supplémentaire.
- **SymbolicLink** : plus flexible (fonctionne mieux entre disques différents), mais nécessite les droits admin.
- **Copy** : si tu veux des copies physiques (plus lent et prend de la place).

### Étape 2 : Utiliser le dossier de travail

Après le setup :

```powershell
# Définir l'environnement pour cette session
$env:RTBPATH = "D:\Syzygy"

# Vérifier l'état
.\Syzygy-Status.ps1 -Path "D:\Syzygy"

# Continuer la génération des 5 pièces manquantes
.\Syzygy-Generate.ps1 -FiveOnly -Destination "D:\Syzygy" -Threads 12 -Disk -Verify
```

## Astuces

- Le script `Syzygy-Setup.ps1` est idempotent : tu peux le relancer plus tard quand tu ajoutes de nouveaux fichiers sur tes NAS.
- Une fois tout centralisé dans `D:\Syzygy`, tu n'as plus qu'à pointer tes moteurs d'échecs sur ce dossier.
- Si tu as beaucoup de 6pc/7pc dans le dossier "A_Trier", tu peux les inclure progressivement.

## Besoin d'aide supplémentaire ?

**Mise à jour importante (mai 2026)** : Tu as décidé de faire de **T:** le dépôt maître unique pour tous les Syzygy.

→ Lis le plan complet et les scripts dédiés ici : **[Syzygy-T-Master-Plan.md](Syzygy-T-Master-Plan.md)**

Les deux scripts clés créés pour ça :
- `Move-Plots-T-to-F.ps1` → vide les 358 fichiers plot* (~35.4 To) de T: vers F: (libère l'espace)
- `Syzygy-Consolidate-To-T.ps1` → rapatrie tout vers `T:\Syzygy` une fois l'espace libéré

---

Dis-moi où tu en es :
- Tu veux lancer la simulation du déplacement des plots tout de suite ?
- Tu as déjà commencé à bouger des plots manuellement ?
- Tu veux que je raffine les scripts (ex: support pour d'autres gros fichiers à déplacer en même temps, ou meilleure gestion des 7pc) ?

Je reste disponible pour piloter les passes une par une.