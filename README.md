# Amazon Bedrock AgentCore - Automated Full-Stack Deployment

Starter template for deploying AI agents with [Amazon Bedrock AgentCore](https://aws.amazon.com/bedrock/agentcore/resources/). Complete infrastructure scaffolding with authentication, API, and web interface - deployment automated in one command.

The example agent is built with the [Strands Agents framework](https://github.com/strands-agents/) and includes calculator and weather tools to demonstrate tool integration. The focus is on deployment automation - you can easily swap the agent implementation or extend its capabilities.

## Architecture

![Architecture](./img/architecture_diagram.svg)

Flow:
1. Browser loads React app from CloudFront/S3
2. User authenticates with Cognito, receives JWT token
3. Browser calls AgentCore directly with JWT Bearer token
4. AgentCore validates JWT and processes agent requests

## Quick Start

### Prerequisites
- **AWS CLI v2.31.13 or later** installed and configured ([Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
  - Check your version: `aws --version`
  - AgentCore support was added in AWS CLI v2.31.13 (January 2025)
- **Node.js 22+** installed
- **AWS credentials** configured with permissions for CloudFormation, Lambda, S3, ECR, CodeBuild, API Gateway, Cognito, and IAM via:
  - `aws configure` (access key/secret key)
  - AWS SSO: `aws sso login --profile <profile-name>`
  - Environment variables: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- **No Docker required!** (CodeBuild handles container builds)

### ⚠️ Important: Region Requirements

**Amazon Bedrock AgentCore is only available in specific AWS regions.**

Before deploying, verify AgentCore availability in your target region by checking the [AWS AgentCore Regions Documentation](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/agentcore-regions.html).

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
> - **Windows users**: Use the PowerShell script (`.ps1`)
> - **macOS/Linux users**: Use the bash script (`.sh`)
> - Both scripts perform identical operations and produce the same infrastructure
> - If you prefer PowerShell on macOS: `brew install --cask powershell` then run `pwsh deploy-all.ps1`

**Time:** ~10 minutes (most time is CodeBuild creating the container image)

**Done!** Your app is live at the CloudFront URL shown in the output.

> **Architecture Note**: This demo uses a simple architecture where the React frontend calls AgentCore directly with JWT authentication.

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
6. See the response from the agent

Try these prompts:
- "What's the weather like today?"
- "Calculate 123 * 456"
- "What is 2 to the power of 10?"


## Stack Architecture

| Stack Name | Purpose | Key Resources |
|------------|---------|---------------|
| **AgentCoreInfra** | Build infrastructure | ECR Repository, CodeBuild Project, IAM Roles, S3 Bucket |
| **AgentCoreAuth** | Authentication | Cognito User Pool, User Pool Client |
| **AgentCoreRuntime** | Agent runtime with built-in auth | AgentCore Runtime with Cognito JWT Authorizer, Lambda Waiter |
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

├── frontend/                   # React app (Vite)
│   ├── src/
│   │   ├── App.tsx            # Main UI component with auth
│   │   ├── AuthModal.tsx      # Login/signup modal
│   │   ├── auth.ts            # Cognito authentication logic
│   │   ├── agentcore.ts       # Direct AgentCore invocation
│   │   └── main.tsx           # React entry point
│   ├── dist/                  # Build output (gitignored)
│   └── package.json           # Frontend dependencies
│
├── scripts/
│   ├── build-frontend.ps1     # Builds React app with AgentCore ARN injection (Windows)
│   └── build-frontend.sh      # Builds React app with AgentCore ARN injection (macOS/Linux)
│
├── deploy-all.ps1             # Main deployment orchestration (Windows)
├── deploy-all.sh              # Main deployment orchestration (macOS/Linux)
└── README.md                  # This file
```

## How It Works

### Deployment Flow

The `deploy-all.ps1` script orchestrates the complete deployment:

1. **Verify AWS credentials** (checks AWS CLI configuration)
2. **Check AWS CLI version** (requires v2.31.13+ for AgentCore support)
3. **Check AgentCore availability** (verifies service is available in your configured region)
4. **Install CDK dependencies** (cdk/node_modules)
5. **Install frontend dependencies** (frontend/node_modules, includes amazon-cognito-identity-js)
6. **Create placeholder frontend build** (for initial deployment)
7. **Bootstrap CDK environment** (sets up CDK deployment resources in your AWS account/region)
8. **Deploy AgentCoreInfra** - Creates build pipeline resources:
   - ECR repository for agent container images
   - IAM role for AgentCore runtime
   - S3 bucket for CodeBuild sources
   - CodeBuild project for ARM64 builds
9. **Deploy AgentCoreAuth** - Creates authentication resources:
    - Cognito User Pool (email/password)
    - User Pool Client for frontend
    - Password policy (min 8 chars, uppercase, lowercase, digit)
10. **Deploy AgentCoreRuntime** - Deploys agent with built-in auth:
    - Uploads agent source code to S3
    - Triggers CodeBuild via Custom Resource
    - **Lambda waiter polls CodeBuild** (5-10 minutes)
    - Creates AgentCore runtime with built-in Cognito JWT authentication
11. **Build frontend with AgentCore ARN and Cognito config, then deploy AgentCoreFrontend**:
    - Retrieves AgentCore Runtime ARN and Cognito config from stack outputs
    - Builds React app with injected configuration
    - S3 bucket for static hosting
    - CloudFront distribution with OAC
    - Deploys React app with authentication UI

### Request Flow

1. User signs in via Cognito (email verification required)
2. Frontend receives JWT access token from Cognito
3. User enters prompt in React UI
4. Frontend sends POST directly to AgentCore `/runtimes/{arn}/invocations` with JWT Bearer token
5. AgentCore validates JWT token with Cognito (built-in authentication)
6. AgentCore executes agent in isolated container (microVM)
7. Agent processes request using Strands framework + Anthropic Claude Haiku 4.5
8. Response returned directly to frontend

## Key Components

### 1. Authentication (`AgentCoreAuth` stack)
- **Cognito User Pool** for user management
- Email-based authentication with verification
- Password policy: min 8 chars, uppercase, lowercase, digit
- **Frontend integration** via amazon-cognito-identity-js
- JWT tokens automatically included in API requests
- Sign in/sign up modal with email confirmation flow
- **JWT Bearer Token Authentication**: Implements AgentCore's built-in JWT authorization (see [JWT Authentication Guide](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-oauth.html#invoke-agent))

### 2. Agent (`agent/strands_agent.py`)
- Built with Strands Agents framework
- Uses Anthropic Claude Haiku 4.5
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

### 5. Direct AgentCore Integration
- Frontend calls AgentCore directly using HTTPS
- JWT Bearer token authentication (Cognito access tokens)
- Built-in Cognito JWT authorizer in AgentCore runtime
- Session ID generation for request tracking

### 6. IAM Permissions
The execution role includes:
- Bedrock model invocation
- ECR image access
- CloudWatch Logs & Metrics
- X-Ray tracing
- AgentCore Identity (workload access tokens)

### 7. Built-in Observability
- **CloudWatch Logs:** `/aws/bedrock-agentcore/runtimes/strands_agent-*`
- **X-Ray Tracing:** Distributed tracing enabled
- **CloudWatch Metrics:** Custom metrics in `bedrock-agentcore` namespace
- **CodeBuild Logs:** `/aws/codebuild/bedrock-agentcore-strands-agent-builder`

## Manual Deployment

If you prefer to deploy stacks individually:

### 1. Bootstrap CDK (one-time setup)
```bash
cd cdk
npx cdk bootstrap --no-cli-pager
```

### 2. Deploy Infrastructure
```bash
cd cdk
npx cdk deploy AgentCoreInfra --no-cli-pager
```

### 3. Deploy Authentication
```bash
cd cdk
npx cdk deploy AgentCoreAuth --no-cli-pager
```

### 4. Deploy Runtime (triggers build automatically)
```bash
cd cdk
npx cdk deploy AgentCoreRuntime --no-cli-pager
```
*Note: This will pause for 5-10 minutes while CodeBuild runs*

### 5. Deploy Frontend

**Windows (PowerShell):**
```powershell
$agentRuntimeArn = aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].Outputs[?OutputKey=='AgentRuntimeArn'].OutputValue" --output text --no-cli-pager
$region = aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].Outputs[?OutputKey=='Region'].OutputValue" --output text --no-cli-pager
$userPoolId = aws cloudformation describe-stacks --stack-name AgentCoreAuth --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" --output text --no-cli-pager
$userPoolClientId = aws cloudformation describe-stacks --stack-name AgentCoreAuth --query "Stacks[0].Outputs[?OutputKey=='UserPoolClientId'].OutputValue" --output text --no-cli-pager
.\scripts\build-frontend.ps1 -UserPoolId $userPoolId -UserPoolClientId $userPoolClientId -AgentRuntimeArn $agentRuntimeArn -Region $region
cd cdk
npx cdk deploy AgentCoreFrontend --no-cli-pager
```

**macOS/Linux (Bash):**
```bash
AGENT_RUNTIME_ARN=$(aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].Outputs[?OutputKey=='AgentRuntimeArn'].OutputValue" --output text --no-cli-pager)
REGION=$(aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].Outputs[?OutputKey=='Region'].OutputValue" --output text --no-cli-pager)
USER_POOL_ID=$(aws cloudformation describe-stacks --stack-name AgentCoreAuth --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue" --output text --no-cli-pager)
USER_POOL_CLIENT_ID=$(aws cloudformation describe-stacks --stack-name AgentCoreAuth --query "Stacks[0].Outputs[?OutputKey=='UserPoolClientId'].OutputValue" --output text --no-cli-pager)
./scripts/build-frontend.sh "$USER_POOL_ID" "$USER_POOL_CLIENT_ID" "$AGENT_RUNTIME_ARN" "$REGION"
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

### ❌ "Template format error: Unrecognized resource types: [AWS::BedrockAgentCore::Runtime]"

**This is the most common deployment error.** It means you're trying to deploy to a region where AgentCore is not available.

**Solution:**

1. **Check current regional availability** - Visit [AWS AgentCore Regions Documentation](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/agentcore-regions.html)
2. **Set the region environment variables** to a supported region before deploying:

**Windows (PowerShell):**
```powershell
$env:AWS_DEFAULT_REGION = "your-supported-region"
$env:AWS_REGION = "your-supported-region"
.\deploy-all.ps1
```

**macOS/Linux (Bash):**
```bash
export AWS_DEFAULT_REGION="your-supported-region"
export AWS_REGION="your-supported-region"
./deploy-all.sh
```

### "CDK Bootstrap Required" or "SSM parameter not found"
If you see errors like "Has the environment been bootstrapped? Please run 'cdk bootstrap'":

This means CDK hasn't been set up in your AWS account/region yet. The deployment script now handles this automatically, but if you're doing manual deployment:

```bash
cd cdk
npx cdk bootstrap --no-cli-pager
```

**Region-specific bootstrap**: CDK bootstrap is required once per AWS account/region combination.

### "Access Denied" or "Unauthorized"
If AWS credentials are not configured or have expired:

**Option 1: Configure with access keys**
```bash
aws configure
```

**Option 2: Use AWS SSO**
```bash
aws sso login --profile <profile-name>
export AWS_PROFILE=<profile-name>
```

**Option 3: Set environment variables**
```bash
export AWS_ACCESS_KEY_ID=your-access-key
export AWS_SECRET_ACCESS_KEY=your-secret-key
export AWS_DEFAULT_REGION=your-region
```

**Verify credentials are working:**
```bash
aws sts get-caller-identity
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
Verify AgentCore Runtime ARN and Cognito config are correct:
```bash
aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].Outputs[?OutputKey=='AgentRuntimeArn'].OutputValue" --output text --no-cli-pager
aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].Outputs[?OutputKey=='Region'].OutputValue" --output text --no-cli-pager
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

### CDK vs AgentCore CLI

This project uses AWS CDK to replicate the functionality of the AgentCore CLI's `agentcore launch` command. Here's how they compare:

**AgentCore CLI Approach:**
```bash
# Simple CLI commands handle everything
agentcore configure -e agent.py
agentcore launch
```

**Our CDK Approach:**
```bash
# Infrastructure as Code with same end result
./deploy-all.ps1  # or ./deploy-all.sh
```

**Why CDK Instead of CLI?**
- **Full-stack deployment**: Includes authentication, frontend, and infrastructure
- **Reproducible infrastructure**: Version-controlled, declarative infrastructure
- **Team collaboration**: Shared infrastructure definitions
- **Integration flexibility**: Easy to extend with additional AWS services
- **Production readiness**: Proper IAM roles, security groups, and resource tagging

Both approaches create the same AgentCore runtime, but CDK provides more control over the complete application stack.

### Why Lambda Waiter?
The AgentCore CLI's `agentcore launch` command waits for container builds to complete before creating the runtime. Our CDK implementation replicates this synchronous behavior using a Lambda Custom Resource:

- **Replicates CLI synchronization**: Simulates how `agentcore launch` waits for build completion
- **CloudFormation limitation**: Custom Resources have a 4KB response limit, but CodeBuild's `batchGetBuilds` response exceeds this
- **Internal polling**: Lambda waiter polls CodeBuild internally and returns only success/failure to CloudFormation
- **Ensures proper sequencing**: Prevents AgentCore runtime creation before container image exists (same as CLI)

### Why CodeBuild?
AgentCore CLI's `agentcore launch` command automatically handles container building and ECR pushing. Our CDK implementation replicates this functionality using CodeBuild to provide the same automated container build process:

- **Replicates CLI behavior**: Simulates `agentcore launch` container build process
- **Native ARM64 build environment** (no emulation, matches AgentCore CLI)
- **Consistent builds across team members** (no local Docker Desktop required)
- **Build history and logs in AWS Console** (same as CLI provides)
- **Automatic image push to ECR** (matches CLI workflow)
- **Infrastructure as Code**: Declarative alternative to CLI commands

### Why Four Stacks?
- **AgentCoreInfra**: Rarely changes, contains build pipeline
- **AgentCoreAuth**: Authentication resources, rarely changes
- **AgentCoreRuntime**: Changes when agent code updates, includes built-in Cognito authentication
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

Approximate monthly costs:
- **Cognito**: Free for first 50,000 MAUs (Monthly Active Users)
- **AgentCore Runtime**: $0.10 per hour active + $0.000008 per request
- **Bedrock Model Usage**: Pay-per-token (varies by model, ~$0.003 per 1K input tokens for Claude Sonnet)
- **Lambda**: Free tier covers most demos ($0.20 per 1M requests after free tier)
- **API Gateway**: $3.50 per million requests
- **CloudFront**: $0.085 per GB + $0.01 per 10,000 requests
- **S3**: $0.023 per GB-month (negligible for static hosting)
- **ECR**: $0.10 per GB-month for container image storage
- **CodeBuild**: $0.005 per build minute (ARM64) - only during deployments
- **CloudWatch Logs**: $0.50 per GB ingested + $0.03 per GB stored
- **CloudFormation**: Free for stack operations
- **IAM**: Free

**Typical demo cost**: $5-15/month with light usage
- AgentCore runtime (~$7/month if active 1 hour/day)
- Bedrock model calls (~$1-5/month depending on usage)
- Other services mostly covered by free tiers

## Customizing the UI

The frontend is built with [AWS Cloudscape Design System](https://cloudscape.design/), AWS's open-source design system for building intuitive web applications. While AgentCore is the focus of this demo, the UI is designed to be easily customizable.

### Why Cloudscape?

- **AWS Native**: Built by AWS for AWS applications
- **Accessibility**: WCAG 2.1 AA compliant out of the box
- **Responsive**: Works seamlessly across devices
- **Rich Components**: 50+ pre-built components for common patterns
- **GenAI Patterns**: Specialized components for AI chat interfaces

### Quick Customization Examples

**1. Change Support Prompts** (`frontend/src/App.tsx`):
```typescript
// Modify the getSupportPrompts() function
const getSupportPrompts = () => {
  if (messages.length === 0) {
    return [
      { id: 'custom1', text: 'Your custom prompt here' },
      { id: 'custom2', text: 'Another custom prompt' },
      // Add more prompts...
    ];
  }
  // Add contextual prompts based on conversation...
};
```

**2. Change Prompt Alignment** (horizontal/vertical):
```typescript
<SupportPromptGroup
  alignment="horizontal"  // or "vertical"
  items={getSupportPrompts()}
  // ...
/>
```

**3. Customize Markdown Styling** (`frontend/src/markdown.css`):
```css
/* Change code block background */
.markdown-content pre {
  background-color: #f0f0f0;
}

/* Customize table styling */
.markdown-content table th {
  background-color: #e0e0e0;
}
```

**4. Add More Feedback Options**:
```typescript
// In the ButtonGroup items array, add:
{
  type: 'icon-button',
  id: 'share',
  iconName: 'share',
  text: 'Share',
}
```

**5. Change App Theme Colors**:
Cloudscape uses design tokens. Create `frontend/src/theme.css`:
```css
:root {
  --awsui-color-text-heading-default: #your-color;
  --awsui-color-background-container-content: #your-bg;
}
```

### Cloudscape Resources

- [Component Library](https://cloudscape.design/components/)
- [GenAI Chat Patterns](https://cloudscape.design/patterns/genai/generative-AI-chat/)
- [Design Tokens](https://cloudscape.design/foundation/visual-foundation/design-tokens/)
- [GitHub Repository](https://github.com/cloudscape-design/components)

### Key UI Features in This Demo

- **Chat Components**: `ChatBubble`, `Avatar`, `SupportPromptGroup`
- **Markdown Rendering**: Full markdown support with `react-markdown`
- **Feedback Buttons**: Thumbs up/down and copy functionality
- **Authentication UI**: Sign in/sign up modal with Cognito
- **Responsive Layout**: 3-column grid that adapts to screen size
- **Design Tokens**: Consistent styling using Cloudscape tokens

## Next Steps

- **Change Model**: Edit `model_id` in `agent/strands_agent.py` (try different Amazon Nova or Anthropic models)
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
- **[JWT Bearer Token Authentication Guide](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-oauth.html#invoke-agent)** - Key documentation for understanding AgentCore's built-in JWT authentication
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