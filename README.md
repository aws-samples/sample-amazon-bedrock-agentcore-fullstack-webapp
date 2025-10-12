# AgentCore Demo

Full-stack AWS Bedrock AgentCore demo application with automated deployment. Deploy a containerized AI agent with web interface in one command.

## Quick Start

### Prerequisites
- AWS CLI configured
- Node.js 22+ installed
- AWS credentials with admin access
- **No Docker required!** (CodeBuild handles container builds)

### One-Command Deploy

**Windows (PowerShell):**
```powershell
.\deploy-all.ps1
```

**macOS/Linux (Bash):**
```bash
chmod +x deploy-all.sh scripts/build-frontend.sh
./deploy-all.sh
```

> **Platform Notes:**
> - **Windows users**: Use the PowerShell script (primary/tested version)
> - **macOS/Linux users**: Use the bash script (cross-platform equivalent)
> - Both scripts perform identical operations and produce the same infrastructure
> - If you prefer PowerShell on macOS: `brew install --cask powershell` then run `pwsh deploy-all.ps1`

**Time:** ~15 minutes (most time is CodeBuild creating the container image)

**Done!** Your app is live at the CloudFront URL shown in the output.

### Test Your App

1. Open the CloudFront URL from deployment output
2. **Click "Sign In"** in the header
3. **Create an account:**
   - Click "Sign up"
   - Enter your email and password (min 8 chars, needs uppercase, lowercase, digit)
   - Check your email for verification code
   - Enter the code to confirm
4. You'll be automatically signed in
5. Enter a prompt: "What is 42 + 58?"
6. See the response from Claude 3.5 Sonnet!

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
│   + Auth UI     │
└──────┬──────────┘
       │ POST /invoke
       │ + JWT Token
       ▼
┌─────────────────┐
│  API Gateway    │
│  + Cognito Auth │
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

┌─────────────────┐
│ Cognito         │
│ User Pool       │
│ (Auth)          │
└─────────────────┘
```

## Stack Architecture

| Stack Name | Purpose | Key Resources |
|------------|---------|---------------|
| **AgentCoreInfra** | Build infrastructure | ECR Repository, CodeBuild Project, IAM Roles, S3 Bucket |
| **AgentCoreAuth** | Authentication | Cognito User Pool, User Pool Client |
| **AgentCoreRuntime** | Agent runtime & API | AgentCore Runtime, Lambda Waiter, Lambda Invoker, API Gateway + Cognito Authorizer |
| **AgentCoreFrontend** | Web UI | S3 Bucket, CloudFront Distribution, React App with Auth |

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
│   │   ├── App.tsx            # Main UI component with auth
│   │   ├── AuthModal.tsx      # Login/signup modal
│   │   ├── auth.ts            # Cognito authentication logic
│   │   └── main.tsx           # React entry point
│   ├── dist/                  # Build output (gitignored)
│   └── package.json           # Frontend dependencies
│
├── scripts/
│   ├── build-frontend.ps1     # Builds React app with API URL injection (Windows)
│   └── build-frontend.sh      # Builds React app with API URL injection (macOS/Linux)
│
├── deploy-all.ps1             # Main deployment orchestration (Windows)
├── deploy-all.sh              # Main deployment orchestration (macOS/Linux)
└── README.md                  # This file
```

## How It Works

### Deployment Flow

The `deploy-all.ps1` script orchestrates the complete deployment:

1. **Refresh AWS credentials** using isengardcli
2. **Install CDK dependencies** (cdk/node_modules)
3. **Install frontend dependencies** (frontend/node_modules, includes amazon-cognito-identity-js)
4. **Deploy AgentCoreInfra** - Creates build pipeline resources:
   - ECR repository for agent container images
   - IAM role for AgentCore runtime
   - S3 bucket for CodeBuild sources
   - CodeBuild project for ARM64 builds
5. **Deploy AgentCoreAuth** - Creates authentication resources:
   - Cognito User Pool (email/password)
   - User Pool Client for frontend
   - Password policy (min 8 chars, uppercase, lowercase, digit)
6. **Create placeholder frontend build** (for initial deployment)
7. **Deploy AgentCoreRuntime** - Deploys agent and API:
   - Uploads agent source code to S3
   - Triggers CodeBuild via Custom Resource
   - **Lambda waiter polls CodeBuild** (5-10 minutes)
   - Creates AgentCore runtime with built image
   - Creates Lambda invoker function
   - Creates API Gateway with Cognito authorizer
8. **Build frontend with API URL and Cognito config** (from stack outputs)
9. **Deploy AgentCoreFrontend** - Deploys web interface:
   - S3 bucket for static hosting
   - CloudFront distribution with OAC
   - Deploys React app with authentication UI

