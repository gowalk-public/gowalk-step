import os
import requests
import jwt
import time

# Test data
bundle_id = "com.ski.parcelTracker"
key_id = "9DYUS8CM4N"
issuer_id = "8425a091-5dc8-4c20-851b-646a1200d697"
private_key = """-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgFVq8WnK9YfMGGzLD
5d1+G7RSGoJvofA4rFQItJLkPVygCgYIKoZIzj0DAQehRANCAAS2mtzpl3A48N9l
/1fbLpdgTygpMD9FDinS29JF1iSWXCDRfwzXfBOZwkCcuo2GSJ2/xxLAa6BWTNAB
jmgwX4Kr
-----END PRIVATE KEY-----
"""
'''
# Accessing the bundle_identifier environment variable
bundle_id = os.environ.get('PRODUCT_BUNDLE_IDENTIFIER')
key_id = os.environ.get('APPLE_KEY_ID')
issuer_id = os.environ.get('APPLE_ISSUER_ID')
private_key = os.environ.get('APPLE_PRIVATE_KEY')
'''
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
    # Set APP_ID environment variable
    os.environ['APP_ID'] = app_id
    print(f"APP_ID set to {app_id}")
else:
    print("No matching app found.")