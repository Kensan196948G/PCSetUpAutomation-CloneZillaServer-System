"""Test Settings API endpoints."""
import requests
import json


def test_settings_api():
    """Test all settings API endpoints."""
    base_url = "http://localhost:5000"

    print("=" * 80)
    print("Settings API Test")
    print("=" * 80)
    print()

    # Test 1: Get current settings
    print("1. Testing GET /api/settings")
    print("-" * 80)
    try:
        response = requests.get(f"{base_url}/api/settings")
        if response.status_code == 200:
            data = response.json()
            print(f"Status: OK (200)")
            print(f"Current settings:")
            print(json.dumps(data, indent=2, ensure_ascii=False))
        else:
            print(f"Status: ERROR ({response.status_code})")
            print(f"Response: {response.text}")
    except Exception as e:
        print(f"ERROR: {e}")
    print()

    # Test 2: Validate valid path
    print("2. Testing POST /api/settings/image-path/validate (valid path)")
    print("-" * 80)
    try:
        payload = {"path": "/mnt/Linux-ExHDD/Ubuntu-ExHDD"}
        response = requests.post(
            f"{base_url}/api/settings/image-path/validate",
            json=payload,
            headers={"Content-Type": "application/json"}
        )
        if response.status_code == 200:
            data = response.json()
            print(f"Status: OK (200)")
            print(f"Validation result:")
            print(json.dumps(data, indent=2, ensure_ascii=False))
        else:
            print(f"Status: ERROR ({response.status_code})")
            print(f"Response: {response.text}")
    except Exception as e:
        print(f"ERROR: {e}")
    print()

    # Test 3: Validate invalid path (non-existent)
    print("3. Testing POST /api/settings/image-path/validate (invalid path)")
    print("-" * 80)
    try:
        payload = {"path": "/non/existent/path"}
        response = requests.post(
            f"{base_url}/api/settings/image-path/validate",
            json=payload,
            headers={"Content-Type": "application/json"}
        )
        data = response.json()
        print(f"Status: {response.status_code}")
        print(f"Validation result:")
        print(json.dumps(data, indent=2, ensure_ascii=False))
    except Exception as e:
        print(f"ERROR: {e}")
    print()

    # Test 4: Validate /tmp (should be valid)
    print("4. Testing POST /api/settings/image-path/validate (/tmp)")
    print("-" * 80)
    try:
        payload = {"path": "/tmp"}
        response = requests.post(
            f"{base_url}/api/settings/image-path/validate",
            json=payload,
            headers={"Content-Type": "application/json"}
        )
        if response.status_code == 200:
            data = response.json()
            print(f"Status: OK (200)")
            print(f"Validation result:")
            print(json.dumps(data, indent=2, ensure_ascii=False))
        else:
            print(f"Status: ERROR ({response.status_code})")
            print(f"Response: {response.text}")
    except Exception as e:
        print(f"ERROR: {e}")
    print()

    # Test 5: Update image path (demonstration - comment out if you don't want to change)
    print("5. Testing POST /api/settings/image-path (update path)")
    print("-" * 80)
    print("SKIPPED: To avoid changing production settings")
    print("To test this, uncomment the code below and run manually")
    print()

    # Uncomment to test path update:
    # try:
    #     payload = {"path": "/mnt/Linux-ExHDD/Ubuntu-ExHDD"}
    #     response = requests.post(
    #         f"{base_url}/api/settings/image-path",
    #         json=payload,
    #         headers={"Content-Type": "application/json"}
    #     )
    #     data = response.json()
    #     print(f"Status: {response.status_code}")
    #     print(f"Update result:")
    #     print(json.dumps(data, indent=2, ensure_ascii=False))
    # except Exception as e:
    #     print(f"ERROR: {e}")
    # print()

    print("=" * 80)
    print("Test completed!")
    print("=" * 80)


if __name__ == "__main__":
    print("\nMake sure the Flask server is running on http://localhost:5000")
    print("You can start it with: source venv/bin/activate && python app.py")
    print()

    try:
        test_settings_api()
    except KeyboardInterrupt:
        print("\n\nTest interrupted by user")
    except Exception as e:
        print(f"\n\nTest failed with error: {e}")
