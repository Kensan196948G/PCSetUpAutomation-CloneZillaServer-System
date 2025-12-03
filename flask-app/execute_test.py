#!/usr/bin/env python3
import sqlite3
import os
import subprocess

print("=" * 60)
print("PC EDIT FUNCTIONALITY TEST")
print("=" * 60)

db_path = "/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app/pc_setup.db"

# STEP 1: Check and prepare database
print("\n[STEP 1] Checking Database...")
print("-" * 60)

if os.path.exists(db_path):
    print(f"✓ Database found at: {db_path}")

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Check if pc_master table exists
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='pc_master'")
    table_exists = cursor.fetchone()

    if table_exists:
        print("✓ pc_master table exists")

        # Count existing records
        cursor.execute("SELECT COUNT(*) FROM pc_master")
        count = cursor.fetchone()[0]
        print(f"✓ Existing records: {count}")

        # Show all records
        cursor.execute("SELECT id, serial, pcname, odj_path, created_at FROM pc_master")
        records = cursor.fetchall()

        if records:
            print("\n  Current PC records:")
            for record in records:
                print(f"    ID: {record[0]}, Serial: {record[1]}, PCName: {record[2]}, ODJ: {record[3]}, Created: {record[4]}")
        else:
            print("\n  No records found. Adding test data...")
            cursor.execute(
                "INSERT INTO pc_master (serial, pcname, odj_path, created_at) VALUES (?, ?, ?, datetime('now'))",
                ("TEST001", "20251117M", "/odj/20251117M.txt")
            )
            conn.commit()
            print("  ✓ Test record added: Serial=TEST001, PCName=20251117M")
    else:
        print("✗ pc_master table does not exist. Creating it...")
        cursor.execute("""
            CREATE TABLE pc_master (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                serial TEXT UNIQUE NOT NULL,
                pcname TEXT NOT NULL,
                odj_path TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
        """)
        cursor.execute(
            "INSERT INTO pc_master (serial, pcname, odj_path, created_at) VALUES (?, ?, ?, datetime('now'))",
            ("TEST001", "20251117M", "/odj/20251117M.txt")
        )
        conn.commit()
        print("  ✓ Table created and test record added")

    conn.close()
else:
    print(f"✗ Database not found at: {db_path}")
    print("  Creating new database...")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE pc_master (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            serial TEXT UNIQUE NOT NULL,
            pcname TEXT NOT NULL,
            odj_path TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)
    cursor.execute(
        "INSERT INTO pc_master (serial, pcname, odj_path, created_at) VALUES (?, ?, ?, datetime('now'))",
        ("TEST001", "20251117M", "/odj/20251117M.txt")
    )
    conn.commit()
    conn.close()
    print("  ✓ Database created with test record")

# STEP 2: Test PC edit endpoint
print("\n[STEP 2] Testing PC Edit Page...")
print("-" * 60)

try:
    result = subprocess.run(
        ["curl", "-s", "-w", "\\nHTTP_CODE:%{http_code}", "http://localhost:5000/pcs/edit/1"],
        capture_output=True,
        text=True,
        timeout=5
    )

    output = result.stdout

    # Extract HTTP code
    http_code = "000"
    if "HTTP_CODE:" in output:
        parts = output.split("HTTP_CODE:")
        output = parts[0]
        http_code = parts[1].strip()

    print(f"HTTP Status Code: {http_code}")

    if http_code == "200":
        print("✓ Request successful (HTTP 200)")

        if "500 Internal Server Error" in output:
            print("✗ ERROR: 500 Internal Server Error detected")
            print("\nResponse preview:")
            print(output[:1000])
        elif "404" in output or "Not Found" in output:
            print("✗ ERROR: 404 Not Found")
            print("\nResponse preview:")
            print(output[:1000])
        elif "PC編集" in output or "<form" in output:
            print("✓ SUCCESS: Edit page loaded successfully")
            print("\nResponse preview (first 500 chars):")
            print(output[:500])
        else:
            print("⚠ Response received but content unclear")
            print("\nResponse preview:")
            print(output[:1000])
    elif http_code == "000":
        print("✗ ERROR: Could not connect to server")
        print("  Is the Flask app running on localhost:5000?")
        print("\nTo start the server, run:")
        print("  cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app")
        print("  python3 app.py")
    else:
        print(f"⚠ Unexpected HTTP status: {http_code}")
        print("\nResponse preview:")
        print(output[:1000])

except subprocess.TimeoutExpired:
    print("✗ ERROR: Request timeout (server not responding)")
except Exception as e:
    print(f"✗ ERROR: {str(e)}")

print("\n" + "=" * 60)
print("TEST COMPLETE")
print("=" * 60)
