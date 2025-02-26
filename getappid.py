import os
import requests
import jwt
import time
import json
import sys

# Accessing the bundle_identifier environment variable
bundle_id = os.environ.get('PRODUCT_BUNDLE_IDENTIFIER')
key_id = os.environ.get('APPLE_KEY_ID')
issuer_id = os.environ.get('APPLE_ISSUER_ID')
private_key = os.environ.get('APPLE_PRIVATE_KEY')

# Create the JWT Token
token = jwt.encode(
    {
        'iss': issuer_id,
        'exp': time.time() + 60*20,
        'aud': 'appstoreconnect-v1'
    },
    private_key,
    algorithm='ES256',
    headers={'kid': key_id}
)

# Set up the request headers
headers = {
    'Authorization': f'Bearer {token}',
    'Content-Type': 'application/json'
}

# Make the request to list apps
response = requests.get('https://api.appstoreconnect.apple.com/v1/apps', headers=headers)

# Try to parse the response as JSON
try:
    response_json = response.json()
except ValueError:
    print(f"Error: Unable to parse JSON from the response.")
    print(f"Status Code: {response.status_code}")
    print(f"Response Text: {response.text}")
    sys.exit(1)

# Check if 'data' is present in the JSON
if 'data' not in response_json:
    print(f"Error: 'data' field not found in the response JSON.")
    print(f"Status Code: {response.status_code}")
    print("Full Response JSON:")
    print(json.dumps(response_json, indent=2))
    sys.exit(1)

# If 'data' is present, loop through it to find the correct app ID
app_id = None
for app in response_json['data']:
    if app['attributes']['bundleId'] == bundle_id:
        app_id = app['id']
        break

# Output the result
if app_id:
    # Output APP_ID as JSON
    result = {'APP_ID': app_id}
else:
    # If we couldn't find a matching app, set APP_ID to 0
    result = {'APP_ID': 0}

print(json.dumps(result))