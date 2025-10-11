# Quick Start Guide

Deploy your AgentCore demo to AWS in one command!

## Prerequisites

- AWS CLI configured
- Node.js 22+ installed
- AWS credentials with admin access
- **No Docker required!** (CodeBuild handles container builds)

## One-Command Deploy

```powershell
.\deploy-all.ps1
```

This automatically:
1. ✅ Refreshes AWS credentials
2. ✅ Deploys infrastructure (ECR, IAM, CodeBuild, S3)
3. ✅ Builds ARM64 Docker image via CodeBuild
4. ✅ Deploys AgentCore backend (Runtime + API Gateway + Lambda)
5. ✅ Builds and deploys frontend (S3 + CloudFront)

**Done!** Your app is live at the CloudFront URL shown in the output.

## What Gets Deployed

| Stack Name | Purpose | Deployed Assets & Source Files |
|------------|---------|--------------------------------|
| **StrandsClaudeAgentInfra** | Infrastructure foundation | • ECR Repository (stores container images)<br>• IAM Execution Role (AgentCore permissions)<br>• CodeBuild Project (ARM64 builder)<br>• S3 Source Bucket (build artifacts) |
| **StrandsClaudeAgentStack** | Backend runtime & API | • AgentCore Runtime (from `Dockerfile`, `strands_claude.py`, `requirements.txt`)<br>• Lambda Function (`lambda/invoke-agent/index.ts`)<br>• API Gateway REST API with CORS |
| **AgentCoreFrontendStack** | Web UI | • S3 Bucket (static hosting)<br>• CloudFront Distribution (HTTPS CDN)<br>• React App (`frontend/src/App.tsx`, `frontend/src/main.tsx`) |

## Test Your App

1. Open the CloudFront URL from deployment output
2. Enter a prompt: "What is 42 + 58?"
3. Click "Invoke Agent"
4. See the response!

## Manual Deployment (Step-by-Step)

If you prefer to deploy step-by-step:

### Step 1: Deploy Infrastructure

```powershell
isengardcli creds bllecoq@amazon.com --role Admin
npx cdk deploy StrandsClaudeAgentInfra --no-cli-pager
```

### Step 2: Build Agent Image

```powershell
.\scripts\build-agent-image.ps1
```

This triggers CodeBuild to:
- Build ARM64 Docker image
- Push to ECR with `:latest` tag
- Takes ~3-5 minutes

### Step 3: Deploy Backend

```powershell
npx cdk deploy StrandsClaudeAgentStack --no-cli-pager
```

### Step 4: Deploy Frontend

```powershell
$apiUrl = aws cloudformation describe-stacks --stack-name StrandsClaudeAgentStack --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" --output text --no-cli-pager
.\scripts\build-frontend.ps1 -ApiUrl $apiUrl
npx cdk deploy AgentCoreFrontendStack --no-cli-pager
```

## Updating the Agent

To modify the agent code:

1. Edit `strands_claude.py` or `requirements.txt`
2. Rebuild image: `.\scripts\build-agent-image.ps1`
3. Update runtime: `npx cdk deploy StrandsClaudeAgentStack --no-cli-pager`

AgentCore automatically creates a new version (V2, V3, etc.) when the container changes.

## Architecture Overview

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │ HTTPS
       ▼
┌─────────────────┐
│   CloudFront    │
└──────┬──────────┘
       │
       ▼
┌─────────────────┐
│   React App     │
│   (S3 Bucket)   │
└──────┬──────────┘
       │ POST /invoke
       ▼
┌─────────────────┐
│  API Gateway    │
└──────┬──────────┘
       │
       ▼
┌─────────────────┐
│  Lambda         │
│  (Node.js 22)   │
└──────┬──────────┘
       │ InvokeAgentRuntime
       ▼
┌─────────────────┐
│ AgentCore       │
│ Runtime         │
│ (ARM64 Docker)  │
└─────────────────┘
```

## Key Features

### No Local Docker Required
CodeBuild handles all container builds in AWS with native ARM64 support.

### Automatic Versioning
Each deployment creates a new immutable version. The DEFAULT endpoint auto-updates to the latest.

### Serverless & Scalable
AgentCore Runtime scales automatically based on demand. Pay only for what you use.

### Built-in Observability
- CloudWatch Logs: `/aws/bedrock-agentcore/runtimes/strands_agent-*`
- X-Ray Tracing: Distributed tracing enabled
- CloudWatch Metrics: Custom metrics in `bedrock-agentcore` namespace

### Security
- IAM-based authentication
- Isolated microVM execution
- HTTPS everywhere
- Least privilege IAM roles

## Troubleshooting

### "Access Denied"
```powershell
isengardcli creds bllecoq@amazon.com --role Admin
```

### "Container failed to start"
Check CloudWatch logs:
```powershell
aws logs tail /aws/bedrock-agentcore/runtimes/strands_agent-* --follow --no-cli-pager
```

### "Image not found in ECR"
Build the image first:
```powershell
.\scripts\build-agent-image.ps1
```

### CodeBuild fails
Check build logs:
```powershell
aws logs tail /aws/codebuild/bedrock-agentcore-strands-agent-builder --follow --no-cli-pager
```

### Frontend shows old API URL
Rebuild and redeploy:
```powershell
.\deploy-all.ps1
```

## Cleanup

Remove all resources:

```powershell
npx cdk destroy AgentCoreFrontendStack --no-cli-pager
npx cdk destroy StrandsClaudeAgentStack --no-cli-pager
npx cdk destroy StrandsClaudeAgentInfra --no-cli-pager
```

## Next Steps

- **Modify Agent**: Edit `strands_claude.py` to add custom tools
- **Change Model**: Update `model_id` in `strands_claude.py`
- **Add Memory**: Integrate AgentCore Memory for persistent context
- **Custom Domain**: Add Route53 and ACM certificate to frontend stack
- **Monitoring**: Set up CloudWatch alarms for errors and latency

## Cost Estimate

Approximate monthly costs (us-east-1):
- **AgentCore Runtime**: $0.10 per hour active + $0.000008 per request
- **Lambda**: Free tier covers most demos
- **API Gateway**: $3.50 per million requests
- **CloudFront**: $0.085 per GB + $0.01 per 10,000 requests
- **S3**: Negligible for static hosting
- **ECR**: $0.10 per GB-month
- **CodeBuild**: $0.005 per build minute (ARM64)

**Typical demo cost**: < $5/month with light usage

## Support

- [AgentCore Documentation](https://docs.aws.amazon.com/bedrock-agentcore/)
- [Strands Agents Documentation](https://strandsagents.com/)
- [CDK API Reference](https://docs.aws.amazon.com/cdk/api/v2/)
