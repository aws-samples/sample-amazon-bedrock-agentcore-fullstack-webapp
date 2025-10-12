#!/bin/bash
# Deploy AgentCore Demo - Complete Deployment Script
# macOS/Linux version - auto-generated from deploy-all.ps1

set -e  # Exit on error

echo -e "\033[0;36m=== AgentCore Demo Deployment ===\033[0m"

# Step 1: Refresh AWS credentials
echo -e "\n\033[0;33m[1/5] Refreshing AWS credentials...\033[0m"
isengardcli creds bllecoq@amazon.com --role Admin

# Step 2: Install CDK dependencies
echo -e "\n\033[0;33m[2/6] Installing CDK dependencies...\033[0m"
if [ ! -d "cdk/node_modules" ]; then
    pushd cdk > /dev/null
    npm install
    popd > /dev/null
fi

# Step 3: Install frontend dependencies
echo -e "\n\033[0;33m[3/6] Installing frontend dependencies...\033[0m"
pushd frontend > /dev/null
# Commented out to save time during development - uncomment for clean builds
# if [ -d "node_modules" ]; then
#     echo "Removing existing node_modules..."
#     rm -rf node_modules
# fi
npm install
popd > /dev/null

# Step 4: Deploy infrastructure stack
echo -e "\n\033[0;33m[4/7] Deploying infrastructure stack...\033[0m"
pushd cdk > /dev/null
npx cdk deploy AgentCoreInfra --no-cli-pager --require-approval never
popd > /dev/null

# Step 5: Deploy auth stack
echo -e "\n\033[0;33m[5/7] Deploying authentication stack...\033[0m"
pushd cdk > /dev/null
npx cdk deploy AgentCoreAuth --no-cli-pager --require-approval never
popd > /dev/null

# Step 6: Create placeholder dist for initial deployment
echo -e "\n\033[0;33m[6/7] Creating placeholder frontend build...\033[0m"
if [ ! -d "frontend/dist" ]; then
    mkdir -p frontend/dist
    echo "<!DOCTYPE html><html><body><h1>Building...</h1></body></html>" > frontend/dist/index.html
fi

# Step 7: Deploy backend stack (triggers build and waits via Lambda)
echo -e "\n\033[0;33m[7/7] Deploying AgentCore backend stack...\033[0m"
echo -e "\033[0;90mNote: CodeBuild will run and Lambda will wait for completion (5-10 minutes)\033[0m"
echo -e "\033[0;90mThe stack deployment will pause while the Docker image builds...\033[0m"
pushd cdk > /dev/null
npx cdk deploy AgentCoreRuntime --no-cli-pager --require-approval never
popd > /dev/null

# Step 8: Get API URL and Cognito config, then build/deploy frontend
echo -e "\n\033[0;33m[8/8] Building and deploying frontend...\033[0m"
API_URL=$(aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" --output text --no-cli-pager)
USER_POOL_ID=$(aws cloudformation describe-stacks --stack-name AgentCoreAuth --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" --output text --no-cli-pager)
USER_POOL_CLIENT_ID=$(aws cloudformation describe-stacks --stack-name AgentCoreAuth --query "Stacks[0].Outputs[?OutputKey=='UserPoolClientId'].OutputValue" --output text --no-cli-pager)

if [ -z "$API_URL" ]; then
    echo -e "\033[0;31mFailed to get API URL from stack outputs\033[0m"
    exit 1
fi

if [ -z "$USER_POOL_ID" ] || [ -z "$USER_POOL_CLIENT_ID" ]; then
    echo -e "\033[0;31mFailed to get Cognito config from stack outputs\033[0m"
    exit 1
fi

echo -e "\033[0;32mAPI URL: $API_URL\033[0m"
echo -e "\033[0;32mUser Pool ID: $USER_POOL_ID\033[0m"
echo -e "\033[0;32mUser Pool Client ID: $USER_POOL_CLIENT_ID\033[0m"

# Build frontend with API URL and Cognito config
./scripts/build-frontend.sh "$API_URL" "$USER_POOL_ID" "$USER_POOL_CLIENT_ID"

# Deploy frontend stack
pushd cdk > /dev/null
npx cdk deploy AgentCoreFrontend --no-cli-pager --require-approval never
popd > /dev/null

# Get CloudFront URL
WEBSITE_URL=$(aws cloudformation describe-stacks --stack-name AgentCoreFrontend --query "Stacks[0].Outputs[?OutputKey=='WebsiteUrl'].OutputValue" --output text --no-cli-pager)

echo -e "\n\033[0;32m=== Deployment Complete ===\033[0m"
echo -e "\033[0;36mWebsite URL: $WEBSITE_URL\033[0m"
echo -e "\033[0;36mAPI URL: $API_URL\033[0m"
echo -e "\033[0;36mUser Pool ID: $USER_POOL_ID\033[0m"
echo -e "\033[0;36mUser Pool Client ID: $USER_POOL_CLIENT_ID\033[0m"
echo -e "\n\033[0;33mNote: Users must sign up and log in to use the application\033[0m"
