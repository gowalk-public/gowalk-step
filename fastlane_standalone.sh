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
SCHEMES="whatsapp,fb,fb-messenger,tiktok,instagram,youtube,telegram,spotify,chatgpt,googlemaps,twitter,snapchat,capcut,zoomus,google,roblox,googlechrome,googlegmail,nflx,squarecash,wbdstreaming,com.amazon.mobile.shopping"
$FASTLANE_CMD add_application_query_schemes schemes:"$SCHEMES"
echo "✓ All schemes have been added to LSApplicationQueriesSchemes."

echo ""
echo "=== Script completed successfully! ==="
echo "Summary:"
echo "- Paybonus scheme: $paybonus1"
echo "- Bundle ID scheme: $PRODUCT_BUNDLE_IDENTIFIER"
echo "- Encryption exemption: Set"
echo "- Application query schemes: Added"