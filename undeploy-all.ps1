# Create placeholder dist directory
if (-not (Test-Path "frontend/dist")) {
    Write-Host "Creating placeholder frontend/dist directory for CDK synthesis..."
    New-Item -ItemType Directory -Path "frontend/dist" -Force | Out-Null
    echo "<!DOCTYPE html><html><body><h1>Destroying...</h1></body></html>" > frontend/dist/index.html

    Write-Host "Installing CDK dependencies..."
    Push-Location cdk
    npm install
    Pop-Location
}

Set-Location cdk
npx cdk destroy AgentCoreFrontend --force
npx cdk destroy AgentCoreApi --force
npx cdk destroy AgentCoreRuntime --force
npx cdk destroy AgentCoreAuth --force
npx cdk destroy AgentCoreInfra --force
