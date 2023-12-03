#!/bin/bash
runner_bin="/bin/bash"
working_dir="$BITRISE_SOURCE_DIR"
script_file_path=""
is_debug="no"
SUBDIR=$(dirname "$BITRISE_PROJECT_PATH")
# Build app working directory
if [[ -n "$SUBDIR" && -d "$SUBDIR" ]]; then    
    APP_WORKING_DIR="$BITRISE_SOURCE_DIR/$SUBDIR"
else
    APP_WORKING_DIR="$BITRISE_SOURCE_DIR"
fi
PROJECT_DIR=$(ls $APP_WORKING_DIR | grep ".xcodeproj$" | head -n 1)
PROJECT="$APP_WORKING_DIR/$PROJECT_DIR/project.pbxproj"