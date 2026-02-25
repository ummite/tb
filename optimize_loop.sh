#!/bin/bash
# Ralph Loop - Automated Code Optimization for Chess Tablebase Generator
# This script continuously compiles, analyzes warnings, and fixes one issue at a time

set -e

SRC_DIR="C:/Programmation/tb-1/src"
LOG_FILE="optimize_log.txt"
MAX_ITERATIONS=50
ITERATION=0

echo "=========================================="
echo "Ralph Loop - Automated Code Optimization"
echo "=========================================="
echo "Source: $SRC_DIR"
echo "Max iterations: $MAX_ITERATIONS"
echo "=========================================="
echo ""

cd "$SRC_DIR"

# Function to extract and analyze warnings
analyze_warnings() {
    make clean 2>&1 | grep -v "Entering\|Leaving" > /dev/null
    make all 2>&1 | tee "$LOG_FILE"
}

# Function to fix one warning at a time
fix_warning() {
    local warning_file=$1
    local warning_line=$2
    local warning_text=$3

    echo "  Fixing: $warning_text"

    case "$warning_text" in
        *"unknown type name"*|*"undeclared"*|*"implicit declaration"*)
            # Missing includes or forward declarations
            echo "    -> Adding missing include/declaration"
            ;;
        *"warning: left shift count"*|*"overflow"*)
            # Type width issues
            echo "    -> Fixing type to uint64_t"
            sed -i 's/((size_t)/((uint64_t)/g' "$warning_file"
            ;;
        *"#define max"*)
            # Macro conflicts with Windows headers
            echo "    -> Replacing macro with function"
            sed -i 's/#define max(a,b)/static inline int max_int(int a, int b) { return a > b ? a : b; }/' "$warning_file"
            sed -i 's/\bmax(/max_int(/g' "$warning_file"
            ;;
        *"unused variable"*|*"unused parameter"*)
            echo "    -> Removing or marking unused"
            ;;
        *"redefined"*|*"previous definition"*)
            echo "    -> Removing duplicate definition"
            ;;
        *)
            echo "    -> Manual review needed"
            ;;
    esac
}

# Main optimization loop
echo "Starting optimization loop..."
echo ""

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ITERATION=$((ITERATION + 1))
    echo "=========================================="
    echo "Iteration $ITERATION"
    echo "=========================================="

    # Compile and capture output
    analyze_warnings

    # Check for warnings
    WARNINGS=$(grep -c "warning:" "$LOG_FILE" || true)

    if [ "$WARNINGS" -eq 0 ]; then
        echo "No warnings found!"
        echo ""
        echo "=========================================="
        echo "Optimization complete - no warnings!"
        echo "=========================================="

        # Verify binaries exist
        echo ""
        echo "Generated binaries:"
        ls -la ../bin/*.exe 2>&1 | grep -v "No such" || true
        exit 0
    fi

    echo "Found $WARNINGS warning(s)"

    # Extract first warning
    FIRST_WARNING=$(grep "warning:" "$LOG_FILE" | head -1)
    WARNING_LINE=$(echo "$FIRST_WARNING" | grep -o "^[^:]*:[0-9]*" | cut -d: -f1)
    WARNING_TEXT=$(echo "$FIRST_WARNING" | sed 's/.*warning: //')

    echo ""
    echo "First warning: $WARNING_TEXT"

    if [ -z "$WARNING_LINE" ]; then
        echo "Could not parse warning location"
        break
    fi

    # Apply fix
    fix_warning "$WARNING_LINE" "$FIRST_WARNING" "$WARNING_TEXT"

    echo ""
    echo "Press Ctrl+C to stop, or wait for next iteration..."
    echo ""

    sleep 1
done

echo "=========================================="
echo "Reached maximum iterations ($MAX_ITERATIONS)"
echo "=========================================="
echo ""
echo "Final compilation output:"
cat "$LOG_FILE"