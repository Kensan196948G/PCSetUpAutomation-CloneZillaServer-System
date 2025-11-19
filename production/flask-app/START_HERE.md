# START HERE - PC Edit Functionality Testing

## One Command to Rule Them All

```bash
bash RUN_TEST.sh
```

That's it! This command will test everything automatically.

---

## But First...

Make sure Flask is running in another terminal:

```bash
cd /mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app
python3 app.py
```

Leave it running, then run the test in a new terminal.

---

## What This Tests

1. Database structure and test data
2. Flask application code
3. Edit page at: http://localhost:5000/pcs/edit/1

---

## Test Data

The test will ensure this record exists:

| Field | Value |
|-------|-------|
| Serial | TEST001 |
| PC Name | 20251117M |
| ODJ Path | /odj/20251117M.txt |

---

## Success Looks Like

```
✓ File Structure      : PASSED
✓ Database Setup      : PASSED
✓ App Code Analysis   : PASSED
✓ Edit Endpoint       : PASSED

✓ ALL TESTS PASSED
```

---

## If You See "Server Not Running"

Start Flask first:
```bash
python3 app.py
```

Then run the test again.

---

## Want More Details?

- **Quick Guide**: Read `README_TEST.md`
- **Full Docs**: Read `TEST_SUMMARY.md`
- **All Files**: See `TEST_FILES_INDEX.md`

---

## Ready?

```bash
bash RUN_TEST.sh
```

Go!

---

**File Location**: `/mnt/Linux-ExHDD/PCSetUpAutomation-CloneZillaServer-Project/flask-app/`
