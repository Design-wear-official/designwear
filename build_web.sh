#!/bin/bash

# Exit script if any command fails
set -e

echo "Starting secure web build process..."

# Check if .env file exists
if [ ! -f "assets/.env" ]; then
    echo "Error: assets/.env file not found. Ensure it exists before building."
    exit 1
fi

# Initialize array for DART_DEFINES to handle spaces properly
DART_DEFINES=()

# Read the .env file line by line
while IFS='=' read -r key value || [ -n "$key" ]; do
    # Skip empty lines and comments
    if [ -z "$key" ] || [[ "$key" == \#* ]]; then
        continue
    fi
    # Remove leading/trailing quotes and carriage returns from the value
    value="${value%\"}"
    value="${value#\"}"
    value="${value%\'}"
    value="${value#\'}"
    value="${value%$'\r'}"
    
    # Append to DART_DEFINES array 
    # Use proper escaping so arguments with spaces don't break the CLI
    DART_DEFINES+=("--dart-define=$key=$value")
done < assets/.env

echo "Building Flutter Web with secured environment variables..."

# Execute the flutter build command with the definitions array
flutter build web --release "${DART_DEFINES[@]}"

echo "Build successful! Ready for Firebase deployment."
