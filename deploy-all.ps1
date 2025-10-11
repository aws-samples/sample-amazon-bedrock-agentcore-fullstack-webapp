# Deploy AgentCore Demo - Complete Deployment Script

Write-Host "=== AgentCore Demo Deployment ===" -ForegroundColor Cyan

# Step 1: Refresh AWS credentials
Write-Host "`n[1/5] Refreshing AWS credentials..." -ForegroundColor Yellow
isengardcli creds bllecoq@amazon.com --role Admin

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to refresh credentials" -ForegroundColor Red
    exit 1
}

# Step 2: Install frontend dependencies
Write-Host "`n[2/5] Installing frontend dependencies..." -ForegroundColor Yellow
# Remove existing node_modules to ensure fresh install with latest dependencies
if (Test-Path "frontend/node_modules") {
    Write-Host "Removing existing node_modules..." -ForegroundColor Gray
    Remove-Item -Recurse -Force "frontend/node_modules"
}
npm install --prefix frontend

# Step 3: Deploy infrastructure stack
Write-Host "`n[3/7] Deploying infrastructure stack..." -ForegroundColor Yellow
npx cdk deploy StrandsClaudeAgentInfra --no-cli-pager --require-approval never

if ($LASTEXITCODE -ne 0) {
    Write-Host "Infrastructure deployment failed" -ForegroundColor Red
    exit 1
}

# Step 4: Create placeholder dist for initial deployment
Write-Host "`n[4/7] Creating placeholder frontend build..." -ForegroundColor Yellow
if (-not (Test-Path "frontend/dist")) {
    New-Item -ItemType Directory -Path "frontend/dist" -Force | Out-Null
    echo "<!DOCTYPE html><html><body><h1>Building...</h1></body></html>" > frontend/dist/index.html
}

# Step 5: Build agent Docker image
Write-Host "`n[5/7] Building agent Docker image..." -ForegroundColor Yellow
& .\scripts\build-agent-image.ps1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Agent image build failed" -ForegroundColor Red
    exit 1
}

# Step 6: Deploy backend stack
Write-Host "`n[6/7] Deploying AgentCore backend stack..." -ForegroundColor Yellow
npx cdk deploy StrandsClaudeAgentStack --no-cli-pager --require-approval never

if ($LASTEXITCODE -ne 0) {
    Write-Host "Backend deployment failed" -ForegroundColor Red
    exit 1
}

# Step 7: Get API URL and build/deploy frontend
Write-Host "`n[7/7] Building and deploying frontend..." -ForegroundColor Yellow
$apiUrl = aws cloudformation describe-stacks --stack-name StrandsClaudeAgentStack --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" --output text --no-cli-pager

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
npx cdk deploy AgentCoreFrontendStack --no-cli-pager --require-approval never

if ($LASTEXITCODE -ne 0) {
    Write-Host "Frontend deployment failed" -ForegroundColor Red
    exit 1
}

# Get CloudFront URL
$websiteUrl = aws cloudformation describe-stacks --stack-name AgentCoreFrontendStack --query "Stacks[0].Outputs[?OutputKey=='WebsiteUrl'].OutputValue" --output text --no-cli-pager

Write-Host "`n=== Deployment Complete ===" -ForegroundColor Green
Write-Host "Website URL: $websiteUrl" -ForegroundColor Cyan
Write-Host "API URL: $apiUrl" -ForegroundColor Cyan
