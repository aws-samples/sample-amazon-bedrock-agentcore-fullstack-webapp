#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { AgentCoreInfraStack } from '../lib/infra-stack';
import { AgentCoreStack } from '../lib/runtime-stack';
import { FrontendStack } from '../lib/frontend-stack';

const app = new cdk.App();

// Infrastructure stack (ECR, IAM, CodeBuild, S3)
new AgentCoreInfraStack(app, 'AgentCoreInfra', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
  description: 'AgentCore Infrastructure: Container registry, build pipeline, and IAM roles',
});

// Runtime stack (depends on infra stack)
const agentStack = new AgentCoreStack(app, 'AgentCoreRuntime', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
  description: 'AgentCore Runtime: Container-based agent with API Gateway integration',
});

// Frontend stack (depends on runtime stack)
new FrontendStack(app, 'AgentCoreFrontend', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
  apiUrl: agentStack.apiUrl,
  description: 'AgentCore Frontend: CloudFront-hosted React interface',
});

app.synth();