### Request Flow

1. User signs in via Cognito (email verification required)
2. Frontend receives JWT token from Cognito
3. User enters prompt in React UI
4. Frontend sends POST to API Gateway `/invoke` with JWT token in Authorization header
5. API Gateway validates JWT token with Cognito
6. Lambda invokes AgentCore Runtime
7. AgentCore executes agent in isolated container (microVM)
8. Agent processes request using Strands framework + Claude 3.5 Sonnet
9. Response returned through Lambda to frontend

## Key Components

### 1. Authentication (`AgentCoreAuth` stack)
- **Cognito User Pool** for user management
- Email-based authentication with verification
- Password policy: min 8 chars, uppercase, lowercase, digit
- **Frontend integration** via amazon-cognito-identity-js
- JWT tokens automatically included in API requests
- Sign in/sign up modal with email confirmation flow

### 2. Agent (`agent/strands_agent.py`)
- Built with Strands Agents framework
- Uses Claude 3.5 Sonnet model (`us.anthropic.claude-3-5-sonnet-20241022-v2:0`)
- Includes calculator and weather tools
- Wrapped with `@BedrockAgentCoreApp` decorator

### 3. Container Build
- ARM64 architecture (native AgentCore support)
- Python 3.13 slim base image
- Built via CodeBuild (no local Docker required)
- Automatic build on deployment
- Build history and logs in AWS Console

### 4. Lambda Waiter (Critical Component)
- Custom Resource that waits for CodeBuild completion
- Polls every 30 seconds, 15-minute timeout
- Returns minimal response to CloudFormation (<4KB)
- Ensures image exists before AgentCore runtime creation
- **Why needed:** CodeBuild's `batchGetBuilds` response exceeds CloudFormation's 4KB Custom Resource limit

### 5. IAM Permissions
The execution role includes:
- Bedrock model invocation
- ECR image access
- CloudWatch Logs & Metrics
- X-Ray tracing
- AgentCore Identity (workload access tokens)

### 6. Built-in Observability
- **CloudWatch Logs:** `/aws/bedrock-agentcore/runtimes/strands_agent-*`
- **X-Ray Tracing:** Distributed tracing enabled
- **CloudWatch Metrics:** Custom metrics in `bedrock-agentcore` namespace
- **CodeBuild Logs:** `/aws/codebuild/bedrock-agentcore-strands-agent-builder`

## Manual Deployment

If you prefer to deploy stacks individually:

### 1. Deploy Infrastructure
```bash
cd cdk
npx cdk deploy AgentCoreInfra --no-cli-pager
```

### 2. Deploy Authentication
```bash
cd cdk
npx cdk deploy AgentCoreAuth --no-cli-pager
```

### 3. Deploy Runtime (triggers build automatically)
```bash
cd cdk
npx cdk deploy AgentCoreRuntime --no-cli-pager
```
*Note: This will pause for 5-10 minutes while CodeBuild runs*

### 4. Deploy Frontend

**Windows (PowerShell):**
```powershell
$apiUrl = aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" --output text --no-cli-pager
$userPoolId = aws cloudformation describe-stacks --stack-name AgentCoreAuth --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" --output text --no-cli-pager
$userPoolClientId = aws cloudformation describe-stacks --stack-name AgentCoreAuth --query "Stacks[0].Outputs[?OutputKey=='UserPoolClientId'].OutputValue" --output text --no-cli-pager
.\scripts\build-frontend.ps1 -ApiUrl $apiUrl -UserPoolId $userPoolId -UserPoolClientId $userPoolClientId
cd cdk
npx cdk deploy AgentCoreFrontend --no-cli-pager
```

**macOS/Linux (Bash):**
```bash
API_URL=$(aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" --output text --no-cli-pager)
USER_POOL_ID=$(aws cloudformation describe-stacks --stack-name AgentCoreAuth --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" --output text --no-cli-pager)
USER_POOL_CLIENT_ID=$(aws cloudformation describe-stacks --stack-name AgentCoreAuth --query "Stacks[0].Outputs[?OutputKey=='UserPoolClientId'].OutputValue" --output text --no-cli-pager)
./scripts/build-frontend.sh "$API_URL" "$USER_POOL_ID" "$USER_POOL_CLIENT_ID"
cd cdk
npx cdk deploy AgentCoreFrontend --no-cli-pager
```

## Updating the Agent

To modify the agent code:

1. Edit `agent/strands_agent.py` or `agent/requirements.txt`
2. Redeploy runtime stack:
   ```bash
   cd cdk
   npx cdk deploy AgentCoreRuntime --no-cli-pager
   ```

