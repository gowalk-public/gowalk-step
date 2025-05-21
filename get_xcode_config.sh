#!/usr/bin/env bash

echo "Step Get Xcode Config"

echo "BITRISE_TARGET = '${BITRISE_TARGET}'"
echo "BITRISE_SCHEME = '${BITRISE_SCHEME}'"

if [ -n "${BITRISE_TARGET}" ]; then
    echo "WARNING: BITRISE_TARGET is set to '${BITRISE_TARGET}', but we want to use a scheme for SwiftPM."
    echo "Ignoring BITRISE_TARGET and using BITRISE_SCHEME instead."
fi

# Hard-force scheme usage:
SCHEME_TO_USE="${BITRISE_SCHEME}"
if [ -z "${SCHEME_TO_USE}" ]; then
    echo "ERROR: No scheme provided. Please set BITRISE_SCHEME."
    exit 1
fi

echo "running xcodebuild -showBuildSettings with verbose logs."
set -x
output=$(xcodebuild \
  -project "${PROJECT_FILE}" \
  -scheme "${SCHEME_TO_USE}" \
  -configuration Release \
  -showBuildSettings \
  -skipPackageUpdates \
  -skipPackagePluginValidation \
  -disableAutomaticPackageResolution \
  -verbose \
  -showBuildTimingSummary
)
set +x

# Continue extracting PRODUCT_BUNDLE_IDENTIFIER etc. 
echo "Step Find the line containing PRODUCT_BUNDLE_IDENTIFIER"
bundle_identifier=$(echo "$output" | grep -E "^ *PRODUCT_BUNDLE_IDENTIFIER =" | cut -d '=' -f2 | xargs)

echo "Step Export the PRODUCT_BUNDLE_IDENTIFIER environment variable"
export PRODUCT_BUNDLE_IDENTIFIER="$bundle_identifier"
echo "PRODUCT_BUNDLE_IDENTIFIER: $PRODUCT_BUNDLE_IDENTIFIER"

echo "Step Find the line containing INFOPLIST_FILE and extract its value"
info_plist_file=$(echo "$output" | grep -E "^ *INFOPLIST_FILE =" | cut -d '=' -f2 | xargs)

echo "Step Export the INFOPLIST_FILE environment variable"
export INFOPLIST_FILE="$APP_WORKING_DIR/$info_plist_file"
echo "INFOPLIST_FILE: $INFOPLIST_FILE"