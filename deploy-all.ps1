# Deploy AgentCore Demo - Complete Deployment Script

Write-Host "=== AgentCore Demo Deployment ===" -ForegroundColor Cyan

# Step 1: Verify AWS credentials
Write-Host "`n[1/10] Verifying AWS credentials..." -ForegroundColor Yellow
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

# Step 2: Check AWS CLI version
Write-Host "`n[2/10] Checking AWS CLI version..." -ForegroundColor Yellow
$awsVersion = aws --version 2>&1
$versionMatch = $awsVersion -match 'aws-cli/(\d+)\.(\d+)\.(\d+)'
if ($versionMatch) {
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    $patch = [int]$Matches[3]
    Write-Host "      Current version: aws-cli/$major.$minor.$patch" -ForegroundColor Gray
    
    # Check if version is >= 2.31.13
    $isVersionValid = ($major -gt 2) -or 
                      ($major -eq 2 -and $minor -gt 31) -or 
                      ($major -eq 2 -and $minor -eq 31 -and $patch -ge 13)
    
    if (-not $isVersionValid) {
        Write-Host "      ❌ AWS CLI version 2.31.13 or later is required" -ForegroundColor Red
        Write-Host ""
        Write-Host "      AgentCore support was added in AWS CLI v2.31.13 (January 2025)" -ForegroundColor Yellow
        Write-Host "      Your current version: aws-cli/$major.$minor.$patch" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "      Please upgrade your AWS CLI:" -ForegroundColor Yellow
        Write-Host "        https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html" -ForegroundColor Cyan
        exit 1
    }
    Write-Host "      ✓ AWS CLI version is compatible" -ForegroundColor Green
} else {
    Write-Host "      ⚠ Could not parse AWS CLI version, continuing anyway..." -ForegroundColor Yellow
}

# Step 3: Check AgentCore availability in current region
Write-Host "`n[3/10] Checking AgentCore availability in current region..." -ForegroundColor Yellow
# Detect current region from AWS CLI configuration
$currentRegion = aws configure get region
if ([string]::IsNullOrEmpty($currentRegion)) {
    Write-Host "      ❌ No AWS region configured" -ForegroundColor Red
    Write-Host ""
    Write-Host "      Please configure your AWS region using:" -ForegroundColor Yellow
    Write-Host "        aws configure set region <your-region>" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "      For supported regions, see:" -ForegroundColor Gray
    Write-Host "      https://docs.aws.amazon.com/bedrock/latest/userguide/bedrock-regions.html" -ForegroundColor Gray
    exit 1
}
Write-Host "      Target region: $currentRegion" -ForegroundColor Gray

# Try to list AgentCore runtimes to verify service availability
$agentCoreCheck = aws bedrock-agentcore-control list-agent-runtimes --region $currentRegion --max-results 1 2>&1
if ($LASTEXITCODE -ne 0) {
    $errorMessage = $agentCoreCheck | Out-String
    Write-Host "      ❌ AgentCore is not available in region: $currentRegion" -ForegroundColor Red
    Write-Host ""
    Write-Host "      Error details:" -ForegroundColor Gray
    Write-Host "      $errorMessage" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "      For supported regions, see:" -ForegroundColor Gray
    Write-Host "      https://docs.aws.amazon.com/bedrock/latest/userguide/bedrock-regions.html" -ForegroundColor Gray
    exit 1
}
Write-Host "      ✓ AgentCore is available in $currentRegion" -ForegroundColor Green

# Step 4: Install CDK dependencies
Write-Host "`n[4/10] Installing CDK dependencies..." -ForegroundColor Yellow
Write-Host "      (Installing AWS CDK libraries and TypeScript packages for infrastructure code)" -ForegroundColor Gray
if (-not (Test-Path "cdk/node_modules")) {
    Push-Location cdk
    npm install
    Pop-Location
} else {
    Write-Host "      CDK dependencies already installed, skipping..." -ForegroundColor Gray
}

