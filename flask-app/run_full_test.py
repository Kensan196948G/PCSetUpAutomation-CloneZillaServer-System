#!/usr/bin/env python3
"""
PC Edit Functionality Test Script
Tests the PC editing feature of the Flask app
"""

import os
import sys
import sqlite3
import subprocess

FLASK_DIR = "/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app"
DB_PATH = os.path.join(FLASK_DIR, "pc_setup.db")

def print_header(text):
    print("\n" + "=" * 70)
    print(f"  {text}")
    print("=" * 70)

def print_section(text):
    print(f"\n[{text}]")
    print("-" * 70)

def check_files():
    """Check if required files exist"""
    print_section("File System Check")

    print(f"Flask directory: {FLASK_DIR}")

    if not os.path.exists(FLASK_DIR):
        print(f"✗ ERROR: Directory not found")
        return False

    print("✓ Directory exists")

    # List all files
    print("\nFiles in flask-app:")
    try:
        items = sorted(os.listdir(FLASK_DIR))
        for item in items:
            full_path = os.path.join(FLASK_DIR, item)
            if os.path.isfile(full_path):
                size = os.path.getsize(full_path)
                print(f"  - {item} ({size:,} bytes)")
            elif os.path.isdir(full_path):
                print(f"  - {item}/ (directory)")
    except Exception as e:
        print(f"✗ Error listing files: {e}")
        return False

    # Check key files
    print("\nKey files check:")
    key_files = {
        "app.py": "Main Flask application",
        "models.py": "Database models",
        "pc_setup.db": "SQLite database"
    }

    all_exist = True
    for filename, description in key_files.items():
        filepath = os.path.join(FLASK_DIR, filename)
        if os.path.exists(filepath):
            print(f"  ✓ {filename} - {description}")
        else:
            print(f"  ✗ {filename} - {description} [NOT FOUND]")
            all_exist = False

    return all_exist

def check_database():
    """Check database and ensure test data exists"""
    print_section("Database Check")

    if not os.path.exists(DB_PATH):
        print(f"✗ Database not found at: {DB_PATH}")
        print("  Creating new database...")
        try:
            conn = sqlite3.connect(DB_PATH)
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
            cursor.execute("""
                CREATE TABLE setup_logs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    serial TEXT,
                    pcname TEXT,
                    status TEXT,
                    timestamp DATETIME,
                    logs TEXT
                )
            """)
            conn.commit()
            print("  ✓ Database created with tables")
        except Exception as e:
            print(f"  ✗ Error creating database: {e}")
            conn.close()
            return False
    else:
        print(f"✓ Database found at: {DB_PATH}")
        conn = sqlite3.connect(DB_PATH)

    try:
        cursor = conn.cursor()

        # Check pc_master table
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='pc_master'")
        if not cursor.fetchone():
            print("✗ pc_master table not found")
            return False

        print("✓ pc_master table exists")

        # Count records
        cursor.execute("SELECT COUNT(*) FROM pc_master")
        count = cursor.fetchone()[0]
        print(f"✓ Records in pc_master: {count}")

        # Show existing records
        cursor.execute("SELECT id, serial, pcname, odj_path, created_at FROM pc_master ORDER BY id")
        records = cursor.fetchall()

        if records:
            print("\nExisting PC records:")
            for record in records:
                print(f"  ID: {record[0]} | Serial: {record[1]} | PCName: {record[2]} | ODJ: {record[3]} | Created: {record[4]}")
        else:
            print("\nNo records found. Adding test data...")
            cursor.execute(
                "INSERT INTO pc_master (serial, pcname, odj_path, created_at) VALUES (?, ?, ?, datetime('now'))",
                ("TEST001", "20251117M", "/odj/20251117M.txt")
            )
            conn.commit()
            print("✓ Test record added: ID=1, Serial=TEST001, PCName=20251117M")

        conn.close()
        return True

    except Exception as e:
        print(f"✗ Database error: {e}")
        conn.close()
        return False

