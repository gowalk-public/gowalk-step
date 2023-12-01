#!/usr/bin/env bash

# Extract the directory path from BITRISE_PROJECT_PATH
SUBDIR=$(dirname "$BITRISE_PROJECT_PATH")

# Change to the BITRISE_SOURCE_DIR
cd "$BITRISE_SOURCE_DIR"

# Check if SUBDIR is not empty and is a directory
if [[ -n "$SUBDIR" && -d "$SUBDIR" ]]; then
    # If SUBDIR exists, change to this directory
    cd "$SUBDIR"
fi

#Assign values for path
PROJECT_DIR=$(ls | grep ".xcodeproj$" | head -n 1)
PROJECT="./$PROJECT_DIR/project.pbxproj"

# Check if Podfile exists, if not create an empty one
if [ ! -f "Podfile" ]; then
    echo "workspace '$BITRISE_PROJECT_PATH'" >Podfile
fi

update_project() {
    sudo sed -i '' -e "$1" "$PROJECT" 2>&1 | grep -v "Permission denied"
    value=$(sed -n "$2") "$PROJECT" 2>&1 | grep -v "Permission denied"
    echo $value
}

build_number=$(update_project 's/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = '$BITRISE_BUILD_NUMBER';/' '/CURRENT_PROJECT_VERSION/{s/CURRENT_PROJECT_VERSION = //;s/;//;s/^[[:space:]]*//;p;q;}')
version_number=$(update_project 's/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = '$BITRISE_VERSION_NUMBER';/' '/MARKETING_VERSION/{s/MARKETING_VERSION = //;s/;//;s/^[[:space:]]*//;p;q;}')
code_sign_style=$(update_project 's/CODE_SIGN_STYLE = [^;]*;/CODE_SIGN_STYLE = Manual;/' '/CODE_SIGN_STYLE/{s/CODE_SIGN_STYLE = //;s/;//;s/^[[:space:]]*//;p;q;}')
development_team=$(update_project 's/DEVELOPMENT_TEAM = [^;]*;/DEVELOPMENT_TEAM = "";/' '/DEVELOPMENT_TEAM/{s/DEVELOPMENT_TEAM = //;s/;//;s/^[[:space:]]*//;p;q;}')

# Remove Package.resolved files
sudo rm -rf "./$WORKSPACE_DIR/xcshareddata/swiftpm/Package.resolved"
sudo rm -rf "./$PROJECT_DIR/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
