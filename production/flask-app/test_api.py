"""Simple API test script."""
import requests
import json

BASE_URL = 'http://localhost:5000/api'


def test_pc_crud():
    """Test PC CRUD operations."""
    print("Testing PC CRUD operations...")

    # Create PC
    data = {
        'serial': 'TEST123456',
        'pcname': '20251116M',
        'odj_path': '/srv/odj/20251116M.txt'
    }

    response = requests.post(f'{BASE_URL}/pc', json=data)
    print(f"Create PC: {response.status_code}")
    print(json.dumps(response.json(), indent=2))

    # Get PC info
    response = requests.get(f'{BASE_URL}/pcinfo?serial=TEST123456')
    print(f"\nGet PC info: {response.status_code}")
    print(json.dumps(response.json(), indent=2))

    # List PCs
    response = requests.get(f'{BASE_URL}/pc')
    print(f"\nList PCs: {response.status_code}")
    data = response.json()
    print(f"Total PCs: {data.get('count', 0)}")


def test_images():
    """Test images API."""
    print("\n\nTesting Images API...")

    response = requests.get(f'{BASE_URL}/images')
    print(f"List images: {response.status_code}")
    data = response.json()
    print(f"Total images: {data.get('count', 0)}")


def test_deployment():
    """Test deployment API."""
    print("\n\nTesting Deployment API...")

    # Create deployment
    data = {
        'name': 'Test Deployment',
        'image_name': 'test-image',
        'mode': 'multicast',
        'target_serials': ['TEST123456'],
        'created_by': 'test-script'
    }

    response = requests.post(f'{BASE_URL}/deployment', json=data)
    print(f"Create deployment: {response.status_code}")
    if response.status_code == 201:
        deployment = response.json()['deployment']
        print(f"Deployment ID: {deployment['id']}")

        # Get deployment status
        response = requests.get(f"{BASE_URL}/deployment/{deployment['id']}/status")
        print(f"\nGet deployment status: {response.status_code}")
        print(json.dumps(response.json(), indent=2))


if __name__ == '__main__':
    print("API Test Script")
    print("=" * 50)

    try:
        test_pc_crud()
        test_images()
        # test_deployment()  # Uncomment when ready to test

    except requests.exceptions.ConnectionError:
        print("\nError: Could not connect to API server.")
        print("Make sure the Flask app is running on http://localhost:5000")

    except Exception as e:
        print(f"\nError: {e}")
