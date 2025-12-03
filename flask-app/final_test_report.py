#!/usr/bin/env python3
"""
Complete PC Edit Functionality Test
Performs all necessary checks and generates a report
"""

import os
import sys
import sqlite3
import subprocess
import re
from datetime import datetime

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def print_header(text):
    print(f"\n{Colors.BOLD}{'='*70}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.BLUE}{text:^70}{Colors.RESET}")
    print(f"{Colors.BOLD}{'='*70}{Colors.RESET}\n")

def print_section(text):
    print(f"\n{Colors.BOLD}[{text}]{Colors.RESET}")
    print("-"*70)

def success(text):
    print(f"{Colors.GREEN}✓{Colors.RESET} {text}")

def error(text):
    print(f"{Colors.RED}✗{Colors.RESET} {text}")

def warning(text):
    print(f"{Colors.YELLOW}⚠{Colors.RESET} {text}")

def info(text):
    print(f"  {text}")

# Configuration
FLASK_DIR = "/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app"
DB_PATH = os.path.join(FLASK_DIR, "pc_setup.db")
APP_PY_PATH = os.path.join(FLASK_DIR, "app.py")
TEMPLATES_DIR = os.path.join(FLASK_DIR, "templates")

test_results = {}

def test_1_file_structure():
    """Test 1: Check file structure"""
    print_section("TEST 1: File Structure Check")

    passed = True

    # Check directory exists
    if os.path.exists(FLASK_DIR):
        success(f"Flask directory exists: {FLASK_DIR}")
    else:
        error(f"Flask directory not found: {FLASK_DIR}")
        return False

    # List all files
    info("\nFiles in flask-app directory:")
    try:
        items = sorted(os.listdir(FLASK_DIR))
        for item in items:
            full_path = os.path.join(FLASK_DIR, item)
            if os.path.isfile(full_path):
                size = os.path.getsize(full_path)
                info(f"  {item} ({size:,} bytes)")
            elif os.path.isdir(full_path):
                info(f"  {item}/ (directory)")
    except Exception as e:
        error(f"Cannot list directory: {e}")
        return False

    # Check critical files
    info("\nCritical files:")
    critical_files = {
        "app.py": APP_PY_PATH,
        "templates/": TEMPLATES_DIR
    }

    for name, path in critical_files.items():
        if os.path.exists(path):
            success(f"{name} exists")
        else:
            error(f"{name} NOT FOUND")
            passed = False

    return passed

def test_2_database():
    """Test 2: Check database and add test data"""
    print_section("TEST 2: Database Check and Setup")

    # Check if database exists
    if not os.path.exists(DB_PATH):
        warning(f"Database not found: {DB_PATH}")
        info("Creating new database...")

        try:
            conn = sqlite3.connect(DB_PATH)
            cursor = conn.cursor()

            # Create tables
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
            success("Database created successfully")

        except Exception as e:
            error(f"Failed to create database: {e}")
            conn.close()
            return False
    else:
        success(f"Database found: {DB_PATH}")
        conn = sqlite3.connect(DB_PATH)

    # Check tables and data
    try:
        cursor = conn.cursor()

        # Verify pc_master table
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='pc_master'")
        if cursor.fetchone():
            success("pc_master table exists")
        else:
            error("pc_master table not found")
            return False

        # Count records
        cursor.execute("SELECT COUNT(*) FROM pc_master")
        count = cursor.fetchone()[0]
        info(f"Current records in pc_master: {count}")

        # If no records, add test data
        if count == 0:
            info("No records found. Adding test data...")
            cursor.execute(
                "INSERT INTO pc_master (serial, pcname, odj_path, created_at) VALUES (?, ?, ?, datetime('now'))",
                ("TEST001", "20251117M", "/odj/20251117M.txt")
            )
            conn.commit()
            success("Test record added: ID=1, Serial=TEST001, PCName=20251117M")

        # Display all records
        cursor.execute("SELECT id, serial, pcname, odj_path, created_at FROM pc_master ORDER BY id")
        records = cursor.fetchall()

        info("\nAll PC records:")
        info("  " + "-"*66)
        info(f"  {'ID':<5} {'Serial':<15} {'PC Name':<15} {'ODJ Path':<25}")
        info("  " + "-"*66)

        for record in records:
            info(f"  {record[0]:<5} {record[1]:<15} {record[2]:<15} {record[3] or 'N/A':<25}")

        conn.close()
        return True

    except Exception as e:
        error(f"Database error: {e}")
        conn.close()
        return False

