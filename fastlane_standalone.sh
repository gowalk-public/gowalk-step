#!/bin/bash
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Variables from environment
APP_ID="${APP_STORE_APPLE_ID}"
BITRISE_SCHEME="${XCODE_SCHEME}"
BITRISE_TARGET="${XCODE_SCHEME}"
PROJECT_FILE="${XCODE_WORKSPACE}"
PRODUCT_BUNDLE_IDENTIFIER="${BUNDLE_ID}"

echo "=== Fastlane Standalone Setup Script ==="

# Function to prompt for input if empty
prompt_if_empty() {
    local var_name=$1
    local current_value=$2
    local prompt_text=$3
    
    if [ -z "$current_value" ]; then
        read -p "$prompt_text: " new_value
        echo "$new_value"
    else
        echo "$current_value"
    fi
}

# Function to auto-detect Xcode project/workspace
auto_detect_project() {
    local detected=""
    
    # First try to find .xcworkspace (preferred)
    local workspaces=(*.xcworkspace)
    if [ -e "${workspaces[0]}" ]; then
        detected="${workspaces[0]}"
        echo "Auto-detected workspace: $detected" >&2
    else
        # If no workspace, try to find .xcodeproj
        local projects=(*.xcodeproj)
        if [ -e "${projects[0]}" ]; then
            detected="${projects[0]}"
            echo "Auto-detected project: $detected" >&2
        fi
    fi
    
    echo "$detected"
}

# Function to auto-detect schemes
auto_detect_scheme() {
    local project="$1"
    local detected=""
    
    if [ -n "$project" ]; then
        # Extract project name without extension for matching
        local project_name=""
        if [[ "$project" == *.xcworkspace ]]; then
            project_name=$(basename "$project" .xcworkspace)
        else
            project_name=$(basename "$project" .xcodeproj)
        fi
        
        # Try to list schemes using xcodebuild
        if [[ "$project" == *.xcworkspace ]]; then
            schemes=$(xcodebuild -workspace "$project" -list 2>/dev/null | sed -n '/Schemes:/,/^$/p' | grep -v "Schemes:" | sed 's/^[ ]*//' | grep -v '^$')
        else
            schemes=$(xcodebuild -project "$project" -list 2>/dev/null | sed -n '/Schemes:/,/^$/p' | grep -v "Schemes:" | sed 's/^[ ]*//' | grep -v '^$')
        fi
        
        # First, try to find a scheme matching the project name
        for scheme in $schemes; do
            if [ "$scheme" = "$project_name" ]; then
                detected="$scheme"
                echo "Auto-detected scheme (matching project name): $detected" >&2
                break
            fi
        done
        
        # If not found, look for schemes that are likely the main app
        # Exclude: Extensions, Widgets, Tests, Pods, and third-party library names
        if [ -z "$detected" ]; then
            for scheme in $schemes; do
                # Skip if it contains extension/test/widget keywords
                if [[ "$scheme" =~ (Extension|Widget|Tests|Pods|UITests|IntentsUI) ]]; then
                    continue
                fi
                
                # Skip if it's a known third-party library (common ones)
                if [[ "$scheme" =~ ^(Amplitude|Facebook|Firebase|Google|Mixpanel|OneSignal|Lottie|Qonversion|WireGuard|FBSDKCoreKit|GTM|Promises|KeychainSwift|SwiftProtobuf|nanopb|leveldb|abseil|gRPC) ]]; then
                    continue
                fi
                
                # Skip if it contains a dash or dot (likely a library)
                if [[ "$scheme" =~ [-\.] ]]; then
                    continue
                fi
                
                detected="$scheme"
                echo "Auto-detected scheme: $detected" >&2
                break
            done
        fi
        
        # If still no main app scheme found, fall back to any non-Pods/non-library scheme
        if [ -z "$detected" ]; then
            for scheme in $schemes; do
                if [[ ! "$scheme" =~ (Pods|Extension|Widget|Tests|Amplitude|Facebook|Firebase|Google) ]]; then
                    detected="$scheme"
                    echo "Auto-detected scheme (fallback): $detected" >&2
                    break
                fi
            done
        fi
    fi
    
    echo "$detected"
}

