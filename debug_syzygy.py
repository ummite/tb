import os

wdl_set = set(f for f in os.listdir('Syzygy') if f.endswith('.rtbw'))
dtz_set = set(f for f in os.listdir('Syzygy') if f.endswith('.rtbz'))

print(f"WDL files: {len(wdl_set)}")
print(f"DTZ files: {len(dtz_set)}")
print(f"KBvK.rtbw in set: {'KBvK.rtbw' in wdl_set}")
print(f"KBvK.rtbz in set: {'KBvK.rtbz' in dtz_set}")

# Vérifier les correspondances
wdl_base = sorted(set(f.replace('.rtbw', '') for f in wdl_set))
dtz_base = sorted(set(f.replace('.rtbz', '') for f in dtz_set))

print(f"\nWDL bases (first 10): {wdl_base[:10]}")
print(f"DTZ bases (first 10): {dtz_base[:10]}")

# Trouver les correspondances
common = set(wdl_base) & set(dtz_base)
print(f"\nCommon bases: {len(common)}")
print(f"Only WDL: {len(set(wdl_base) - set(dtz_base))}")
print(f"Only DTZ: {len(set(dtz_base) - set(wdl_base))}")

# Afficher un exemple
for base in sorted(common)[:5]:
    wdl_path = f"Syzygy/{base}.rtbw"
    dtz_path = f"Syzygy/{base}.rtbz"
    if os.path.exists(wdl_path) and os.path.exists(dtz_path):
        print(f"\n✓ {base}: WDL={os.path.getsize(wdl_path)}, DTZ={os.path.getsize(dtz_path)}")
    else:
        print(f"\n✗ {base}: WDL exists={os.path.exists(wdl_path)}, DTZ exists={os.path.exists(dtz_path)}")