def test_edit_endpoint():
    """Test the PC edit endpoint"""
    print_section("PC Edit Endpoint Test")

    url = "http://localhost:5000/pcs/edit/1"
    print(f"Testing URL: {url}")

    try:
        # Use curl to test the endpoint
        result = subprocess.run(
            ["curl", "-s", "-w", "\nHTTP_CODE:%{http_code}", url],
            capture_output=True,
            text=True,
            timeout=5
        )

        output = result.stdout

        # Extract HTTP code
        http_code = "000"
        if "HTTP_CODE:" in output:
            parts = output.rsplit("HTTP_CODE:", 1)
            output = parts[0]
            http_code = parts[1].strip()

        print(f"\nHTTP Status: {http_code}")

        if http_code == "000":
            print("✗ ERROR: Cannot connect to server")
            print("\n  The Flask application is not running.")
            print("  To start it, run:")
            print(f"    cd {FLASK_DIR}")
            print("    python3 app.py")
            return False

        elif http_code == "200":
            print("✓ HTTP 200 OK - Request successful")

            # Check response content
            if "500 Internal Server Error" in output:
                print("✗ ERROR: Server returned 500 error")
                print("\nError details:")
                lines = output.split('\n')
                for i, line in enumerate(lines[:30]):
                    print(f"  {line}")
                return False

            elif "404" in output or "Not Found" in output:
                print("✗ ERROR: 404 Not Found")
                print("  The edit route may not be properly configured")
                return False

            elif "PC編集" in output or "<form" in output or "pcname" in output.lower():
                print("✓ SUCCESS: Edit page loaded successfully")

                # Try to extract form fields
                if "pcname" in output.lower():
                    print("  ✓ Form contains pcname field")
                if "serial" in output.lower():
                    print("  ✓ Form contains serial field")
                if "odj" in output.lower():
                    print("  ✓ Form contains ODJ path field")

                print("\nResponse preview (first 600 characters):")
                print("-" * 70)
                preview = output[:600]
                # Clean up HTML for better readability
                for line in preview.split('\n')[:15]:
                    if line.strip():
                        print(f"  {line.strip()[:70]}")

                return True

            else:
                print("⚠ WARNING: Response received but content unclear")
                print("\nResponse preview:")
                print(output[:800])
                return False

        elif http_code == "404":
            print("✗ ERROR: 404 Not Found")
            print("  The route /pcs/edit/1 does not exist")
            print("  Check if the route is defined in app.py")
            return False

        elif http_code == "500":
            print("✗ ERROR: 500 Internal Server Error")
            print("  There is an error in the application code")
            print("\nResponse preview:")
            print(output[:800])
            return False

        else:
            print(f"⚠ WARNING: Unexpected HTTP status {http_code}")
            print("\nResponse preview:")
            print(output[:800])
            return False

    except subprocess.TimeoutExpired:
        print("✗ ERROR: Request timeout")
        print("  Server is not responding")
        return False

    except FileNotFoundError:
        print("✗ ERROR: curl command not found")
        print("  Please install curl: sudo apt-get install curl")
        return False

    except Exception as e:
        print(f"✗ ERROR: {str(e)}")
        return False

def main():
    """Main test runner"""
    print_header("PC EDIT FUNCTIONALITY TEST")
    print("Testing Date: 2025-11-17")
    print(f"Working Directory: {FLASK_DIR}")

    # Run tests
    results = {
        "Files Check": check_files(),
        "Database Check": check_database(),
        "Edit Endpoint": test_edit_endpoint()
    }

    # Summary
    print_header("TEST SUMMARY")

    for test_name, passed in results.items():
        status = "✓ PASSED" if passed else "✗ FAILED"
        print(f"  {test_name:20} : {status}")

    all_passed = all(results.values())

    print("\n" + "=" * 70)
    if all_passed:
        print("  OVERALL RESULT: ✓ ALL TESTS PASSED")
    else:
        print("  OVERALL RESULT: ✗ SOME TESTS FAILED")
    print("=" * 70)

    return 0 if all_passed else 1

if __name__ == "__main__":
    sys.exit(main())
