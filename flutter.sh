#!/usr/bin/env bash
if [[ $APP_VERSION =~ ^[0-9]+\.[0-9]+$ ]]; then
    APP_VERSION="${APP_VERSION}.0"
fi
sed -i '' "/^version: /s/version: .*/version: $APP_VERSION+$BITRISE_BUILD_NUMBER/" $BITRISE_SOURCE_DIR/pubspec.yaml

rm -rf $BITRISE_SOURCE_DIR/ios/Podfile.lock $BITRISE_SOURCE_DIR/ios/Pods/