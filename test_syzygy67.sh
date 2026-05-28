#!/usr/bin/env bash
#
# test_syzygy67.sh - Test sequence for Syzygy 6-piece and 7-piece tablebases
#
# Usage:
#   ./test_syzygy67.sh [path/to/6-7-piece/files]
#
# If no argument, scans current directory and ./Syzygy/
#

set -euo pipefail

TEST_DIR="${1:-.}"
BIN_DIR="bin"
CHECKSUM_DIR="checksums"

echo
echo "============================================"
echo "  Syzygy 6-Piece / 7-Piece Test Sequence"
echo "============================================"
echo "Test directory : $TEST_DIR"
echo "Binaries       : $BIN_DIR"
echo

# --- 1. Tool check ---
echo "[1/6] Checking built tools..."
for tool in tbcheck rtbver rtbverp rtbgen rtbgenp; do
    if [[ -x "$BIN_DIR/$tool" || -x "$BIN_DIR/$tool.exe" ]]; then
        echo "  Found: $tool"
    else
        if [[ "$tool" == "tbcheck" ]]; then
            echo "ERROR: $tool not found. Build first (make or build.bat)."
            exit 1
        else
            echo "  WARNING: $tool not found (some tests will be skipped)."
        fi
    fi
done

# --- 2. RTBPATH ---
echo
echo "[2/6] RTBPATH check..."
if [[ -z "${RTBPATH:-}" ]]; then
    if [[ -d "Syzygy" ]]; then
        export RTBPATH="$(pwd)/Syzygy"
        echo "  RTBPATH not set - defaulting to $RTBPATH"
    else
        echo "  WARNING: RTBPATH not set and no Syzygy/ directory."
        echo "  6/7 generation requires lower-piece subbases."
    fi
else
    echo "  RTBPATH=$RTBPATH"
fi

# --- 3. Discover 6+ piece files ---
echo
echo "[3/6] Scanning for 6-piece and 7-piece files..."

count6=0
count7=0

shopt -s nullglob
for f in "$TEST_DIR"/*.rtbw "$TEST_DIR"/*.rtbz; do
    [[ -f "$f" ]] || continue
    base=$(basename "$f" .rtbw)
    base=$(basename "$base" .rtbz)
    # total pieces = length of name - 1
    len=${#base}
    pieces=$((len - 1))

    if (( pieces >= 5 )); then
        if (( pieces == 5 )); then
            ((count6++))
            echo "  [6pc] $(basename "$f")"
        else
            ((count7++))
            echo "  [7pc] $(basename "$f")"
        fi
    fi
done
shopt -u nullglob

echo "  6-piece candidates: $count6"
echo "  7-piece candidates: $count7"

if (( count6 == 0 && count7 == 0 )); then
    echo
    echo "  No 6+ piece files found in $TEST_DIR"
    echo "  Put your .rtbw/.rtbz files here or pass a directory argument."
fi

# --- 4. tbcheck (checksums) ---
echo
echo "[4/6] Running tbcheck on 6/7-piece files..."

shopt -s nullglob
for f in "$TEST_DIR"/*.rtbw "$TEST_DIR"/*.rtbz; do
    [[ -f "$f" ]] || continue
    base=$(basename "$f" .rtbw)
    base=$(basename "$base" .rtbz)
    len=${#base}
    pieces=$((len - 1))

    if (( pieces >= 5 )); then
        echo
        echo "  Verifying $(basename "$f") ..."
        if "$BIN_DIR/tbcheck" "$f" 2>&1; then
            echo "  PASS: $(basename "$f")"
        else
            echo "  *** FAILED: $(basename "$f") ***"
        fi
    fi
done
shopt -u nullglob

# --- 5. rtbver / rtbverp logical verification ---
echo
echo "[5/6] Logical verification (rtbver/rtbverp --log)..."

if command -v "$BIN_DIR/rtbver" >/dev/null 2>&1 || command -v "$BIN_DIR/rtbver.exe" >/dev/null 2>&1; then
    shopt -s nullglob
    for f in "$TEST_DIR"/*.rtbw; do
        [[ -f "$f" ]] || continue
        base=$(basename "$f" .rtbw)
        len=${#base}
        pieces=$((len - 1))
        if (( pieces >= 5 )); then
            echo
            echo "  rtbver --log on $(basename "$f") ..."
            "$BIN_DIR/rtbver" -t 4 --log "${base}" || true
        fi
    done
    shopt -u nullglob
else
    echo "  rtbver not present - skipping."
fi

if command -v "$BIN_DIR/rtbverp" >/dev/null 2>&1 || command -v "$BIN_DIR/rtbverp.exe" >/dev/null 2>&1; then
    shopt -s nullglob
    for f in "$TEST_DIR"/*.rtbw; do
        [[ -f "$f" ]] || continue
        base=$(basename "$f" .rtbw)
        if [[ "$base" == *"P"* ]]; then
            len=${#base}
            pieces=$((len - 1))
            if (( pieces >= 5 )); then
                echo
                echo "  rtbverp --log on $(basename "$f") (pawnful) ..."
                "$BIN_DIR/rtbverp" -t 2 --log "${base}" || true
            fi
        fi
    done
    shopt -u nullglob
fi

# --- 6. Generation hints ---
echo
echo "[6/6] Summary + Generation hints"
echo
echo "  Reference checksums: $CHECKSUM_DIR/{wdl,dtz}6.txt and {wdl,dtz}7.txt"
echo
echo "  Minimal 6-piece generation example (disk mode, use with caution):"
echo "    export RTBPATH=Syzygy"
echo "    $BIN_DIR/rtbgen   -t 8 -d --stats KQvKQR"
echo "    $BIN_DIR/rtbgenp  -t 4 -d --stats KRPvKRP"
echo
echo "  7-piece generation is only realistic on servers with 512 GB+ RAM."
echo
echo "  Full documentation: docs/TESTING_SYZYGY_6_7.md"
echo
echo "============================================"
echo "  Syzygy 6/7 Test Sequence Complete"
echo "============================================"
echo
