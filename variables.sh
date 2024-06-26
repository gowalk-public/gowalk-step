#!/bin/bash

export runner_bin="/bin/bash"
export working_dir="$BITRISE_SOURCE_DIR"
export script_file_path=""

if [ -d "$BITRISE_SOURCE_DIR/ios/Flutter" ]; then
    export BITRISE_PROJECT_PATH="ios/Runner.xcodeproj"
    export BITRISE_SCHEME="Runner"
fi

export SUBDIR=$(dirname "$BITRISE_PROJECT_PATH")
if [ "$SUBDIR" = "." ]; then
    export SUBDIR=""
fi

if [[ -n "$SUBDIR" && -d "$SUBDIR" ]]; then    
    export APP_WORKING_DIR="$BITRISE_SOURCE_DIR/$SUBDIR"
else
    export APP_WORKING_DIR="$BITRISE_SOURCE_DIR"
fi

export PROJECT_DIR=$(ls "$APP_WORKING_DIR" | grep ".xcodeproj$" | head -n 1)
export WORKSPACE_DIR=$(ls "$APP_WORKING_DIR" | grep ".xcworkspace$" | head -n 1)
export PROJECT="$APP_WORKING_DIR/$PROJECT_DIR/project.pbxproj"
export PROJECT_FILE="$APP_WORKING_DIR/$PROJECT_DIR"

if [ -n "$FLUTTER_VERSION" ]; then
    export flutter_version=$FLUTTER_VERSION
fi