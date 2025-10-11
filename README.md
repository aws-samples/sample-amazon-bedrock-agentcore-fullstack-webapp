# AgentCore Demo

React app demonstrating how to invoke AWS Bedrock AgentCore agents using CDK deployment.

## Architecture

```
React Frontend (CloudFront/S3) → API Gateway → Lambda → AgentCore Runtime
```

## Stack Architecture

| Stack Name | Purpose | Deployed Assets & Source Files |
|------------|---------|--------------------------------|
| **StrandsClaudeAgentInfra** | Infrastructure foundation | • ECR Repository<br>• IAM Execution Role<br>• CodeBuild Project<br>• S3 Source Bucket |
| **StrandsClaudeAgentStack** | Backend runtime & API | • AgentCore Runtime (from `Dockerfile`, `strands_claude.py`, `requirements.txt`)<br>• Lambda Function (`lambda/invoke-agent/index.ts`)<br>• API Gateway REST API |
| **AgentCoreFrontendStack** | Web UI | • S3 Bucket<br>• CloudFront Distribution<br>• React App (`frontend/src/App.tsx`, `frontend/src/main.tsx`) |

## Project Structure

```
├── agentcore-infra-stack.ts    # Infrastructure (ECR, IAM, CodeBuild, S3)
├── agentcore-stack.ts          # Runtime + API Gateway + Lambda
├── lib/frontend-stack.ts       # Frontend (S3 + CloudFront)
├── lambda/invoke-agent/        # Lambda function
│   └── index.ts                # Agent invocation handler
├── frontend/                   # React app (Vite)
│   └── src/
│       ├── App.tsx             # Main UI component
│       └── main.tsx            # React entry point
├── scripts/
│   ├── build-agent-image.ps1   # Triggers CodeBuild to build Docker image
│   └── build-frontend.ps1      # Builds frontend with API URL
├── deploy-all.ps1              # One-command deployment
├── Dockerfile                  # Agent container definition
├── strands_claude.py           # Agent code (Strands framework)
└── requirements.txt            # Python dependencies
```

## Quick Deploy

```powershell
.\deploy-all.ps1
```

This automatically:
1. Refreshes AWS credentials
2. Deploys infrastructure (ECR, IAM roles, CodeBuild, S3)
3. Builds ARM64 Docker image via CodeBuild
4. Deploys AgentCore runtime + API Gateway + Lambda
5. Builds and deploys frontend to CloudFront

**Done!** Your app is live at the CloudFront URL shown in the output.

## Manual Deployment

### 1. Deploy Infrastructure

```powershell
# Refresh credentials
isengardcli creds bllecoq@amazon.com --role Admin

# Deploy infrastructure stack
npx cdk deploy StrandsClaudeAgentInfra --no-cli-pager
```

This creates:
- ECR repository for agent container
- IAM execution role with full AgentCore permissions
- CodeBuild project for building ARM64 images
- S3 bucket for CodeBuild source

### 2. Build Agent Docker Image

```powershell
.\scripts\build-agent-image.ps1
```

This:
- Zips source files (Dockerfile, requirements.txt, strands_claude.py)
- Uploads to S3
- Triggers CodeBuild to build ARM64 image
- Pushes to ECR with `:latest` tag

### 3. Deploy Backend

```powershell
npx cdk deploy StrandsClaudeAgentStack --no-cli-pager
```

This creates:
- AgentCore Runtime (pulls image from ECR)
- Lambda function for invocation
- API Gateway with CORS

### 4. Build & Deploy Frontend

```powershell
# Get API URL
$apiUrl = aws cloudformation describe-stacks --stack-name StrandsClaudeAgentStack --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" --output text --no-cli-pager

# Build frontend
.\scripts\build-frontend.ps1 -ApiUrl $apiUrl

# Deploy frontend
npx cdk deploy AgentCoreFrontendStack --no-cli-pager
```

## How It Works

1. **User enters prompt** in React UI (CloudFront)
2. **Frontend sends POST** to API Gateway `/invoke` endpoint
3. **Lambda generates session ID** and invokes AgentCore Runtime
4. **AgentCore Runtime** executes agent in isolated container
5. **Agent processes request** using Strands framework + Claude 3.7 Sonnet
6. **Response returned** through Lambda to frontend

## Key Components

### Agent Code (`strands_claude.py`)
- Built with Strands Agents framework
- Uses Claude 3.7 Sonnet model
- Includes calculator and weather tools
- Wrapped with BedrockAgentCoreApp decorator

### Docker Image
- Built on ARM64 architecture (native AgentCore support)
- Python 3.13 slim base image
- Includes OpenTelemetry instrumentation
- Exposes port 8080 for HTTP protocol

### IAM Permissions
The execution role includes:
- Bedrock model invocation
- ECR image access
- CloudWatch Logs
- X-Ray tracing
- CloudWatch metrics
- AgentCore Identity (workload access tokens)

### CodeBuild
- Uses ARM64 build environment
- Builds Docker image natively (no emulation)
- Pushes to ECR automatically
- Triggered via PowerShell script

## Local Development

To test the agent locally before deploying:

```powershell
# Install dependencies
pip install -r requirements.txt

# Run locally (requires agentcore CLI)
agentcore launch --local
```

## Updating the Agent

1. Modify `strands_claude.py` or `requirements.txt`
2. Run `.\scripts\build-agent-image.ps1` to rebuild
3. Run `npx cdk deploy StrandsClaudeAgentStack --no-cli-pager` to update runtime

AgentCore automatically creates a new version when the container changes.

## Cleanup

Remove all resources:

```powershell
npx cdk destroy AgentCoreFrontendStack --no-cli-pager
npx cdk destroy StrandsClaudeAgentStack --no-cli-pager
npx cdk destroy StrandsClaudeAgentInfra --no-cli-pager
```

## Troubleshooting

### "Access Denied"
Refresh credentials: `isengardcli creds bllecoq@amazon.com --role Admin`

### "Container failed to start"
Check CloudWatch logs: `/aws/bedrock-agentcore/runtimes/strands_agent-*`

### "Image not found in ECR"
Run `.\scripts\build-agent-image.ps1` to build and push the image

### CodeBuild fails
Check logs: `aws logs tail /aws/codebuild/bedrock-agentcore-strands-agent-builder --follow`

## Security

- Frontend served via HTTPS (CloudFront)
- AWS credentials never exposed to browser
- CORS configured for API Gateway
- Lambda has minimal IAM permissions
- AgentCore Runtime runs in isolated microVMs
- IAM role follows principle of least privilege
