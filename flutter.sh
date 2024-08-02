#!/usr/bin/env bash
if [[ $APP_VERSION =~ ^[0-9]+\.[0-9]+$ ]]; then
    APP_VERSION="${APP_VERSION}.0"
fi
sed -i '' "/^version: /s/version: .*/version: $APP_VERSION+$BITRISE_BUILD_NUMBER/" $BITRISE_SOURCE_DIR/pubspec.yaml

if [[ -z "$flutter_version" ]]; then
    flutter upgrade
else
    fvm install $flutter_version
    fvm use $flutter_version --force
    fvm flutter --version
    git -C /Users/vagrant/fvm/default/bin/ checkout $flutter_version
fi

flutter pub get
cd ios
rm -rf $BITRISE_SOURCE_DIR/ios/Podfile.lock $BITRISE_SOURCE_DIR/ios/Pods/
pod install --repo-update