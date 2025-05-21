import requests
import jwt
import time
import os
import json
from packaging.version import parse

app_id = os.environ.get('APP_ID')
bundle_id = os.environ.get('PRODUCT_BUNDLE_IDENTIFIER')
key_id = os.environ.get('APPLE_KEY_ID')
issuer_id = os.environ.get('APPLE_ISSUER_ID')
private_key = os.environ.get('APPLE_PRIVATE_KEY')

#For Debug
#app_id = "6473677751"
#bundle_id = "gowalk.fastingApp.com"
#key_id = "5NWGU79GMQ"
#issuer_id = "f24f1629-3461-4a57-8807-8f7c9964d652"
#private_key = """"""

# Create the JWT Token
jwt_token = jwt.encode(
    {
        'iss': issuer_id,
        'exp': time.time() + 60*20,
        'aud': 'appstoreconnect-v1'
    },
    private_key,
    algorithm='ES256',
    headers={'kid': key_id}
)

def get_latest_app_version(app_id, jwt_token):
    # Fetches the latest app version information from the App Store API.
    # Define the request headers
    headers = {
        'Authorization': f'Bearer {jwt_token}',
        'Content-Type': 'application/json'
    }

    # API endpoint to list all App Store versions for an app
    url = f'https://api.appstoreconnect.apple.com/v1/apps/{app_id}/appStoreVersions'

    # Make the GET request
    try:
        response = requests.get(url, headers=headers, timeout=30)
    except requests.exceptions.RequestException as e:
        return {"versionString": None, "appStoreVersionId": None, "error": f"Network error: {e}"}
    # Comment if not debug
    #print(f"The get_latest_app_version response is: {response.json()}")
    # Check if the request was successful
    if response.status_code == 200:
        data = response.json()
        versions = data.get('data', [])
        # Find the version with the latest createdDate
        latest_version = max(versions, key=lambda x: x['attributes']['createdDate'], default=None)
        if latest_version:
            return {
                'versionString': latest_version['attributes']['versionString'],
                'appStoreVersionId': latest_version['id'],  # Corrected extraction of the ID
                'appStoreState': latest_version['attributes']['appStoreState']  # Extracting the state here if needed
            }
        else:
            return {"versionString": None, "appStoreVersionId": None}
    else:
        return {"versionString": None, "appStoreVersionId": None, "error": f"Request failed with status code: {response.status_code}"}

def calculate_next_version(current_version):
    version = parse(current_version)
    
    # Increment the micro version
    new_micro = version.micro + 1
    new_minor = version.minor
    new_major = version.major

    # Check if micro version needs to reset and minor needs to increment
    if new_micro >= 10:
        new_micro = 0
        new_minor = version.minor + 1

    # Check if minor version needs to reset and major needs to increment
    if new_minor >= 10:
        new_minor = 0
        new_micro = 0
        new_major = version.major + 1

    return f"{new_major}.{new_minor}.{new_micro}"

def create_app_store_version(app_id, version_string, jwt_token):
    url = "https://api.appstoreconnect.apple.com/v1/appStoreVersions"
    headers = {
        'Authorization': f'Bearer {jwt_token}',
        'Content-Type': 'application/json'
    }
    payload = {
        "data": {
            "type": "appStoreVersions",
            "attributes": {
                "platform": "IOS",
                "versionString": version_string,
                "releaseType": "AFTER_APPROVAL",
            },
            "relationships": {
                "app": {
                    "data": {
                        "type": "apps",
                        "id": app_id
                    }
                }
            }
        }
    }
    try:
        response = requests.post(url, json=payload, headers=headers, timeout=30)
    except requests.exceptions.RequestException as e:
        return {"error": f"Network error: {e}"}
    # Comment if not debug
    #print(f"The create_app_store_version response is: {response.json()}")
    return response.json()

def main():
    latest_version_attributes = get_latest_app_version(app_id, jwt_token)
    app_store_state = latest_version_attributes.get('appStoreState')
    current_version_id = latest_version_attributes.get('appStoreVersionId')
    current_version = latest_version_attributes.get('versionString')

    if app_store_state == 'PENDING_DEVELOPER_RELEASE':
        print("Error: App is Pending Developer Release. Publish it in AppStore when try again")
        return
    elif app_store_state == 'READY_FOR_SALE': #and os.getenv('create_new_version') == 'yes':
        new_version = calculate_next_version(current_version)
        response = create_app_store_version(app_id, new_version, jwt_token)
        new_version_id = response.get('data', {}).get('id')
        new_app_store_state = 'PREPARE_FOR_SUBMISSION'
        result = {'APP_VERSION': new_version, 'APP_VERSION_ID': new_version_id, 'APP_STATUS': new_app_store_state}
    else:
        result = {'APP_VERSION': current_version, 'APP_VERSION_ID': current_version_id, 'APP_STATUS': app_store_state}
    print(json.dumps(result))
if __name__ == "__main__":
    main()