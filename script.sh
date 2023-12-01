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

# Replace CURRENT_PROJECT_VERSION
sudo sed -i '' -e 's/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = '$BITRISE_BUILD_NUMBER';/' "$PROJECT"
build_number=$(sed -n '/CURRENT_PROJECT_VERSION/{s/CURRENT_PROJECT_VERSION = //;s/;//;s/^[[:space:]]*//;p;q;}') "$PROJECT"

# Replace MARKETING_VERSION
sudo sed -i '' -e 's/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = '$BITRISE_VERSION_NUMBER';/' "$PROJECT"
version_number=$(sed -n '/MARKETING_VERSION/{s/MARKETING_VERSION = //;s/;//;s/^[[:space:]]*//;p;q;}') "$PROJECT"

# Replace CODE_SIGN_STYLE
sudo sed -i '' -e 's/CODE_SIGN_STYLE = [^;]*;/CODE_SIGN_STYLE = Manual;/' "$PROJECT"
code_sign_style=$(sed -n '/CODE_SIGN_STYLE/{s/CODE_SIGN_STYLE = //;s/;//;s/^[[:space:]]*//;p;q;}') "$PROJECT"

# Replace DEVELOPMENT_TEAM
sudo sed -i '' -e 's/DEVELOPMENT_TEAM = [^;]*;/DEVELOPMENT_TEAM = "";/' "$PROJECT"
development_team=$(sed -n '/DEVELOPMENT_TEAM/{s/DEVELOPMENT_TEAM = //;s/;//;s/^[[:space:]]*//;p;q;}') "$PROJECT"

# Remove Package.resolved files
sudo rm -rf "./$WORKSPACE_DIR/xcshareddata/swiftpm/Package.resolved"
sudo rm -rf "./$PROJECT_DIR/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
