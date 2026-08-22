import os
import sys

def analyze_dir(path):
    """Analyser correctement les tailles de fichiers"""
    if not os.path.exists(path):
        return 0, 0
    
    wdl_total = 0
    dtz_total = 0
    
    for f in os.listdir(path):
        full_path = os.path.join(path, f)
        if not os.path.isfile(full_path):
            continue
        
        size = os.path.getsize(full_path)
        if f.endswith('.rtbw'):
            wdl_total += size
        elif f.endswith('.rtbz'):
            dtz_total += size
    
    return wdl_total, dtz_total

# Tester sur 3-6men
wdl_bytes, dtz_bytes = analyze_dir('T:\\Syzygy\\3-6men')
print(f"3-6men: WDL={wdl_bytes/(1024*1024):.2f} MB, DTZ={dtz_bytes/(1024*1024):.2f} MB")

# Tester sur 7men/4v3_pawnful
wdl_bytes7, dtz_bytes7 = analyze_dir('T:\\Syzygy\\7men\\4v3_pawnful')
print(f"7men/4v3_pawnful: WDL={wdl_bytes7/(1024*1024):.2f} MB, DTZ={dtz_bytes7/(1024*1024):.2f} MB")
