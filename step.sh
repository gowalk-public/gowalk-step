#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CONFIG_tmp_script_file_path="${THIS_SCRIPT_DIR}/._script_cont"

#Install Python packages from requirements
echo "Installing Python packages from requirements.txt..."
pip3 install -r "${THIS_SCRIPT_DIR}/requirements.txt"
echo "Installation complete."

#config
source "${THIS_SCRIPT_DIR}/variables.sh"

#functions to change app version and build
source "${THIS_SCRIPT_DIR}/change_version.sh"

#functions to manipulate with Pods and Packages
source "${THIS_SCRIPT_DIR}/pods_packages.sh"

#function to get credentials for AppStoreConnect API
source "${THIS_SCRIPT_DIR}/appstore_creds.sh"

#function to get budnle id from Xcode project
source "${THIS_SCRIPT_DIR}/get_bundleid.sh"

#function to get app id from AppStoreConnect API
export APP_ID=$(echo "$(python3 "${THIS_SCRIPT_DIR}/getappid.py")" | jq -r '.APP_ID')

#function to create app at AppStoreConnect API if app id not found
#if [ "$APP_ID" -eq 0 ]; then
	#python3 content+=$(python3 "${THIS_SCRIPT_DIR}/create_app.py")
#fi

#function to manage app version in AppStoreConnect
python3 "${THIS_SCRIPT_DIR}/manage_version.py"
#export APP_VERSION=$(echo "$(python3 "${THIS_SCRIPT_DIR}/manage_version.py")" | jq -r '.APP_VERSION')
#echo "APP VERSION IS $APP_VERSION"

#function to update What's New field in AppStoreConnect
#python3 content+=$(python3 "${THIS_SCRIPT_DIR}/update_whatsnew.py")

script_result=$?
exit ${script_result}