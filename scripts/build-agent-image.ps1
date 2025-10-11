# Build and push agent Docker image using CodeBuild

param(
    [string]$StackName = "StrandsClaudeAgentInfra"
)

Write-Host "=== Building Agent Docker Image ===" -ForegroundColor Cyan

# Get stack outputs
Write-Host "`n[1/4] Getting stack outputs..." -ForegroundColor Yellow
$sourceBucket = aws cloudformation describe-stacks --stack-name $StackName --query "Stacks[0].Outputs[?OutputKey=='SourceBucketName'].OutputValue" --output text --no-cli-pager
$buildProject = aws cloudformation describe-stacks --stack-name $StackName --query "Stacks[0].Outputs[?OutputKey=='BuildProjectName'].OutputValue" --output text --no-cli-pager

if ([string]::IsNullOrEmpty($sourceBucket) -or [string]::IsNullOrEmpty($buildProject)) {
    Write-Host "Failed to get stack outputs. Deploy infra stack first." -ForegroundColor Red
    exit 1
}

Write-Host "Source Bucket: $sourceBucket" -ForegroundColor Green
Write-Host "Build Project: $buildProject" -ForegroundColor Green

# Create source archive
Write-Host "`n[2/4] Creating source archive..." -ForegroundColor Yellow
$tempZip = "source.zip"
if (Test-Path $tempZip) {
    Remove-Item $tempZip
}

# Zip source files (Dockerfile, requirements.txt, strands_claude.py)
Compress-Archive -Path Dockerfile,requirements.txt,strands_claude.py -DestinationPath $tempZip

# Upload to S3
Write-Host "`n[3/4] Uploading source to S3..." -ForegroundColor Yellow
aws s3 cp $tempZip s3://$sourceBucket/source.zip --no-cli-pager

# Clean up local zip
Remove-Item $tempZip

# Trigger CodeBuild
Write-Host "`n[4/4] Starting CodeBuild..." -ForegroundColor Yellow
$buildId = aws codebuild start-build --project-name $buildProject --query "build.id" --output text --no-cli-pager

Write-Host "Build started: $buildId" -ForegroundColor Green
Write-Host "`nMonitoring build progress..." -ForegroundColor Yellow

# Wait for build to complete
$status = "IN_PROGRESS"
while ($status -eq "IN_PROGRESS") {
    Start-Sleep -Seconds 10
    $status = aws codebuild batch-get-builds --ids $buildId --query "builds[0].buildStatus" --output text --no-cli-pager
    Write-Host "Build status: $status" -ForegroundColor Cyan
}

if ($status -eq "SUCCEEDED") {
    Write-Host "`n✅ Docker image built and pushed successfully!" -ForegroundColor Green
} else {
    Write-Host "`n❌ Build failed with status: $status" -ForegroundColor Red
    Write-Host "Check logs: aws logs tail /aws/codebuild/$buildProject --follow" -ForegroundColor Yellow
    exit 1
}
