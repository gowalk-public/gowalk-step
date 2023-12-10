#!/bin/bash

#configuration
export THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export CONFIG_tmp_script_file_path="${THIS_SCRIPT_DIR}/._script_cont"

#Install Python packages from requirements
[ "$IS_DEBUG" -eq "1" ] && echo "Installing Python packages from requirements.txt..."
pip3 install -r "${THIS_SCRIPT_DIR}/requirements.txt"
[ "$IS_DEBUG" -eq "1" ] && echo "Installation complete"

#config
source "${THIS_SCRIPT_DIR}/variables.sh"

#functions to manipulate with Pods and Packages
source "${THIS_SCRIPT_DIR}/pods_packages.sh"

#function to get credentials for AppStoreConnect API
source "${THIS_SCRIPT_DIR}/appstore_creds.sh"

#function to get budnle id from Xcode project
source "${THIS_SCRIPT_DIR}/get_bundleid.sh"

#function to get app id from AppStoreConnect API
getappid=$(python3 "${THIS_SCRIPT_DIR}/getappid.py")
export APP_ID=$(echo "$getappid" | jq -r '.APP_ID')
[ "$IS_DEBUG" -eq "1" ] && echo "Result of getappid.py: $getappid"
[ "$IS_DEBUG" -eq "1" ] && echo "APP_ID: $APP_ID"

#function to check current version in AppStore and create if needed
manage_version=$(python3 "${THIS_SCRIPT_DIR}/manage_version.py")
export APP_VERSION=$(echo "$manage_version" | jq -r '.APP_VERSION')
export APP_VERSION_ID=$(echo "$manage_version" | jq -r '.APP_VERSION_ID')
export APP_STATUS=$(echo "$manage_version" | jq -r '.APP_STATUS')
[ "$IS_DEBUG" -eq "1" ] && echo "Result of manage_version.py: $manage_version"
[ "$IS_DEBUG" -eq "1" ] && echo "APP_VERSION: $APP_VERSION"
[ "$IS_DEBUG" -eq "1" ] && echo "APP_VERSION_ID: $APP_VERSION_ID"
[ "$IS_DEBUG" -eq "1" ] && echo "APP_STATUS: $APP_STATUS"

#functions to change app version and build in xcode project
source "${THIS_SCRIPT_DIR}/change_version.sh"

#function to update What's New field in AppStoreConnect
if [ "$update_whats_new" = "yes" ] && [ "$APP_STATUS" = "PREPARE_FOR_SUBMISSION" ]; then
    source "${THIS_SCRIPT_DIR}/update_whatsnew.sh"
fi

#dsym upload preparing
source "${THIS_SCRIPT_DIR}/crashlytics_prepare.sh"

#check app rating
check_rating=$(python3 "${THIS_SCRIPT_DIR}/check_rating.py")
export APP_RATING=$(echo "$check_rating" | jq -r '.APP_RATING')
[ "$IS_DEBUG" -eq "1" ] && echo "Result of check_rating.py: $check_rating"
[ "$IS_DEBUG" -eq "1" ] && echo "App Rating in US Store is: $APP_RATING"

script_result=$?
exit ${script_result}