# TODO — premier Syzygy 8 pièces lisible par Stockfish

État au 2026-11-10, PC `INTEL13900`. Aucun fichier 8 pièces n'a été généré. Ce document est le plan, pas un travail déjà fait.

## Ce qui est déjà vrai

- `C:\Programmation\tb-1\src\tbgen.vcxproj` et `C:\Programmation\tb-1\src\tbgenp.vcxproj` compilent le générateur régulier avec `TBPIECES=8`.
- Pour 7 pièces et plus, la table de travail passe par `alloc_mapped` dans `C:\Programmation\tb-1\src\util.c` : un fichier `tablename.tmpN.table` dans le répertoire courant, taille fixée par `SetEndOfFile`, projection mémoire, `FILE_FLAG_DELETE_ON_CLOSE`. Ce n'est pas le fichier de pagination Windows.
- `--use-vt` ne fait qu'une sonde de 1 Mio. `table_w` reste un pointeur dense. VirtualTable n'est pas un moyen de répartir la table sur plusieurs disques.
- Les 1001 WDL et 1001 DTZ 7 pièces sont lisibles sur `\\ds1817\40TB Raid 0 B\Syzygy\7-WDL` et `\\ds1817\40TB Raid 0 B\Syzygy\7-DTZ`. La lettre `T:` n'est pas montée sur ce PC.
- Stockfish, dans `C:\Programmation\tb-1\StockfishSrc\src\syzygy\tbprobe.cpp`, a `TBPIECES = 7`. `Tablebases::init` ne cherche aucun matériel à 8 pièces.

## Stockfish sur ce PC

La dernière version n'est pas là.

| Exemplaire | Version mesurée |
|---|---|
| `C:\Programmation\tb-1\bin\stockfish.exe` | `Stockfish dev-20260529-b1053e60` |
| `C:\Programmation\tb-1\bin\stockfish-tb8.exe` | le même identifiant UCI. Le nom ne veut pas dire que la sonde 8 pièces existe. |
| `C:\Programmation\tb-1\StockfishSrc` | même commit, 2026-05-29, dépôt git |
| `\\ds1817\40TB Raid 0 B\Stockfish\stockfish` | sources et binaire **Stockfish 18**, sans `.git` |
| Stable publique | **Stockfish 19**, 2026-09-05 |
| Dev public le plus récent vu le 2026-11-10 | `stockfish-dev-20261109-43e01e07` |

Visual Studio présent : VS 18 Community, MSBuild `C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe`.

## Quelle table 8 pièces coûte le moins

Dans ce générateur, le matériel ne change pas la taille de la table de travail. La réservation est dense, avant compression.

- Sans pion (`tbgen`, `C:\Programmation\tb-1\src\tbgen.c`) : `462 << (6 * (numpcs - 2))`. Pour 8 pièces : 31 768 398 272 512 octets par camp, **57,78 Tio pour les deux camps**.
- Avec pions (`tbgenp`, `C:\Programmation\tb-1\src\tbgenp.c`) : `6 << (6 * (numpcs - 1))`. Pour 8 pièces : 26 388 279 066 624 octets par camp, **48,00 Tio pour les deux camps**.

Toutes les tables pawnful 8 pièces se valent sur ce scratch. Toutes les pawnless se valent, et elles sont plus grosses. `KPPPPPPvK` n'est pas plus léger que `KQQQQQPvK`.

Le volume `\\ds1817\40TB Raid 0 B` fait 40 To. Il ne peut pas porter à lui seul un scratch de 48 Tio, encore moins le scratch plus les sous-tables et le fichier final. Il faut plusieurs disques agrégés, ou un autre volume d'au moins 50 To libres.

Premier candidat, à coût de scratch égal au plus bas : une table **pawnful** facile à contrôler, avec beaucoup de pièces identiques, dont les sous-tables 7 pièces sont déjà sur le NAS. Exemple : `KQQQQQPvK`. Le fichier compressé final sera bien plus petit que le scratch. On ne le saura qu'après génération.

## Scratch et fichier final

Aujourd'hui, non : on ne peut pas nommer un disque de scratch et un autre disque pour le `.rtbw` / `.rtbz`.

- Le scratch `*.tmpN.table` est créé dans le répertoire courant du processus. `SetEndOfFile` demande l'espace réel. Le fichier n'est pas sparse.
- Le `.rtbw` et le `.rtbz` sont écrits dans ce même répertoire.
- Lancer la génération depuis `C:` remplit le NVMe. Il ne faut pas le faire.
- Mettre le répertoire courant sur le SAN écrit le scratch et le final au même endroit, et le SAN est trop petit pour le scratch.

