# Reprise après panne — tb-1 / Syzygy (2026-07-10)

> **Document de reprise durable.**  
> Dernière mise à jour snapshot : **2026-07-12 ~09:05** (heure locale machine).  
> ✅ **CHANTIER HASH TERMINE — 3022/3022 fichiers validés, 0 mismatch.**

---

## 1. Où on en est (snapshot)

### 1.1 Chantier hash — ✅ TERMINE (38 fichiers réparés, 3022/3022 validés)

| Statut | Nb | Détail |
|--------|----|--------|
| **✅ OK (hash officiel)** | **38** | Tous les fichiers réparés et vérifiés |
| **BAD** | **0** | Plus aucun fichier corrompu |
| **MISMATCH** | **0** | Vérification officielle 3022/3022 PASS |

**Session 1 (2026-07-11, 18:20 → 04:20) :** 16 fichiers réparés, 1 interrompu (script tué à 10h)
- Log : `logs/syzygy-repair-20260711-182012.log`

**Session 2 (2026-07-12, 04:58 → 08:42) :** 3 fichiers réparés, 0 échec
- KBBPvKRN.rtbw (66.8 Go) — 06:07
- KQRPvKQR.rtbw (70.9 Go) — 07:03
- KRBNvKQP.rtbw (100.6 Go) — 08:41
- Log : `logs/syzygy-repair-20260712-045826.log`

**Vérification finale (2026-07-12, 09:00 → 09:02) :**
- `Verify-Syzygy-OfficialHashes.ps1 -Root T:\Syzygy`
- **3022 MATCH, 0 MISMATCH, 0 NO_EMBEDDED, 0 MISSING**
- Rapport : `logs/syzygy-hash-verify-20260712-090046.csv`

**Plan CSV :** `logs\syzygy-bad-hash-repair-plan.csv`  
**Snapshot OK/BAD :** `logs\syzygy-bad-hash-status-snapshot.csv`  
**Script de réparation :** `Repair-Syzygy-BadHashes.ps1`  
**Vérif hash :** `Verify-Syzygy-OfficialHashes.ps1`

#### Les 13 déjà OK (ne pas re-télécharger)

```
T:\Syzygy\3-6men\KBBNvKB.rtbz
T:\Syzygy\3-6men\KBBNvKN.rtbz
T:\Syzygy\3-6men\KBBNvKP.rtbz
T:\Syzygy\3-6men\KBBNvKQ.rtbw
T:\Syzygy\3-6men\KBBNvKR.rtbz
T:\Syzygy\3-6men\KBBPvKB.rtbw
T:\Syzygy\3-6men\KBBPvKN.rtbw
T:\Syzygy\3-6men\KBBPvKN.rtbz
T:\Syzygy\3-6men\KBBvK.rtbw
T:\Syzygy\3-6men\KBNvK.rtbw
T:\Syzygy\3-6men\KQvKR.rtbw
T:\Syzygy\7men\4v3_pawnful\KQNNvKQP.rtbz
T:\Syzygy\7men\4v3_pawnful\KRNPvKRP.rtbz
```

#### Les 25 encore BAD (ordre croissant de taille ≈ ordre de download du script)

| Fichier | Dest | ~Mo |
|---------|------|-----|
| KQQQRBvK.rtbz | T:\Syzygy\7men\6v1_pawnless\ | 302 |
| KQBBPPvK.rtbw | T:\Syzygy\7men\6v1_pawnful\ | 809 |
| KRNNNNvK.rtbz | T:\Syzygy\7men\6v1_pawnless\ | 1004 |
| KQQBBNvK.rtbz | T:\Syzygy\7men\6v1_pawnless\ | 1110 |
| KBBBBvKR.rtbz | T:\Syzygy\7men\5v2_pawnless\ | 1385 |
| KQRBBPvK.rtbw | T:\Syzygy\7men\6v1_pawnful\ | 3045 |
| KRBNNNvK.rtbz | T:\Syzygy\7men\6v1_pawnless\ | 3744 |
| KBBBNvKN.rtbz | T:\Syzygy\7men\5v2_pawnless\ | 5106 |
| KRBBNNvK.rtbz | T:\Syzygy\7men\6v1_pawnless\ | 5636 |
| KBBNNvKN.rtbz | T:\Syzygy\7men\5v2_pawnless\ | 7354 |
| KRBPvKBB.rtbw | T:\Syzygy\7men\4v3_pawnful\ | 18525 |
| KBNPvKRN.rtbz | T:\Syzygy\7men\4v3_pawnful\ | 22880 |
| KRBPvKBP.rtbw | T:\Syzygy\7men\4v3_pawnful\ | 25748 |
| KQRPvKQP.rtbw | T:\Syzygy\7men\4v3_pawnful\ | 28219 |
| KRRPvKQR.rtbz | T:\Syzygy\7men\4v3_pawnful\ | 28291 |
| KRBNvKNP.rtbw | T:\Syzygy\7men\4v3_pawnful\ | 30214 |
| KRBPvKBN.rtbw | T:\Syzygy\7men\4v3_pawnful\ | 30932 |
| KBBPvKRP.rtbw | T:\Syzygy\7men\4v3_pawnful\ | 37222 |
| KRBNvKBP.rtbz | T:\Syzygy\7men\4v3_pawnful\ | 49365 |
| KRBBvKQP.rtbw | T:\Syzygy\7men\4v3_pawnful\ | 50778 |
| KRBNvKRP.rtbw | T:\Syzygy\7men\4v3_pawnful\ | 54424 |
| KBNPvKRB.rtbz | T:\Syzygy\7men\4v3_pawnful\ | 62217 |
| KBBPvKRN.rtbw | T:\Syzygy\7men\4v3_pawnful\ | 66784 |
| KQRPvKQR.rtbw | T:\Syzygy\7men\4v3_pawnful\ | 70871 |
| KRBNvKQP.rtbw | T:\Syzygy\7men\4v3_pawnful\ | 100631 |

