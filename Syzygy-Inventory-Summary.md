# Inventaire actuel de tes Syzygy (mis à jour avec S:)

## Dossiers découverts

### A: (\\ds1817\IA)
- `A:\Syzygy`
- `A:\Syzygy_A_Trier_FromOld_Ryzen7950` → ~1751 fichiers (très riche en 6pc et 7pc)

### S: (\\ds1821\2x10TB RAID0) ← "plein de syzygy"
- `S:\Syzygy` + `S:\Syzygy\3-6men` → **1020 fichiers**
  - 3pc : 10
  - 4pc : 60
  - 5pc : 220
  - 6pc : 730

- `S:\5v2_pawnful` → 420 fichiers
- `S:\5v2_pawnless` → 280 fichiers
- `S:\6v1_pawnful` → 140 fichiers
- `S:\6v1_pawnless` → 112 fichiers
- `S:\4v3_pawnless_ManyMissing` → 400 fichiers

**Total estimé sur S: seul : plus de 2000+ fichiers Syzygy**

### T: (nouveau — ajouté par l'utilisateur)
- `T:\Syzygy\3-6men` → **1020 fichiers**, ~**150 GB**
  - 3pc : 10
  - 4pc : 60
  - 5pc : 220
  - 6pc : 730

  → **Identique** (même nombre et même répartition) à `S:\Syzygy\3-6men`.
  → Probablement une copie / backup / miroir du même set 3-6 pièces.

- Pas de 7pc ni d'autres splits (5v2_, 4v3_, 6v1_) découverts dans les scans rapides sur T: pour l'instant.

**Note** : Les scans complets récursifs sur tout T: sont très lents. Si tu as d'autres dossiers Syzygy sur T: (surtout des 7 pièces !), dis-le-moi pour que je les ajoute explicitement au script.

## D'où viennent tes splits actuels (5v2_pawnful, 4v3_..., 3-6men) ?

Ce sont **exactement** la structure des miroirs chessdb.cn (Bojun Guo, générateur des 7pc Syzygy) :

- 3-6men/
- 7men/4v3_pawnful (12 To !)
- 7men/4v3_pawnless
- 7men/5v2_pawnful
- 7men/5v2_pawnless
- 7men/6v1_pawnful
- 7men/6v1_pawnless

C'est fait pour **télécharger** 17 To en chunks gérables. Ce n'est **pas** une structure optimale pour le probing (le code ne scanne pas récursivement).

## Stratégie recommandée maintenant

1. Choisis un **dossier de travail final** sur un disque rapide local (ex: `D:\Syzygy` ou `E:\Syzygy`).
2. Lance `Syzygy-Setup.ps1` (j'ai déjà ajouté tous tes dossiers S: et A: dedans).
3. Le script va agréger tout via des liens (idéalement HardLink) **dans un dossier plat** (ou 3-6men/ + 7men/ selon ton choix).
4. Une fois fait, tu auras **un seul** `RTBPATH` propre et complet, avec presque tout ce que tu possèdes (surtout très bon en 5pc et 6pc).

**Voir le guide complet** : [Syzygy-Network-Setup-Guide.md](Syzygy-Network-Setup-Guide.md)

---

## Plan actuel : T: comme dépôt maître unique

Tu as demandé à :
1. Déplacer tous les `plot*` de T: → F: (pour libérer ~35 To)
2. Regrouper **tous** les Syzygy proprement sur T: (le gros volume RAID0)

→ Plan détaillé + scripts : **[Syzygy-T-Master-Plan.md](Syzygy-T-Master-Plan.md)**

Scripts prêts :
- `Move-Plots-T-to-F.ps1`
- `Syzygy-Consolidate-To-T.ps1`

État espace (dernière mesure) :
- T: 1.76 To libres (358 plots = 35.44 To)
- F: 13.19 To libres

L'opération se fera nécessairement en plusieurs passes à cause de l'espace.

## Commande à lancer

```powershell
# Exemple (adapte le WorkingDir selon ton disque le plus rapide)
.\Syzygy-Setup.ps1 -WorkingDir D:\Syzygy -LinkType HardLink
```

Ou en simulation d'abord :
```powershell
.\Syzygy-Setup.ps1 -WorkingDir D:\Syzygy -LinkType HardLink -WhatIf
```

Après ça tu pourras générer tes 5 pièces manquantes beaucoup plus facilement car tu auras toutes les sous-bases.

Veux-tu que je te fasse une version du script qui priorise les 5pc (pour finir rapidement ton set 5 pièces) ?
