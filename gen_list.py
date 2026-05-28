#!/usr/bin/env python3
"""Generate the full tablebase list for 3-5 pieces and output batch file calls."""
from itertools import combinations_with_replacement

PIECES = ['Q', 'R', 'B', 'N', 'P']

def multiset_sequences(k):
    if k == 0:
        yield []
        return
    for combo in combinations_with_replacement(PIECES, k):
        yield list(combo)

min_pcs = 3
max_pcs = 5

tbs = []
for a_count in range(1, 4):
    for d_count in range(0, 3):
        total = 2 + a_count + d_count
        if total > max_pcs:
            continue
        for a_seq in multiset_sequences(a_count):
            for d_seq in multiset_sequences(d_count):
                tb = 'K' + ''.join(a_seq) + 'v' + 'K' + ''.join(d_seq)
                total_pieces = len(tb) - 1
                if total_pieces >= min_pcs and total_pieces <= max_pcs:
                    has_pawn = 1 if 'P' in tb else 0
                    tbs.append((tb, total_pieces, has_pawn))

# Group by piece count
for pieces in range(3, 6):
    group = [(tb, hp) for tb, p, hp in tbs if p == pieces]
    print(f'# {pieces} pieces ({len(group)} tables)')
    for tb, hp in sorted(group):
        print(f'call :gen_table "{tb}" {hp}')
print(f'# Total: {len(tbs)} tables')
