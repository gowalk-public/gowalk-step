#!/usr/bin/env bash

# Remove Package.resolved files
if [ "$remove_package_resolved" = "yes" ]; then
    echo "Path to Package.resolved: $APP_WORKING_DIR/$WORKSPACE_DIR/xcshareddata/swiftpm/Package.resolved"
    echo "Path2 to Package.resolved: $APP_WORKING_DIR/$PROJECT_DIR/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    echo "Path to Podfile.lock: $APP_WORKING_DIR/Podfile.lock"
    echo "Path to Pods folder: $APP_WORKING_DIR/Pods/"
    rm -rf "$APP_WORKING_DIR/$WORKSPACE_DIR/xcshareddata/swiftpm/Package.resolved"
    rm -rf "$APP_WORKING_DIR/$PROJECT_DIR/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    [ "$is_debug" = "yes" ] && echo "Package.resolved removed"
fi

# Remove Podfile.lock
if [ "$remove_podsfile_lock" = "yes" ]; then
    rm -rf "$APP_WORKING_DIR/Podfile.lock"
    [ "$is_debug" = "yes" ] && echo "Podfile.lock removed"
elif [ "$last_gowalk_helper" = "yes" ]; then
# Force to use last Gowalk Helper if not Flutter
    if [ ! -d "$BITRISE_SOURCE_DIR/ios/Flutter" ]; then
        if [ -f "Podfile" ]; then
            if grep -q "GowalkDevHelper" "Podfile"; then
                pod install
                pod update GowalkDevHelper
                [ "$is_debug" = "yes" ] && echo "GowalkDevHelper updated"
                if grep -q "GowalkOnboardingSDK" "Podfile"; then
                    pod update GowalkOnboardingSDK
                    [ "$is_debug" = "yes" ] && echo "GowalkOnboardingSDK updated"
                fi
            fi
        fi
    fi
fi

# Remove Pods
if [ "$remove_pods" = "yes" ]; then
    rm -rf "$APP_WORKING_DIR/Pods/"
    [ "$is_debug" = "yes" ] && echo "Pods folder removed"
fi

# Check if Podfile exists, if not create an empty one
if [ ! -f "$APP_WORKING_DIR/Podfile" ]; then
    echo "workspace '$BITRISE_PROJECT_PATH'" >"$APP_WORKING_DIR/Podfile"
    [ "$is_debug" = "yes" ] && echo "Created empty Podfile to prevent errors"
fi