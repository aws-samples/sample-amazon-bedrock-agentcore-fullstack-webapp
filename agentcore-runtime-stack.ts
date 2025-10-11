#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import * as bedrockagentcore from 'aws-cdk-lib/aws-bedrockagentcore';
import { Construct } from 'constructs';

export class AgentCoreRuntimeStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Import the role ARN from the infrastructure stack
    const roleArn = cdk.Fn.importValue('AgentCoreRuntimeRoleArn');
    
    // Get repository URI from parameters or construct it
    const account = cdk.Stack.of(this).account;
    const region = cdk.Stack.of(this).region;
    const repositoryUri = `${account}.dkr.ecr.${region}.amazonaws.com/strands_claude_agent`;

    // Create the AgentCore Runtime
    const agentRuntime = new bedrockagentcore.CfnRuntime(this, 'StrandsClaudeRuntime', {
      agentRuntimeName: 'strandsClaudeAgent',
      description: 'Strands agent with Claude 3.7 Sonnet for math and weather',
      roleArn: roleArn,
      
      // Container configuration
      agentRuntimeArtifact: {
        containerConfiguration: {
          containerUri: `${repositoryUri}:latest`,
        },
      },

      // Network configuration - PUBLIC for internet access
      networkConfiguration: {
        networkMode: 'PUBLIC',
      },

      // Environment variables
      environmentVariables: {
        LOG_LEVEL: 'INFO',
      },

      tags: {
        Environment: 'dev',
        Application: 'strands-claude-agent',
      },
    });

    // Create Runtime Endpoint for invoking the agent
    const runtimeEndpoint = new bedrockagentcore.CfnRuntimeEndpoint(this, 'AgentEndpoint', {
      agentRuntimeId: agentRuntime.attrAgentRuntimeId,
      name: 'strandsClaudeEndpoint',
      description: 'Endpoint for Strands Claude agent',
    });

    // Outputs
    new cdk.CfnOutput(this, 'AgentRuntimeId', {
      value: agentRuntime.attrAgentRuntimeId,
      description: 'AgentCore Runtime ID',
    });

    new cdk.CfnOutput(this, 'AgentRuntimeArn', {
      value: agentRuntime.attrAgentRuntimeArn,
      description: 'AgentCore Runtime ARN',
    });

    new cdk.CfnOutput(this, 'EndpointId', {
      value: runtimeEndpoint.attrId,
      description: 'Runtime Endpoint ID',
    });

    new cdk.CfnOutput(this, 'EndpointArn', {
      value: runtimeEndpoint.attrAgentRuntimeEndpointArn,
      description: 'Runtime Endpoint ARN',
    });
  }
}

const app = new cdk.App();

new AgentCoreRuntimeStack(app, 'StrandsClaudeAgentRuntime', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
  description: 'Strands Claude Agent Runtime on Bedrock AgentCore',
});

app.synth();
