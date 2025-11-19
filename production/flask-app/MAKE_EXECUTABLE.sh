#!/bin/bash
# Make all test scripts executable

echo "Making test scripts executable..."

chmod +x RUN_TEST.sh
chmod +x automated_test.sh
chmod +x run_test.sh
chmod +x final_test_report.py
chmod +x simple_test.py
chmod +x check_app_structure.py
chmod +x test_edit.py
chmod +x execute_test.py
chmod +x run_full_test.py
chmod +x check_files.py

echo "Done! All test scripts are now executable."
echo ""
echo "To run the main test, use:"
echo "  ./RUN_TEST.sh"
echo "  or"
echo "  bash RUN_TEST.sh"
