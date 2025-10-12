#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { AgentCoreInfraStack } from '../lib/infra-stack';
import { AgentCoreStack } from '../lib/runtime-stack';
import { FrontendStack } from '../lib/frontend-stack';
import { AuthStack } from '../lib/auth-stack';

const app = new cdk.App();

// Infrastructure stack (ECR, IAM, CodeBuild, S3)
new AgentCoreInfraStack(app, 'AgentCoreInfra', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
  description: 'AgentCore Infrastructure: Container registry, build pipeline, and IAM roles',
});

// Auth stack (Cognito User Pool)
const authStack = new AuthStack(app, 'AgentCoreAuth', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
  description: 'AgentCore Authentication: Cognito User Pool for API access',
});

// Runtime stack (depends on infra and auth stacks)
const agentStack = new AgentCoreStack(app, 'AgentCoreRuntime', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
  userPool: authStack.userPool,
  description: 'AgentCore Runtime: Container-based agent with API Gateway integration',
});

// Frontend stack (depends on runtime and auth stacks)
new FrontendStack(app, 'AgentCoreFrontend', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
  apiUrl: agentStack.apiUrl,
  userPoolId: authStack.userPool.userPoolId,
  userPoolClientId: authStack.userPoolClient.userPoolClientId,
  description: 'AgentCore Frontend: CloudFront-hosted React interface',
});

app.synth();
