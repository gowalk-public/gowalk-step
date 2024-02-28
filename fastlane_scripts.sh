#!/bin/bash
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

FORMATTED_PRIVATE_KEY=$(echo "$APPLE_PRIVATE_KEY" | awk 'ORS="\\n"')

if [ -n "${BITRISE_TARGET}" ]; then
    FASTLANE_SCHEME=$BITRISE_TARGET
    [ "$is_debug" = "yes" ] && echo "For Fastlane will be used BITRISE_TARGET"
else
    FASTLANE_SCHEME=$BITRISE_SCHEME
    [ "$is_debug" = "yes" ] && echo "For Fastlane will be used BITRISE_SCHEME"
fi

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

cat << EOF > "./fastlane/Fastfile"
lane :update_encryption_settings do
  update_info_plist(
    scheme: "$FASTLANE_SCHEME",
    xcodeproj: "$PROJECT_FILE",
    block: proc do |plist|
      plist['ITSAppUsesNonExemptEncryption'] = false
      plist['CFBundleVersion'] = $APP_VERSION
      plist['CFBundleShortVersionString'] = $APP_VERSION
    end
  )
end
EOF

#Update build encryption settings
if [ "$is_debug" = "yes" ]; then
  fastlane update_encryption_settings
else
  fastlane update_encryption_settings >/dev/null 2>&1
fi

#Update what's new only if status PREPARE_FOR_SUBMISSION, update_whats_new = yes and this is "appstore-release" workflow
if [ "$update_whats_new" = "yes" ] && [ "$APP_STATUS" = "PREPARE_FOR_SUBMISSION" ] && { [ "$BITRISE_TRIGGERED_WORKFLOW_TITLE" = "appstore-release" ] || [ "$BITRISE_TRIGGERED_WORKFLOW_TITLE" = "deploy" ]; }; then
    case "$APP_VERSION" in
        "1.0"|"1.0.0"|"0.0.0"|"0.0")
            [ "$is_debug" = "yes" ] && echo "It's a first App version, What's new will not be updated"
            ;;
        *)
            if [ "$is_debug" = "yes" ]; then
              fastlane run set_changelog api_key_path:"./fastlane/key.json" version:"$APP_VERSION" app_identifier:"$PRODUCT_BUNDLE_IDENTIFIER" || true
            else
              fastlane run set_changelog api_key_path:"./fastlane/key.json" version:"$APP_VERSION" app_identifier:"$PRODUCT_BUNDLE_IDENTIFIER" >/dev/null 2>&1 || true
            fi
            ;;
    esac
fi