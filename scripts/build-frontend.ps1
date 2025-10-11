param(
    [Parameter(Mandatory=$true)]
    [string]$ApiUrl
)

Write-Host "Building frontend with API URL: $ApiUrl"

# Set environment variable for build
$env:VITE_API_URL = $ApiUrl

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
