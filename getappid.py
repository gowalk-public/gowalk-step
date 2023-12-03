import os
import requests
import jwt
import time
import json

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
response_json = response.json()  # Convert response to JSON

app_id = None
for app in response_json['data']:  # Access data in the JSON object
    if app['attributes']['bundleId'] == bundle_id:
        app_id = app['id']
        break

if app_id:
    # Output APP_ID as JSON
    result = {'APP_ID': app_id}
else:
    result = {'APP_ID': 0}
print(json.dumps(result))