**Miroir officiel :** `http://tablebase.sesse.net/syzygy/`

| Pièces | Dossier Sesse |
|--------|----------------|
| ≤5 | `3-4-5/` |
| 6 WDL | `6-WDL/` |
| 6 DTZ | `6-DTZ/` |
| 7 WDL | `7-WDL/` |
| 7 DTZ | `7-DTZ/` |

Exemple : `http://tablebase.sesse.net/syzygy/7-DTZ/KQQQRBvK.rtbz`

**Job download (relancé 2026-07-10 ~06:21, script corrigé) :**
- Lanceur durable : `logs\run-hash-repair.bat`
- Watcher auto-restart : `logs\watch-hash-repair.ps1` → status live `logs\syzygy-repair-LIVE-STATUS.txt`
- Premier download validé : `KQQQRBvK.rtbz` hash **OK** (`ed1524a0…`)
- Vitesse observée ≈ **13–15 Mo/s** sur Sesse
- **Relancer est toujours sûr** : skip déjà OK + `curl -C -`

### 1.2 Drop (miroirs de couleur) — fait

- **76 fichiers** (`38` basenames × w+z) **supprimés** de `T:\Syzygy\3-6men\` (~143 Mo)
- Noms type `KvKQ`, `KvKRBN`, `KNvKQ`… = **non officiels**, inutiles pour Stockfish
- CSV : `logs\syzygy-redundant-flips.csv`
- `3-6men` : **1021** fichiers après purge (était 1097)

### 1.3 Code générateur — fait (validation canonique)

- `validate_tablename()` dans `src/util.c` + `util.h`
- Appelé depuis : `tbgen.c`, `tbgenp.c`, `tbver.c`, `tbverp.c`
- `src/run.py` : `is_canonical_tb()`
- Refuse : `KvKQ`, `KRvKQ`, mauvais ordre pièces, etc.
- Accepte : les **1511** noms officiels WDL
- Binaires rebuild : `bin\rtbgen.exe`, `bin\rtbgenp.exe` (MSVC Insiders)

### 1.4 Inventaire master T: (contexte)

- Master : `T:\Syzygy\` structure `3-6men\` + `7men\{4v3,5v2,6v1}_*` + `8men\` (vide)
- Validation inventaire (présence paires) ≠ validation hash — faite avant
- Official entries : **3022** fichiers listés dans `checksums/`
- Après fix hash : objectif **0 MISMATCH** sur `Verify-Syzygy-OfficialHashes.ps1`

### 1.5 Autres notes session

- VirtualTable 8pc : prototype prêt, **pas branché** dans hot path (`tbgenp.c` TODO)
- `7men` était vide au premier listing incorrect ; en fait **2002 fichiers** sous sous-dossiers
- Stockfish : ne lit **que** l’orientation officielle (flip au probe)

---

## 2. STATUT — ✅ TOUS LES CHANTIERS HASH SONT TERMINES

**Aucune action requise.** Tous les 38 fichiers corrompus ont été réparés et les 3022 fichiers Syzygy sont vérifiés conformes aux hashes officiels.

### Étape 0 — Disques

```powershell
Get-PSDrive T,A,S | Format-Table Name, @{N='FreeTB';E={[math]::Round($_.Free/1TB,2)}}
Test-Path T:\Syzygy, A:\Syzygy, S:\Syzygy
```

### Étape 1 — Voir ce qui reste BAD

```powershell
cd C:\Programmation\tb-1
# Option A : snapshot rapide
Import-Csv logs\syzygy-bad-hash-status-snapshot.csv | ? Status -ne 'OK'

