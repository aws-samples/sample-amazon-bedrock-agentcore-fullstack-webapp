import * as cdk from 'aws-cdk-lib';
import * as bedrockagentcore from 'aws-cdk-lib/aws-bedrockagentcore';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import { Construct } from 'constructs';

export interface AgentCoreStackProps extends cdk.StackProps {
  userPool: cognito.IUserPool;
  userPoolClient: cognito.IUserPoolClient;
}

export class AgentCoreStack extends cdk.Stack {
  public readonly agentRuntimeArn: string;
  public readonly memoryId: string;

  constructor(scope: Construct, id: string, props: AgentCoreStackProps) {
    super(scope, id, props);

    // Import resources from infra stack via CDK parameters
    const sourceBucket = cdk.Fn.importValue('AgentCoreSourceBucketName');

    // Import existing IAM role
    const agentRole = iam.Role.fromRoleArn(
      this,
      'AgentRuntimeRole',
      cdk.Fn.importValue('AgentCoreRuntimeRoleArn')
    );

    // Get Cognito discovery URL for inbound auth
    const region = cdk.Stack.of(this).region;
    const discoveryUrl = `https://cognito-idp.${region}.amazonaws.com/${props.userPool.userPoolId}/.well-known/openid-configuration`;

    // Create AgentCore Memory for short-term conversation history
    const agentMemory = new bedrockagentcore.CfnMemory(this, 'AgentMemory', {
      name: 'strands_agent_memory',
      eventExpiryDuration: 365,
      description: 'Short-term memory store for conversation history',
    });

    // Store Memory ID for exports
    this.memoryId = agentMemory.attrMemoryId;

    // Create the AgentCore Runtime with direct code deployment
    const agentRuntime = new bedrockagentcore.CfnRuntime(this, 'AgentRuntime', {
      agentRuntimeName: 'strands_agent',
      description: 'AgentCore runtime using Strands Agents framework with Cognito authentication (direct code deployment)',
      roleArn: agentRole.roleArn,

      // Direct code deployment configuration
      agentRuntimeArtifact: {
        codeConfiguration: {
          code: {
            s3: {
              bucket: sourceBucket,
              prefix: 'strands_agent/deployment_package.zip',
            },
          },
          runtime: 'PYTHON_3_13',
          entryPoint: ['strands_agent.py'],
        },
      },

      // Network configuration - PUBLIC for internet access
      networkConfiguration: {
        networkMode: 'PUBLIC',
      },

      // Protocol configuration
      protocolConfiguration: 'HTTP',

      // Inbound authentication configuration
      authorizerConfiguration: {
        customJwtAuthorizer: {
          discoveryUrl: discoveryUrl,
          allowedClients: [props.userPoolClient.userPoolClientId],
        },
      },

      // Environment variables
      environmentVariables: {
        AGENTCORE_MEMORY_ID: agentMemory.attrMemoryId,
        AWS_DEFAULT_REGION: region,
        LOG_LEVEL: 'INFO',
        IMAGE_VERSION: new Date().toISOString(),
      },

      tags: {
        Environment: 'dev',
        Application: 'strands-agent',
      },
    });

    // Store runtime info for frontend
    this.agentRuntimeArn = agentRuntime.attrAgentRuntimeArn;

    new cdk.CfnOutput(this, 'AgentRuntimeArn', {
      value: agentRuntime.attrAgentRuntimeArn,
      description: 'AgentCore Runtime ARN',
      exportName: 'AgentCoreRuntimeArn',
    });

    new cdk.CfnOutput(this, 'EndpointName', {
      value: 'DEFAULT',
      description: 'Runtime Endpoint Name (DEFAULT auto-created)',
      exportName: 'AgentCoreEndpointName',
    });

    new cdk.CfnOutput(this, 'Region', {
      value: region,
      description: 'AWS Region for AgentCore Runtime',
      exportName: 'AgentCoreRegion',
    });

    new cdk.CfnOutput(this, 'AgentMemoryId', {
      value: agentMemory.attrMemoryId,
      description: 'AgentCore Memory ID for session management',
      exportName: 'AgentCoreMemoryId',
    });
  }
}
