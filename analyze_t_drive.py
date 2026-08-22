import os

def analyze_directory(path, label):
    """Analyser un dossier de tables Syzygy"""
    if not os.path.exists(path):
        return {label: {'wdl': 0, 'dtz': 0, 'complete': 0}}
    
    wdl_files = [f for f in os.listdir(path) if f.endswith('.rtbw')]
    dtz_files = [f for f in os.listdir(path) if f.endswith('.rtbz')]
    
    wdl_bases = set(f.replace('.rtbw', '') for f in wdl_files)
    dtz_bases = set(f.replace('.rtbz', '') for f in dtz_files)
    complete = wdl_bases & dtz_bases
    
    # Par nombre de pièces
    by_pieces = {}
    for base in wdl_bases:
        n = len(base) - 1  # -1 pour le K initial
        by_pieces.setdefault(n, set()).add(base)
    
    total_wdl_size = sum(os.path.getsize(os.path.join(path, f"{b}.rtbw")) for b in wdl_bases)
    total_dtz_size = sum(os.path.getsize(os.path.join(path, f"{b}.rtbz")) for b in complete)
    
    print(f"\n{'='*80}")
    print(f"📁 {label}: {path}")
    print(f"{'='*80}")
    print(f"  WDL:  {len(wdl_files):6d} fichiers")
    print(f"  DTZ:  {len(dtz_files):6d} fichiers")
    print(f"  Complet (WDL+DTZ): {len(complete):6d} paires")
    print(f"  Taille: {total_wdl_size/(1024*1024):7.2f} MB WDL + {total_dtz_size/(1024*1024):7.2f} MB DTZ = { (total_wdl_size + total_dtz_size)/(1024*1024):7.2f} MB")
    
    print(f"\n  Par nombre de pièces:")
    for n in sorted(by_pieces.keys()):
        count = len(by_pieces[n])
        complete_n = sum(1 for b in by_pieces[n] if b in complete)
        print(f"    {n}-piece: {count:5d} tables ({complete_n:5d} complètes)")
    
    return {label: {'wdl': len(wdl_files), 'dtz': len(dtz_files), 'complete': len(complete)}}

print("="*80)
print("🔍 ANALYSE COMPLETE - LECTEUR T: // SYZYGY")
print("="*80)

results = {}

# Dossier principal 3-6men
results.update(analyze_directory('T:\\Syzygy\\3-6men', '3-6men (racine)'))

# Sous-dossiers de 7men
for subdir in ['4v3_pawnful', '4v3_pawnless', '5v2_pawnful', '5v2_pawnless', 
               '6v1_pawnful', '6v1_pawnless', 'other']:
    path = f'T:\\Syzygy\\7men\\{subdir}'
    results.update(analyze_directory(path, f'7men/{subdir}'))

# Résumé
print(f"\n{'='*80}")
print("📊 RÉSUMÉ GLOBAL - LECTEUR T:")
print(f"{'='*80}")

total_wdl = sum(v['wdl'] for v in results.values())
total_dtz = sum(v['dtz'] for v in results.values())
total_complete = sum(v['complete'] for v in results.values())

print(f"\n  Total WDL:  {total_wdl:6d}")
print(f"  Total DTZ:  {total_dtz:6d}")
print(f"  Complet:    {total_complete:6d} paires")
