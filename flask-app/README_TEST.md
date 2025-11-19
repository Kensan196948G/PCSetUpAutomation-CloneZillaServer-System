# PC Edit Functionality Test - README

## Quick Start Guide

To test the PC edit functionality, run:

```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app
bash RUN_TEST.sh
```

That's it! The script will test everything automatically.

## What Gets Tested?

1. **Database Check** - Verifies pc_setup.db exists with correct structure
2. **Test Data** - Ensures test record exists (Serial: TEST001, PCName: 20251117M)
3. **Flask App** - Validates app.py code structure
4. **Edit Page** - Tests HTTP access to http://localhost:5000/pcs/edit/1

## Before Running Tests

Make sure the Flask server is running:

```bash
# In one terminal:
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app
python3 app.py

# In another terminal, run the test:
bash RUN_TEST.sh
```

## Test Files

| File | Purpose |
|------|---------|
| `RUN_TEST.sh` | **Main test launcher** - Start here! |
| `final_test_report.py` | Comprehensive test with colored output |
| `TEST_SUMMARY.md` | Detailed test documentation |
| `TEST_INSTRUCTIONS.md` | Step-by-step testing guide |

## Expected Result

If everything works, you'll see:

```
✓ File Structure          : PASSED
✓ Database Setup          : PASSED
✓ App Code Analysis       : PASSED
✓ Edit Endpoint           : PASSED

✓ ALL TESTS PASSED
```

## If Tests Fail

### Server Not Running?
```bash
python3 app.py
```

### Need More Details?
Read `TEST_SUMMARY.md` for complete troubleshooting guide.

## Manual Test (Optional)

You can also test manually:

```bash
# 1. Check database
python3 simple_test.py

# 2. Test endpoint
curl http://localhost:5000/pcs/edit/1

# 3. Or use browser
# Navigate to: http://localhost:5000/pcs/edit/1
```

## Files Created

All test scripts are in:
```
/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app/
```

Database location:
```
/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app/pc_setup.db
```

## Questions?

- See `TEST_INSTRUCTIONS.md` for detailed documentation
- See `TEST_SUMMARY.md` for troubleshooting
- See main `CLAUDE.md` for project overview

---

**Ready to test? Run:**
```bash
bash RUN_TEST.sh
```