The deployment will:
- Upload new agent code to S3
- Trigger CodeBuild to rebuild container
- Wait for build completion
- Update AgentCore runtime with new image

## Cleanup

```bash
cd cdk
npx cdk destroy AgentCoreFrontend --no-cli-pager
npx cdk destroy AgentCoreRuntime --no-cli-pager
npx cdk destroy AgentCoreAuth --no-cli-pager
npx cdk destroy AgentCoreInfra --no-cli-pager
```

**Note:** Cognito User Pool will be deleted along with all user accounts.

## Troubleshooting

### "Access Denied" or "Unauthorized"
If AWS credentials expired, refresh them:
```bash
# For internal AWS users
isengardcli creds your-email@amazon.com --role Admin

# For external users, configure AWS CLI
aws configure
```

If API returns 401 Unauthorized:
- Make sure you're signed in (check header shows your email)
- Try signing out and back in
- Check browser console for JWT token errors

### "Container failed to start"
Check CloudWatch logs:
```bash
aws logs tail /aws/bedrock-agentcore/runtimes/strands_agent-* --follow --no-cli-pager
```

### "Image not found in ECR"
Redeploy runtime stack - it will trigger a new build:
```bash
cd cdk
npx cdk deploy AgentCoreRuntime --no-cli-pager
```

### "Build timeout after 15 minutes"
Check CodeBuild console for build status. If build is still running, wait for completion and redeploy runtime stack.

### CodeBuild fails
Check build logs:
```bash
aws logs tail /aws/codebuild/bedrock-agentcore-strands-agent-builder --follow --no-cli-pager
```

### Frontend shows errors
Verify API URL and Cognito config are correct:
```bash
aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" --output text --no-cli-pager
aws cloudformation describe-stacks --stack-name AgentCoreAuth --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" --output text --no-cli-pager
aws cloudformation describe-stacks --stack-name AgentCoreAuth --query "Stacks[0].Outputs[?OutputKey=='UserPoolClientId'].OutputValue" --output text --no-cli-pager
```

### Email verification not received
- Check spam/junk folder
- Verify email address is correct
- Wait a few minutes (can take up to 5 minutes)
- Try signing up with a different email

### Verify deployment status
Check all stack statuses:
```bash
aws cloudformation describe-stacks --stack-name AgentCoreInfra --query "Stacks[0].StackStatus" --no-cli-pager
aws cloudformation describe-stacks --stack-name AgentCoreAuth --query "Stacks[0].StackStatus" --no-cli-pager
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

### Why Four Stacks?
- **AgentCoreInfra**: Rarely changes, contains build pipeline
- **AgentCoreAuth**: Authentication resources, rarely changes
- **AgentCoreRuntime**: Changes when agent code updates
- **AgentCoreFrontend**: Changes when UI updates

This separation allows independent updates without rebuilding everything.

### Why ARM64?
AgentCore natively supports ARM64 architecture, providing better performance and cost efficiency compared to x86_64.

## Security

- **Authentication required** - API protected by Cognito JWT tokens
- **Email verification** - Users must verify email before access
- **Password policy** - Enforced minimum complexity requirements
- Frontend served via HTTPS (CloudFront)
- AWS credentials never exposed to browser
- CORS configured for API Gateway
- Lambda has minimal IAM permissions
- AgentCore Runtime runs in isolated microVMs
- Container images scanned by ECR
- Origin Access Control (OAC) for S3/CloudFront
- JWT tokens stored in browser session (not localStorage)

## Cost Estimate

Approximate monthly costs (us-east-1):
- **Cognito**: Free for first 50,000 MAUs (Monthly Active Users)
- **AgentCore Runtime**: $0.10 per hour active + $0.000008 per request
- **Lambda**: Free tier covers most demos
- **API Gateway**: $3.50 per million requests
- **CloudFront**: $0.085 per GB + $0.01 per 10,000 requests
- **S3**: Negligible for static hosting
- **ECR**: $0.10 per GB-month
- **CodeBuild**: $0.005 per build minute (ARM64)

**Typical demo cost**: < $5/month with light usage (Cognito is free for small user bases)

## Next Steps

- **Change Model**: Edit `model_id` in `agent/strands_agent.py` (try different Claude versions or Nova models)
- **Add Tools**: Create custom `@tool` functions in the agent
- **Add Memory**: Integrate AgentCore Memory for persistent context
- **Custom Domain**: Add Route53 and ACM certificate to frontend stack
- **Monitoring**: Set up CloudWatch alarms for errors and latency
- **Streaming**: Implement streaming responses for better UX
- **MFA**: Enable multi-factor authentication in Cognito
- **Social Login**: Add Google/Facebook OAuth to Cognito
- **User Management**: Build admin panel for user management

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