# Step 5: Install frontend dependencies
Write-Host "`n[5/10] Installing frontend dependencies..." -ForegroundColor Yellow
Write-Host "      (Installing React, Vite, Cognito SDK, and UI component libraries)" -ForegroundColor Gray
Push-Location frontend
# Commented out to save time during development - uncomment for clean builds
# if (Test-Path "node_modules") {
#     Write-Host "Removing existing node_modules..." -ForegroundColor Gray
#     Remove-Item -Recurse -Force "node_modules"
# }
npm install
Pop-Location

# Step 6: Create placeholder dist BEFORE any CDK commands
# (CDK synthesizes all stacks even when deploying one, so frontend/dist must exist)
Write-Host "`n[6/10] Creating placeholder frontend build..." -ForegroundColor Yellow
Write-Host "      (Generating temporary HTML file - required for CDK synthesis)" -ForegroundColor Gray
if (-not (Test-Path "frontend/dist")) {
    New-Item -ItemType Directory -Path "frontend/dist" -Force | Out-Null
    echo "<!DOCTYPE html><html><body><h1>Building...</h1></body></html>" > frontend/dist/index.html
} else {
    Write-Host "      Placeholder already exists, skipping..." -ForegroundColor Gray
}

# Step 7: Bootstrap CDK (if needed)
Write-Host "`n[7/10] Bootstrapping CDK environment..." -ForegroundColor Yellow
Write-Host "      (Setting up CDK deployment resources in your AWS account/region)" -ForegroundColor Gray
Push-Location cdk
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
npx cdk bootstrap --output "cdk.out.$timestamp" --no-cli-pager
Pop-Location

if ($LASTEXITCODE -ne 0) {
    Write-Host "CDK bootstrap failed" -ForegroundColor Red
    exit 1
}

# Step 8: Deploy infrastructure stack
Write-Host "`n[8/10] Deploying infrastructure stack..." -ForegroundColor Yellow
Write-Host "      (Creating ECR repository, CodeBuild project, S3 bucket, and IAM roles)" -ForegroundColor Gray
Push-Location cdk
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
npx cdk deploy AgentCoreInfra --output "cdk.out.$timestamp" --no-cli-pager --require-approval never
Pop-Location

if ($LASTEXITCODE -ne 0) {
    Write-Host "Infrastructure deployment failed" -ForegroundColor Red
    exit 1
}

# Step 9: Deploy auth stack
Write-Host "`n[9/10] Deploying authentication stack..." -ForegroundColor Yellow
Write-Host "      (Creating Cognito User Pool with email verification and password policies)" -ForegroundColor Gray
Push-Location cdk
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
npx cdk deploy AgentCoreAuth --output "cdk.out.$timestamp" --no-cli-pager --require-approval never
Pop-Location

if ($LASTEXITCODE -ne 0) {
    Write-Host "Auth deployment failed" -ForegroundColor Red
    exit 1
}

# Step 10: Deploy backend stack (triggers build and waits via Lambda)
Write-Host "`n[10/10] Deploying AgentCore backend stack..." -ForegroundColor Yellow
Write-Host "      (Uploading agent code, building ARM64 Docker image, creating AgentCore runtime with built-in Cognito auth)" -ForegroundColor Gray
Write-Host "      Note: CodeBuild will compile the container image - this takes 5-10 minutes" -ForegroundColor DarkGray
Write-Host "      The deployment will pause while waiting for the build to complete..." -ForegroundColor DarkGray
Push-Location cdk
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$deployOutput = npx cdk deploy AgentCoreRuntime --output "cdk.out.$timestamp" --no-cli-pager --require-approval never 2>&1 | Tee-Object -Variable cdkOutput
Pop-Location

