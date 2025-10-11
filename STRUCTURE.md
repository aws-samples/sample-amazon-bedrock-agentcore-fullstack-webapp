# Project Structure

This document describes the organization of the AgentCore project.

## Directory Layout

```
project-root/
├── agent/                   # Agent runtime code
│   ├── strands_agent.py    # Agent implementation
│   ├── requirements.txt    # Python dependencies
│   ├── Dockerfile          # Container definition
│   └── .dockerignore       # Docker ignore patterns
│
├── cdk/                     # Infrastructure as Code
│   ├── bin/
│   │   └── app.ts          # CDK app entry point
│   ├── lib/
│   │   ├── infra-stack.ts  # Infrastructure stack (ECR, IAM, CodeBuild)
│   │   ├── runtime-stack.ts # Runtime stack (AgentCore, Lambda, API Gateway)
│   │   └── frontend-stack.ts # Frontend stack (S3, CloudFront)
│   ├── cdk.json            # CDK configuration
│   ├── tsconfig.json       # TypeScript configuration
│   └── package.json        # CDK dependencies
│
├── lambda/                  # Lambda functions
│   └── invoke-agent/       # Agent invocation Lambda
│       └── index.ts
│
├── frontend/                # React frontend application
│   ├── src/                # Source code
│   ├── dist/               # Build output
│   └── package.json        # Frontend dependencies
│
├── scripts/                 # Deployment & build scripts
│   ├── build-agent-image.ps1  # Builds and pushes Docker image
│   └── build-frontend.ps1     # Builds React frontend
│
├── deploy-all.ps1          # Main deployment orchestration script
└── README.md               # Project documentation
```

## Stack Organization

### 1. AgentCoreInfra (Infrastructure Stack)
**File:** `cdk/lib/infra-stack.ts`

Creates foundational resources:
- ECR repository for agent container images
- IAM role for AgentCore runtime with necessary permissions
- S3 bucket for CodeBuild sources
- CodeBuild project for building ARM64 Docker images

**Outputs:**
- Repository URI
- Role ARN (exported for use by runtime stack)
- Source bucket name
- Build project name

### 2. AgentCoreRuntime (Runtime Stack)
**File:** `cdk/lib/runtime-stack.ts`

Deploys the agent runtime:
- Uploads agent source code to S3 (via BucketDeployment)
- Triggers CodeBuild to build Docker image (via Custom Resource)
- Waits for build completion (via Custom Resource)
- AgentCore runtime with container configuration
- Lambda function to invoke the agent
- API Gateway REST API with CORS
- Network configuration (PUBLIC mode for internet access)

**Dependencies:** Imports IAM role, S3 bucket, and CodeBuild project from AgentCoreInfra

**Outputs:**
- Agent runtime ARN and ID
- API Gateway URL
- Invoke endpoint URL

### 3. AgentCoreFrontend (Frontend Stack)
**File:** `cdk/lib/frontend-stack.ts`

Deploys the web interface:
- S3 bucket for static website hosting
- CloudFront distribution with Origin Access Control
- Automatic deployment of built React app

**Dependencies:** Requires API URL from AgentCoreRuntime

**Outputs:**
- CloudFront distribution URL
- S3 bucket name

## Deployment Flow

The `deploy-all.ps1` script orchestrates the complete deployment:

1. **Refresh AWS credentials** using isengardcli
2. **Install frontend dependencies** (npm install)
3. **Deploy infrastructure stack** (AgentCoreInfra)
4. **Create placeholder frontend build** (for initial deployment)
5. **Deploy runtime stack** (AgentCoreRuntime)
   - Automatically uploads agent source to S3
   - Triggers CodeBuild via Custom Resource
   - Waits for build completion
   - Creates AgentCore runtime with built image
6. **Build frontend with API URL** (from runtime stack outputs)
7. **Deploy frontend stack** (AgentCoreFrontend)

## Key Files

### Agent Files
- `agent/strands_agent.py` - Main agent implementation
- `agent/Dockerfile` - Container definition for ARM64
- `agent/requirements.txt` - Python dependencies

### CDK Files
- `cdk/bin/app.ts` - Defines all three stacks
- `cdk/lib/*.ts` - Individual stack definitions
- `cdk/cdk.json` - CDK configuration (app entry point)

### Scripts
- `deploy-all.ps1` - Complete deployment orchestration
- `scripts/build-frontend.ps1` - React app build with API URL injection

## Running Deployments

### Full Deployment
```powershell
.\deploy-all.ps1
```

### Individual Stack Deployment
```powershell
# From project root
npx cdk deploy AgentCoreInfra --app "npx ts-node --prefer-ts-exts cdk/bin/app.ts"
npx cdk deploy AgentCoreRuntime --app "npx ts-node --prefer-ts-exts cdk/bin/app.ts"
npx cdk deploy AgentCoreFrontend --app "npx ts-node --prefer-ts-exts cdk/bin/app.ts"
```

### Rebuild Agent Image
Agent image is automatically rebuilt when deploying the runtime stack. To force a rebuild:
```powershell
npx cdk deploy AgentCoreRuntime --app "npx ts-node --prefer-ts-exts cdk/bin/app.ts"
```

## Notes

- All CDK commands must specify the app path since cdk.json is now in `cdk/` directory
- Agent files are zipped from `agent/` directory for CodeBuild
- Lambda code is referenced from `../lambda/invoke-agent` (relative to cdk/)
- Frontend dist is referenced from `../frontend/dist` (relative to cdk/)
- Build artifacts (*.js, *.d.ts, cdk.out*) are gitignored
