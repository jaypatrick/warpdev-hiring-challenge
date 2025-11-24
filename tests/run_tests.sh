#!/bin/bash

# Test runner for AWK solution
# Usage: ./tests/run_tests.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
AWK_SCRIPT="$PROJECT_ROOT/src/mars_mission_analyzer.awk"
TEST_DATA="$SCRIPT_DIR/test_data.log"
FULL_DATA="$PROJECT_ROOT/space_missions.log"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0

# Test function
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_exit="$3"
    local check_output="$4"
    
    echo -n "Testing: $test_name... "
    
    # Run command and capture output and exit code
    set +e
    output=$(eval "$command" 2>&1)
    exit_code=$?
    set -e
    
    # Check exit code
    if [ "$exit_code" -ne "$expected_exit" ]; then
        echo -e "${RED}FAILED${NC}"
        echo "  Expected exit code: $expected_exit"
        echo "  Got exit code: $exit_code"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
    
    # Check output if specified
    if [ -n "$check_output" ]; then
        if echo "$output" | grep -q "$check_output"; then
            echo -e "${GREEN}PASSED${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}FAILED${NC}"
            echo "  Expected output to contain: $check_output"
            echo "  Got: $output"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    else
        echo -e "${GREEN}PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
}

echo -e "${YELLOW}Running AWK Solution Tests${NC}"
echo "================================"
echo ""

# Test 1: Help output
run_test "Help flag displays usage" \
    "awk -v help=1 -f '$AWK_SCRIPT'" \
    0 \
    "Usage: awk"

# Test 2: Default output with test data
run_test "Default output format" \
    "awk -f '$AWK_SCRIPT' '$TEST_DATA'" \
    0 \
    "STU-901-FGH"

# Test 3: JSON output format
run_test "JSON output format" \
    "awk -v format=json -f '$AWK_SCRIPT' '$TEST_DATA'" \
    0 \
    "\"security_code\""

# Test 4: CSV output format
run_test "CSV output format" \
    "awk -v format=csv -f '$AWK_SCRIPT' '$TEST_DATA'" \
    0 \
    "Rank,Date,Mission ID"

# Test 5: Top N missions
run_test "Top 3 missions" \
    "awk -v top=3 -f '$AWK_SCRIPT' '$TEST_DATA' | grep -c 'Rank #'" \
    0 \
    "3"

# Test 6: Empty file handling
run_test "Empty file error handling" \
    "echo '' | awk -f '$AWK_SCRIPT'" \
    1 \
    "ERROR"

# Test 7: Full data file (if exists)
if [ -f "$FULL_DATA" ]; then
    run_test "Full data file - longest mission" \
        "awk -f '$AWK_SCRIPT' '$FULL_DATA'" \
        0 \
        "XRT-421-ZQP"
    
    run_test "Full data file - JSON format" \
        "awk -v format=json -f '$AWK_SCRIPT' '$FULL_DATA' | head -20" \
        0 \
        "\"duration_days\": 1629"
        
    run_test "Full data file - top 5 missions" \
        "awk -v top=5 -f '$AWK_SCRIPT' '$FULL_DATA' | grep -c 'Security Code'" \
        0 \
        "5"
fi

# Test 8: Verbose mode
run_test "Verbose mode statistics" \
    "awk -v verbose=1 -f '$AWK_SCRIPT' '$TEST_DATA' 2>&1 | grep -c 'Processing Statistics'" \
    0 \
    "1"

echo ""
echo "================================"
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo "================================"

if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
