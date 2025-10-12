# AgentCore Demo

Full-stack AWS Bedrock AgentCore demo application with automated deployment. Deploy a containerized AI agent with web interface in one command.

## Quick Start

### Prerequisites
- AWS CLI configured
- Node.js 22+ installed
- AWS credentials with admin access
- **No Docker required!** (CodeBuild handles container builds)

### One-Command Deploy

```powershell
.\deploy-all.ps1
```

**Time:** ~15 minutes (most time is CodeBuild creating the container image)

**Done!** Your app is live at the CloudFront URL shown in the output.

### Test Your App

1. Open the CloudFront URL from deployment output
2. Enter a prompt: "What is 42 + 58?"
3. Click "Invoke Agent"
4. See the response from Claude 3.5 Sonnet!

Try these prompts:
- "What's the weather like today?"
- "Calculate 123 * 456"
- "What is 2 to the power of 10?"

## Architecture

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
│  (Invoker)      │
└──────┬──────────┘
       │ InvokeAgentRuntime
       ▼
┌─────────────────┐
│ AgentCore       │
│ Runtime         │
│ (ARM64 Docker)  │
│ Bedrock LLM     │
└─────────────────┘
```

## Stack Architecture

| Stack Name | Purpose | Key Resources |
|------------|---------|---------------|
| **AgentCoreInfra** | Build infrastructure | ECR Repository, CodeBuild Project, IAM Roles, S3 Bucket |
| **AgentCoreRuntime** | Agent runtime & API | AgentCore Runtime, Lambda Waiter, Lambda Invoker, API Gateway |
| **AgentCoreFrontend** | Web UI | S3 Bucket, CloudFront Distribution |

## Project Structure

```
project-root/
├── agent/                      # Agent runtime code
│   ├── strands_agent.py       # Agent implementation (Strands framework)
│   ├── requirements.txt       # Python dependencies
│   ├── Dockerfile             # ARM64 container definition
│   └── .dockerignore          # Docker ignore patterns
│
├── cdk/                        # Infrastructure as Code
│   ├── bin/
│   │   └── app.ts             # CDK app entry point
│   ├── lib/
│   │   ├── infra-stack.ts     # Build infrastructure (ECR, IAM, CodeBuild)
│   │   ├── runtime-stack.ts   # AgentCore runtime + API
│   │   └── frontend-stack.ts  # CloudFront + S3
│   ├── cdk.json               # CDK configuration
│   ├── tsconfig.json          # TypeScript configuration
│   └── package.json           # CDK dependencies
│
├── lambda/                     # Lambda functions
│   └── invoke-agent/
│       └── index.ts           # Agent invocation handler
│
├── frontend/                   # React app (Vite)
│   ├── src/
│   │   ├── App.tsx            # Main UI component
│   │   └── main.tsx           # React entry point
│   ├── dist/                  # Build output (gitignored)
│   └── package.json           # Frontend dependencies
│
├── scripts/
│   └── build-frontend.ps1     # Builds React app with API URL injection
│
├── deploy-all.ps1             # Main deployment orchestration
└── README.md                  # This file
```

## How It Works

### Deployment Flow

The `deploy-all.ps1` script orchestrates the complete deployment:

1. **Refresh AWS credentials** using isengardcli
2. **Install CDK dependencies** (cdk/node_modules)
3. **Install frontend dependencies** (frontend/node_modules)
4. **Deploy AgentCoreInfra** - Creates build pipeline resources:
   - ECR repository for agent container images
   - IAM role for AgentCore runtime
   - S3 bucket for CodeBuild sources
   - CodeBuild project for ARM64 builds
5. **Create placeholder frontend build** (for initial deployment)
6. **Deploy AgentCoreRuntime** - Deploys agent and API:
   - Uploads agent source code to S3
   - Triggers CodeBuild via Custom Resource
   - **Lambda waiter polls CodeBuild** (5-10 minutes)
   - Creates AgentCore runtime with built image
   - Creates Lambda invoker function
   - Creates API Gateway with CORS
7. **Build frontend with API URL** (from runtime stack outputs)
8. **Deploy AgentCoreFrontend** - Deploys web interface:
   - S3 bucket for static hosting
   - CloudFront distribution with OAC
   - Deploys React app from frontend/dist

### Request Flow

1. User enters prompt in React UI
2. Frontend sends POST to API Gateway `/invoke`
3. Lambda invokes AgentCore Runtime
4. AgentCore executes agent in isolated container (microVM)
5. Agent processes request using Strands framework + Claude 3.5 Sonnet
6. Response returned through Lambda to frontend

## Key Components

### 1. Agent (`agent/strands_agent.py`)
- Built with Strands Agents framework
- Uses Claude 3.5 Sonnet model (`us.anthropic.claude-3-5-sonnet-20241022-v2:0`)
- Includes calculator and weather tools
- Wrapped with `@BedrockAgentCoreApp` decorator

### 2. Container Build
- ARM64 architecture (native AgentCore support)
- Python 3.13 slim base image
- Built via CodeBuild (no local Docker required)
- Automatic build on deployment
- Build history and logs in AWS Console

### 3. Lambda Waiter (Critical Component)
- Custom Resource that waits for CodeBuild completion
- Polls every 30 seconds, 15-minute timeout
- Returns minimal response to CloudFormation (<4KB)
- Ensures image exists before AgentCore runtime creation
- **Why needed:** CodeBuild's `batchGetBuilds` response exceeds CloudFormation's 4KB Custom Resource limit

### 4. IAM Permissions
The execution role includes:
- Bedrock model invocation
- ECR image access
- CloudWatch Logs & Metrics
- X-Ray tracing
- AgentCore Identity (workload access tokens)

### 5. Built-in Observability
- **CloudWatch Logs:** `/aws/bedrock-agentcore/runtimes/strands_agent-*`
- **X-Ray Tracing:** Distributed tracing enabled
- **CloudWatch Metrics:** Custom metrics in `bedrock-agentcore` namespace
- **CodeBuild Logs:** `/aws/codebuild/bedrock-agentcore-strands-agent-builder`

## Manual Deployment

If you prefer to deploy stacks individually:

### 1. Deploy Infrastructure
```powershell
cd cdk
npx cdk deploy AgentCoreInfra --no-cli-pager
```

### 2. Deploy Runtime (triggers build automatically)
```powershell
cd cdk
npx cdk deploy AgentCoreRuntime --no-cli-pager
```
*Note: This will pause for 5-10 minutes while CodeBuild runs*

### 3. Deploy Frontend
```powershell
$apiUrl = aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" --output text --no-cli-pager
.\scripts\build-frontend.ps1 -ApiUrl $apiUrl
cd cdk
npx cdk deploy AgentCoreFrontend --no-cli-pager
```

## Updating the Agent

To modify the agent code:

1. Edit `agent/strands_agent.py` or `agent/requirements.txt`
2. Redeploy runtime stack:
   ```powershell
   cd cdk
   npx cdk deploy AgentCoreRuntime --no-cli-pager
   ```

The deployment will:
- Upload new agent code to S3
- Trigger CodeBuild to rebuild container
- Wait for build completion
- Update AgentCore runtime with new image

## Cleanup

```powershell
cd cdk
npx cdk destroy AgentCoreFrontend --no-cli-pager
npx cdk destroy AgentCoreRuntime --no-cli-pager
npx cdk destroy AgentCoreInfra --no-cli-pager
```

## Troubleshooting

### "Access Denied"
Refresh AWS credentials:
```powershell
isengardcli creds bllecoq@amazon.com --role Admin
```

### "Container failed to start"
Check CloudWatch logs:
```powershell
aws logs tail /aws/bedrock-agentcore/runtimes/strands_agent-* --follow --no-cli-pager
```

### "Image not found in ECR"
Redeploy runtime stack - it will trigger a new build:
```powershell
cd cdk
npx cdk deploy AgentCoreRuntime --no-cli-pager
```

### "Build timeout after 15 minutes"
Check CodeBuild console for build status. If build is still running, wait for completion and redeploy runtime stack.

### CodeBuild fails
Check build logs:
```powershell
aws logs tail /aws/codebuild/bedrock-agentcore-strands-agent-builder --follow --no-cli-pager
```

### Frontend shows errors
Verify API URL is correct:
```powershell
aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" --output text --no-cli-pager
```

### Verify deployment status
Check all stack statuses:
```powershell
aws cloudformation describe-stacks --stack-name AgentCoreInfra --query "Stacks[0].StackStatus" --no-cli-pager
aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].StackStatus" --no-cli-pager
aws cloudformation describe-stacks --stack-name AgentCoreFrontend --query "Stacks[0].StackStatus" --no-cli-pager
```

## Architecture Details

### Why Lambda Waiter?
CloudFormation Custom Resources have a 4KB response limit. CodeBuild's `batchGetBuilds` response exceeds this. The Lambda waiter polls CodeBuild internally and returns only success/failure to CloudFormation.

### Why CodeBuild?
- Native ARM64 build environment (no emulation)
- Consistent builds across team members
- No local Docker Desktop required
- Build history and logs in AWS Console
- Automatic image push to ECR

### Why Three Stacks?
- **AgentCoreInfra**: Rarely changes, contains build pipeline
- **AgentCoreRuntime**: Changes when agent code updates
- **AgentCoreFrontend**: Changes when UI updates

This separation allows independent updates without rebuilding everything.

### Why ARM64?
AgentCore natively supports ARM64 architecture, providing better performance and cost efficiency compared to x86_64.

## Security

- Frontend served via HTTPS (CloudFront)
- AWS credentials never exposed to browser
- CORS configured for API Gateway
- Lambda has minimal IAM permissions
- AgentCore Runtime runs in isolated microVMs
- Container images scanned by ECR
- Origin Access Control (OAC) for S3/CloudFront

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

## Next Steps

- **Change Model**: Edit `model_id` in `agent/strands_agent.py` (try different Claude versions or Nova models)
- **Add Tools**: Create custom `@tool` functions in the agent
- **Add Memory**: Integrate AgentCore Memory for persistent context
- **Custom Domain**: Add Route53 and ACM certificate to frontend stack
- **Monitoring**: Set up CloudWatch alarms for errors and latency
- **Streaming**: Implement streaming responses for better UX
- **Authentication**: Add Cognito for user authentication

## Resources

- [AgentCore Documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-agentcore.html)
- [Strands Agents Documentation](https://github.com/awslabs/strands)
- [CDK API Reference](https://docs.aws.amazon.com/cdk/api/v2/)
- [Bedrock Model IDs](https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids.html)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Support

For issues and questions:
- Check the troubleshooting section
- Review AWS Bedrock documentation
- Open an issue in the repository
## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.