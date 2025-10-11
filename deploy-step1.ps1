# Step 1: Deploy ECR repository and IAM role only
# This creates the infrastructure needed before building the container

param(
    [string]$Region = "us-east-1",
    [string]$StackName = "StrandsClaudeAgentInfra"
)

Write-Host "Step 1: Deploying ECR repository and IAM role..." -ForegroundColor Green

# Deploy the infrastructure stack
npx cdk deploy $StackName --require-approval never --region $Region --no-cli-pager

if ($LASTEXITCODE -ne 0) {
    Write-Host "Infrastructure deployment failed!" -ForegroundColor Red
    exit 1
}

# Get ECR repository URI
$RepositoryUri = aws cloudformation describe-stacks `
    --stack-name $StackName `
    --region $Region `
    --query "Stacks[0].Outputs[?OutputKey=='RepositoryUri'].OutputValue" `
    --output text --no-cli-pager

Write-Host "`n✅ Infrastructure deployed successfully!" -ForegroundColor Green
Write-Host "Repository URI: $RepositoryUri" -ForegroundColor Yellow
Write-Host "`nNext: Run deploy-step2.ps1 to build and push the container" -ForegroundColor Cyan
