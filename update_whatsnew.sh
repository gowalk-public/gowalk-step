#!/bin/bash

FORMATTED_PRIVATE_KEY=$(echo "$APPLE_PRIVATE_KEY" | awk 'ORS="\\n"')

# Define the content of the key.json file
cat << EOF > "${THIS_SCRIPT_DIR}/fastlane/key.json"
{
  "key_id": "$APPLE_KEY_ID",
  "issuer_id": "$APPLE_ISSUER_ID",
  "key": "$FORMATTED_PRIVATE_KEY",
  "duration": 1200,
  "in_house": false
}
EOF

fastlane run set_changelog api_key_path:"${THIS_SCRIPT_DIR}/fastlane/key.json" version:"$APP_VERSION" app_identifier:"$PRODUCT_BUNDLE_IDENTIFIER"