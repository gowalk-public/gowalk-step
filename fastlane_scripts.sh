#!/bin/bash
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

FORMATTED_PRIVATE_KEY=$(echo "$APPLE_PRIVATE_KEY" | awk 'ORS="\\n"')

# Check if md5sum is installed
if ! command -v md5sum &> /dev/null; then
    echo "md5sum could not be found. Installing..."
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "Homebrew is not installed."
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" &> /dev/null
    else
        # Install md5sum via Homebrew
        brew install md5sha1sum &> /dev/null
    fi
else
    echo "md5sum is already installed."
fi

# Generate four distinct paybonus schemes based on APP_ID
# Original formula for the first scheme (unchanged)
hash=$(echo -n "$APP_ID" | md5sum | awk '{print $1}')
N1=$(( (0x${hash:0:8} % 45) + 1 ))
paybonus1="paybonus${N1}"

# Three new formulas for additional schemes
# Each one uses a different part of the hash and a different modulus to ensure different values.
N2=$(( (0x${hash:8:8} % 53) + 1 ))
N3=$(( (0x${hash:16:8} % 61) + 1 ))
N4=$(( (0x${hash:24:8} % 67) + 1 ))
paybonus2="paybonus${N2}"
paybonus3="paybonus${N3}"
paybonus4="paybonus${N4}"

if [ -n "${BITRISE_TARGET}" ]; then
    FASTLANE_SCHEME=$BITRISE_TARGET
    [ "$is_debug" = "yes" ] && echo "For Fastlane will be used $BITRISE_TARGET"
else
    FASTLANE_SCHEME=$BITRISE_SCHEME
    [ "$is_debug" = "yes" ] && echo "For Fastlane will be used $BITRISE_SCHEME"
fi

rm -rf "./fastlane"
mkdir "./fastlane"

cat << EOF > "./fastlane/changelog.txt"
- Improved Performance: Faster, smoother app experience
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

# Fastfile updated to handle multiple paybonus schemes
cat << EOF > "./fastlane/Fastfile"
lane :update_encryption_settings do
  update_info_plist(
    scheme: "$FASTLANE_SCHEME",
    xcodeproj: "$PROJECT_FILE",
    block: proc do |plist|
      plist['ITSAppUsesNonExemptEncryption'] = false
    end
  )
end

lane :update_build_version do
  update_info_plist(
    scheme: "$FASTLANE_SCHEME",
    xcodeproj: "$PROJECT_FILE",
    block: proc do |plist|
      plist['CFBundleVersion'] = '$BITRISE_BUILD_NUMBER'
      plist['CFBundleShortVersionString'] = '$APP_VERSION'
    end
  )
end

# Updated lane to add multiple paybonus schemes at once
lane :add_paybonus_schemes do |options|
  schemes_to_add = options[:schemes] || []
  update_info_plist(
    scheme: "$FASTLANE_SCHEME",
    xcodeproj: "$PROJECT_FILE",
    block: proc do |plist|
      plist['CFBundleURLTypes'] ||= []
      existing_schemes = plist['CFBundleURLTypes'].flat_map { |t| t['CFBundleURLSchemes'] || [] }

      schemes_to_add.each do |s|
        unless existing_schemes.include?(s)
          plist['CFBundleURLTypes'] << { 'CFBundleURLSchemes' => [s] }
          UI.message("Added URL scheme: #{s}")
        else
          UI.message("URL scheme #{s} already present, no need to add.")
        end
      end
    end
  )
end

lane :add_application_query_schemes do |options|
  schemes = (options[:schemes] || '').split(',')
  update_info_plist(
    scheme: "$FASTLANE_SCHEME",
    xcodeproj: "$PROJECT_FILE",
    block: proc do |plist|
      plist['LSApplicationQueriesSchemes'] ||= []

      schemes.each do |scheme|
        scheme.strip!  # Remove any extra whitespace
        if plist['LSApplicationQueriesSchemes'].include?(scheme)
          UI.message("Scheme '#{scheme}' already exists in LSApplicationQueriesSchemes.")
        else
          plist['LSApplicationQueriesSchemes'] << scheme
          UI.message("Added scheme '#{scheme}' to LSApplicationQueriesSchemes.")
        end
      end
    end
  )
end
EOF

# Check for "ITSAppUsesNonExemptEncryption" and update if not found
if ! grep -q "ITSAppUsesNonExemptEncryption" "$INFOPLIST_FILE"; then
  if [ "$is_debug" = "yes" ]; then
    fastlane update_encryption_settings
    echo "Fastlane update_encryption_settings finished"
  else
    fastlane update_encryption_settings >/dev/null 2>&1
    echo "Fastlane update_encryption_settings finished"
  fi
else
  echo "ITSAppUsesNonExemptEncryption settings found, no need to add"
fi

# Check each paybonus scheme individually and add if missing
MISSING_SCHEMES=()
for scheme in "$paybonus1" "$paybonus2" "$paybonus3" "$paybonus4"; do
  if ! grep -q "$scheme" "$INFOPLIST_FILE"; then
    MISSING_SCHEMES+=("$scheme")
  fi
done

if [ ${#MISSING_SCHEMES[@]} -gt 0 ]; then
  echo "Missing paybonus schemes: ${MISSING_SCHEMES[*]}"
  # Add only the missing schemes
  missing_schemes_str=$(IFS=','; echo "${MISSING_SCHEMES[*]}")
  if [ "$is_debug" = "yes" ]; then
    fastlane add_paybonus_schemes schemes:"$missing_schemes_str"
    echo "Fastlane add_paybonus_schemes finished. Added: $missing_schemes_str"
  else
    fastlane add_paybonus_schemes schemes:"$missing_schemes_str" >/dev/null 2>&1
    echo "Fastlane add_paybonus_schemes finished. Added: $missing_schemes_str"
  fi
else
  echo "All paybonus schemes already present, no need to add."
fi

# Add deeplinks into LSApplicationQueriesSchemes
SCHEMES="whatsapp,fb,fb-messenger,tiktok,instagram,youtube,telegram,spotify,chatgpt,googlemaps,twitter,snapchat,capcut,zoomus,google,roblox,googlechrome,googlegmail,nflx,squarecash,wbdstreaming,com.amazon.mobile.shopping"
fastlane add_application_query_schemes schemes:"$SCHEMES"
echo "All schemes have been added to LSApplicationQueriesSchemes."

# Create artifact files for each paybonus scheme
touch "${BITRISE_DEPLOY_DIR}/${paybonus1}.txt"
touch "${BITRISE_DEPLOY_DIR}/${paybonus2}.txt"
touch "${BITRISE_DEPLOY_DIR}/${paybonus3}.txt"
touch "${BITRISE_DEPLOY_DIR}/${paybonus4}.txt"

# Update version and build numbers
if [ "$is_debug" = "yes" ]; then
  fastlane update_build_version
  echo "Fastlane updated build and version numbers"
else
  fastlane update_build_version >/dev/null 2>&1
  echo "Fastlane updated build and version numbers"
fi

# Update what's new if conditions are met
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