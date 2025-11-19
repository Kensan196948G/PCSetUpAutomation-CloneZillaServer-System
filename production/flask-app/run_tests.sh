#!/bin/bash
# Test execution script with comprehensive reporting

set -e

echo "=========================================="
echo "Flask Application Test Suite"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create test results directory
RESULTS_DIR="test-results"
mkdir -p "$RESULTS_DIR"

# Timestamp for this test run
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="$RESULTS_DIR/test_report_$TIMESTAMP.txt"

# Function to print section header
print_section() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
    echo ""
}

# Function to run test suite
run_tests() {
    local test_type=$1
    local test_path=$2
    local marker=$3

    print_section "$test_type Tests"

    if [ -n "$marker" ]; then
        pytest "$test_path" -m "$marker" -v --tb=short 2>&1 | tee -a "$REPORT_FILE"
    else
        pytest "$test_path" -v --tb=short 2>&1 | tee -a "$REPORT_FILE"
    fi

    local exit_code=${PIPESTATUS[0]}

    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓ $test_type tests passed${NC}"
    else
        echo -e "${RED}✗ $test_type tests failed${NC}"
    fi

    return $exit_code
}

# Initialize report
echo "Test Execution Report - $TIMESTAMP" > "$REPORT_FILE"
echo "==========================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Track overall status
OVERALL_STATUS=0

# Run integration tests
if run_tests "Integration" "tests/integration" ""; then
    INTEGRATION_STATUS="PASS"
else
    INTEGRATION_STATUS="FAIL"
    OVERALL_STATUS=1
fi

# Run E2E tests
if run_tests "E2E" "tests/e2e" ""; then
    E2E_STATUS="PASS"
else
    E2E_STATUS="FAIL"
    OVERALL_STATUS=1
fi

# Run performance tests
if run_tests "Performance" "tests/performance" ""; then
    PERFORMANCE_STATUS="PASS"
else
    PERFORMANCE_STATUS="FAIL"
    OVERALL_STATUS=1
fi

# Generate coverage report
print_section "Code Coverage Report"
echo "Generating coverage report..."

pytest tests/ --cov=. --cov-report=html --cov-report=term-missing 2>&1 | tee -a "$REPORT_FILE"

echo ""
echo "Coverage report saved to: htmlcov/index.html"

# Summary
print_section "Test Summary"

{
    echo "Integration Tests: $INTEGRATION_STATUS"
    echo "E2E Tests: $E2E_STATUS"
    echo "Performance Tests: $PERFORMANCE_STATUS"
    echo ""
    echo "Detailed report: $REPORT_FILE"
    echo "Coverage report: htmlcov/index.html"
} | tee -a "$REPORT_FILE"

# Final status
echo ""
if [ $OVERALL_STATUS -eq 0 ]; then
    echo -e "${GREEN}=========================================="
    echo "✓ All tests passed!"
    echo -e "==========================================${NC}"
    exit 0
else
    echo -e "${RED}=========================================="
    echo "✗ Some tests failed"
    echo -e "==========================================${NC}"
    exit 1
fi
