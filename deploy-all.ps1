# Deploy AgentCore Demo - Complete Deployment Script

Write-Host "=== AgentCore Demo Deployment ===" -ForegroundColor Cyan

# Step 1: Verify AWS credentials
Write-Host "`n[1/8] Verifying AWS credentials..." -ForegroundColor Yellow
Write-Host "      (Checking AWS CLI configuration and validating access)" -ForegroundColor Gray

# Check if AWS credentials are configured
$callerIdentity = aws sts get-caller-identity 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "AWS credentials are not configured or have expired" -ForegroundColor Red
    Write-Host "`nPlease configure AWS credentials using one of these methods:" -ForegroundColor Yellow
    Write-Host "  1. Run: aws configure" -ForegroundColor Cyan
    Write-Host "  2. Set environment variables: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY" -ForegroundColor Cyan
    Write-Host "  3. Use AWS SSO: aws sso login --profile <profile-name>" -ForegroundColor Cyan
    Write-Host "`nFor more info: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html" -ForegroundColor Gray
    exit 1
}

# Display current AWS identity
$accountId = ($callerIdentity | ConvertFrom-Json).Account
$arn = ($callerIdentity | ConvertFrom-Json).Arn
Write-Host "      Authenticated as: $arn" -ForegroundColor Green
Write-Host "      AWS Account: $accountId" -ForegroundColor Green

# Step 2: Install CDK dependencies
Write-Host "`n[2/8] Installing CDK dependencies..." -ForegroundColor Yellow
Write-Host "      (Installing AWS CDK libraries and TypeScript packages for infrastructure code)" -ForegroundColor Gray
if (-not (Test-Path "cdk/node_modules")) {
    Push-Location cdk
    npm install
    Pop-Location
} else {
    Write-Host "      CDK dependencies already installed, skipping..." -ForegroundColor Gray
}

# Step 3: Install frontend dependencies
Write-Host "`n[3/8] Installing frontend dependencies..." -ForegroundColor Yellow
Write-Host "      (Installing React, Vite, Cognito SDK, and UI component libraries)" -ForegroundColor Gray
Push-Location frontend
# Commented out to save time during development - uncomment for clean builds
# if (Test-Path "node_modules") {
#     Write-Host "Removing existing node_modules..." -ForegroundColor Gray
#     Remove-Item -Recurse -Force "node_modules"
# }
npm install
Pop-Location

# Step 4: Deploy infrastructure stack
Write-Host "`n[4/8] Deploying infrastructure stack..." -ForegroundColor Yellow
Write-Host "      (Creating ECR repository, CodeBuild project, S3 bucket, and IAM roles)" -ForegroundColor Gray
Push-Location cdk
npx cdk deploy AgentCoreInfra --no-cli-pager --require-approval never
Pop-Location

if ($LASTEXITCODE -ne 0) {
    Write-Host "Infrastructure deployment failed" -ForegroundColor Red
    exit 1
}

# Step 5: Deploy auth stack
Write-Host "`n[5/8] Deploying authentication stack..." -ForegroundColor Yellow
Write-Host "      (Creating Cognito User Pool with email verification and password policies)" -ForegroundColor Gray
Push-Location cdk
npx cdk deploy AgentCoreAuth --no-cli-pager --require-approval never
Pop-Location

if ($LASTEXITCODE -ne 0) {
    Write-Host "Auth deployment failed" -ForegroundColor Red
    exit 1
}

# Step 6: Create placeholder dist for initial deployment
Write-Host "`n[6/8] Creating placeholder frontend build..." -ForegroundColor Yellow
Write-Host "      (Generating temporary HTML file to satisfy S3 deployment requirements)" -ForegroundColor Gray
if (-not (Test-Path "frontend/dist")) {
    New-Item -ItemType Directory -Path "frontend/dist" -Force | Out-Null
    echo "<!DOCTYPE html><html><body><h1>Building...</h1></body></html>" > frontend/dist/index.html
} else {
    Write-Host "      Placeholder already exists, skipping..." -ForegroundColor Gray
}

# Step 7: Deploy backend stack (triggers build and waits via Lambda)
Write-Host "`n[7/8] Deploying AgentCore backend stack..." -ForegroundColor Yellow
Write-Host "      (Uploading agent code, building ARM64 Docker image, creating AgentCore runtime, Lambda, and API Gateway)" -ForegroundColor Gray
Write-Host "      Note: CodeBuild will compile the container image - this takes 5-10 minutes" -ForegroundColor DarkGray
Write-Host "      The deployment will pause while waiting for the build to complete..." -ForegroundColor DarkGray
Push-Location cdk
npx cdk deploy AgentCoreRuntime --no-cli-pager --require-approval never
Pop-Location

if ($LASTEXITCODE -ne 0) {
    Write-Host "Backend deployment failed" -ForegroundColor Red
    exit 1
}

# Step 8: Get API URL and Cognito config, then build/deploy frontend
Write-Host "`n[8/8] Building and deploying frontend..." -ForegroundColor Yellow
Write-Host "      (Retrieving API endpoint and Cognito config, building React app, deploying to S3 + CloudFront)" -ForegroundColor Gray
$apiUrl = aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" --output text --no-cli-pager
$userPoolId = aws cloudformation describe-stacks --stack-name AgentCoreAuth --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" --output text --no-cli-pager
$userPoolClientId = aws cloudformation describe-stacks --stack-name AgentCoreAuth --query "Stacks[0].Outputs[?OutputKey=='UserPoolClientId'].OutputValue" --output text --no-cli-pager

if ([string]::IsNullOrEmpty($apiUrl)) {
    Write-Host "Failed to get API URL from stack outputs" -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrEmpty($userPoolId) -or [string]::IsNullOrEmpty($userPoolClientId)) {
    Write-Host "Failed to get Cognito config from stack outputs" -ForegroundColor Red
    exit 1
}

Write-Host "API URL: $apiUrl" -ForegroundColor Green
Write-Host "User Pool ID: $userPoolId" -ForegroundColor Green
Write-Host "User Pool Client ID: $userPoolClientId" -ForegroundColor Green

# Build frontend with API URL and Cognito config
& .\scripts\build-frontend.ps1 -ApiUrl $apiUrl -UserPoolId $userPoolId -UserPoolClientId $userPoolClientId

if ($LASTEXITCODE -ne 0) {
    Write-Host "Frontend build failed" -ForegroundColor Red
    exit 1
}

# Deploy frontend stack
Push-Location cdk
npx cdk deploy AgentCoreFrontend --no-cli-pager --require-approval never
Pop-Location

if ($LASTEXITCODE -ne 0) {
    Write-Host "Frontend deployment failed" -ForegroundColor Red
    exit 1
}

# Get CloudFront URL
$websiteUrl = aws cloudformation describe-stacks --stack-name AgentCoreFrontend --query "Stacks[0].Outputs[?OutputKey=='WebsiteUrl'].OutputValue" --output text --no-cli-pager

Write-Host "`n=== Deployment Complete ===" -ForegroundColor Green
Write-Host "Website URL: $websiteUrl" -ForegroundColor Cyan
Write-Host "API URL: $apiUrl" -ForegroundColor Cyan
Write-Host "User Pool ID: $userPoolId" -ForegroundColor Cyan
Write-Host "User Pool Client ID: $userPoolClientId" -ForegroundColor Cyan
Write-Host "`nNote: Users must sign up and log in to use the application" -ForegroundColor Yellow
