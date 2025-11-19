# PC Edit Functionality Test Instructions

## Overview
This document provides instructions for testing the PC edit functionality of the Flask management application.

## Test Date
2025-11-17

## Test Scope
The test verifies the following:
1. Database existence and structure (pc_master table)
2. Test data availability (Serial: TEST001, PCName: 20251117M)
3. PC edit page accessibility (http://localhost:5000/pcs/edit/1)
4. Flask application code structure and routes

## Test Files Created

### 1. final_test_report.py (RECOMMENDED)
**Description**: Comprehensive automated test with colored output and detailed reporting

**Usage**:
```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app
python3 final_test_report.py
```

**Features**:
- Complete file structure check
- Database validation and test data insertion
- Flask app code analysis
- Edit endpoint HTTP testing
- Colored output for easy reading
- Detailed error messages

### 2. automated_test.sh
**Description**: Shell script version of the test suite

**Usage**:
```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app
bash automated_test.sh
```

### 3. simple_test.py
**Description**: Quick database check and test data insertion

**Usage**:
```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app
python3 simple_test.py
```

### 4. check_app_structure.py
**Description**: Analyzes Flask app.py code structure

**Usage**:
```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app
python3 check_app_structure.py
```

## Test Execution Steps

### Step 1: Ensure Flask Server is Running

Before running tests, make sure the Flask application is running:

```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app
python3 app.py
```

The server should start on http://localhost:5000

### Step 2: Run the Complete Test (Recommended)

In a new terminal:

```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app
python3 final_test_report.py
```

This will:
1. Check if all required files exist
2. Verify database structure
3. Add test data if needed (Serial: TEST001, PCName: 20251117M)
4. Analyze app.py code
5. Test the edit endpoint with curl
6. Generate a comprehensive report

### Step 3: Manual Verification (Optional)

You can also manually test the edit page:

```bash
# Using curl
curl http://localhost:5000/pcs/edit/1

# Or using a web browser
# Navigate to: http://localhost:5000/pcs/edit/1
```

## Expected Results

### Success Criteria

1. **Database Check**:
   - pc_master table exists
   - At least 1 test record present (ID=1, Serial=TEST001, PCName=20251117M)

2. **Edit Endpoint**:
   - HTTP 200 status code
   - HTML page with edit form
   - Form fields: serial, pcname, odj_path

3. **File Structure**:
   - app.py exists
   - templates/ directory exists
   - pc_setup.db exists

### Failure Scenarios and Solutions

#### Scenario 1: Flask Server Not Running
**Error**: "Flask server is NOT running"

**Solution**:
```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app
python3 app.py
```

#### Scenario 2: Database Not Found
**Error**: "Database not found"

**Solution**: The test will automatically create the database and add test data

#### Scenario 3: 404 Not Found
**Error**: "404 Not Found - Route does not exist"

**Solution**: Check if the edit route is defined in app.py:
```python
@app.route('/pcs/edit/<int:pc_id>', methods=['GET', 'POST'])
def edit_pc(pc_id):
    # Edit logic here
```

#### Scenario 4: 500 Internal Server Error
**Error**: "500 Internal Server Error"

**Solution**: Check Flask application logs for detailed error messages

## Database Schema

The test expects the following database structure:

### pc_master Table
```sql
CREATE TABLE pc_master (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    serial TEXT UNIQUE NOT NULL,
    pcname TEXT NOT NULL,
    odj_path TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)
```

### Test Data
```sql
INSERT INTO pc_master (serial, pcname, odj_path, created_at)
VALUES ('TEST001', '20251117M', '/odj/20251117M.txt', datetime('now'))
```

## Manual Database Inspection

To manually inspect the database:

```bash
sqlite3 /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app/pc_setup.db

# Inside sqlite3:
.tables                           # List all tables
SELECT * FROM pc_master;          # View all PC records
.schema pc_master                 # View table structure
.quit                             # Exit
```

## Troubleshooting

### Issue: curl not found
```bash
sudo apt-get update
sudo apt-get install curl
```

### Issue: Permission denied on database
```bash
chmod 664 /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app/pc_setup.db
```

### Issue: Test script not executable
```bash
chmod +x final_test_report.py
chmod +x automated_test.sh
```

## Test Results Location

Test results and responses are saved to:
- `/tmp/edit_response.html` - Full HTTP response from edit endpoint

View with:
```bash
cat /tmp/edit_response.html
# or
less /tmp/edit_response.html
```

## Contact

For issues or questions about these tests, refer to the main project documentation in CLAUDE.md
