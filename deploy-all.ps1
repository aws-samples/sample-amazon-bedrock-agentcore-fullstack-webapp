# Deploy AgentCore Demo - Complete Deployment Script

Write-Host "=== AgentCore Demo Deployment ===" -ForegroundColor Cyan

# Step 1: Refresh AWS credentials
Write-Host "`n[1/5] Refreshing AWS credentials..." -ForegroundColor Yellow
isengardcli creds bllecoq@amazon.com --role Admin

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to refresh credentials" -ForegroundColor Red
    exit 1
}

# Step 2: Install CDK dependencies
Write-Host "`n[2/6] Installing CDK dependencies..." -ForegroundColor Yellow
if (-not (Test-Path "cdk/node_modules")) {
    Push-Location cdk
    npm install
    Pop-Location
}

# Step 3: Install frontend dependencies
Write-Host "`n[3/6] Installing frontend dependencies..." -ForegroundColor Yellow
Push-Location frontend
# Commented out to save time during development - uncomment for clean builds
# if (Test-Path "node_modules") {
#     Write-Host "Removing existing node_modules..." -ForegroundColor Gray
#     Remove-Item -Recurse -Force "node_modules"
# }
npm install
Pop-Location

# Step 4: Deploy infrastructure stack
Write-Host "`n[4/6] Deploying infrastructure stack..." -ForegroundColor Yellow
Push-Location cdk
npx cdk deploy AgentCoreInfra --no-cli-pager --require-approval never
Pop-Location

if ($LASTEXITCODE -ne 0) {
    Write-Host "Infrastructure deployment failed" -ForegroundColor Red
    exit 1
}

# Step 5: Create placeholder dist for initial deployment
Write-Host "`n[5/6] Creating placeholder frontend build..." -ForegroundColor Yellow
if (-not (Test-Path "frontend/dist")) {
    New-Item -ItemType Directory -Path "frontend/dist" -Force | Out-Null
    echo "<!DOCTYPE html><html><body><h1>Building...</h1></body></html>" > frontend/dist/index.html
}

# Step 6: Deploy backend stack (triggers build and waits via Lambda)
Write-Host "`n[6/6] Deploying AgentCore backend stack..." -ForegroundColor Yellow
Write-Host "Note: CodeBuild will run and Lambda will wait for completion (5-10 minutes)" -ForegroundColor Gray
Write-Host "The stack deployment will pause while the Docker image builds..." -ForegroundColor Gray
Push-Location cdk
npx cdk deploy AgentCoreRuntime --no-cli-pager --require-approval never
Pop-Location

if ($LASTEXITCODE -ne 0) {
    Write-Host "Backend deployment failed" -ForegroundColor Red
    exit 1
}

# Step 7: Get API URL and build/deploy frontend
Write-Host "`n[7/7] Building and deploying frontend..." -ForegroundColor Yellow
$apiUrl = aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" --output text --no-cli-pager

if ([string]::IsNullOrEmpty($apiUrl)) {
    Write-Host "Failed to get API URL from stack outputs" -ForegroundColor Red
    exit 1
}

Write-Host "API URL: $apiUrl" -ForegroundColor Green

# Build frontend with API URL
& .\scripts\build-frontend.ps1 -ApiUrl $apiUrl

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
