#!/usr/bin/env bash

# Remove Package.resolved files
if [ "$remove_package_resolved" = "yes" ]; then
    rm -rf "$APP_WORKING_DIR/$WORKSPACE_DIR/xcshareddata/swiftpm/Package.resolved"
    rm -rf "$APP_WORKING_DIR/$PROJECT_DIR/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
fi

# Remove Podfile.lock
if [ "$remove_podsfile_lock" = "yes" ]; then
    rm -rf "$APP_WORKING_DIR/Podfile.lock"
elif [ "$last_gowalk_helper" = "yes" ]; then
# Force to use last Gowalk Helper
    if [ -f "Podfile" ]; then
        if grep -q "GowalkDevHelper" "Podfile"; then
            pod install
            pod update GowalkDevHelper
        fi
    fi
fi

# Remove Pods
if [ "$remove_pods" = "yes" ]; then
    rm -rf "$APP_WORKING_DIR/Pods/"
fi

# Check if Podfile exists, if not create an empty one
if [ ! -f "$APP_WORKING_DIR/Podfile" ]; then
    echo "workspace '$BITRISE_PROJECT_PATH'" >"$APP_WORKING_DIR/Podfile"
fi