# Option B : re-scan complet (recommandé après panne)
.\Verify-Syzygy-OfficialHashes.ps1 -Root T:\Syzygy
# → regarde MISMATCH dans logs\syzygy-hash-verify-*.txt
```

### Étape 2 — Nettoyer un download mort (si besoin)

```powershell
# Partiels orphelins
Get-ChildItem T:\Syzygy -Recurse -Filter *.repair-part
Get-ChildItem T:\Syzygy -Recurse -Filter *.repair-tmp

# Si un .repair-part est bloqué / 0 octets depuis longtemps : le laisser
# (curl -C - reprend) OU le supprimer pour repartir de zéro.
```

### Étape 3 — Relancer la réparation (idempotent)

```powershell
cd C:\Programmation\tb-1

# Reprend tout : skip OK, copie locale si dispo, sinon Sesse avec resume
.\Repair-Syzygy-BadHashes.ps1

# Session limitée (ex. 20 Go max cette nuit)
.\Repair-Syzygy-BadHashes.ps1 -MaxDownloadMB 20000

# Background (recommandé pour ~690 Go)
Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File C:\Programmation\tb-1\Repair-Syzygy-BadHashes.ps1' -WorkingDirectory C:\Programmation\tb-1 -WindowStyle Minimized
```

Le script :
1. Lit `logs\syzygy-bad-hash-repair-plan.csv` (ou `-Rescan`)
2. Skip si trailer == hash officiel
3. Prefers S:/A: local
4. Sinon `curl -L --fail --retry 5 -C - -o DEST.repair-part URL`
5. Vérifie hash → `Move-Item` vers dest finale

### Étape 4 — Quand les 25 sont finis

```powershell
.\Verify-Syzygy-OfficialHashes.ps1 -Root T:\Syzygy
# Attendu : MISMATCH = 0 pour les entrées officielles présentes
```

Mettre à jour ce fichier + `T:\Syzygy\STATE.md` : `Hash repair: COMPLETE`.

---

## 3. Ne pas faire

- Ne **pas** supprimer les 25 BAD tant que le download n’a pas réussi (occupe la place mais garde le chemin / taille de référence)
- Ne **pas** régénérer les 7pc monstrueux tant que Sesse répond (générateur 7pc = énorme RAM/temps)
- Ne **pas** remettre les Drop `KvK*` (inutiles ; générateur les refuse maintenant)
- Ne **pas** confondre inventaire « paires présentes » avec hash OK

---

## 4. Fichiers clés (carte mémoire)

| Fichier | Rôle |
|---------|------|
| `RESUME_AFTER_OUTAGE.md` | **Ce doc** — reprise panne |
| `Repair-Syzygy-BadHashes.ps1` | Réparation hash (local + Sesse) |
| `Verify-Syzygy-OfficialHashes.ps1` | Audit hash vs `checksums/` |
| `logs/syzygy-bad-hash-repair-plan.csv` | Liste des 38 + sources |
| `logs/syzygy-bad-hash-status-snapshot.csv` | OK/BAD snapshot |
| `logs/syzygy-redundant-flips.csv` | 38 drop (déjà purgés) |
| `logs/syzygy-repair-*.log` | Logs de réparation |
| `checksums/wdl*.txt` + `dtz*.txt` | Vérité officielle CityHash |
| `src/util.c` → `validate_tablename` | Interdit combos illégales |
| `T:\Syzygy\` | Master tables |
| `T:\Syzygy\STATE.md` | État agent / ops (à jour avec ce chantier) |
| `docs/8PC_DISK_DISTRIBUTED.md` | Chantier 8pc (autre fil) |

---

## 5. Checklist post-panne (copier-coller mental)

1. [ ] Disques T/A/S montés  
2. [ ] `Verify-Syzygy-OfficialHashes` ou snapshot → compter MISMATCH  
3. [ ] Lancer `Repair-Syzygy-BadHashes.ps1`  
4. [ ] Surveiller `logs\syzygy-repair-*.log` + `*.repair-part`  
5. [ ] Quand MISMATCH=0 → noter COMPLETE ici  
6. [ ] Ensuite seulement : autres chantiers (8pc VT, etc.)

---

## 6. Estimation temps restant

- ~**690 Go** sur Sesse pour les 25 restants  
- À 10 Mo/s ≈ **19 h** ; à 50 Mo/s ≈ **4 h**  
- Relançable à l’infini (idempotent + resume)

---

*Écrit pour survie panne électrique / crash session. Ne pas supprimer ce fichier tant que MISMATCH > 0.*
