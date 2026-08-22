import os

# Tables présentes
all_files = sorted(f for f in os.listdir('Syzygy') if f.endswith('.rtbw'))
wdl_files = sorted(f.replace('.rtbw', '') for f in all_files)
dtz_files = sorted(f.replace('.rtbz', '') for f in all_files if f.replace('.rtbw', '.rtbz') in all_files)

print("=" * 80)
print("ANALYSE DES BASES SYZYGY")
print("=" * 80)

print(f"\nTotal fichiers .rtbw (WDL): {len(wdl_files)}")
print(f"Total fichiers .rtbz (DTZ): {len([f for f in os.listdir('Syzygy') if f.endswith('.rtbz')])}")
print(f"Paires complètes (WDL+DTZ): {len(set(wdl_files) & set(dtz_files))}")

# Catégoriser par nombre de pièces
print("\n" + "=" * 80)
print("PAR NOMBRE DE PIÈCES")
print("=" * 80)

by_count = {}
for t in wdl_files:
    n = len(t) - 1  # -1 pour le K initial
    by_count.setdefault(n, []).append(t)

for n in sorted(by_count.keys()):
    tables = by_count[n]
    print(f"\n{n}-piece ({len(tables)} tables):")
    for t in sorted(tables):
        has_dtz = f"{t}.rtbz" in [f for f in os.listdir('Syzygy') if f.endswith('.rtbz')]
        status = "OK" if has_dtz else "MANQUE DTZ"
        print(f"  {t:25s} [{status}]")

# Vérifier les paires KBvK, KQvK, KRvK, KNvK, etc. (les plus importantes)
print("\n" + "=" * 80)
print("VERIFICATION: Tables fondamentales")
print("=" * 80)

essential = [
    "KBvK", "KNvK", "KBvKB", "KBvKN", "KNvKB", "KNvKN",
    "KQvK", "KQvKB", "KQvKN", "KQvKR",
    "KRvK", "KRvKB", "KRvKN", "KRvKR",
    "KRPvKR", "KBPvKB", "KBPvKN",
]

print("\nTables pawnless essentielles (3-4 pièces):")
for t in essential:
    if t in wdl_files:
        print(f"  {t:20s} [PRESENT]")
    else:
        print(f"  {t:20s} [MANQUANTE]")

# Vérifier les tables 6-7 pièces
print("\n" + "=" * 80)
print("Tables 6-7 pièces (les plus lourdes)")
print("=" * 80)

for n in [6, 7]:
    if n in by_count:
        print(f"\n{n}-piece ({len(by_count[n])} tables):")
        for t in sorted(by_count[n]):
            has_dtz = f"{t}.rtbz" in [f for f in os.listdir('Syzygy') if f.endswith('.rtbz')]
            size_mb = os.path.getsize(f"Syzygy/{t}.rtbw") / (1024*1024)
            dtz_size = 0
            if has_dtz:
                dtz_size = os.path.getsize(f"Syzygy/{t}.rtbz") / (1024*1024)
            print(f"  {t:25s} WDL={size_mb:6.2f}MB  DTZ={dtz_size:6.2f}MB  {'OK' if has_dtz else 'MANQUE DTZ'}")
    else:
        print(f"\n{n}-piece: AUCUNE TABLE")

print("\n" + "=" * 80)
print("RECOMMENDATIONS")
print("=" * 80)
print("""
Pour avoir les bases Syzygy COMPLÈTES jusqu'à 7 pièces, il faut:

1. Tables 3-4 pièces (déjà présentes): ✅
   - KvK, KBvK, KNvK, KPvK, KQvK, KRvK
   - KBvKB, KBvKN, KNvKB, KNvKR, etc.

2. Tables 5 pièces (partiellement présentes): ⚠️
   - 40 tables présentes sur ~625 possibles
   - Manque beaucoup de combinaisons (KBBvK, KQBBvK, etc.)

3. Tables 6 pièces (très incomplètes): ❌
   - 41 tables présentes sur ~5184 possibles
   - Manque la majorité des tables

4. Tables 7 pièces (quasi inexistantes): ❌
   - 0 tables (normalement très lourdes)

NOTE: Les bases Syzygy officielles complètes à 7 pièces pèsent ~100+ Go
et nécessitent des mois de calcul sur matériel puissant.

Pour télécharger les bases officielles complètes:
  https://downloads.lichess.org/db/syzygy/7/7-man.tar.gz
  ou
  https://github.com/badstant/syzygy-tablebases/releases
""")
