#!/usr/bin/env python3
import sqlite3
import os

db_path = "/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app/pc_setup.db"

print("="*60)
print("DATABASE CHECK AND SETUP")
print("="*60)

# Create or check database
if not os.path.exists(db_path):
    print(f"\nDatabase not found. Creating: {db_path}")
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
    print("Database created successfully")
else:
    print(f"\nDatabase exists: {db_path}")
    conn = sqlite3.connect(db_path)

cursor = conn.cursor()

# Check if pc_master table exists and has data
cursor.execute("SELECT COUNT(*) FROM pc_master")
count = cursor.fetchone()[0]

print(f"Current record count: {count}")

if count == 0:
    print("\nNo records found. Adding test data...")
    cursor.execute(
        "INSERT INTO pc_master (serial, pcname, odj_path, created_at) VALUES (?, ?, ?, datetime('now'))",
        ("TEST001", "20251117M", "/odj/20251117M.txt")
    )
    conn.commit()
    print("Test record added successfully")
    count = 1

# Display all records
print(f"\nAll PC records (Total: {count}):")
print("-"*60)
cursor.execute("SELECT id, serial, pcname, odj_path, created_at FROM pc_master ORDER BY id")
for row in cursor.fetchall():
    print(f"ID: {row[0]:3} | Serial: {row[1]:12} | PC: {row[2]:12} | ODJ: {row[3]:25} | Created: {row[4]}")

conn.close()

print("\n" + "="*60)
print("Next step: Test the edit endpoint")
print("Run: curl http://localhost:5000/pcs/edit/1")
print("="*60)
