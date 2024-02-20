#!/usr/bin/env bash
sed -i '' "/^version: /s/version: .*/version: $APP_VERSION+$BITRISE_BUILD_NUMBER/" $BITRISE_SOURCE_DIR/pubspec.yaml
flutter upgrade
flutter pub get
cd ios
rm -rf $BITRISE_SOURCE_DIR/ios/Podfile.lock $BITRISE_SOURCE_DIR/ios/Pods/
pod install --repo-update