# Système de vérification Syzygy

## But

Vérifier que le dépôt Syzygy maître (`T:\Syzygy`) contient exactement les **3022** fichiers
annoncés par les fichiers de référence de `C:\Programmation\tb-1\checksums\` :

| Fichier      | Entrées |
|--------------|---------|
| wdl345.txt   | 145     |
| dtz345.txt   | 145     |
| wdl6.txt     | 365     |
| dtz6.txt     | 365     |
| wdl7.txt     | 1001    |
| dtz7.txt     | 1001    |
| **Total**    | **3022**|

Le manifeste `C:\Programmation\tb-1\verification\expected-manifest.csv` (3022 lignes de données)
est généré par `Build-Manifest.ps1` : pour chaque table il donne le nom, le type (WDL/DTZ),
le nombre de pièces, le dossier attendu dans le dépôt et le MD5 attendu.

Mappage des dossiers : pièces 3-5 → `3-4-5\` ; 6 pièces → `6-WDL\` / `6-DTZ\` ; 7 pièces → `7-WDL\` / `7-DTZ\`.

## Les 4 modes

- **Presence** : scanne les 6 emplacements (racine + `3-4-5`, `6-WDL`, `6-DTZ`, `7-WDL`, `7-DTZ`), **sans récursion**. Classe chaque table : `PRESENT` / `WRONG_FOLDER` / `MISSING` ; les fichiers `.rtbw`/`.rtbz` extra (non listés dans le manifeste) sont signalés en avertissement sans affecter le code de sortie. Durée : quelques secondes.
- **Hash** : MD5 de chaque fichier (lecture streaming par blocs de 1 Mo, parallélisme `System.Threading.Tasks.Parallel.For`, chunks de 50 fichiers). **Reprenable** via `hash-state.csv`.
- **Full** : Presence puis Hash (continue même si Presence signale des manquements). Code de sortie = le plus mauvais des deux.
- **Report** : résumé de l'état hash (comptes par statut + dernier `verified_at`) et du dernier rapport Presence. **Aucun accès à `T:\Syzygy`.**

## Commandes

Générer le manifeste (à faire une fois, puis après toute modification de `checksums/`) :

```
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Programmation\tb-1\verification\Build-Manifest.ps1
```

Vérification de présence (rapide) :

```
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Programmation\tb-1\verification\Verify-Syzygy.ps1 -Mode Presence
```

Hash complet :

```
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Programmation\tb-1\verification\Verify-Syzygy.ps1 -Mode Hash -Parallel 4
```

Hash filtré (wildcard sur le nom) :

```
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Programmation\tb-1\verification\Verify-Syzygy.ps1 -Mode Hash -Only "KQvK*"
```

Re-hash des lignes déjà `OK` (et `MISMATCH`) : ajouter `-Force`.

Vérification complète (présence + hash) : `-Mode Full`.

Résumé local (sans accès au dépôt) : `-Mode Report`.

Options : `-Root` (défaut `T:\Syzygy`), `-Parallel` (défaut 4), `-Only` (filtre wildcard), `-StateFile`, `-Manifest`, `-ReportsDir`, `-Force`.

## Repreneabilité

L'état du hash est dans `C:\Programmation\tb-1\verification\hash-state.csv`
(en-tête : `name;expected_md5;actual_md5;status;verified_at` ; statuts `OK` / `MISMATCH` / `PENDING`).
Après chaque chunk de 50 fichiers, l'état complet est réécrit de façon atomique (fichier temporaire puis `Move-Item`).
**Relancer la même commande reprend exactement où on s'était arrêté** : les lignes `OK` sont
conservées (sauf avec `-Force`), seules les lignes `PENDING` (et `MISMATCH`) sont re-hachées.
Chaque exécution écrit aussi un rapport horodaté dans `C:\Programmation\tb-1\verification\reports\`
(`<yyyyMMdd-HHmmss>-presence.csv`, `<yyyyMMdd-HHmmss>-hash.csv`).

## Codes de sortie

| Code | Signification |
|------|---------------|
| 0 | OK — Presence : aucun manquant/mal placé ; Hash : tout est `OK` |
| 1 | Presence : au moins un `MISSING` ou `WRONG_FOLDER` ; Hash : au moins un `MISMATCH` ; Full : le plus mauvais des deux |
| 2 | Hash : des fichiers restent `PENDING` (exécution interrompue — relancer pour reprendre) |

## ⚠ Avertissement

Un hash MD5 complet lit **~17 TiB** sur SMB : cela prend **plusieurs jours**. Lancer en
arrière-plan, par exemple :

```
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','C:\Programmation\tb-1\verification\Verify-Syzygy.ps1','-Mode','Hash','-Parallel','4' -WindowStyle Hidden"
```

La vérification est repreneable : toute interruption (coupure réseau, arrêt de machine,
Ctrl+C) se reprend en relançant la même commande. Le dépôt `T:\Syzygy` est traité **en
lecture seule** ; toutes les écritures se font sous `C:\Programmation\tb-1\verification\`.
