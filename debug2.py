import os

path = 'T:\\Syzygy\\3-6men'
files = [f for f in os.listdir(path) if f.endswith('.rtbw')]
print(f'Nb fichiers WDL: {len(files)}')

# Afficher les 5 premiers
for f in files[:5]:
    full = os.path.join(path, f)
    size = os.path.getsize(full)
    print(f'  {f}: {size:,} bytes = {size/(1024*1024):.2f} MB')

# Calculer le total
total = sum(os.path.getsize(os.path.join(path, f)) for f in files)
print(f'\nTotal WDL: {total:,} bytes = {total/(1024*1024):.2f} MB = {total/(1024*1024*1024):.2f} GB')