def test_3_app_code():
    """Test 3: Analyze app.py code"""
    print_section("TEST 3: Flask App Code Analysis")

    if not os.path.exists(APP_PY_PATH):
        error(f"app.py not found: {APP_PY_PATH}")
        return False

    success(f"app.py found: {APP_PY_PATH}")

    try:
        with open(APP_PY_PATH, 'r', encoding='utf-8') as f:
            content = f.read()

        size = len(content)
        lines = content.count('\n') + 1
        info(f"Size: {size:,} bytes, Lines: {lines:,}")

        # Check for key components
        info("\nCode analysis:")

        checks = {
            "Flask import": "from flask import" in content or "import flask" in content,
            "Database (sqlite3)": "sqlite3" in content,
            "Route decorator": "@app.route" in content,
            "Edit route": "/pcs/edit/" in content or "'/pcs/edit/" in content,
            "render_template": "render_template" in content,
            "GET/POST methods": "request.method" in content or "methods=" in content,
        }

        all_passed = True
        for check_name, result in checks.items():
            if result:
                success(check_name)
            else:
                error(f"{check_name} NOT FOUND")
                all_passed = False

        # Try to find all routes
        routes = re.findall(r"@app\.route\(['\"]([^'\"]+)['\"].*?\)", content)
        if routes:
            info(f"\nFound {len(routes)} route(s):")
            for route in routes:
                info(f"  - {route}")

        return all_passed

    except Exception as e:
        error(f"Cannot read app.py: {e}")
        return False

def test_4_edit_endpoint():
    """Test 4: Test the edit endpoint with curl"""
    print_section("TEST 4: PC Edit Endpoint Test")

    url = "http://localhost:5000/pcs/edit/1"
    info(f"Testing URL: {url}")

    try:
        # First check if server is reachable
        result = subprocess.run(
            ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", "http://localhost:5000"],
            capture_output=True,
            text=True,
            timeout=2
        )

        if result.stdout == "000":
            error("Flask server is NOT running")
            info("\nTo start the server, run:")
            info(f"  cd {FLASK_DIR}")
            info("  python3 app.py")
            return False

        success("Flask server is running")

        # Now test the edit endpoint
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

        info(f"\nHTTP Status Code: {http_code}")

        if http_code == "200":
            success("HTTP 200 OK - Request successful")

            # Analyze response content
            has_error = "500 Internal Server Error" in output
            has_404 = "404" in output or "Not Found" in output
            has_form = "<form" in output
            has_pcname = "pcname" in output.lower()
            has_serial = "serial" in output.lower()
            has_odj = "odj" in output.lower()

            if has_error:
                error("Server returned 500 Internal Server Error")
                info("\nError preview:")
                for line in output.split('\n')[:20]:
                    if line.strip():
                        info(f"  {line[:70]}")
                return False

            elif has_404:
                error("404 Not Found")
                return False

            elif has_form:
                success("Edit form page loaded successfully")

                info("\nForm field verification:")
                if has_pcname:
                    success("PCName field present")
                else:
                    warning("PCName field not found")

                if has_serial:
                    success("Serial field present")
                else:
                    warning("Serial field not found")

                if has_odj:
                    success("ODJ path field present")
                else:
                    warning("ODJ path field not found")

                # Show preview
                info("\nHTML preview (first 500 chars):")
                preview_lines = output[:500].split('\n')
                for line in preview_lines[:10]:
                    if line.strip():
                        info(f"  {line.strip()[:68]}")

                return True

            else:
                warning("Response received but no form detected")
                info("\nResponse preview:")
                for line in output.split('\n')[:15]:
                    if line.strip():
                        info(f"  {line[:70]}")
                return False

        elif http_code == "404":
            error("404 Not Found - Route does not exist")
            return False

        elif http_code == "500":
            error("500 Internal Server Error")
            info("\nError details:")
            for line in output.split('\n')[:20]:
                if line.strip():
                    info(f"  {line[:70]}")
            return False

        else:
            warning(f"Unexpected HTTP status: {http_code}")
            return False

    except subprocess.TimeoutExpired:
        error("Request timeout - Server not responding")
        return False

    except FileNotFoundError:
        error("curl command not found. Please install curl:")
        info("  sudo apt-get install curl")
        return False

    except Exception as e:
        error(f"Test error: {e}")
        return False

def main():
    """Main test runner"""
    print_header("PC EDIT FUNCTIONALITY TEST REPORT")
    print(f"Test Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Working Directory: {FLASK_DIR}")

    # Run all tests
    tests = [
        ("File Structure", test_1_file_structure),
        ("Database Setup", test_2_database),
        ("App Code Analysis", test_3_app_code),
        ("Edit Endpoint", test_4_edit_endpoint),
    ]

    results = {}
    for test_name, test_func in tests:
        try:
            results[test_name] = test_func()
        except Exception as e:
            error(f"Test '{test_name}' crashed: {e}")
            results[test_name] = False

    # Summary
    print_header("TEST SUMMARY")

    for test_name, passed in results.items():
        if passed:
            success(f"{test_name:25} : PASSED")
        else:
            error(f"{test_name:25} : FAILED")

    total = len(results)
    passed = sum(1 for v in results.values() if v)
    failed = total - passed

    print(f"\n{Colors.BOLD}Total Tests: {total} | "
          f"Passed: {Colors.GREEN}{passed}{Colors.RESET}{Colors.BOLD} | "
          f"Failed: {Colors.RED}{failed}{Colors.RESET}")

    if all(results.values()):
        print(f"\n{Colors.BOLD}{Colors.GREEN}✓ ALL TESTS PASSED{Colors.RESET}")
        return 0
    else:
        print(f"\n{Colors.BOLD}{Colors.RED}✗ SOME TESTS FAILED{Colors.RESET}")
        return 1

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print(f"\n\n{Colors.YELLOW}Test interrupted by user{Colors.RESET}")
        sys.exit(130)
