#!/usr/bin/env python3
import os

flask_dir = "/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app"

print("Files in flask-app directory:")
print("-" * 60)

for item in sorted(os.listdir(flask_dir)):
    full_path = os.path.join(flask_dir, item)
    if os.path.isfile(full_path):
        size = os.path.getsize(full_path)
        print(f"  {item} ({size} bytes)")
    elif os.path.isdir(full_path):
        print(f"  {item}/ (directory)")

print("\nChecking for key files:")
print("-" * 60)

key_files = ["app.py", "models.py", "api.py", "pc_setup.db"]
for filename in key_files:
    filepath = os.path.join(flask_dir, filename)
    if os.path.exists(filepath):
        print(f"  ✓ {filename} exists")
    else:
        print(f"  ✗ {filename} NOT FOUND")
