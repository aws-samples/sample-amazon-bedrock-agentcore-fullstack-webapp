#!/bin/bash
# Deploy AgentCore Demo - Complete Deployment Script
# macOS/Linux version - auto-generated from deploy-all.ps1

set -e  # Exit on error

echo -e "\033[0;36m=== AgentCore Demo Deployment ===\033[0m"

# Verify required commands
MISSING_COMMANDS=()
if ! command -v pip3 &> /dev/null; then
    MISSING_COMMANDS+=("pip3")
fi
if ! command -v zip &> /dev/null; then
    MISSING_COMMANDS+=("zip")
fi
if ! command -v unzip &> /dev/null; then
    MISSING_COMMANDS+=("unzip")
fi
if ! command -v aws &> /dev/null; then
    MISSING_COMMANDS+=("aws")
fi

if [ ${#MISSING_COMMANDS[@]} -ne 0 ]; then
    echo -e "\033[0;31m      ❌ Missing required commands: ${MISSING_COMMANDS[*]}\033[0m"
    echo -e "\033[0;33m      Please install the missing commands and try again.\033[0m"
    exit 1
fi

# Step 1: Verify AWS credentials
echo -e "\n\033[0;33m[1/10] Verifying AWS credentials...\033[0m"
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

# Step 2: Check AWS CLI version
echo -e "\n\033[0;33m[2/10] Checking AWS CLI version...\033[0m"
AWS_VERSION=$(aws --version 2>&1)
if [[ $AWS_VERSION =~ aws-cli/([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    MAJOR=${BASH_REMATCH[1]}
    MINOR=${BASH_REMATCH[2]}
    PATCH=${BASH_REMATCH[3]}
    echo -e "\033[0;90m      Current version: aws-cli/$MAJOR.$MINOR.$PATCH\033[0m"

    # Check if version is >= 2.31.13
    if [ "$MAJOR" -gt 2 ] || \
       [ "$MAJOR" -eq 2 -a "$MINOR" -gt 31 ] || \
       [ "$MAJOR" -eq 2 -a "$MINOR" -eq 31 -a "$PATCH" -ge 13 ]; then
        echo -e "\033[0;32m      ✓ AWS CLI version is compatible\033[0m"
    else
        echo -e "\033[0;31m      ❌ AWS CLI version 2.31.13 or later is required\033[0m"
        echo -e ""
        echo -e "\033[0;33m      AgentCore support was added in AWS CLI v2.31.13 (January 2025)\033[0m"
        echo -e "\033[0;33m      Your current version: aws-cli/$MAJOR.$MINOR.$PATCH\033[0m"
        echo -e ""
        echo -e "\033[0;33m      Please upgrade your AWS CLI:\033[0m"
        echo -e "\033[0;36m        https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html\033[0m"
        exit 1
    fi
else
    echo -e "\033[0;33m      ⚠ Could not parse AWS CLI version, continuing anyway...\033[0m"
fi

# Step 3: Check AgentCore availability in current region
echo -e "\n\033[0;33m[3/10] Checking AgentCore availability in current region...\033[0m"
# Detect current region from AWS CLI configuration
CURRENT_REGION=$(aws configure get region)
if [ -z "$CURRENT_REGION" ]; then
    echo -e "\033[0;31m      ❌ No AWS region configured\033[0m"
    echo -e ""
    echo -e "\033[0;33m      Please configure your AWS region using:\033[0m"
    echo -e "\033[0;36m        aws configure set region <your-region>\033[0m"
    echo -e ""
    echo -e "\033[0;90m      For supported regions, see:\033[0m"
    echo -e "\033[0;90m      https://docs.aws.amazon.com/bedrock/latest/userguide/bedrock-regions.html\033[0m"
    exit 1
fi
echo -e "\033[0;90m      Target region: $CURRENT_REGION\033[0m"

# Try to list AgentCore Runtime to verify service availability
if ! aws bedrock-agentcore-control list-agent-runtimes --region "$CURRENT_REGION" --max-results 1 > /dev/null 2>&1; then
    echo -e "\033[0;31m      ❌ AgentCore is not available in region: $CURRENT_REGION\033[0m"
    echo -e ""
    echo -e "\033[0;90m      For supported regions, see:\033[0m"
    echo -e "\033[0;90m      https://docs.aws.amazon.com/bedrock/latest/userguide/bedrock-regions.html\033[0m"
    exit 1
fi
echo -e "\033[0;32m      ✓ AgentCore is available in $CURRENT_REGION\033[0m"

# Step 4: Install CDK dependencies
echo -e "\n\033[0;33m[4/10] Installing CDK dependencies...\033[0m"
echo -e "\033[0;90m      (Installing AWS CDK libraries and TypeScript packages for infrastructure code)\033[0m"
if [ ! -d "cdk/node_modules" ]; then
    pushd cdk > /dev/null
    npm install
    popd > /dev/null
else
    echo -e "\033[0;90m      CDK dependencies already installed, skipping...\033[0m"
fi

# Step 5: Install frontend dependencies
echo -e "\n\033[0;33m[5/10] Installing frontend dependencies...\033[0m"
echo -e "\033[0;90m      (Installing React, Vite, Cognito SDK, and UI component libraries)\033[0m"
pushd frontend > /dev/null
# Commented out to save time during development - uncomment for clean builds
# if [ -d "node_modules" ]; then
#     echo "Removing existing node_modules..."
#     rm -rf node_modules
# fi
npm install
popd > /dev/null

# Step 6: Create placeholder dist BEFORE any CDK commands
# (CDK synthesizes all stacks even when deploying one, so frontend/dist must exist)
echo -e "\n\033[0;33m[6/10] Creating placeholder frontend build...\033[0m"
echo -e "\033[0;90m      (Generating temporary HTML file - required for CDK synthesis)\033[0m"
if [ ! -d "frontend/dist" ]; then
    mkdir -p frontend/dist
    echo "<!DOCTYPE html><html><body><h1>Building...</h1></body></html>" > frontend/dist/index.html
else
    echo -e "\033[0;90m      Placeholder already exists, skipping...\033[0m"
fi

# Step 7: Bootstrap CDK (if needed)
echo -e "\n\033[0;33m[7/10] Bootstrapping CDK environment...\033[0m"
echo -e "\033[0;90m      (Setting up CDK deployment resources in your AWS account/region)\033[0m"
pushd cdk > /dev/null
npx cdk bootstrap
popd > /dev/null

# Step 8: Deploy infrastructure stack
echo -e "\n\033[0;33m[8/10] Deploying infrastructure stack...\033[0m"
echo -e "\033[0;90m      (Creating S3 code bucket and IAM roles for direct code deployment)\033[0m"
pushd cdk > /dev/null
TIMESTAMP=$(date +%Y%m%d%H%M%S)
npx cdk deploy AgentCoreInfra --output "cdk.out.$TIMESTAMP" --exclusively --require-approval never
popd > /dev/null

# Get the S3 bucket name from stack outputs
CODE_BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name AgentCoreInfra --query "Stacks[0].Outputs[?OutputKey=='CodeBucketName'].OutputValue" --output text --no-cli-pager)
if [ -z "$CODE_BUCKET_NAME" ]; then
    echo -e "\033[0;31mFailed to get Code Bucket Name from stack outputs\033[0m"
    exit 1
fi

# Build agent deployment package
echo -e "\nBuilding agent deployment package..."
echo -e "\033[0;90m      (Downloading ARM64 packages and creating ZIP for direct code deployment)\033[0m"

# Create build directory
TIMESTAMP=$(date +%Y%m%d%H%M%S)
BUILD_DIR="cdk/agentcore.out.$TIMESTAMP"
mkdir -p "$BUILD_DIR/packages" "$BUILD_DIR/deployment"

# Download ARM64-compatible packages
pip3 download \
    --platform manylinux2014_aarch64 \
    --python-version 313 \
    --only-binary=:all: \
    --dest "$BUILD_DIR/packages" \
    -r agent/requirements.txt > /dev/null 2>&1

# Extract wheel packages to deployment directory
for whl in "$BUILD_DIR/packages/"*.whl; do
    unzip -q -o "$whl" -d "$BUILD_DIR/deployment"
done

# Copy agent source code
cp agent/strands_agent.py "$BUILD_DIR/deployment/"

# Create ZIP with maximum compression
pushd "$BUILD_DIR/deployment" > /dev/null
zip -9 -r ../deployment_package.zip . > /dev/null
popd > /dev/null

# Upload to S3
aws s3 cp "$BUILD_DIR/deployment_package.zip" \
    "s3://$CODE_BUCKET_NAME/strands_agent/deployment_package.zip" \
    --no-cli-pager

# Step 9: Deploy auth stack
echo -e "\n\033[0;33m[9/10] Deploying authentication stack...\033[0m"
echo -e "\033[0;90m      (Creating Cognito User Pool with email verification and password policies)\033[0m"
pushd cdk > /dev/null
TIMESTAMP=$(date +%Y%m%d%H%M%S)
npx cdk deploy AgentCoreAuth --output "cdk.out.$TIMESTAMP" --exclusively --require-approval never
popd > /dev/null

# Step 10: Deploy backend stack
echo -e "\n\033[0;33m[10/10] Deploying AgentCore backend stack...\033[0m"
echo -e "\033[0;90m      (Creating AgentCore Runtime with direct code deployment and built-in Cognito auth)\033[0m"
pushd cdk > /dev/null
TIMESTAMP=$(date +%Y%m%d%H%M%S)
if ! npx cdk deploy AgentCoreRuntime --output "cdk.out.$TIMESTAMP" --exclusively --require-approval never 2>&1 | tee /tmp/agentcore-deploy.log; then
    # Check if the error is about unrecognized resource type
    if grep -q "Unrecognized resource types.*BedrockAgentCore" /tmp/agentcore-deploy.log; then
        CURRENT_REGION="${AWS_DEFAULT_REGION:-${AWS_REGION:-unknown}}"
        echo -e "\n\033[0;31m❌ DEPLOYMENT FAILED: AgentCore is not available in region '$CURRENT_REGION'\033[0m"
        echo -e ""
        echo -e "\033[0;33mPlease verify AgentCore availability in your target region:\033[0m"
        echo -e "\033[0;36mhttps://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/agentcore-regions.html\033[0m"
        echo -e ""
        echo -e "\033[0;33mTo deploy to a supported region, set the AWS_DEFAULT_REGION environment variable:\033[0m"
        echo -e "\033[0;90m  export AWS_DEFAULT_REGION=\"your-supported-region\"\033[0m"
        echo -e "\033[0;90m  export AWS_REGION=\"your-supported-region\"\033[0m"
        echo -e "\033[0;90m  ./deploy-all.sh\033[0m"
        popd > /dev/null
        exit 1
    fi
    # Re-throw other errors
    popd > /dev/null
    exit 1
fi
popd > /dev/null

# Build and deploy frontend (after backend is complete)
echo -e "\nBuilding and deploying frontend...\033[0m"
echo -e "\033[0;90m      (Retrieving AgentCore Runtime ID and Cognito config, building React app, deploying to S3 + CloudFront)\033[0m"
AGENT_RUNTIME_ARN=$(aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].Outputs[?OutputKey=='AgentRuntimeArn'].OutputValue" --output text --no-cli-pager)
REGION=$(aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].Outputs[?OutputKey=='Region'].OutputValue" --output text --no-cli-pager)
MEMORY_ID=$(aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].Outputs[?OutputKey=='AgentMemoryId'].OutputValue" --output text --no-cli-pager)
USER_POOL_ID=$(aws cloudformation describe-stacks --stack-name AgentCoreAuth --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" --output text --no-cli-pager)
USER_POOL_CLIENT_ID=$(aws cloudformation describe-stacks --stack-name AgentCoreAuth --query "Stacks[0].Outputs[?OutputKey=='UserPoolClientId'].OutputValue" --output text --no-cli-pager)
IDENTITY_POOL_ID=$(aws cloudformation describe-stacks --stack-name AgentCoreAuth --query "Stacks[0].Outputs[?OutputKey=='IdentityPoolId'].OutputValue" --output text --no-cli-pager)

if [ -z "$AGENT_RUNTIME_ARN" ]; then
    echo -e "\033[0;31mFailed to get Agent Runtime ARN from stack outputs\033[0m"
    exit 1
fi

if [ -z "$REGION" ]; then
    echo -e "\033[0;31mFailed to get Region from stack outputs\033[0m"
    exit 1
fi

if [ -z "$MEMORY_ID" ]; then
    echo -e "\033[0;31mFailed to get Memory ID from stack outputs\033[0m"
    exit 1
fi

if [ -z "$USER_POOL_ID" ] || [ -z "$USER_POOL_CLIENT_ID" ]; then
    echo -e "\033[0;31mFailed to get Cognito config from stack outputs\033[0m"
    exit 1
fi

if [ -z "$IDENTITY_POOL_ID" ]; then
    echo -e "\033[0;31mFailed to get Identity Pool ID from stack outputs\033[0m"
    exit 1
fi

echo -e "\033[0;32mAgent Runtime ARN: $AGENT_RUNTIME_ARN\033[0m"
echo -e "\033[0;32mRegion: $REGION\033[0m"
echo -e "\033[0;32mMemory ID: $MEMORY_ID\033[0m"
echo -e "\033[0;32mUser Pool ID: $USER_POOL_ID\033[0m"
echo -e "\033[0;32mUser Pool Client ID: $USER_POOL_CLIENT_ID\033[0m"
echo -e "\033[0;32mIdentity Pool ID: $IDENTITY_POOL_ID\033[0m"

# Build frontend with AgentCore Runtime ARN and Cognito config
./scripts/build-frontend.sh "$USER_POOL_ID" "$USER_POOL_CLIENT_ID" "$AGENT_RUNTIME_ARN" "$IDENTITY_POOL_ID" "$MEMORY_ID" "$REGION"

# Deploy frontend stack
pushd cdk > /dev/null
TIMESTAMP=$(date +%Y%m%d%H%M%S)
npx cdk deploy AgentCoreFrontend --output "cdk.out.$TIMESTAMP" --exclusively --require-approval never
popd > /dev/null

# Get CloudFront URL
WEBSITE_URL=$(aws cloudformation describe-stacks --stack-name AgentCoreFrontend --query "Stacks[0].Outputs[?OutputKey=='WebsiteUrl'].OutputValue" --output text --no-cli-pager)

echo -e "\n\033[0;32m=== Deployment Complete ===\033[0m"
echo -e "\033[0;36mWebsite URL: $WEBSITE_URL\033[0m"
echo -e "\033[0;36mAgent Runtime ARN: $AGENT_RUNTIME_ARN\033[0m"
echo -e "\033[0;36mRegion: $REGION\033[0m"
echo -e "\033[0;36mMemory ID: $MEMORY_ID\033[0m"
echo -e "\033[0;36mUser Pool ID: $USER_POOL_ID\033[0m"
echo -e "\033[0;36mUser Pool Client ID: $USER_POOL_CLIENT_ID\033[0m"
echo -e "\033[0;36mIdentity Pool ID: $IDENTITY_POOL_ID\033[0m"
echo -e "\n\033[0;33mNote: Users must sign up and log in to use the application\033[0m"
echo -e "\033[0;32mFrontend now calls AgentCore directly with JWT authentication\033[0m"
