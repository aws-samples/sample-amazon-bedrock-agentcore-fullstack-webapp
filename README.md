# AgentCore Demo

React app demonstrating how to deploy and invoke AWS Bedrock AgentCore agents using CDK.

## Architecture

```
React Frontend (CloudFront/S3) → API Gateway → Lambda → AgentCore Runtime (Container)
```

## Stack Architecture

| Stack Name | Purpose | Key Resources |
|------------|---------|---------------|
| **AgentCoreInfra** | Container build infrastructure | ECR Repository, CodeBuild Project, IAM Roles, S3 Bucket |
| **AgentCoreRuntime** | Agent runtime & API | AgentCore Runtime, Lambda Function, API Gateway |
| **AgentCoreFrontend** | Web interface | S3 Bucket, CloudFront Distribution |

## Project Structure

```
├── agent/                      # Agent runtime code
│   ├── strands_agent.py       # Agent implementation
│   ├── requirements.txt       # Python dependencies
│   └── Dockerfile             # Container definition
├── cdk/                        # Infrastructure as Code
│   ├── bin/app.ts             # CDK app entry point
│   └── lib/
│       ├── infra-stack.ts     # Build infrastructure
│       ├── runtime-stack.ts   # AgentCore runtime + API
│       └── frontend-stack.ts  # CloudFront + S3
├── lambda/invoke-agent/        # Lambda function
│   └── index.ts               # Agent invocation handler
├── frontend/                   # React app (Vite)
│   └── src/
│       ├── App.tsx            # Main UI component
│       └── main.tsx           # React entry point
├── scripts/
│   └── build-frontend.ps1     # Builds frontend with API URL
└── deploy-all.ps1             # One-command deployment
```

## Quick Deploy

```powershell
.\deploy-all.ps1
```

This automatically:
1. ✅ Refreshes AWS credentials
2. ✅ Deploys infrastructure (ECR, CodeBuild, IAM, S3)
3. ✅ Deploys runtime stack (triggers CodeBuild, waits for completion, creates AgentCore runtime)
4. ✅ Builds and deploys frontend to CloudFront

**Done!** Your app is live at the CloudFront URL shown in the output.

## How It Works

### Deployment Flow

1. **Infrastructure Stack** creates build pipeline resources
2. **Runtime Stack** uploads agent code, triggers CodeBuild, and waits via Lambda Custom Resource
3. **CodeBuild** builds ARM64 container image and pushes to ECR (~5-10 minutes)
4. **AgentCore Runtime** is created using the built image
5. **Frontend Stack** deploys React app to CloudFront

### Request Flow

1. User enters prompt in React UI
2. Frontend sends POST to API Gateway `/invoke`
3. Lambda invokes AgentCore Runtime
4. AgentCore executes agent in isolated container
5. Agent processes request using Strands framework + Claude 3.5 Sonnet
6. Response returned through Lambda to frontend

## Key Components

### Agent (`agent/strands_agent.py`)
- Built with Strands Agents framework
- Uses Claude 3.5 Sonnet model
- Includes calculator and weather tools
- Wrapped with BedrockAgentCoreApp decorator

### Container Build
- ARM64 architecture (native AgentCore support)
- Python 3.13 slim base image
- Built via CodeBuild (no local Docker required)
- Automatic build on deployment

### Lambda Waiter
- Custom Resource that waits for CodeBuild completion
- Polls every 30 seconds, 15-minute timeout
- Returns minimal response to CloudFormation (<4KB)
- Ensures image exists before AgentCore runtime creation

### IAM Permissions
The execution role includes:
- Bedrock model invocation
- ECR image access
- CloudWatch Logs & Metrics
- X-Ray tracing
- AgentCore Identity (workload access tokens)

## Manual Deployment

### Deploy Infrastructure
```powershell
cd cdk
npx cdk deploy AgentCoreInfra --no-cli-pager
```

### Deploy Runtime (triggers build automatically)
```powershell
cd cdk
npx cdk deploy AgentCoreRuntime --no-cli-pager
```
*Note: This will pause for 5-10 minutes while CodeBuild runs*

### Deploy Frontend
```powershell
$apiUrl = aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" --output text --no-cli-pager
.\scripts\build-frontend.ps1 -ApiUrl $apiUrl
cd cdk
npx cdk deploy AgentCoreFrontend --no-cli-pager
```

## Updating the Agent

1. Modify `agent/strands_agent.py` or `agent/requirements.txt`
2. Redeploy runtime stack:
   ```powershell
   cd cdk
   npx cdk deploy AgentCoreRuntime --no-cli-pager
   ```

The stack will automatically rebuild the container and update the runtime.

## Cleanup

```powershell
cd cdk
npx cdk destroy AgentCoreFrontend --no-cli-pager
npx cdk destroy AgentCoreRuntime --no-cli-pager
npx cdk destroy AgentCoreInfra --no-cli-pager
```

## Troubleshooting

### "Access Denied"
Refresh credentials: `isengardcli creds bllecoq@amazon.com --role Admin`

### "Container failed to start"
Check CloudWatch logs: `/aws/bedrock-agentcore/runtimes/strands_agent-*`

### "Image not found in ECR"
Redeploy runtime stack - it will trigger a new build

### CodeBuild fails
Check logs: `aws logs tail /aws/codebuild/bedrock-agentcore-strands-agent-builder --follow`

## Architecture Details

### Why Lambda Waiter?
CloudFormation Custom Resources have a 4KB response limit. CodeBuild's `batchGetBuilds` response exceeds this. The Lambda waiter polls CodeBuild internally and returns only success/failure to CloudFormation.

### Why CodeBuild?
- Native ARM64 build environment (no emulation)
- Consistent builds across team members
- No local Docker Desktop required
- Build history and logs in AWS Console

### Why Three Stacks?
- **Infra**: Rarely changes, contains build pipeline
- **Runtime**: Changes when agent code updates
- **Frontend**: Changes when UI updates

This separation allows independent updates without rebuilding everything.

## Security

- Frontend served via HTTPS (CloudFront)
- AWS credentials never exposed to browser
- CORS configured for API Gateway
- Lambda has minimal IAM permissions
- AgentCore Runtime runs in isolated microVMs
- Container images scanned by ECR

## Documentation

See [STRUCTURE.md](STRUCTURE.md) for detailed project organization.
