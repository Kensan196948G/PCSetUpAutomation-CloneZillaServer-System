#!/usr/bin/env python3
import sqlite3
import os

db_path = "/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app/pc_setup.db"

# Check if database exists
if os.path.exists(db_path):
    print(f"Database found at: {db_path}")

    # Connect and check existing records
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Check if pc_master table exists
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='pc_master'")
    table_exists = cursor.fetchone()

    if table_exists:
        print("pc_master table exists")

        # Count existing records
        cursor.execute("SELECT COUNT(*) FROM pc_master")
        count = cursor.fetchone()[0]
        print(f"Existing records: {count}")

        # Show all records
        cursor.execute("SELECT id, serial, pcname, odj_path, created_at FROM pc_master")
        records = cursor.fetchall()

        if records:
            print("\nExisting PC records:")
            for record in records:
                print(f"  ID: {record[0]}, Serial: {record[1]}, PCName: {record[2]}, ODJ: {record[3]}, Created: {record[4]}")
        else:
            print("\nNo records found. Adding test data...")
            cursor.execute(
                "INSERT INTO pc_master (serial, pcname, odj_path, created_at) VALUES (?, ?, ?, datetime('now'))",
                ("TEST001", "20251117M", "/odj/20251117M.txt")
            )
            conn.commit()
            print("Test record added: Serial=TEST001, PCName=20251117M")
    else:
        print("pc_master table does not exist. Creating it...")
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
        print("Table created and test record added")

    conn.close()
else:
    print(f"Database not found at: {db_path}")
    print("Please ensure the Flask app has been initialized")
