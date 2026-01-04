#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as s3 from 'aws-cdk-lib/aws-s3';
import { Construct } from 'constructs';

export class AgentCoreInfraStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Create S3 bucket for direct code deployment
    const sourceBucket = new s3.Bucket(this, 'SourceBucket', {
      bucketName: `bedrock-agentcore-sources-${this.account}-${this.region}`,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      versioned: true,  // Enable versioning for overwrites
      lifecycleRules: [{
        expiration: cdk.Duration.days(7),
        id: 'DeleteOldSources',
      }],
    });

    // Create IAM role for the agent runtime
    const agentRole = new iam.Role(this, 'AgentRuntimeRole', {
      assumedBy: new iam.ServicePrincipal('bedrock-agentcore.amazonaws.com'),
      description: 'Execution role for AgentCore runtime',
    });

    // S3 Bucket Access
    agentRole.addToPolicy(new iam.PolicyStatement({
      sid: 'S3BucketAccess',
      effect: iam.Effect.ALLOW,
      actions: [
        's3:GetObject',
        's3:GetObjectVersion',
      ],
      resources: [`${sourceBucket.bucketArn}/*`],
    }));

    // CloudWatch Logs
    agentRole.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'logs:DescribeLogStreams',
        'logs:CreateLogGroup',
      ],
      resources: [`arn:aws:logs:${this.region}:${this.account}:log-group:/aws/bedrock-agentcore/runtimes/*`],
    }));

    agentRole.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: ['logs:DescribeLogGroups'],
      resources: [`arn:aws:logs:${this.region}:${this.account}:log-group:*`],
    }));

    agentRole.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'logs:CreateLogStream',
        'logs:PutLogEvents',
      ],
      resources: [`arn:aws:logs:${this.region}:${this.account}:log-group:/aws/bedrock-agentcore/runtimes/*:log-stream:*`],
    }));

    // X-Ray Tracing
    agentRole.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'xray:PutTraceSegments',
        'xray:PutTelemetryRecords',
        'xray:GetSamplingRules',
        'xray:GetSamplingTargets',
      ],
      resources: ['*'],
    }));

    // CloudWatch Metrics
    agentRole.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: ['cloudwatch:PutMetricData'],
      resources: ['*'],
      conditions: {
        StringEquals: {
          'cloudwatch:namespace': 'bedrock-agentcore',
        },
      },
    }));

    // AgentCore Identity - Get Workload Access Token
    agentRole.addToPolicy(new iam.PolicyStatement({
      sid: 'GetAgentAccessToken',
      effect: iam.Effect.ALLOW,
      actions: [
        'bedrock-agentcore:GetWorkloadAccessToken',
        'bedrock-agentcore:GetWorkloadAccessTokenForJWT',
        'bedrock-agentcore:GetWorkloadAccessTokenForUserId',
      ],
      resources: [
        `arn:aws:bedrock-agentcore:${this.region}:${this.account}:workload-identity-directory/default`,
        `arn:aws:bedrock-agentcore:${this.region}:${this.account}:workload-identity-directory/default/workload-identity/strands_agent-*`,
      ],
    }));

    // Bedrock Model Invocation (including Converse API and Inference Profiles)
    agentRole.addToPolicy(new iam.PolicyStatement({
      sid: 'BedrockModelInvocation',
      effect: iam.Effect.ALLOW,
      actions: [
        'bedrock:InvokeModel',
        'bedrock:InvokeModelWithResponseStream',
        'bedrock:Converse',
        'bedrock:ConverseStream',
      ],
      resources: [
        'arn:aws:bedrock:*::foundation-model/*',
        `arn:aws:bedrock:${this.region}:${this.account}:inference-profile/*`,
        `arn:aws:bedrock:*:${this.account}:inference-profile/*`,
        `arn:aws:bedrock:${this.region}:${this.account}:*`,
      ],
    }));

    // AWS Marketplace permissions for Bedrock models
    agentRole.addToPolicy(new iam.PolicyStatement({
      sid: 'MarketplaceAccess',
      effect: iam.Effect.ALLOW,
      actions: [
        'aws-marketplace:ViewSubscriptions',
        'aws-marketplace:Subscribe',
        'aws-marketplace:Unsubscribe',
      ],
      resources: ['*'],
    }));

    // AgentCore Memory Access
    agentRole.addToPolicy(new iam.PolicyStatement({
      sid: 'AgentCoreMemoryAccess',
      effect: iam.Effect.ALLOW,
      actions: [
        'bedrock-agentcore:ListSessions',
        'bedrock-agentcore:CreateEvent',
        'bedrock-agentcore:GetEvent',
        'bedrock-agentcore:ListEvents',
        'bedrock-agentcore:DeleteEvent',
      ],
      resources: [
        `arn:aws:bedrock-agentcore:${this.region}:${this.account}:memory/*`,
      ],
    }));

    // Outputs
    new cdk.CfnOutput(this, 'SourceBucketName', {
      value: sourceBucket.bucketName,
      description: 'S3 bucket for direct code deployment',
      exportName: 'AgentCoreSourceBucketName',
    });

    new cdk.CfnOutput(this, 'RoleArn', {
      value: agentRole.roleArn,
      description: 'IAM Role ARN for AgentCore Runtime',
      exportName: 'AgentCoreRuntimeRoleArn',
    });
  }
}