# Function to auto-detect bundle identifier
auto_detect_bundle_id() {
    local project="$1"
    local scheme="$2"
    local detected=""
    
    # Method 1: Try to grep from .pbxproj file first (most reliable)
    if [ -n "$project" ]; then
        local pbxproj_file=""
        if [[ "$project" == *.xcworkspace ]]; then
            # For workspace, try to find the main project
            local main_project=$(ls *.xcodeproj 2>/dev/null | head -1)
            if [ -n "$main_project" ]; then
                pbxproj_file="$main_project/project.pbxproj"
            fi
        else
            pbxproj_file="$project/project.pbxproj"
        fi
        
        if [ -f "$pbxproj_file" ]; then
            # Look for PRODUCT_BUNDLE_IDENTIFIER in the pbxproj file
            # Get all unique bundle IDs and filter them
            local bundle_ids=$(grep "PRODUCT_BUNDLE_IDENTIFIER = " "$pbxproj_file" | sed 's/.*PRODUCT_BUNDLE_IDENTIFIER = //;s/;//;s/"//g' | sort -u)
            
            # First try to find the main app bundle (not extension, not tunnel, not test)
            for bid in $bundle_ids; do
                # Skip variable references, tests, and known extensions
                if [[ ! "$bid" == *'$'* ]] && \
                   [[ ! "$bid" == *".test"* ]] && \
                   [[ ! "$bid" == *".Test"* ]] && \
                   [[ ! "$bid" == *".Tests"* ]] && \
                   [[ ! "$bid" == *".adblocker"* ]] && \
                   [[ ! "$bid" == *".AdBlocker"* ]] && \
                   [[ ! "$bid" == *".extension"* ]] && \
                   [[ ! "$bid" == *".Extension"* ]] && \
                   [[ ! "$bid" == *".widget"* ]] && \
                   [[ ! "$bid" == *".Widget"* ]] && \
                   [[ ! "$bid" == *".Tunnel"* ]] && \
                   [[ ! "$bid" == *".tunnel"* ]] && \
                   [[ ! "$bid" == *".NetworkExtension"* ]]; then
                    detected="$bid"
                    echo "Auto-detected bundle ID from project.pbxproj: $detected" >&2
                    break
                fi
            done
            
            # If no main app bundle found, take the shortest one (usually the main app)
            if [ -z "$detected" ]; then
                local shortest=""
                local shortest_len=999
                for bid in $bundle_ids; do
                    if [[ ! "$bid" == *'$'* ]]; then
                        local len=${#bid}
                        if [ $len -lt $shortest_len ]; then
                            shortest="$bid"
                            shortest_len=$len
                        fi
                    fi
                done
                if [ -n "$shortest" ]; then
                    detected="$shortest"
                    echo "Auto-detected bundle ID from project.pbxproj (shortest): $detected" >&2
                fi
            fi
        fi
    fi
    
    # Method 2: Try to get from xcodebuild if not found
    if [ -z "$detected" ] && [ -n "$project" ] && [ -n "$scheme" ]; then
        # Try to get bundle identifier from build settings
        if [[ "$project" == *.xcworkspace ]]; then
            detected=$(xcodebuild -workspace "$project" -scheme "$scheme" -showBuildSettings 2>/dev/null | grep "PRODUCT_BUNDLE_IDENTIFIER" | grep -v "=" | head -1 | awk '{print $NF}')
        else
            detected=$(xcodebuild -project "$project" -scheme "$scheme" -showBuildSettings 2>/dev/null | grep "PRODUCT_BUNDLE_IDENTIFIER" | grep -v "=" | head -1 | awk '{print $NF}')
        fi
        
        # Clean up the detected value
        if [[ "$detected" == *'$'* ]] || [ "$detected" == "NO" ] || [[ "$detected" == *"="* ]]; then
            detected=""
        elif [ -n "$detected" ]; then
            echo "Auto-detected bundle ID from xcodebuild: $detected" >&2
        fi
    fi
    
    # Method 3: If still not found, try to find in Info.plist files (last resort)
    if [ -z "$detected" ]; then
        # Look for Info.plist files, preferring main app folder
        local info_plists=$(find . -maxdepth 2 -name "Info.plist" -not -path "*/Pods/*" -not -path "*/build/*" -not -path "*/.build/*" -not -path "*/DerivedData/*" 2>/dev/null)
        
        for plist in $info_plists; do
            # Skip extension, test, and framework Info.plist files
            if [[ "$plist" =~ (Extension|Tests|UITests|Widget|Tunnel|xcframework|framework) ]]; then
                continue
            fi
            
            # Try to extract CFBundleIdentifier using plutil or PlistBuddy
            if command -v plutil &> /dev/null; then
                local bundle_id=$(plutil -extract CFBundleIdentifier raw "$plist" 2>/dev/null)
                if [ -n "$bundle_id" ] && [[ ! "$bundle_id" == *'$'* ]]; then
                    detected="$bundle_id"
                    echo "Auto-detected bundle ID from $plist: $detected" >&2
                    break
                fi
            elif [ -x "/usr/libexec/PlistBuddy" ]; then
                local bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$plist" 2>/dev/null)
                if [ -n "$bundle_id" ] && [[ ! "$bundle_id" == *'$'* ]]; then
                    detected="$bundle_id"
                    echo "Auto-detected bundle ID from $plist: $detected" >&2
                    break
                fi
            fi
        done
    fi
    
    if [ -n "$detected" ] && [ "$detected" != "NO" ]; then
        echo "$detected"
    else
        echo ""
    fi
}

# Function to auto-detect APP_ID from App Store Connect
auto_detect_app_id() {
    local bundle_id="$1"
    local detected=""
    
    # Check if we have the necessary App Store Connect credentials
    local key_id="${APPLE_KEY_ID}"
    local issuer_id="${APPLE_ISSUER_ID}"
    local private_key="${APPLE_PRIVATE_KEY}"
    
    if [ -z "$key_id" ] || [ -z "$issuer_id" ] || [ -z "$private_key" ]; then
        echo "App Store Connect credentials not found in environment" >&2
        return
    fi
    
    # Check if Python and required packages are available
    if ! command -v python3 &> /dev/null; then
        echo "Python3 not found, skipping APP_ID auto-detection" >&2
        return
    fi
    
    # Create a temporary Python script
    local temp_script=$(mktemp /tmp/get_app_id.XXXXXX.py)
    cat > "$temp_script" << 'PYTHON_SCRIPT'
import os
import sys
import json
import time

try:
    import requests
    import jwt
except ImportError:
    print("Required Python packages (requests, PyJWT) not installed", file=sys.stderr)
    sys.exit(1)

bundle_id = sys.argv[1]
key_id = os.environ.get('APPLE_KEY_ID')
issuer_id = os.environ.get('APPLE_ISSUER_ID')
private_key = os.environ.get('APPLE_PRIVATE_KEY')

try:
    # Create the JWT Token
    token = jwt.encode(
        {
            'iss': issuer_id,
            'exp': time.time() + 60*20,
            'aud': 'appstoreconnect-v1'
        },
        private_key,
        algorithm='ES256',
        headers={'kid': key_id}
    )
    
    # Set up the request headers
    headers = {
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    
    # Make the request to list apps
    response = requests.get('https://api.appstoreconnect.apple.com/v1/apps', headers=headers)
    response_json = response.json()
    
    # Find the app with matching bundle ID
    if 'data' in response_json:
        for app in response_json['data']:
            if app['attributes']['bundleId'] == bundle_id:
                print(app['id'])
                sys.exit(0)
except Exception as e:
    print(f"Error detecting APP_ID: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON_SCRIPT
    
    # Run the Python script
    detected=$(python3 "$temp_script" "$bundle_id" 2>/dev/null)
    
    # Clean up
    rm -f "$temp_script"
    
    if [ -n "$detected" ]; then
        echo "Auto-detected APP_ID from App Store Connect: $detected" >&2
        echo "$detected"
    fi
}

# 1. Try to get from environment
# 2. If empty, try to auto-detect
# 3. If still empty, prompt user

# Handle PROJECT_FILE
if [ -z "$PROJECT_FILE" ]; then
    echo "PROJECT_FILE not found in environment, attempting auto-detection..."
    PROJECT_FILE=$(auto_detect_project)
fi
PROJECT_FILE=$(prompt_if_empty "PROJECT_FILE" "$PROJECT_FILE" "Enter XCODE_WORKSPACE or XCODE_PROJECT (e.g., YourProject.xcworkspace)")

# Handle BITRISE_SCHEME
if [ -z "$BITRISE_SCHEME" ]; then
    echo "XCODE_SCHEME not found in environment, attempting auto-detection..."
    BITRISE_SCHEME=$(auto_detect_scheme "$PROJECT_FILE")
fi
BITRISE_SCHEME=$(prompt_if_empty "BITRISE_SCHEME" "$BITRISE_SCHEME" "Enter XCODE_SCHEME")

# Handle PRODUCT_BUNDLE_IDENTIFIER
if [ -z "$PRODUCT_BUNDLE_IDENTIFIER" ]; then
    echo "BUNDLE_ID not found in environment, attempting auto-detection..."
    PRODUCT_BUNDLE_IDENTIFIER=$(auto_detect_bundle_id "$PROJECT_FILE" "$BITRISE_SCHEME")
fi
PRODUCT_BUNDLE_IDENTIFIER=$(prompt_if_empty "PRODUCT_BUNDLE_IDENTIFIER" "$PRODUCT_BUNDLE_IDENTIFIER" "Enter BUNDLE_ID (e.g., com.yourcompany.app)")

# Handle APP_ID
if [ -z "$APP_ID" ] && [ -n "$PRODUCT_BUNDLE_IDENTIFIER" ]; then
    echo "APP_ID not found in environment, attempting auto-detection from App Store Connect..."
    APP_ID=$(auto_detect_app_id "$PRODUCT_BUNDLE_IDENTIFIER")
fi
APP_ID=$(prompt_if_empty "APP_ID" "$APP_ID" "Enter APP_STORE_APPLE_ID")

# Update BITRISE_TARGET if scheme was updated
if [ -z "$BITRISE_TARGET" ]; then
    BITRISE_TARGET="$BITRISE_SCHEME"
fi

echo ""
echo "Using configuration:"
echo "APP_ID: $APP_ID"
echo "SCHEME: $BITRISE_SCHEME"
echo "PROJECT: $PROJECT_FILE"
echo "BUNDLE_ID: $PRODUCT_BUNDLE_IDENTIFIER"
echo ""

# Check if fastlane is installed and find its path
FASTLANE_CMD=""
FASTLANE_PATH=$(which fastlane 2>/dev/null)

if [ -n "$FASTLANE_PATH" ]; then
    FASTLANE_CMD="$FASTLANE_PATH"
    echo "Using Fastlane at: $FASTLANE_PATH"
else
    # Check if we can use bundle exec
    if [ -f "Gemfile" ] && command -v bundle &> /dev/null; then
        if bundle list 2>/dev/null | grep -q fastlane; then
            FASTLANE_CMD="bundle exec fastlane"
            echo "Using Fastlane via bundle exec"
        fi
    fi
    
    # If still not found, try common locations
    if [ -z "$FASTLANE_CMD" ]; then
        if [ -f "/usr/local/bin/fastlane" ]; then
            FASTLANE_CMD="/usr/local/bin/fastlane"
        elif [ -f "$HOME/.fastlane/bin/fastlane" ]; then
            FASTLANE_CMD="$HOME/.fastlane/bin/fastlane"
        elif [ -f "/opt/homebrew/bin/fastlane" ]; then
            FASTLANE_CMD="/opt/homebrew/bin/fastlane"
        elif [ -f "$HOME/.gem/ruby/2.6.0/bin/fastlane" ]; then
            FASTLANE_CMD="$HOME/.gem/ruby/2.6.0/bin/fastlane"
        fi
    fi
    
    # If still not found, suggest installation
    if [ -z "$FASTLANE_CMD" ]; then
        echo "ERROR: Fastlane is not installed."
        echo ""
        echo "Please install Fastlane using one of these methods:"
        echo ""
        echo "1. Using Homebrew (recommended - fastest):"
        echo "   brew install fastlane"
        echo ""
        echo "2. Using RubyGems:"
        echo "   sudo gem install fastlane -NV"
        echo ""
        echo "3. Using RubyGems with user install:"
        echo "   gem install fastlane --user-install"
        echo "   Then add to PATH: export PATH=\"\$PATH:\$(ruby -r rubygems -e 'puts Gem.user_dir')/bin\""
        echo ""
        echo "After installation, please run this script again."
        exit 1
    fi
fi

echo "Fastlane command: $FASTLANE_CMD"

# Check if md5sum is installed
if ! command -v md5sum &> /dev/null; then
    echo "md5sum could not be found. Installing..."
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "Homebrew is not installed."
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    # Install md5sum via Homebrew
    brew install md5sha1sum
else
    echo "md5sum is already installed."
fi

# ------------------------------------------------------------------------------
# Global array to track used paybonus numbers so they remain distinct:
# ------------------------------------------------------------------------------
USED_NUMBERS=()

# ------------------------------------------------------------------------------
# Function to generate a distinct paybonus number from 1..46, using a specific
# offset in the MD5 hash and skipping duplicates deterministically.
# ------------------------------------------------------------------------------
function generate_distinct_paybonus() {
  local offset="$1"
  # Extract an 8-character segment from the hash
  local part_hex="${hash:${offset}:8}"
  # Interpret the hex as an integer (base 16)
  local part=$((16#$part_hex))

  # Candidate is (part mod 46) + 1 => ensures 1..46
  local candidate=$(( (part % 46) + 1 ))

  # If the candidate is already used, increment until we find a free number
  # Wrapping around if we exceed 46
  while [[ " ${USED_NUMBERS[*]} " =~ " $candidate " ]]; do
    candidate=$((candidate + 1))
    if [ $candidate -gt 46 ]; then
      candidate=1
    fi
  done

  USED_NUMBERS+=("$candidate")
  echo "$candidate"
}

# Generate paybonus scheme based on APP_ID
hash=$(echo -n "$APP_ID" | md5sum | awk '{print $1}')
N1=$(generate_distinct_paybonus 0)
paybonus1="paybonus${N1}"

echo "Generated paybonus scheme: $paybonus1"

# Decide which scheme name to use for Fastlane
if [ -n "${BITRISE_TARGET}" ]; then
    FASTLANE_SCHEME=$BITRISE_TARGET
    echo "For Fastlane will be used $BITRISE_TARGET"
else
    FASTLANE_SCHEME=$BITRISE_SCHEME
    echo "For Fastlane will be used $BITRISE_SCHEME"
fi

# Get Info.plist path dynamically
echo ""
echo "Getting Info.plist path..."
# Extract project name from workspace
PROJECT_DIR=$(echo "$PROJECT_FILE" | sed 's/\.xcworkspace$/\.xcodeproj/')

# Check if we're using workspace or project
if [[ "$PROJECT_FILE" == *.xcworkspace ]]; then
    # Run xcodebuild with workspace
    echo "Running xcodebuild with workspace: $PROJECT_FILE"
    output=$(xcodebuild \
      -workspace "${PROJECT_FILE}" \
      -scheme "${FASTLANE_SCHEME}" \
      -showBuildSettings \
      -skipPackageUpdates \
      -skipPackagePluginValidation \
      2>&1)
else
    # Run xcodebuild with project
    echo "Running xcodebuild with project: $PROJECT_DIR"
    output=$(xcodebuild \
      -project "${PROJECT_DIR}" \
      -scheme "${FASTLANE_SCHEME}" \
      -showBuildSettings \
      -skipPackageUpdates \
      -skipPackagePluginValidation \
      2>&1)
fi

# Extract INFOPLIST_FILE path
info_plist_file=$(echo "$output" | grep -E "^ *INFOPLIST_FILE =" | head -1 | cut -d '=' -f2 | xargs)

# Debug output
echo "Raw info_plist_file from xcodebuild: '$info_plist_file'"

# Get the current directory
CURRENT_DIR=$(pwd)

# If empty, try to find Info.plist manually
if [ -z "$info_plist_file" ]; then
    echo "xcodebuild did not return INFOPLIST_FILE, searching for Info.plist..."
    # Look for Info.plist in common locations
    if [ -f "${CURRENT_DIR}/SafeVPN/Info.plist" ]; then
        INFOPLIST_FILE="${CURRENT_DIR}/SafeVPN/Info.plist"
    elif [ -f "${CURRENT_DIR}/SafeVPN/SupportingFiles/Info.plist" ]; then
        INFOPLIST_FILE="${CURRENT_DIR}/SafeVPN/SupportingFiles/Info.plist"
    elif [ -f "${CURRENT_DIR}/Info.plist" ]; then
        INFOPLIST_FILE="${CURRENT_DIR}/Info.plist"
    else
        # Find first Info.plist
        INFOPLIST_FILE=$(find "${CURRENT_DIR}" -name "Info.plist" -not -path "*/Pods/*" -not -path "*/build/*" -not -path "*/.build/*" -not -path "*/DerivedData/*" | head -1)
    fi
else
    # Check if the path is already absolute
    if [[ "$info_plist_file" == /* ]]; then
        INFOPLIST_FILE="$info_plist_file"
    else
        INFOPLIST_FILE="${CURRENT_DIR}/${info_plist_file}"
    fi
fi

echo "INFOPLIST_FILE: $INFOPLIST_FILE"

# Check if Info.plist exists
if [ ! -f "$INFOPLIST_FILE" ]; then
    echo "ERROR: Info.plist not found at $INFOPLIST_FILE"
    exit 1
fi

echo ""
echo "Setting up Fastlane directory..."
rm -rf "./fastlane"
mkdir "./fastlane"

cat << EOF > "./fastlane/Fastfile"
lane :update_encryption_settings do
  update_info_plist(
    scheme: "$FASTLANE_SCHEME",
    xcodeproj: "${PROJECT_DIR}",
    block: proc do |plist|
      plist['ITSAppUsesNonExemptEncryption'] = false
    end
  )
end

lane :add_paybonus_schemes do |options|
  # Ensure schemes_to_add is always an array
  schemes_to_add = (options[:schemes] || '').split(',')

  update_info_plist(
    scheme: "$FASTLANE_SCHEME",
    xcodeproj: "${PROJECT_DIR}",
    block: proc do |plist|
      plist['CFBundleURLTypes'] ||= []
      existing_schemes = plist['CFBundleURLTypes'].flat_map { |t| t['CFBundleURLSchemes'] || [] }

      schemes_to_add.each do |s|
        s = s.strip
        unless existing_schemes.include?(s)
          plist['CFBundleURLTypes'] << { 'CFBundleURLSchemes' => [s] }
          UI.message("Added URL scheme: #{s}")
        else
          UI.message("URL scheme #{s} already present, no need to add.")
        end
      end
    end
  )
end

lane :add_bundle_id_scheme do
  bundle_scheme = '$PRODUCT_BUNDLE_IDENTIFIER'

  update_info_plist(
    scheme: "$FASTLANE_SCHEME",
    xcodeproj: "${PROJECT_DIR}",
    block: proc do |plist|
      plist['CFBundleURLTypes'] ||= []
      existing_schemes = plist['CFBundleURLTypes'].flat_map { |t| t['CFBundleURLSchemes'] || [] }

      unless existing_schemes.include?(bundle_scheme)
        plist['CFBundleURLTypes'] << { 'CFBundleURLSchemes' => [bundle_scheme] }
        UI.message("Added URL scheme: #{bundle_scheme}")
      else
        UI.message("URL scheme #{bundle_scheme} already present, no need to add.")
      end
    end
  )
end

lane :add_application_query_schemes do |options|
  schemes = (options[:schemes] || '').split(',')
  update_info_plist(
    scheme: "$FASTLANE_SCHEME",
    xcodeproj: "${PROJECT_DIR}",
    block: proc do |plist|
      plist['LSApplicationQueriesSchemes'] ||= []

      schemes.each do |scheme|
        scheme.strip!
        if plist['LSApplicationQueriesSchemes'].include?(scheme)
          UI.message("Scheme '#{scheme}' already exists in LSApplicationQueriesSchemes.")
        else
          plist['LSApplicationQueriesSchemes'] << scheme
          UI.message("Added scheme '#{scheme}' to LSApplicationQueriesSchemes.")
        end
      end
    end
  )
end

# ------------------------------------------------------------------------------
# Lane to remove any existing "paybonus" schemes from the Info.plist
# ------------------------------------------------------------------------------
lane :remove_paybonus_schemes do
  update_info_plist(
    scheme: "$FASTLANE_SCHEME",
    xcodeproj: "${PROJECT_DIR}",
    block: proc do |plist|
      next if plist['CFBundleURLTypes'].nil? or plist['CFBundleURLTypes'].empty?

      new_url_types = []
      plist['CFBundleURLTypes'].each do |url_type|
        if url_type['CFBundleURLSchemes']
          # filter out any CFBundleURLSchemes that contain "paybonus"
          filtered_schemes = url_type['CFBundleURLSchemes'].reject { |s| s.include?('paybonus') }
          # only add url_type if not empty after filtering
          new_url_types << { 'CFBundleURLSchemes' => filtered_schemes } unless filtered_schemes.empty?
        else
          new_url_types << url_type
        end
      end
      plist['CFBundleURLTypes'] = new_url_types
    end
  )
end
EOF

echo ""
echo "Running Fastlane tasks..."

# Check for "ITSAppUsesNonExemptEncryption" and update if not found
echo "Checking ITSAppUsesNonExemptEncryption..."
if ! grep -q "ITSAppUsesNonExemptEncryption" "$INFOPLIST_FILE"; then
  echo "Adding ITSAppUsesNonExemptEncryption..."
  $FASTLANE_CMD update_encryption_settings
  echo "✓ Fastlane update_encryption_settings finished"
else
  echo "✓ ITSAppUsesNonExemptEncryption settings found, no need to add"
fi

# First check if we need to remove old paybonus schemes
echo ""
echo "Checking for existing paybonus schemes..."
# Check if there are any paybonus schemes other than the one we want
if grep -q "paybonus" "$INFOPLIST_FILE"; then
  # Check if the current paybonus scheme is different from what we want
  if ! grep -q "$paybonus1" "$INFOPLIST_FILE"; then
    echo "Found different paybonus scheme(s) in Info.plist. Removing..."
    $FASTLANE_CMD remove_paybonus_schemes
    echo "✓ Fastlane remove_paybonus_schemes finished"
  else
    echo "✓ Correct paybonus scheme ($paybonus1) already present."
  fi
else
  echo "✓ No paybonus scheme found in Info.plist."
fi

# Check each paybonus scheme individually
MISSING_SCHEMES=()
for scheme in "$paybonus1"; do
  if ! grep -q "$scheme" "$INFOPLIST_FILE"; then
    MISSING_SCHEMES+=("$scheme")
  fi
done

if [ ${#MISSING_SCHEMES[@]} -gt 0 ]; then
  echo ""
  echo "Adding missing paybonus schemes: ${MISSING_SCHEMES[*]}"
  missing_schemes_str=$(IFS=','; echo "${MISSING_SCHEMES[*]}")
  $FASTLANE_CMD add_paybonus_schemes schemes:"$missing_schemes_str"
  echo "✓ Fastlane add_paybonus_schemes finished. Added: $missing_schemes_str"
else
  echo "✓ All paybonus schemes already present, no need to add."
fi

# Ensure bundle identifier URL scheme exists
echo ""
echo "Adding bundle identifier URL scheme..."
$FASTLANE_CMD add_bundle_id_scheme
echo "✓ Fastlane add_bundle_id_scheme finished"

# Add deeplinks into LSApplicationQueriesSchemes
echo ""
echo "Adding application query schemes..."
SCHEMES="whatsapp,fb,fb-messenger,tiktok,instagram,youtube,telegram,spotify,chatgpt,googlemaps,twitter,snapchat,capcut,zoomus,google,roblox,googlechrome,googlegmail,nflx,squarecash,wbdstreaming,com.amazon.mobile.shopping,ss,ssconf,v2rayTun,v2box,vless,vmess,vkvideo,ozon,yandexauth,ymaps,gosuslugi"
$FASTLANE_CMD add_application_query_schemes schemes:"$SCHEMES"
echo "✓ All schemes have been added to LSApplicationQueriesSchemes."

echo ""
echo "=== Script completed successfully! ==="
echo "Summary:"
echo "- Paybonus scheme: $paybonus1"
echo "- Bundle ID scheme: $PRODUCT_BUNDLE_IDENTIFIER"
echo "- Encryption exemption: Set"
echo "- Application query schemes: Added"