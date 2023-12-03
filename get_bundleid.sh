#!/usr/bin/env bash

# Run xcodebuild and capture output
output=$(xcodebuild "-project" "$BITRISE_PROJECT_PATH" "-target" "$BITRISE_SCHEME" "-configuration" "Release" "-showBuildSettings")

# Find the line containing PRODUCT_BUNDLE_IDENTIFIER and extract its value
bundle_identifier=$(echo "$output" | grep PRODUCT_BUNDLE_IDENTIFIER | cut -d '=' -f2 | xargs)

# Export the PRODUCT_BUNDLE_IDENTIFIER environment variable
export PRODUCT_BUNDLE_IDENTIFIER="$bundle_identifier"

# Optional: Display the value (for verification)
echo "PRODUCT_BUNDLE_IDENTIFIER: $PRODUCT_BUNDLE_IDENTIFIER"