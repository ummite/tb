#!/bin/bash
# =============================================================================
# tb-1 Tablebase Generator Build Script (GCC/MinGW)
# =============================================================================
# This script provides an easy way to build the tablebase generator
# using GCC/MinGW on Windows (WSL/Linux).
#
# Usage: ./build.sh [target]
#   target: all (default), clean, debug, release, info
#
# Prerequisites:
#   - GCC/MinGW with C11 support
#   - ZSTD library (optional, falls back to LZ4)
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
TARGET="${1:-all}"

echo "============================================"
echo "tb-1 Tablebase Generator Build"
echo "============================================"
echo "Target: $TARGET"
echo "Source directory: $SRC_DIR"
echo ""

# Show configuration info
if [ "$TARGET" = "info" ]; then
    echo "Platform: $(uname -s) $(uname -m)"
    echo "Compiler: $(which gcc 2>/dev/null || echo 'not found')"
    echo ""
    echo "To build, run: make -C $SRC_DIR all"
    echo "For VS2026 build, run: .\\build.bat"
    exit 0
fi

# Check for GCC
if ! command -v gcc &> /dev/null; then
    echo "WARNING: gcc not found."
    echo "Use VS2026 build instead: .\\build.bat"
    echo "Or install MinGW-w64 for GCC build."
    exit 0
fi

# Run make with specified target
cd "$SRC_DIR"
make "$TARGET"

echo ""
echo "============================================"
echo "Build complete!"
echo "Executables in: $SCRIPT_DIR/bin/"
echo "============================================"
ls -la "$SCRIPT_DIR/bin/"/*.exe 2>/dev/null || echo "No executables found."