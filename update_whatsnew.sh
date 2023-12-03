#!/bin/bash

FORMATTED_PRIVATE_KEY=$(echo "$APPLE_PRIVATE_KEY" | awk 'ORS="\\n"')

rm -rf "./fastlane"
mkdir "./fastlane"

cat << EOF > "./fastlane/changelog.txt"
- Improved Performance: Faster, smoother app experience
- New Functionalities: Intuitive and user-friendly
- Refreshed Design: Enhanced user interface
- Bug Fixes: Minor issues resolved for seamless use
- Enhanced Security: Updated to protect your data
EOF

cat << EOF > "./fastlane/key.json"
{
  "key_id": "$APPLE_KEY_ID",
  "issuer_id": "$APPLE_ISSUER_ID",
  "key": "$FORMATTED_PRIVATE_KEY",
  "duration": 1200,
  "in_house": false
}
EOF

fastlane run set_changelog api_key_path:"./fastlane/key.json" version:"$APP_VERSION" app_identifier:"$PRODUCT_BUNDLE_IDENTIFIER"