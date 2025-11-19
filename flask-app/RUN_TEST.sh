#!/bin/bash
# Quick Test Runner for PC Edit Functionality
# This script runs the comprehensive test suite

clear

echo "======================================================================"
echo "  PC EDIT FUNCTIONALITY TEST - QUICK RUN"
echo "======================================================================"
echo ""
echo "This will test the PC edit functionality including:"
echo "  1. File structure check"
echo "  2. Database validation and test data setup"
echo "  3. Flask app code analysis"
echo "  4. Edit endpoint HTTP test (http://localhost:5000/pcs/edit/1)"
echo ""
echo "======================================================================"
echo ""

# Check if we're in the right directory
if [ ! -f "final_test_report.py" ]; then
    echo "Error: final_test_report.py not found"
    echo "Please run this script from the flask-app directory:"
    echo "  cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app"
    exit 1
fi

# Ask user if they want to continue
read -p "Press Enter to start the test, or Ctrl+C to cancel..."

echo ""
echo "Starting test..."
echo ""

# Run the comprehensive test
python3 final_test_report.py

exit_code=$?

echo ""
echo "======================================================================"

if [ $exit_code -eq 0 ]; then
    echo "  TEST COMPLETED SUCCESSFULLY"
else
    echo "  TEST COMPLETED WITH ERRORS"
    echo ""
    echo "  If Flask server is not running, start it with:"
    echo "    python3 app.py"
    echo ""
    echo "  Then run this test again."
fi

echo "======================================================================"

exit $exit_code
