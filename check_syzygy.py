import os
import itertools

# Tables présentes
all_tables = set(f.replace('.rtbw', '') for f in os.listdir('Syzygy') if f.endswith('.rtbw'))

# Générons toutes les tables théoriquement possibles pour 3-7 pièces
# Format: K<pièces_blanches>vK<pièces_noires>, total = n pièces
# Les rois sont toujours présents, on compte les autres pièces

pieces = 'KQRBNP'  # Pièces possibles (sans P pour simplifier, les pawnfuls sont séparés)
# Pour Syzygy standard, on a :
# 3 pièces: KvK (déjà fait, mais c'est trivial)
# 4 pièces: KBvK, KNvK, KPvK, KQvK, KRvK
# etc.

# En fait, la nomenclature Syzygy : K + attacking pieces + vK + defending pieces
# Total = longueur du string - 1 (le K initial)

# Générons tout ce qui est possible pour 3-7 pièces
defined = set()
for total_pieces in range(3, 8):  # 3 à 7 pièces
    # Attaquant a pièces, défenseur b pièces, a+b = total_pieces-1 (moins le roi commun)
    for attack_pieces in range(total_pieces - 1):
        defend_pieces = total_pieces - 1 - attack_pieces
        # Toutes les combinaisons de pièces pour l'attaquant
        for attack_combo in itertools.product('KQRBNP', repeat=attack_pieces):
            attack_str = ''.join(attack_combo)
            # Toutes les combinaisons pour le défenseur
            for defend_combo in itertools.product('KQRBNP', repeat=defend_pieces):
                defend_str = ''.join(defend_combo)
                table = f'K{attack_str}vK{defend_str}'
                defined.add(table)

print(f"Total tables théoriques (3-7 pièces): {len(defined)}")
print(f"Tables présentes: {len(all_tables)}")
missing = defined - all_tables
print(f"Tables manquantes: {len(missing)}")

# Regrouper par nombre de pièces
print("\n--- Manquantes par nombre de pièces ---")
for n in sorted(set(len(t) - 1 for t in missing)):
    n_piece_missing = sorted([t for t in missing if len(t) - 1 == n])
    print(f"{n}-piece: {len(n_piece_missing)} manquantes")
    for t in n_piece_missing[:10]:
        print(f"  {t}")
    if len(n_piece_missing) > 10:
        print(f"  ... et {len(n_piece_missing) - 10} autres")

print(f"\n--- Présentes par nombre de pièces ---")
for n in sorted(set(len(t) - 1 for t in all_tables)):
    n_piece_present = sorted([t for t in all_tables if len(t) - 1 == n])
    print(f"{n}-piece: {len(n_piece_present)} tables")