if ($LASTEXITCODE -ne 0) {
    # Check if the error is about unrecognized resource type
    if ($cdkOutput -match "Unrecognized resource types.*BedrockAgentCore") {
        $currentRegion = if ($env:AWS_DEFAULT_REGION) { $env:AWS_DEFAULT_REGION } elseif ($env:AWS_REGION) { $env:AWS_REGION } else { "unknown" }
        Write-Host "`n❌ DEPLOYMENT FAILED: AgentCore is not available in region '$currentRegion'" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please verify AgentCore availability in your target region:" -ForegroundColor Yellow
        Write-Host "https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/agentcore-regions.html" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "To deploy to a supported region, set the AWS_DEFAULT_REGION environment variable:" -ForegroundColor Yellow
        Write-Host '  $env:AWS_DEFAULT_REGION = "your-supported-region"' -ForegroundColor Gray
        Write-Host '  $env:AWS_REGION = "your-supported-region"' -ForegroundColor Gray
        Write-Host "  .\deploy-all.ps1" -ForegroundColor Gray
        exit 1
    }
    # Re-throw other errors
    Write-Host "Backend deployment failed" -ForegroundColor Red
    exit 1
}

# Build and deploy frontend (after backend is complete)
Write-Host "`nBuilding and deploying frontend..." -ForegroundColor Yellow
Write-Host "      (Retrieving AgentCore Runtime ID and Cognito config, building React app, deploying to S3 + CloudFront)" -ForegroundColor Gray
$agentRuntimeArn = aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].Outputs[?OutputKey=='AgentRuntimeArn'].OutputValue" --output text --no-cli-pager
$region = aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].Outputs[?OutputKey=='Region'].OutputValue" --output text --no-cli-pager
$userPoolId = aws cloudformation describe-stacks --stack-name AgentCoreAuth --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" --output text --no-cli-pager
$userPoolClientId = aws cloudformation describe-stacks --stack-name AgentCoreAuth --query "Stacks[0].Outputs[?OutputKey=='UserPoolClientId'].OutputValue" --output text --no-cli-pager

if ([string]::IsNullOrEmpty($agentRuntimeArn)) {
    Write-Host "Failed to get Agent Runtime ARN from stack outputs" -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrEmpty($region)) {
    Write-Host "Failed to get Region from stack outputs" -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrEmpty($userPoolId) -or [string]::IsNullOrEmpty($userPoolClientId)) {
    Write-Host "Failed to get Cognito config from stack outputs" -ForegroundColor Red
    exit 1
}

Write-Host "Agent Runtime ARN: $agentRuntimeArn" -ForegroundColor Green
Write-Host "Region: $region" -ForegroundColor Green
Write-Host "User Pool ID: $userPoolId" -ForegroundColor Green
Write-Host "User Pool Client ID: $userPoolClientId" -ForegroundColor Green

# Build frontend with AgentCore Runtime ARN and Cognito config
& .\scripts\build-frontend.ps1 -UserPoolId $userPoolId -UserPoolClientId $userPoolClientId -AgentRuntimeArn $agentRuntimeArn -Region $region

if ($LASTEXITCODE -ne 0) {
    Write-Host "Frontend build failed" -ForegroundColor Red
    exit 1
}

# Deploy frontend stack
Push-Location cdk
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
npx cdk deploy AgentCoreFrontend --output "cdk.out.$timestamp" --no-cli-pager --require-approval never
Pop-Location

if ($LASTEXITCODE -ne 0) {
    Write-Host "Frontend deployment failed" -ForegroundColor Red
    exit 1
}

# Get CloudFront URL
$websiteUrl = aws cloudformation describe-stacks --stack-name AgentCoreFrontend --query "Stacks[0].Outputs[?OutputKey=='WebsiteUrl'].OutputValue" --output text --no-cli-pager

Write-Host "`n=== Deployment Complete ===" -ForegroundColor Green
Write-Host "Website URL: $websiteUrl" -ForegroundColor Cyan
Write-Host "Agent Runtime ARN: $agentRuntimeArn" -ForegroundColor Cyan
Write-Host "Region: $region" -ForegroundColor Cyan
Write-Host "User Pool ID: $userPoolId" -ForegroundColor Cyan
Write-Host "User Pool Client ID: $userPoolClientId" -ForegroundColor Cyan
Write-Host "`nNote: Users must sign up and log in to use the application" -ForegroundColor Yellow
Write-Host "Frontend now calls AgentCore directly with JWT authentication" -ForegroundColor Green
