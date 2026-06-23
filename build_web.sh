#!/bin/bash

# Exit script if any command fails
set -e

echo "Starting secure web build process..."

# -----------------------------------------------------------------------------
# Allowlist of PUBLIC dart-defines that are safe to compile into the web bundle.
#
# WHY AN ALLOWLIST: every --dart-define is baked into main.dart.js, which is
# served publicly. This script used to dump *every* line of .env into a
# --dart-define, which would have embedded real secrets (GEMINI_API_KEY,
# RAZORPAY_KEY_ID/SECRET) into the public JS. Only the keys below are non-secret
# and actually consumed by the web client; everything else stays out of the bundle.
#
# Deliberately EXCLUDED (never put these in the web bundle):
#   - GEMINI_API_KEY        : AI is proxied through the backend /api/ai/* endpoints.
#   - RAZORPAY_KEY_ID/SECRET : web checkout receives key_id from the backend order
#                              response; the secret is server-only.
#   - FIREBASE_ANDROID_*/IOS_*: mobile builds read these from .env at runtime; web
#                              never uses them.
#
# The FIREBASE_WEB_* keys below ARE included on purpose: firebase_options.dart
# reads them via ConfigLoader, and on web dotenv is never loaded (see main.dart),
# so dart-defines are the only source — Firebase.initializeApp would fail without
# them. Firebase web config keys are non-secret by design (security is enforced by
# Firebase Security Rules + authorized domains).
# -----------------------------------------------------------------------------
ALLOWED_KEYS=(
    # App / data-source config (public)
    USE_WEB_API
    WEB_API_BASE_URL
    SANITY_PROJECT_ID
    SANITY_DATASET
    APP_NAME
    DEBUG_MODE
    DATA_SOURCE
    ENABLE_FALLBACK
    API_TIMEOUT_SECONDS
    # Firebase web config (non-secret; required for Firebase init on web)
    FIREBASE_PROJECT_ID
    FIREBASE_WEB_API_KEY
    FIREBASE_WEB_APP_ID
    FIREBASE_MESSAGING_SENDER_ID
    FIREBASE_STORAGE_BUCKET
)

is_allowed() {
    local candidate="$1"
    local allowed
    for allowed in "${ALLOWED_KEYS[@]}"; do
        [ "$allowed" = "$candidate" ] && return 0
    done
    return 1
}

# Initialize array for DART_DEFINES to handle spaces properly
DART_DEFINES=()

# If a .env file exists in the project root, read it and convert ONLY the
# allowlisted entries to --dart-define flags.
if [ -f ".env" ]; then
    echo "Loading allowlisted environment variables from .env..."
    # Read the .env file line by line
    while IFS='=' read -r key value || [ -n "$key" ]; do
        # Strip a trailing carriage return from the key (Windows-edited .env)
        key="${key%$'\r'}"

        # Skip empty lines and comments
        if [ -z "$key" ] || [[ "$key" == \#* ]]; then
            continue
        fi

        # Only pass keys on the public allowlist into the web bundle
        if ! is_allowed "$key"; then
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
