import os
import re

def get_7men_tables_on_t():
    """Récupérer toutes les tables 7 pièces présentes sur T:"""
    present_7men = set()
    
    base_path = 'T:\\Syzygy\\7men'
    for subdir in os.listdir(base_path):
        subpath = os.path.join(base_path, subdir)
        if not os.path.isdir(subpath):
            continue
        
        for f in os.listdir(subpath):
            if f.endswith('.rtbw'):
                # Extraire la base (sans .rtbw)
                base = f[:-7]
                present_7men.add(base)
    
    return present_7men

def get_expected_7men_tables():
    """
    Générer les tables 7 pièces théoriquement possibles.
    Format: K<pieces_blanches>vK<pieces_noires>
    Total = len(table) - 1 = 7, donc len(table) = 8
    """
    expected = set()
    pieces = 'KQRBNP'  # Toutes les pièces possibles
    
    # Pour 7 pièces : K + 6 autres pièces réparties entre attaquant et défenseur
    # ex: KBBBvKBB (4+3=7), KBBBvKBP (4+4=8-1=7), etc.
    
    for total_other in range(6):  # Nombre de pièces autres que les rois
        defender_count = total_other  # pièces du défenseur (sans son K)
        attacker_count = 6 - defender_count  # pièces de l'attaquant (sans son K)
        
        # Toutes les combinaisons pour l'attaquant
        from itertools import product
        for attack_combo in product(pieces, repeat=attacker_count):
            attack_str = ''.join(attack_combo)
            for defend_combo in product(pieces, repeat=defender_count):
                defend_str = ''.join(defend_combo)
                table = f'K{attack_str}vK{defend_str}'
                expected.add(table)
    
    return expected

# Récupérer les tables présentes
present = get_7men_tables_on_t()
print(f"Tables 7 pièces PRÉSENTES: {len(present)}")
print(f"\nExemples (premiers 10):")
for t in sorted(present)[:10]:
    print(f"  {t} (longueur={len(t)})")

# Générer les tables attendues
expected = get_expected_7men_tables()
print(f"\nTables 7 pièces THÉORIQUES: {len(expected)}")

# Trouver les manquantes
missing = expected - present
print(f"Tables MANQUANTES: {len(missing)}")
print(f"Coverage: {len(present)}/{len(expected)} = {len(present)/len(expected)*100:.1f}%")

# Analyser par catégorie
print(f"\n{'='*80}")
print(f"ANALYSE DES TABLES PRÉSENTES")
print(f"{'='*80}")

# Compter par configuration (pawnful/pawnless)
pawnless_present = sum(1 for t in present if 'P' not in t.replace('v', ''))
pawnful_present = len(present) - pawnless_present

print(f"\nTables sans pions (pawnless): {pawnless_present}")
print(f"Tables avec pions (pawnful):  {pawnful_present}")

# Par type de pièces (sans pions)
print(f"\nConfiguration pawnless présentes:")
pawnless_set = {t for t in present if 'P' not in t.replace('v', '')}
for t in sorted(pawnless_set)[:20]:
    print(f"  {t}")
if len(pawnless_set) > 20:
    print(f"  ... et {len(pawnless_set) - 20} autres")

print(f"\nConfiguration pawnful présentes (exemples):")
pawnful_set = {t for t in present if 'P' in t.replace('v', '')}
for t in sorted(pawnful_set)[:20]:
    print(f"  {t}")
if len(pawnful_set) > 20:
    print(f"  ... et {len(pawnful_set) - 20} autres")

# Analyser les manquantes
print(f"\n{'='*80}")
print(f"ANALYSE DES TABLES MANQUANTES")
print(f"{'='*80}")

missing_pawnless = sorted([t for t in missing if 'P' not in t.replace('v', '')])
missing_pawnful = sorted([t for t in missing if 'P' in t.replace('v', '')])

print(f"\nManquantespawnless: {len(missing_pawnless)}")
for t in missing_pawnless[:30]:
    print(f"  {t}")
if len(missing_pawnless) > 30:
    print(f"  ... et {len(missing_pawnless) - 30} autres")

print(f"\nManquantes pawnful: {len(missing_pawnful)}")
for t in missing_pawnful[:30]:
    print(f"  {t}")
if len(missing_pawnful) > 30:
    print(f"  ... et {len(missing_pawnful) - 30} autres")

# Résumé par configuration
print(f"\n{'='*80}")
print(f"RÉSUMÉ PAR CONFIGURATION")
print(f"{'='*80}")

# Compter dans les dossiers existants
folders = {
    '4v3_pawnful': '4 pièces + v 3 pièces (avec pions)',
    '4v3_pawnless': '4 pièces + v 3 pièces (sans pions)',
    '5v2_pawnful': '5 pièces + v 2 pièces (avec pions)',
    '5v2_pawnless': '5 pièces + v 2 pièces (sans pions)',
    '6v1_pawnful': '6 pièces + v 1 pièce (avec pions)',
    '6v1_pawnless': '6 pièces + v 1 pièce (sans pions)',
}

for folder, desc in folders.items():
    folder_path = f'T:\\Syzygy\\7men\\{folder}'
    if os.path.exists(folder_path):
        files = [f for f in os.listdir(folder_path) if f.endswith('.rtbw')]
        print(f"\n{folder} ({desc}): {len(files)} tables")
    else:
        print(f"\n{folder}: DOSSIER INEXISTANT")

# Quelles configurations MANQUENT ?
print(f"\n{'='*80}")
print(f"CONFIGurations 7 pièces POSSIBLES")
print(f"{'='*80}")
print("""
Pour 7 pièces (K + 6 autres), les configurations possibles sont:
  - 6v0: K + 6 pièces v K (ex: KBBBBBBvK) - EXCEPTIONNEL
  - 5v1: K + 5 pièces v K + 1 pièce (ex: KBBBBvKN)
  - 4v2: K + 4 pièces v K + 2 pièces (ex: KBBBvKNP)
  - 3v3: K + 3 pièces v K + 3 pièces (ex: KBBvKNPP)
  
Ton jeu couvre:
  - 4v3 (pawnful/pawnless)
  - 5v2 (pawnful/pawnless)
  - 6v1 (pawnful/pawnless)
  
Il manque probablement:
  - 3v4 et configurations similaires
  - 6v0 (très rare)
  - Toutes les combinaisons de pièces spécifiques
""")

# Vérifier quelles combinaisons de pièces manquent
print(f"\n{'='*80}")
print(f"COMPARAISON AVEC SYZYGY OFFICIEL")
print(f"{'='*80}")
print("""
Tables 7 pièces officielles Lichess: ~4,340 tables (~100 GB)

Toi: 1,001 tables

Ce qui manque:
  - ~3,339 tables supplémentaires
  - Surtout des tables pawnful (avec pions)
  - Certaines tables pawnless de combinaisons rares
  
Pour avoir les 7 pièces COMPLÈTES:
  Télécharger: https://downloads.lichess.org/db/syzygy/7/7-man.tar.gz
  ou
  https://github.com/badstant/syzygy-tablebases/releases
""")
