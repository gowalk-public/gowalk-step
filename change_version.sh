#!/usr/bin/env bash

# Function to update project values
update_project() {
    sed -i '' -e "$1" "$PROJECT" 2>&1 | grep -v "Permission denied"
    value=$(sed -n "$2") "$PROJECT" 2>&1 | grep -v "Permission denied"
    echo $value
}

build_number=$(update_project 's/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = '$BITRISE_BUILD_NUMBER';/' '/CURRENT_PROJECT_VERSION/{s/CURRENT_PROJECT_VERSION = //;s/;//;s/^[[:space:]]*//;p;q;}')
version_number=$(update_project 's/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = '$APP_VERSION';/' '/MARKETING_VERSION/{s/MARKETING_VERSION = //;s/;//;s/^[[:space:]]*//;p;q;}')
code_sign_style=$(update_project 's/CODE_SIGN_STYLE = [^;]*;/CODE_SIGN_STYLE = Manual;/' '/CODE_SIGN_STYLE/{s/CODE_SIGN_STYLE = //;s/;//;s/^[[:space:]]*//;p;q;}')
development_team=$(update_project 's/DEVELOPMENT_TEAM = [^;]*;/DEVELOPMENT_TEAM = "";/' '/DEVELOPMENT_TEAM/{s/DEVELOPMENT_TEAM = //;s/;//;s/^[[:space:]]*//;p;q;}')