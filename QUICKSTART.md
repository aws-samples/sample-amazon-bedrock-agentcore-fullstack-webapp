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

**Time:** ~15 minutes (most time is CodeBuild creating the container image)

This automatically:
1. ✅ Refreshes AWS credentials
2. ✅ Installs CDK dependencies
3. ✅ Installs frontend dependencies
4. ✅ Deploys infrastructure stack (ECR, CodeBuild, IAM, S3)
5. ✅ Deploys runtime stack:
   - Uploads agent source code
   - Triggers CodeBuild to build ARM64 container
   - **Waits for build to complete** (5-10 minutes)
   - Creates AgentCore runtime
   - Creates API Gateway
6. ✅ Builds and deploys frontend (S3 + CloudFront)

**Done!** Your app is live at the CloudFront URL shown in the output.

## What Gets Deployed

| Stack Name | Purpose | Key Resources |
|------------|---------|---------------|
| **AgentCoreInfra** | Build infrastructure | ECR Repository, CodeBuild Project, IAM Roles, S3 Bucket |
| **AgentCoreRuntime** | Agent runtime & API | AgentCore Runtime, Lambda Waiter, Lambda Invoker, API Gateway |
| **AgentCoreFrontend** | Web UI | S3 Bucket, CloudFront Distribution |

## Test Your App

1. Open the CloudFront URL from deployment output
2. Enter a prompt: "What is 42 + 58?"
3. Click "Invoke Agent"
4. See the response from Claude 3.5 Sonnet!

Try:
- "What's the weather like today?"
- "Calculate 123 * 456"
- "What is 2 to the power of 10?"

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
│  (Invoker)      │
└──────┬──────────┘
       │ InvokeAgentRuntime
       ▼
┌─────────────────┐
│ AgentCore       │
│ Runtime         │
│ (ARM64 Docker)  │
│ Claude 3.5      │
└─────────────────┘
```

## Key Features

### Automated Build Pipeline
- CodeBuild automatically builds ARM64 container images
- Lambda Custom Resource waits for build completion
- No manual intervention required

### No Local Docker Required
CodeBuild handles all container builds in AWS with native ARM64 support.

### Intelligent Waiting
Lambda Custom Resource polls CodeBuild and only returns success/failure to CloudFormation (avoiding 4KB response limit).

### Serverless & Scalable
AgentCore Runtime scales automatically based on demand. Pay only for what you use.

### Built-in Observability
- CloudWatch Logs: `/aws/bedrock-agentcore/runtimes/strands_agent-*`
- X-Ray Tracing: Distributed tracing enabled
- CloudWatch Metrics: Custom metrics in `bedrock-agentcore` namespace

## Updating the Agent

To modify the agent code:

1. Edit `agent/strands_agent.py` or `agent/requirements.txt`
2. Redeploy:
   ```powershell
   cd cdk
   npx cdk deploy AgentCoreRuntime --no-cli-pager
   ```

The deployment will:
- Upload new agent code
- Trigger CodeBuild
- Wait for build
- Update AgentCore runtime

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
aws cloudformation describe-stacks --stack-name AgentCoreRuntime --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" --output text
```

## Cleanup

Remove all resources:

```powershell
cd cdk
npx cdk destroy AgentCoreFrontend --no-cli-pager
npx cdk destroy AgentCoreRuntime --no-cli-pager
npx cdk destroy AgentCoreInfra --no-cli-pager
```

## Next Steps

- **Change Model**: Edit `model_id` in `agent/strands_agent.py` (try different Claude versions or Nova models)
- **Add Tools**: Create custom `@tool` functions in the agent
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

- [AgentCore Documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/agents-agentcore.html)
- [Strands Agents Documentation](https://github.com/awslabs/strands)
- [CDK API Reference](https://docs.aws.amazon.com/cdk/api/v2/)
