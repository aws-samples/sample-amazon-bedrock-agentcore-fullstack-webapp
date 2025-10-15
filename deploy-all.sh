#!/bin/bash
# Deploy AgentCore Demo - Complete Deployment Script
# macOS/Linux version - auto-generated from deploy-all.ps1

set -e  # Exit on error

echo -e "\033[0;36m=== AgentCore Demo Deployment ===\033[0m"

# Step 1: Verify AWS credentials
echo -e "\n\033[0;33m[1/8] Verifying AWS credentials...\033[0m"
echo -e "\033[0;90m      (Checking AWS CLI configuration and validating access)\033[0m"

# Check if AWS credentials are configured
if ! CALLER_IDENTITY=$(aws sts get-caller-identity 2>&1); then
    echo -e "\033[0;31mAWS credentials are not configured or have expired\033[0m"
    echo -e "\n\033[0;33mPlease configure AWS credentials using one of these methods:\033[0m"
    echo -e "\033[0;36m  1. Run: aws configure\033[0m"
    echo -e "\033[0;36m  2. Set environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY\033[0m"
    echo -e "\033[0;36m  3. Use AWS SSO: aws sso login --profile <profile-name>\033[0m"
    echo -e "\n\033[0;90mFor more info: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html\033[0m"
    exit 1
fi

# Display current AWS identity
ACCOUNT_ID=$(echo "$CALLER_IDENTITY" | grep -o '"Account": "[^"]*' | cut -d'"' -f4)
ARN=$(echo "$CALLER_IDENTITY" | grep -o '"Arn": "[^"]*' | cut -d'"' -f4)
echo -e "\033[0;32m      Authenticated as: $ARN\033[0m"
echo -e "\033[0;32m      AWS Account: $ACCOUNT_ID\033[0m"

# Step 2: Install CDK dependencies
echo -e "\n\033[0;33m[2/8] Installing CDK dependencies...\033[0m"
echo -e "\033[0;90m      (Installing AWS CDK libraries and TypeScript packages for infrastructure code)\033[0m"
if [ ! -d "cdk/node_modules" ]; then
    pushd cdk > /dev/null
    npm install
    popd > /dev/null
else
    echo -e "\033[0;90m      CDK dependencies already installed, skipping...\033[0m"
fi

# Step 3: Install frontend dependencies
echo -e "\n\033[0;33m[3/8] Installing frontend dependencies...\033[0m"
echo -e "\033[0;90m      (Installing React, Vite, Cognito SDK, and UI component libraries)\033[0m"
pushd frontend > /dev/null
# Commented out to save time during development - uncomment for clean builds
# if [ -d "node_modules" ]; then
#     echo "Removing existing node_modules..."
#     rm -rf node_modules
# fi
npm install
popd > /dev/null

# Step 3.5: Create placeholder dist BEFORE any CDK commands
# (CDK synthesizes all stacks even when deploying one, so frontend/dist must exist)
echo -e "\n\033[0;33m[3.5/8] Creating placeholder frontend build...\033[0m"
echo -e "\033[0;90m      (Generating temporary HTML file - required for CDK synthesis)\033[0m"
if [ ! -d "frontend/dist" ]; then
    mkdir -p frontend/dist
    echo "<!DOCTYPE html><html><body><h1>Building...</h1></body></html>" > frontend/dist/index.html
else
    echo -e "\033[0;90m      Placeholder already exists, skipping...\033[0m"
fi

# Step 4: Deploy infrastructure stack
echo -e "\n\033[0;33m[4/8] Deploying infrastructure stack...\033[0m"
echo -e "\033[0;90m      (Creating ECR repository, CodeBuild project, S3 bucket, and IAM roles)\033[0m"
pushd cdk > /dev/null
npx cdk deploy AgentCoreInfra --no-cli-pager --require-approval never
popd > /dev/null

# Step 5: Deploy auth stack
echo -e "\n\033[0;33m[5/8] Deploying authentication stack...\033[0m"
echo -e "\033[0;90m      (Creating Cognito User Pool with email verification and password policies)\033[0m"
pushd cdk > /dev/null
npx cdk deploy AgentCoreAuth --no-cli-pager --require-approval never
popd > /dev/null

# Step 6: Deploy backend stack (triggers build and waits via Lambda)
echo -e "\n\033[0;33m[6/8] Deploying AgentCore backend stack...\033[0m"
echo -e "\033[0;90m      (Uploading agent code, building ARM64 Docker image, creating AgentCore runtime, Lambda, and API Gateway)\033[0m"
echo -e "\033[0;90m      Note: CodeBuild will compile the container image - this takes 5-10 minutes\033[0m"
echo -e "\033[0;90m      The deployment will pause while waiting for the build to complete...\033[0m"
pushd cdk > /dev/null
npx cdk deploy AgentCoreRuntime --no-cli-pager --require-approval never
popd > /dev/null

# Step 7: Get API URL and Cognito config, then build/deploy frontend
echo -e "\n\033[0;33m[7/8] Building and deploying frontend...\033[0m"
echo -e "\033[0;90m      (Retrieving API endpoint and Cognito config, building React app, deploying to S3 + CloudFront)\033[0m"
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
