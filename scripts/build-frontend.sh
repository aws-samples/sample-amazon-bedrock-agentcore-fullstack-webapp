#!/bin/bash
# Build frontend with AgentCore Runtime ARN and Cognito config
# macOS/Linux version - auto-generated from build-frontend.ps1

set -e  # Exit on error

USER_POOL_ID="$1"
USER_POOL_CLIENT_ID="$2"
AGENT_RUNTIME_ARN="$3"
REGION="$4"

if [ -z "$USER_POOL_ID" ] || [ -z "$USER_POOL_CLIENT_ID" ] || [ -z "$AGENT_RUNTIME_ARN" ] || [ -z "$REGION" ]; then
    echo "Usage: $0 <USER_POOL_ID> <USER_POOL_CLIENT_ID> <AGENT_RUNTIME_ARN> <REGION>"
    exit 1
fi

echo "Building frontend with:"
echo "  User Pool ID: $USER_POOL_ID"
echo "  User Pool Client ID: $USER_POOL_CLIENT_ID"
echo "  Agent Runtime ARN: $AGENT_RUNTIME_ARN"
echo "  Region: $REGION"

# Set environment variables for build
export VITE_USER_POOL_ID="$USER_POOL_ID"
export VITE_USER_POOL_CLIENT_ID="$USER_POOL_CLIENT_ID"
export VITE_AGENT_RUNTIME_ARN="$AGENT_RUNTIME_ARN"
export VITE_REGION="$REGION"

# Build frontend
pushd frontend > /dev/null
npm run build
popd > /dev/null

echo "Frontend build complete"
