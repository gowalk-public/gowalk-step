#!/bin/bash

export runner_bin="/bin/bash"
export working_dir="$BITRISE_SOURCE_DIR"
export script_file_path=""

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
export PROJECT_FILE="$APP_WORKING_DIR/$PROJECT_DIR"
export PROJECT="$APP_WORKING_DIR/$PROJECT_DIR/project.pbxproj"