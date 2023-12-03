#!/usr/bin/env bash

# Check if jq is installed, if not, install it using Homebrew
if ! command -v jq &> /dev/null
then
    echo "jq could not be found, installing it now..."
    # Install Homebrew if it's not installed
    if ! command -v brew &> /dev/null
    then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    # Install jq using Homebrew
    brew install jq
fi

# Fetch the JSON data
json_response=$(curl --silent --location "$BITRISE_BUILD_URL/apple_developer_portal_data.json" \
     --header "BUILD_API_TOKEN: $BITRISE_BUILD_API_TOKEN")

# Parse values using jq and store them in variables
key_id=$(echo "$json_response" | jq -r '.key_id')
issuer_id=$(echo "$json_response" | jq -r '.issuer_id')
private_key=$(echo "$json_response" | jq -r '.private_key')

# Export the variables as environment variables
export APPLE_KEY_ID=$key_id
export APPLE_ISSUER_ID=$issuer_id
export APPLE_PRIVATE_KEY="$private_key"

# Optionally, you can print the variables for debugging
echo "Key ID: $APPLE_KEY_ID"
echo "Issuer ID: $APPLE_ISSUER_ID"
echo "Private Key: $APPLE_PRIVATE_KEY"