#!/bin/bash
# Create a folder named 'crashlytics' inside the application working directory
mkdir -p "$APP_WORKING_DIR/crashlytics"

# Copy the 'upload-symbols' file from the script's directory to the 'crashlytics' folder
cp "${THIS_SCRIPT_DIR}/crashlytics/upload-symbols" "$APP_WORKING_DIR/crashlytics/upload-symbols"

# Step 1: Find all .plist files
plist_files=$(find $APP_WORKING_DIR -name "*.plist")

# Filter the files
for file in $plist_files; do
    # Step 2: Check if file contains PRODUCT_BUNDLE_IDENTIFIER
    if grep -q "<string>$PRODUCT_BUNDLE_IDENTIFIER</string>" "$file"; then
        # Step 3: Check for CLIENT_ID
        if grep -q "<key>CLIENT_ID</key>" "$file"; then
            # Step 4: Check for REVERSED_CLIENT_ID
            if grep -q "<key>REVERSED_CLIENT_ID</key>" "$file"; then
                # Step 5: Copy the first matching file
                cp "$file" "$APP_WORKING_DIR/crashlytics/GoogleService-Info.plist"
                break
            fi
        fi
    fi
done
