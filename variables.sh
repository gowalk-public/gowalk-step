#!/bin/bash

export runner_bin="/bin/bash"
echo "runner_bin: $runner_bin"

export working_dir="$BITRISE_SOURCE_DIR"
echo "working_dir: $working_dir"

export script_file_path=""
echo "script_file_path: $script_file_path"

export is_debug="no"
echo "is_debug: $is_debug"

export SUBDIR=$(dirname "$BITRISE_PROJECT_PATH")
if [ "$SUBDIR" = "." ]; then
    export SUBDIR=""
fi
echo "SUBDIR: $SUBDIR"

if [[ -n "$SUBDIR" && -d "$SUBDIR" ]]; then    
    export APP_WORKING_DIR="$BITRISE_SOURCE_DIR/$SUBDIR"
else
    export APP_WORKING_DIR="$BITRISE_SOURCE_DIR"
fi
echo "APP_WORKING_DIR: $APP_WORKING_DIR"

export PROJECT_DIR=$(ls "$APP_WORKING_DIR" | grep ".xcodeproj$" | head -n 1)
echo "PROJECT_DIR: $PROJECT_DIR"

export PROJECT_FILE="$APP_WORKING_DIR/$PROJECT_DIR"
echo "PROJECT FILE: $PROJECT_FILE"

export PROJECT="$APP_WORKING_DIR/$PROJECT_DIR/project.pbxproj"
echo "PROJECT: $PROJECT"