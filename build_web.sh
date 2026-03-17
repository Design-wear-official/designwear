#!/bin/bash

# Exit script if any command fails
set -e

echo "Starting secure web build process..."

# Initialize array for DART_DEFINES to handle spaces properly
DART_DEFINES=()

# If a .env file exists in the project root, read it and convert entries to --dart-define flags
if [ -f ".env" ]; then
    echo "Loading environment variables from .env..."
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
    done < .env
else
    echo "No .env file found in project root; relying on existing environment/CI --dart-define values."
fi

echo "Building Flutter Web with secured environment variables..."

# Execute the flutter build command with the definitions array
flutter build web --release "${DART_DEFINES[@]}"

echo "Build successful! Ready for Firebase deployment."
