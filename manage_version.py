import requests
import jwt
import time
import os
import json

def load_env_variables():
    return {
        "APP_ID": os.environ.get('APP_ID'),
        "BUNDLE_ID": os.environ.get('PRODUCT_BUNDLE_IDENTIFIER'),
        "KEY_ID": os.environ.get('APPLE_KEY_ID'),
        "ISSUER_ID": os.environ.get('APPLE_ISSUER_ID'),
        "PRIVATE_KEY": os.environ.get('APPLE_PRIVATE_KEY')
    }

def generate_jwt_token(issuer_id, key_id, private_key):
    # Generates a JWT token using the given issuer ID, key ID, and the private key string.
    # The private key is passed directly as a string

    # Generate an expiration time (20 minutes from now)
    expir = round(time.time() + 20 * 60)

    # Sign the token
    return jwt.encode(
        {'iss': issuer_id, 'iat': round(time.time()), 'exp': expir, 'aud': 'appstoreconnect-v1'},
        private_key, algorithm='ES256',
        headers={'alg': 'ES256', 'kid': key_id, 'typ': 'JWT'}
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
    response = requests.get(url, headers=headers)

    # Check if the request was successful
    if response.status_code == 200:
        data = response.json()
        versions = data.get('data', [])
        # Find the version with the latest createdDate
        latest_version = max(versions, key=lambda x: x['attributes']['createdDate'], default=None)
        if latest_version:
            return latest_version['attributes']
        else:
            return "No versions found."
    else:
        return f"Request failed with status code: {response.status_code}"

def calculate_next_version(current_version):
    parts = [int(p) for p in current_version.split('.')]
    while len(parts) < 3:
        parts.append(0)

    parts[-1] += 1
    for i in range(len(parts) - 1, 0, -1):
        if parts[i] > 9:
            parts[i] = 0
            parts[i - 1] += 1

    if parts[0] == 0:
        parts[0] = 1

    return '.'.join(map(str, parts))

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
                "releaseType": "MANUAL",
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
    response = requests.post(url, json=payload, headers=headers)
    return response.json()

def main():
    env_vars = load_env_variables()
    jwt_token = generate_jwt_token(env_vars['ISSUER_ID'], env_vars['KEY_ID'], env_vars['PRIVATE_KEY'])
    latest_version_attributes = get_latest_app_version(env_vars['APP_ID'], jwt_token)
    print(f"APP_ID: {env_vars['APP_ID']}")

    if isinstance(latest_version_attributes, dict):
        print(f"Latest Version String: {latest_version_attributes.get('versionString')}")
        print(f"App Store State: {latest_version_attributes.get('appStoreState')}")
    else:
        print(latest_version_attributes)
    latest_version_attributes = get_latest_app_version(env_vars['APP_ID'], jwt_token)
    app_store_state = latest_version_attributes.get('appStoreState')
    current_version = latest_version_attributes.get('versionString')

    eligible_states = [
        'REMOVED_FROM_SALE',
        'READY_FOR_SALE',
        'PENDING_DEVELOPER_RELEASE',
        'PENDING_APPLE_RELEASE',
        'PREORDER_READY_FOR_SALE'
    ]

    if app_store_state in eligible_states:
        new_version = calculate_next_version(current_version)
        response = create_app_store_version(env_vars['APP_ID'], new_version, jwt_token)
        result = {'APP_VERSION': new_version}
    else:
        result = {'APP_VERSION': current_version}
    print(json.dumps(result))

if __name__ == "__main__":
    main()