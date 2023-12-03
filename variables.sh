#!/bin/bash

runner_bin="/bin/bash"
echo "runner_bin: $runner_bin"

working_dir="$BITRISE_SOURCE_DIR"
echo "working_dir: $working_dir"

script_file_path=""
echo "script_file_path: $script_file_path"

is_debug="no"
echo "is_debug: $is_debug"

SUBDIR=$(dirname "$BITRISE_PROJECT_PATH")
if [ "$SUBDIR" = "." ]; then
    SUBDIR=""
fi
echo "SUBDIR: $SUBDIR"

if [[ -n "$SUBDIR" && -d "$SUBDIR" ]]; then    
    APP_WORKING_DIR="$BITRISE_SOURCE_DIR/$SUBDIR"
else
    APP_WORKING_DIR="$BITRISE_SOURCE_DIR"
fi
echo "APP_WORKING_DIR: $APP_WORKING_DIR"

PROJECT_DIR=$(ls "$APP_WORKING_DIR" | grep ".xcodeproj$" | head -n 1)
echo "PROJECT_DIR: $PROJECT_DIR"

PROJECT="$APP_WORKING_DIR/$PROJECT_DIR/project.pbxproj"
echo "PROJECT: $PROJECT"