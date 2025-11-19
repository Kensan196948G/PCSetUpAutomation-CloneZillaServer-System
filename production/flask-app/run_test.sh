#!/bin/bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app

echo "=== Step 1: Checking Database ==="
python3 test_edit.py

echo ""
echo "=== Step 2: Testing PC Edit Page ==="
echo "Attempting to access: http://localhost:5000/pcs/edit/1"
curl -s http://localhost:5000/pcs/edit/1 > /tmp/edit_response.html

if [ $? -eq 0 ]; then
    echo "Request successful"

    # Check for errors in response
    if grep -q "500 Internal Server Error" /tmp/edit_response.html; then
        echo "ERROR: 500 Internal Server Error detected"
        echo "Response preview:"
        head -n 50 /tmp/edit_response.html
    elif grep -q "404 Not Found" /tmp/edit_response.html; then
        echo "ERROR: 404 Not Found"
        echo "Response preview:"
        head -n 50 /tmp/edit_response.html
    elif grep -q "PC編集" /tmp/edit_response.html || grep -q "edit" /tmp/edit_response.html; then
        echo "SUCCESS: Edit page loaded successfully"
        echo "Response preview (first 30 lines):"
        head -n 30 /tmp/edit_response.html
    else
        echo "Response received but content unclear:"
        head -n 50 /tmp/edit_response.html
    fi
else
    echo "ERROR: Failed to connect to server"
    echo "Is the Flask app running on localhost:5000?"
fi

echo ""
echo "Full response saved to: /tmp/edit_response.html"
