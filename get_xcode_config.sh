#!/usr/bin/env bash

echo "Step Get Xcode Config"

if [ -n "${BITRISE_TARGET}" ]; then
    echo "To get Xcode Config will be used BITRISE_TARGET"
    echo "Running: xcodebuild -project \"$PROJECT_FILE\" -target \"$BITRISE_TARGET\" -configuration Release -showBuildSettings -disableAutomaticPackageResolution"
    output=$(xcodebuild -project "$PROJECT_FILE" -target "$BITRISE_TARGET" -configuration Release -showBuildSettings)
else
    echo "To get Xcode Config will be used BITRISE_SCHEME"
    echo "Running: xcodebuild -project \"$PROJECT_FILE\" -target \"$BITRISE_SCHEME\" -configuration Release -showBuildSettings -disableAutomaticPackageResolution"
    output=$(xcodebuild -project "$PROJECT_FILE" -target "$BITRISE_SCHEME" -configuration Release -showBuildSettings)
fi

echo "Step Find the line containing PRODUCT_BUNDLE_IDENTIFIER"
# Find the line containing PRODUCT_BUNDLE_IDENTIFIER and extract its value
bundle_identifier=$(echo "$output" | grep -E "^ *PRODUCT_BUNDLE_IDENTIFIER =" | cut -d '=' -f2 | xargs)

echo "Step Export the PRODUCT_BUNDLE_IDENTIFIER environment variable"
# Export the PRODUCT_BUNDLE_IDENTIFIER environment variable
export PRODUCT_BUNDLE_IDENTIFIER="$bundle_identifier"

# Optional: Display the value (for verification)
echo "PRODUCT_BUNDLE_IDENTIFIER: $PRODUCT_BUNDLE_IDENTIFIER"

echo "Step Find the line containing INFOPLIST_FILE and extract its value"
# Find the line containing INFOPLIST_FILE and extract its value
info_plist_file=$(echo "$output" | grep ' INFOPLIST_FILE =' | cut -d '=' -f2 | xargs)

echo "Step Export the INFOPLIST_FILE environment variable"
# Export the INFOPLIST_FILE environment variable
export INFOPLIST_FILE="$APP_WORKING_DIR/$info_plist_file"

# Optional: Display the INFOPLIST_FILE value (for verification)
echo "INFOPLIST_FILE: $INFOPLIST_FILE"