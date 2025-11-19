#!/usr/bin/env python3
import os
import re

flask_dir = "/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app"

print("="*70)
print("FLASK APP STRUCTURE CHECK")
print("="*70)

# Check if app.py exists
app_py_path = os.path.join(flask_dir, "app.py")

if os.path.exists(app_py_path):
    print(f"\n✓ app.py found at: {app_py_path}")
    print(f"  Size: {os.path.getsize(app_py_path)} bytes")

    # Read and analyze app.py
    with open(app_py_path, 'r', encoding='utf-8') as f:
        content = f.read()

    print("\nAnalyzing app.py content...")

    # Check for edit route
    if '/pcs/edit/' in content or '@app.route' in content:
        print("✓ Contains route definitions")

        # Find all routes
        routes = re.findall(r"@app\.route\(['\"]([^'\"]+)['\"].*?\)", content)
        if routes:
            print(f"\nFound {len(routes)} routes:")
            for route in routes:
                print(f"  - {route}")

            if any('edit' in r for r in routes):
                print("\n✓ Edit route is defined")
            else:
                print("\n✗ Edit route NOT found in routes")
        else:
            print("\n⚠ Could not parse routes")

    else:
        print("✗ No Flask routes found")

    # Check for key functions
    print("\nKey elements check:")
    checks = {
        "Flask import": "from flask import" in content or "import flask" in content,
        "Database connection": "sqlite3" in content or "db" in content.lower(),
        "Edit function": "def edit" in content.lower(),
        "GET/POST handling": "request.method" in content,
        "Template rendering": "render_template" in content
    }

    for check_name, result in checks.items():
        status = "✓" if result else "✗"
        print(f"  {status} {check_name}")

    # Show first 1000 characters
    print("\nFirst 1000 characters of app.py:")
    print("-"*70)
    print(content[:1000])
    print("-"*70)

else:
    print(f"\n✗ app.py NOT FOUND at: {app_py_path}")
    print("\nListing all Python files in flask-app directory:")

    for item in os.listdir(flask_dir):
        if item.endswith('.py'):
            full_path = os.path.join(flask_dir, item)
            size = os.path.getsize(full_path)
            print(f"  - {item} ({size} bytes)")

# Check for templates directory
templates_dir = os.path.join(flask_dir, "templates")
if os.path.exists(templates_dir):
    print(f"\n✓ templates directory found")
    print("  Templates:")
    for item in os.listdir(templates_dir):
        if item.endswith('.html'):
            print(f"    - {item}")
else:
    print(f"\n✗ templates directory NOT FOUND")

print("\n" + "="*70)
