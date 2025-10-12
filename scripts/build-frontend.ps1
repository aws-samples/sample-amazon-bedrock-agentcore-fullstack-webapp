param(
    [Parameter(Mandatory=$true)]
    [string]$ApiUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$UserPoolId,
    
    [Parameter(Mandatory=$true)]
    [string]$UserPoolClientId
)

Write-Host "Building frontend with:"
Write-Host "  API URL: $ApiUrl"
Write-Host "  User Pool ID: $UserPoolId"
Write-Host "  User Pool Client ID: $UserPoolClientId"

# Set environment variables for build
$env:VITE_API_URL = $ApiUrl
$env:VITE_USER_POOL_ID = $UserPoolId
$env:VITE_USER_POOL_CLIENT_ID = $UserPoolClientId
$env:VITE_AWS_REGION = "us-east-1"

# Build frontend
Set-Location frontend
npm run build

# Replace placeholder in built files
$indexPath = "dist/index.html"
if (Test-Path $indexPath) {
    $content = Get-Content $indexPath -Raw
    $content = $content -replace '__API_URL__', $ApiUrl
    Set-Content $indexPath $content
    Write-Host "Updated API URL in built files"
}

Set-Location ..
Write-Host "Frontend build complete"
