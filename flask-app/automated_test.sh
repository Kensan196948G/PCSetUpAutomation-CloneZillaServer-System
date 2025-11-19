#!/bin/bash

echo "======================================================================"
echo "  PC EDIT FUNCTIONALITY TEST - Automated Test Suite"
echo "  Date: 2025-11-17"
echo "======================================================================"

cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app

# Step 1: Check app structure
echo ""
echo "[STEP 1] Checking Flask App Structure..."
echo "----------------------------------------------------------------------"
python3 check_app_structure.py

# Step 2: Check/Setup Database
echo ""
echo "[STEP 2] Checking Database and Test Data..."
echo "----------------------------------------------------------------------"
python3 simple_test.py

# Step 3: Test Edit Endpoint
echo ""
echo "[STEP 3] Testing PC Edit Endpoint..."
echo "----------------------------------------------------------------------"

# Check if server is running
if curl -s http://localhost:5000 > /dev/null 2>&1; then
    echo "✓ Flask server is running"

    echo ""
    echo "Testing: GET http://localhost:5000/pcs/edit/1"

    # Save response to file
    HTTP_CODE=$(curl -s -o /tmp/edit_response.html -w "%{http_code}" http://localhost:5000/pcs/edit/1)

    echo "HTTP Status Code: $HTTP_CODE"

    if [ "$HTTP_CODE" = "200" ]; then
        echo "✓ Request successful (HTTP 200)"

        # Check response content
        if grep -q "500 Internal Server Error" /tmp/edit_response.html; then
            echo "✗ ERROR: Server returned 500 error"
            echo ""
            echo "Error preview:"
            head -n 30 /tmp/edit_response.html

        elif grep -q "404" /tmp/edit_response.html; then
            echo "✗ ERROR: 404 Not Found"

        elif grep -qi "PC編集\|pcname\|serial" /tmp/edit_response.html; then
            echo "✓ SUCCESS: Edit page loaded with form fields"

            echo ""
            echo "Content verification:"

            if grep -qi "pcname" /tmp/edit_response.html; then
                echo "  ✓ PCName field found"
            fi

            if grep -qi "serial" /tmp/edit_response.html; then
                echo "  ✓ Serial field found"
            fi

            if grep -qi "odj" /tmp/edit_response.html; then
                echo "  ✓ ODJ path field found"
            fi

            if grep -qi "<form" /tmp/edit_response.html; then
                echo "  ✓ Form tag found"
            fi

            echo ""
            echo "Response preview (first 20 lines):"
            head -n 20 /tmp/edit_response.html | sed 's/^/  /'

        else
            echo "⚠ Response received but content unclear"
            head -n 20 /tmp/edit_response.html
        fi

    elif [ "$HTTP_CODE" = "404" ]; then
        echo "✗ ERROR: 404 Not Found - Route does not exist"

    elif [ "$HTTP_CODE" = "500" ]; then
        echo "✗ ERROR: 500 Internal Server Error"
        echo ""
        echo "Error details:"
        head -n 30 /tmp/edit_response.html

    else
        echo "⚠ Unexpected HTTP status: $HTTP_CODE"
    fi

else
    echo "✗ ERROR: Flask server is NOT running"
    echo ""
    echo "To start the server:"
    echo "  cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app"
    echo "  python3 app.py"
fi

echo ""
echo "======================================================================"
echo "  TEST COMPLETE"
echo "======================================================================"
echo ""
echo "Full response saved to: /tmp/edit_response.html"
echo "You can view it with: cat /tmp/edit_response.html"