Pour économiser le NVMe sans modifier le code : créer sous Windows un volume agrégé (Espace de stockage ou volume fractionné) sur les gros disques choisis, avec au moins 50 To libres, et lancer `tbgenp` avec ce volume comme répertoire courant. Le NVMe ne sert alors qu'au système et au binaire. Le final reste sur ce volume. Le copier ensuite vers `\\ds1817\40TB Raid 0 B\Syzygy` est une copie, pas une écriture directe séparée.

Pour séparer vraiment scratch et SAN, il faut un changement de générateur, pas encore écrit :

- [ ] `--scratch DIR` : le fichier `tablename.tmpN.table` est créé dans `DIR`, pas dans le répertoire courant.
- [ ] `--output DIR` : les `.rtbw` et `.rtbz` sont créés dans `DIR`. Cible prévue : `\\ds1817\40TB Raid 0 B\Syzygy\8-WDL` et `\\ds1817\40TB Raid 0 B\Syzygy\8-DTZ`.
- [ ] Ne pas router `table_w` dans VirtualTable pour ce premier essai. Le cache n'est pas thread-safe et ne fournit pas de pointeur contigu.

Le fichier de pagination Windows n'est pas le bon outil : le générateur a déjà son propre fichier mappé.

## Ordre de travail

- [ ] Cloner `https://github.com/official-stockfish/Stockfish` sur un disque local, pas compiler à travers le SMB. Le dossier `\\ds1817\40TB Raid 0 B\Stockfish` peut recevoir une copie du dépôt ensuite. Ne pas écraser la copie Stockfish 18 déjà présente : autre sous-dossier, par exemple `\\ds1817\40TB Raid 0 B\Stockfish\stockfish-19`.
- [ ] Partir de Stockfish 19, ou du dev si on veut le dernier code. Le dev bouge chaque commit. Pour une base à modifier, taguer le commit choisi et le noter ici.
- [ ] Compiler avec Visual Studio 2026, profil déjà utilisé par le générateur : `/O2 /GL /LTCG /arch:AVX2`. Le `Makefile` officiel (`profile-build ARCH=x86-64-avx2`) reste la référence de perf. Un build MSVC « maximum » n'est pas automatiquement plus fort que ce profil. Mesurer les deux sur le même banc avant de garder l'un.
- [ ] Vérifier que ce binaire, sans patch 8 pièces, lit une table 7 pièces connue, par exemple `KBBBBBvK`, via `SyzygyPath` pointant explicitement vers `\\ds1817\40TB Raid 0 B\Syzygy\7-WDL` et `\\ds1817\40TB Raid 0 B\Syzygy\7-DTZ`. La sonde ne descend pas dans les sous-dossiers.
- [ ] Patch sonde, fichier `src\syzygy\tbprobe.cpp` de ce clone :
  - [ ] `TBPIECES` de 7 à 8, et tous les tableaux `pieces[TBPIECES]`, `groupIdx`, `groupLen`.
  - [ ] Une profondeur de plus dans les boucles de `Tablebases::init` (aujourd'hui elles s'arrêtent à 7 pièces).
  - [ ] `Binomial` au-delà de `k < 6`.
  - [ ] Pions de tête au-delà de 5 (`LeadPawnIdx`, `LeadPawnsSize`). Le commentaire actuel dit que 5 pions couvrent `KPPPPPK`.
  - [ ] Contrôler l'indexation d'une pièce supplémentaire dans `do_probe_table`, pas seulement l'inventaire des fichiers.
- [ ] Préparer le volume de scratch ≥ 50 To, hors NVMe.
- [ ] Générer une seule table pawnful, `KQQQQQPvK`, avec `RTBPATH` listant les dossiers 3–7 pièces, `-d`, peu de threads, répertoire courant sur le volume de scratch. Journal obligatoire via `C:\Programmation\tb-1\benchmarks\tb_benchmark.ps1`.
- [ ] `tbcheck` sur le `.rtbw` et le `.rtbz`. Il n'existe pas de référence officielle 8 pièces : le contrôle est l'intégrité du fichier, puis une position connue sondée par le Stockfish patché.
- [ ] Copier le fichier final vers le SAN seulement après `tbcheck`. Ne pas générer la suite des 8 pièces tant que cette première sonde n'a pas répondu juste.
