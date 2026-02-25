#!/bin/bash
# Ralph Loop - Fully Automated Code Optimization
# Continuously compiles, analyzes warnings, fixes one issue, and repeats

set -e

SRC_DIR="C:/Programmation/tb-1/src"
LOG_FILE="optimize_log.txt"
MAX_ITERATIONS=100
ITERATION=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Ralph Loop - Fully Automated Optimization"
echo "=========================================="
echo "Source: $SRC_DIR"
echo "Max iterations: $MAX_ITERATIONS"
echo "=========================================="
echo ""

cd "$SRC_DIR"

# Function to fix specific warning patterns
fix_warning() {
    local file=$1
    local line_num=$2
    local warning=$3

    echo -e "${YELLOW}  Fixing: $warning${NC}"

    # Fix shift count warnings
    if echo "$warning" | grep -q "left shift count >= width"; then
        sed -i 's/((size_t)sizeHigh/((uint64_t)sizeHigh/g' "$file"
        echo -e "${GREEN}    Fixed: Changed size_t to uint64_t${NC}"
        return
    fi

    # Fix undefined variable statbuf
    if echo "$warning" | grep -q "statbuf"; then
        sed -i 's/statbuf\.st_size/*map/g' "$file"
        echo -e "${GREEN}    Fixed: Removed undefined statbuf${NC}"
        return
    fi

    # Fix macro redefined warnings
    if echo "$warning" | grep -q "redefined"; then
        if grep -q "#define max(a,b)" "$file"; then
            sed -i 's/#define max(a,b)/static inline int max_int(int a, int b) { return a > b ? a : b; }/' "$file"
            sed -i 's/\bmax(/max_int(/g' "$file"
            echo -e "${GREEN}    Fixed: Replaced max macro with function${NC}"
        fi
        return
    fi

    # Fix unused variable warnings
    if echo "$warning" | grep -q "unused variable"; then
        local var=$(echo "$warning" | grep -oP 'variable \K[a-zA-Z_]+')
        echo -e "${GREEN}    Note: Variable '$var' marked as potentially unused${NC}"
        return
    fi

    # Fix unused parameter warnings
    if echo "$warning" | grep -q "unused parameter"; then
        echo -e "${GREEN}    Note: Parameter marked for review${NC}"
        return
    fi

    echo -e "${YELLOW}    Manual intervention needed${NC}"
}

# Main loop
echo "Starting optimization loop..."
echo ""

while [ $ITERATION -lt $MAX_ITERATIONS ]; do
    ITERATION=$((ITERATION + 1))

    echo "=========================================="
    echo -e "${GREEN}Iteration $ITERATION${NC}"
    echo "=========================================="

    # Step 1: Compile
    echo "Compiling..."
    make clean > /dev/null 2>&1 || true
    make all 2>&1 | tee "$LOG_FILE"

    # Step 2: Check for warnings
    WARNING_COUNT=$(grep -c "warning:" "$LOG_FILE" 2>/dev/null || echo "0")

    if [ "$WARNING_COUNT" -eq 0 ]; then
        echo ""
        echo -e "${GREEN}==========================================${NC}"
        echo -e "${GREEN}Compilation clean - no warnings!${NC}"
        echo -e "${GREEN}==========================================${NC}"
        echo ""
        echo "Generated binaries:"
        ls -la ../bin/*.exe 2>/dev/null | grep -v "No such" || true
        exit 0
    fi

    echo -e "${YELLOW}Found $WARNING_COUNT warning(s)${NC}"

    # Step 3: Extract first warning
    FIRST_WARNING=$(grep "warning:" "$LOG_FILE" | head -1)
    WARNING_FILE=$(echo "$FIRST_WARNING" | grep -oP '^[^:]+(?=:[0-9]+)' | head -1)
    WARNING_LINE_NUM=$(echo "$FIRST_WARNING" | grep -oP '(?<=:[0-9]+:)[0-9]+' | head -1)
    WARNING_TEXT=$(echo "$FIRST_WARNING" | sed 's/.*warning: //')

    echo ""
    echo -e "${RED}First warning:${NC} $WARNING_TEXT"

    if [ -z "$WARNING_FILE" ] || [ -z "$WARNING_LINE_NUM" ]; then
        echo "Could not parse warning location"
        break
    fi

    # Step 4: Apply fix
    fix_warning "$WARNING_FILE" "$WARNING_LINE_NUM" "$WARNING_TEXT"

    # Step 5: Small delay before next iteration
    echo ""
    echo -e "${YELLOW}Waiting 1 second before next iteration...${NC}"
    echo ""
    sleep 1
done

echo "=========================================="
echo -e "${RED}Reached maximum iterations ($MAX_ITERATIONS)${NC}"
echo "=========================================="
echo ""
echo "Final compilation output:"
cat "$LOG_FILE"