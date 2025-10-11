import * as cdk from 'aws-cdk-lib';
import * as bedrockagentcore from 'aws-cdk-lib/aws-bedrockagentcore';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import { Construct } from 'constructs';

export class AgentCoreStack extends cdk.Stack {
  public readonly agentRuntimeArn: string;
  public readonly apiUrl: string;

  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Use existing ECR repository
    const agentRepository = ecr.Repository.fromRepositoryName(
      this,
      'AgentRepository',
      'strands_agent_repository'
    );

    // Import existing IAM role
    const agentRole = iam.Role.fromRoleArn(
      this,
      'AgentRuntimeRole',
      cdk.Fn.importValue('AgentCoreRuntimeRoleArn')
    );

    // Create the AgentCore Runtime
    const agentRuntime = new bedrockagentcore.CfnRuntime(this, 'StrandsClaudeRuntime', {
      agentRuntimeName: 'strands_agent',
      description: 'Strands agent with Claude 3.7 Sonnet for math and weather',
      roleArn: agentRole.roleArn,

      // Container configuration
      agentRuntimeArtifact: {
        containerConfiguration: {
          containerUri: `${agentRepository.repositoryUri}:latest`,
        },
      },

      // Network configuration - PUBLIC for internet access
      networkConfiguration: {
        networkMode: 'PUBLIC',
      },

      // Protocol configuration
      protocolConfiguration: 'HTTP',

      // Environment variables (if needed)
      environmentVariables: {
        LOG_LEVEL: 'INFO',
        IMAGE_VERSION: new Date().toISOString(),
      },

      tags: {
        Environment: 'dev',
        Application: 'strands-claude-agent',
      },
    });

    // DEFAULT endpoint is automatically created by AgentCore

    // Lambda function to invoke the agent
    const invokeAgentLambda = new lambda.Function(this, 'InvokeAgentLambda', {
      runtime: lambda.Runtime.NODEJS_22_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/invoke-agent'),
      timeout: cdk.Duration.seconds(30),
      memorySize: 512,
      environment: {
        AGENT_RUNTIME_ARN: agentRuntime.attrAgentRuntimeArn,
        AGENT_ENDPOINT_NAME: 'DEFAULT'
      },
    });

    // Grant Lambda permission to invoke AgentCore
    invokeAgentLambda.addToRolePolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: ['bedrock-agentcore:InvokeAgentRuntime'],
      resources: ['*'],  // AgentCore requires wildcard for InvokeAgentRuntime
    }));

    // API Gateway REST API
    const api = new apigateway.RestApi(this, 'AgentApi', {
      restApiName: 'AgentCore Demo API',
      description: 'API for invoking AgentCore agent from React frontend',
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
        allowHeaders: ['Content-Type', 'Authorization'],
      },
    });

    const invokeResource = api.root.addResource('invoke');
    invokeResource.addMethod('POST', new apigateway.LambdaIntegration(invokeAgentLambda));



    new cdk.CfnOutput(this, 'AgentRuntimeId', {
      value: agentRuntime.attrAgentRuntimeId,
      description: 'AgentCore Runtime ID',
    });

    new cdk.CfnOutput(this, 'AgentRuntimeArn', {
      value: agentRuntime.attrAgentRuntimeArn,
      description: 'AgentCore Runtime ARN',
    });

    new cdk.CfnOutput(this, 'EndpointName', {
      value: 'DEFAULT',
      description: 'Runtime Endpoint Name (DEFAULT auto-created)',
    });

    new cdk.CfnOutput(this, 'ApiUrl', {
      value: api.url,
      description: 'API Gateway URL for invoking the agent',
    });

    new cdk.CfnOutput(this, 'InvokeEndpoint', {
      value: `${api.url}invoke`,
      description: 'Full endpoint URL to invoke the agent',
    });

    this.apiUrl = api.url;
  }
}
