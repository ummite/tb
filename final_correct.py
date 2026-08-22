import os

def analyze_correct(path, label):
    """Analyse correcte avec comptage des pièces"""
    if not os.path.exists(path):
        return 0, 0
    
    wdl = [f for f in os.listdir(path) if f.endswith('.rtbw')]
    dtz = [f for f in os.listdir(path) if f.endswith('.rtbz')]
    
    # Les bases (sans extension)
    wdl_bases = [f[:-7] for f in wdl]  # enlever .rtbw
    dtz_bases = [f[:-7] for f in dtz]  # enlever .rtbz
    
    complete = sum(1 for b in wdl_bases if b in dtz_bases)
    
    # Compter par longueur de nom (nombre de pièces)
    piece_counts = {}
    for b in wdl_bases:
        n = len(b) - 1  # -1 pour le K initial
        piece_counts[n] = piece_counts.get(n, 0) + 1
    
    wdl_size = sum(os.path.getsize(os.path.join(path, f)) for f in wdl)
    dtz_size = sum(os.path.getsize(os.path.join(path, f)) for f in dtz)
    
    print(f"\n{label}")
    print(f"  WDL: {len(wdl):4d} fichiers ({wdl_size/(1024*1024):8.2f} MB)")
    print(f"  DTZ: {len(dtz):4d} fichiers ({dtz_size/(1024*1024):8.2f} MB)")
    print(f"  Paires completes: {complete:4d}")
    print(f"  Par nombre dePieces:")
    for n in sorted(piece_counts.keys()):
        print(f"    {n}-piece: {piece_counts[n]:4d} tables")
    
    return len(wdl), len(dtz)

print("="*80)
print("ANALYSE FINALE - BASES SYZYGY")
print("="*80)

total_wdl = 0
total_dtz = 0

# T:\Syzygy\3-6men
w, d = analyze_correct('T:\\Syzygy\\3-6men', "\nT:\\Syzygy\\3-6men")
total_wdl += w
total_dtz += d

# T:\Syzygy\7men sous-dossiers
for subdir in ['4v3_pawnful', '4v3_pawnless', '5v2_pawnful', '5v2_pawnless', 
               '6v1_pawnful', '6v1_pawnless']:
    path = f'T:\\Syzygy\\7men\\{subdir}'
    if os.path.exists(path):
        w, d = analyze_correct(path, f"\nT:\\Syzygy\\7men\\{subdir}")
        total_wdl += w
        total_dtz += d

# Local
w, d = analyze_correct('Syzygy', "\nSyzygy/ (local)")
total_wdl += w
total_dtz += d

print(f"\n{'='*80}")
print(f"TOTAL")
print(f"{'='*80}")
print(f"T: drive: {total_wdl} tables WDL + {total_dtz} tables DTZ")
print(f"Local:    80 tables")
print(f"\nNote: Les tables 3-6men sur T: sont un sous-ensemble different")
print(f"      du dossier local (redondance partielle)")
