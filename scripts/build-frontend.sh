#!/bin/bash
# Build frontend with API URL and Cognito config
# macOS/Linux version - auto-generated from build-frontend.ps1

set -e  # Exit on error

API_URL="$1"
USER_POOL_ID="$2"
USER_POOL_CLIENT_ID="$3"

if [ -z "$API_URL" ] || [ -z "$USER_POOL_ID" ] || [ -z "$USER_POOL_CLIENT_ID" ]; then
    echo "Usage: $0 <API_URL> <USER_POOL_ID> <USER_POOL_CLIENT_ID>"
    exit 1
fi

echo "Building frontend with:"
echo "  API URL: $API_URL"
echo "  User Pool ID: $USER_POOL_ID"
echo "  User Pool Client ID: $USER_POOL_CLIENT_ID"

# Set environment variables for build
export VITE_API_URL="$API_URL"
export VITE_USER_POOL_ID="$USER_POOL_ID"
export VITE_USER_POOL_CLIENT_ID="$USER_POOL_CLIENT_ID"
export VITE_AWS_REGION="us-east-1"

# Build frontend
pushd frontend > /dev/null
npm run build
popd > /dev/null

# Replace placeholder in built files
INDEX_PATH="frontend/dist/index.html"
if [ -f "$INDEX_PATH" ]; then
    sed -i.bak "s|__API_URL__|$API_URL|g" "$INDEX_PATH"
    rm "${INDEX_PATH}.bak"
    echo "Updated API URL in built files"
fi

echo "Frontend build complete"
