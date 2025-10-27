#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { AgentCoreInfraStack } from '../lib/infra-stack';
import { AgentCoreStack } from '../lib/runtime-stack';
import { FrontendStack } from '../lib/frontend-stack';
import { AuthStack } from '../lib/auth-stack';
import { MihcStack } from '../lib/mihc-stack';
import process = require('process');

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
  userPoolClient: authStack.userPoolClient,
  description: 'AgentCore Runtime: Container-based agent with built-in Cognito authentication',
});

// Frontend stack (depends on runtime and auth stacks)
new FrontendStack(app, 'AgentCoreFrontend', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
  userPoolId: authStack.userPool.userPoolId,
  userPoolClientId: authStack.userPoolClient.userPoolClientId,
  agentRuntimeArn: agentStack.agentRuntimeArn,
  region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  description: 'AgentCore Frontend: CloudFront-hosted React interface with direct AgentCore integration',
});

// MIHC stack (Medical Intelligent Healthcare Companion)
new MihcStack(app, 'MihcStack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
  description: 'MIHC: Medical database, Lambda functions, and healthcare data infrastructure',
});

app.synth();
