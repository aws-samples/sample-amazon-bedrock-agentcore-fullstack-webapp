param(
    [Parameter(Mandatory=$true)]
    [string]$UserPoolId,
    
    [Parameter(Mandatory=$true)]
    [string]$UserPoolClientId,
    
    [Parameter(Mandatory=$true)]
    [string]$AgentRuntimeArn,
    
    [Parameter(Mandatory=$true)]
    [string]$IdentityPoolId,
    
    [Parameter(Mandatory=$true)]
    [string]$MemoryId,
    
    [Parameter(Mandatory=$true)]
    [string]$Region
)

Write-Host "Building frontend with:"
Write-Host "  User Pool ID: $UserPoolId"
Write-Host "  User Pool Client ID: $UserPoolClientId"
Write-Host "  Agent Runtime ARN: $AgentRuntimeArn"
Write-Host "  Identity Pool ID: $IdentityPoolId"
Write-Host "  Memory ID: $MemoryId"
Write-Host "  Region: $Region"

# Create production environment file (overrides .env.local)
Set-Location frontend

# Remove local development environment file if it exists
if (Test-Path ".env.local") {
    Write-Host "Removing local development environment file..."
    Remove-Item ".env.local"
}

# Create production environment file
@"
VITE_USER_POOL_ID=$UserPoolId
VITE_USER_POOL_CLIENT_ID=$UserPoolClientId
VITE_AGENT_RUNTIME_ARN=$AgentRuntimeArn
VITE_REGION=$Region
VITE_IDENTITY_POOL_ID=$IdentityPoolId
VITE_MEMORY_ID=$MemoryId
VITE_LOCAL_DEV=false
"@ | Out-File -FilePath ".env.production.local" -Encoding UTF8

Write-Host "Created production environment configuration"

# Build frontend
npm run build

Set-Location ..
Write-Host "Frontend build complete"
