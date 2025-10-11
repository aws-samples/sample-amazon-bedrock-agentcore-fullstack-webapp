#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import { Construct } from 'constructs';
import * as path from 'path';

export class AgentCoreDemoStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Get the agent runtime ARN from parameter or use placeholder
    const agentRuntimeArn = new cdk.CfnParameter(this, 'AgentRuntimeArn', {
      type: 'String',
      description: 'ARN of the AgentCore Runtime',
    });

    // Lambda function to invoke the agent
    const invokeAgentLambda = new lambda.Function(this, 'InvokeAgentLambda', {
      runtime: lambda.Runtime.NODEJS_20_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../lambda')),
      timeout: cdk.Duration.seconds(30),
      environment: {
        AGENT_RUNTIME_ARN: agentRuntimeArn.valueAsString,
      },
    });

    // Grant permissions to invoke AgentCore
    invokeAgentLambda.addToRolePolicy(new iam.PolicyStatement({
      actions: ['bedrock-agentcore:InvokeAgentRuntime'],
      resources: [agentRuntimeArn.valueAsString],
    }));

    // API Gateway
    const api = new apigateway.RestApi(this, 'AgentDemoApi', {
      restApiName: 'AgentCore Demo API',
      description: 'API for invoking AgentCore agent from web frontend',
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
        allowHeaders: ['Content-Type', 'Authorization'],
      },
    });

    const invokeResource = api.root.addResource('invoke');
    invokeResource.addMethod('POST', new apigateway.LambdaIntegration(invokeAgentLambda));

    // S3 bucket for hosting React frontend
    const websiteBucket = new s3.Bucket(this, 'WebsiteBucket', {
      websiteIndexDocument: 'index.html',
      publicReadAccess: true,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ACLS,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
    });

    // CloudFront distribution
    const distribution = new cloudfront.Distribution(this, 'Distribution', {
      defaultBehavior: {
        origin: new origins.S3Origin(websiteBucket),
        viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
      },
      defaultRootObject: 'index.html',
    });

    // Deploy React app to S3 (will be built separately)
    new s3deploy.BucketDeployment(this, 'DeployWebsite', {
      sources: [s3deploy.Source.asset(path.join(__dirname, '../frontend/build'))],
      destinationBucket: websiteBucket,
      distribution,
      distributionPaths: ['/*'],
    });

    // Outputs
    new cdk.CfnOutput(this, 'ApiUrl', {
      value: api.url,
      description: 'API Gateway URL',
    });

    new cdk.CfnOutput(this, 'WebsiteUrl', {
      value: `https://${distribution.distributionDomainName}`,
      description: 'CloudFront Website URL',
    });

    new cdk.CfnOutput(this, 'BucketUrl', {
      value: websiteBucket.bucketWebsiteUrl,
      description: 'S3 Website URL (for testing)',
    });
  }
}

const app = new cdk.App();

new AgentCoreDemoStack(app, 'AgentCoreDemo', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
  description: 'Demo web application for AgentCore',
});

app.synth();
