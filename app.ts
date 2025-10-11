#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { AgentCoreInfraStack } from './agentcore-infra-stack';
import { AgentCoreStack } from './agentcore-stack';
import { FrontendStack } from './lib/frontend-stack';

const app = new cdk.App();

// Infrastructure stack (ECR, IAM, CodeBuild, S3)
new AgentCoreInfraStack(app, 'StrandsClaudeAgentInfra', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
  description: 'Infrastructure for Strands Claude Agent (ECR + IAM + CodeBuild)',
});

// Runtime stack (depends on infra stack)
const agentStack = new AgentCoreStack(app, 'StrandsClaudeAgentStack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
  description: 'Strands Claude Agent deployed on Bedrock AgentCore',
});

// Frontend stack (depends on runtime stack)
new FrontendStack(app, 'AgentCoreFrontendStack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
  apiUrl: agentStack.apiUrl,
  description: 'React Frontend for AgentCore Demo',
});

app.synth();
