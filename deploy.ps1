# Deployment script for Strands Claude Agent to Bedrock AgentCore
# This script builds the container, pushes to ECR, and deploys the CDK stack

param(
    [string]$Region = "us-east-1",
    [string]$StackName = "StrandsClaudeAgentStack"
)

Write-Host "Starting deployment of Strands Claude Agent to Bedrock AgentCore..." -ForegroundColor Green

# Step 1: Deploy CDK stack to create ECR repository
Write-Host "`n[1/5] Deploying CDK stack to create infrastructure..." -ForegroundColor Cyan
npx cdk deploy $StackName --require-approval never --region $Region

if ($LASTEXITCODE -ne 0) {
    Write-Host "CDK deployment failed!" -ForegroundColor Red
    exit 1
}

# Step 2: Get ECR repository URI from stack outputs
Write-Host "`n[2/5] Getting ECR repository URI..." -ForegroundColor Cyan
$RepositoryUri = aws cloudformation describe-stacks `
    --stack-name $StackName `
    --region $Region `
    --query "Stacks[0].Outputs[?OutputKey=='RepositoryUri'].OutputValue" `
    --output text --no-cli-pager

if ([string]::IsNullOrEmpty($RepositoryUri)) {
    Write-Host "Failed to get repository URI!" -ForegroundColor Red
    exit 1
}

Write-Host "Repository URI: $RepositoryUri" -ForegroundColor Yellow

# Step 3: Login to ECR
Write-Host "`n[3/5] Logging in to ECR..." -ForegroundColor Cyan
$Account = $RepositoryUri.Split('.')[0]
aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin "$Account.dkr.ecr.$Region.amazonaws.com"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ECR login failed!" -ForegroundColor Red
    exit 1
}

# Step 4: Build and push Docker image
Write-Host "`n[4/5] Building Docker image..." -ForegroundColor Cyan
docker build -t strands-claude-agent .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Tagging and pushing image to ECR..." -ForegroundColor Cyan
docker tag strands-claude-agent:latest "$RepositoryUri:latest"
docker push "$RepositoryUri:latest"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker push failed!" -ForegroundColor Red
    exit 1
}

# Step 5: Update CDK stack to use the new image
Write-Host "`n[5/5] Updating AgentCore Runtime with new container..." -ForegroundColor Cyan
npx cdk deploy $StackName --require-approval never --region $Region

if ($LASTEXITCODE -ne 0) {
    Write-Host "Final CDK deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ Deployment completed successfully!" -ForegroundColor Green
Write-Host "`nTo invoke your agent, use:" -ForegroundColor Yellow
Write-Host "aws bedrock-agentcore-runtime invoke-agent --agent-runtime-id <runtime-id> --payload '{\"prompt\": \"What is 5 + 3?\"}'" -ForegroundColor White
