import * as cdk from 'aws-cdk-lib';
import * as bedrockagentcore from 'aws-cdk-lib/aws-bedrockagentcore';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
import * as cr from 'aws-cdk-lib/custom-resources';
import { Construct } from 'constructs';

export class AgentCoreStack extends cdk.Stack {
  public readonly agentRuntimeArn: string;
  public readonly apiUrl: string;

  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Import resources from infra stack
    const sourceBucketName = cdk.Fn.importValue('AgentCoreSourceBucketName');
    const buildProjectName = cdk.Fn.importValue('AgentCoreBuildProjectName');
    const buildProjectArn = cdk.Fn.importValue('AgentCoreBuildProjectArn');

    const sourceBucket = s3.Bucket.fromBucketName(
      this,
      'SourceBucket',
      sourceBucketName
    );

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

    // Step 1: Upload agent source code to S3
    // BucketDeployment extracts files to the destination prefix
    const agentSourceUpload = new s3deploy.BucketDeployment(this, 'AgentSourceUpload', {
      sources: [s3deploy.Source.asset('../agent')],
      destinationBucket: sourceBucket,
      destinationKeyPrefix: 'agent-source/',  // Upload to agent-source/ folder
      prune: false,
      retainOnDelete: false,
    });

    // Step 2: Trigger CodeBuild to build the Docker image
    const buildTrigger = new cr.AwsCustomResource(this, 'TriggerCodeBuild', {
      onCreate: {
        service: 'CodeBuild',
        action: 'startBuild',
        parameters: {
          projectName: buildProjectName,
        },
        physicalResourceId: cr.PhysicalResourceId.of(`build-${Date.now()}`),
      },
      onUpdate: {
        service: 'CodeBuild',
        action: 'startBuild',
        parameters: {
          projectName: buildProjectName,
        },
        physicalResourceId: cr.PhysicalResourceId.of(`build-${Date.now()}`),
      },
      policy: cr.AwsCustomResourcePolicy.fromStatements([
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: ['codebuild:StartBuild', 'codebuild:BatchGetBuilds'],
          resources: [buildProjectArn],
        }),
      ]),
    });

    // Ensure build happens after source upload
    buildTrigger.node.addDependency(agentSourceUpload);

    // Step 3: Wait for build to complete using a custom Lambda
    const buildWaiterFunction = new lambda.Function(this, 'BuildWaiterFunction', {
      runtime: lambda.Runtime.NODEJS_22_X,
      handler: 'index.handler',
      code: lambda.Code.fromInline(`
const { CodeBuildClient, BatchGetBuildsCommand } = require('@aws-sdk/client-codebuild');

exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event));
  
  if (event.RequestType === 'Delete') {
    return sendResponse(event, 'SUCCESS', { Status: 'DELETED' });
  }
  
  const buildId = event.ResourceProperties.BuildId;
  const maxWaitMinutes = 14; // Lambda timeout is 15 min, leave 1 min buffer
  const pollIntervalSeconds = 30;
  
  console.log('Waiting for build:', buildId);
  
  const client = new CodeBuildClient({});
  const startTime = Date.now();
  const maxWaitMs = maxWaitMinutes * 60 * 1000;
  
  while (Date.now() - startTime < maxWaitMs) {
    try {
      const response = await client.send(new BatchGetBuildsCommand({ ids: [buildId] }));
      const build = response.builds[0];
      const status = build.buildStatus;
      
      console.log(\`Build status: \${status}\`);
      
      if (status === 'SUCCEEDED') {
        return await sendResponse(event, 'SUCCESS', { Status: 'SUCCEEDED' });
      } else if (['FAILED', 'FAULT', 'TIMED_OUT', 'STOPPED'].includes(status)) {
        return await sendResponse(event, 'FAILED', {}, \`Build failed with status: \${status}\`);
      }
      
      await new Promise(resolve => setTimeout(resolve, pollIntervalSeconds * 1000));
      
    } catch (error) {
      console.error('Error:', error);
      return await sendResponse(event, 'FAILED', {}, error.message);
    }
  }
  
  return await sendResponse(event, 'FAILED', {}, \`Build timeout after \${maxWaitMinutes} minutes\`);
};

async function sendResponse(event, status, data, reason) {
  const responseBody = JSON.stringify({
    Status: status,
    Reason: reason || \`See CloudWatch Log Stream: \${event.LogStreamName}\`,
    PhysicalResourceId: event.PhysicalResourceId || event.RequestId,
    StackId: event.StackId,
    RequestId: event.RequestId,
    LogicalResourceId: event.LogicalResourceId,
    Data: data
  });
  
  console.log('Response:', responseBody);
  
  const https = require('https');
  const url = require('url');
  const parsedUrl = url.parse(event.ResponseURL);
  
  return new Promise((resolve, reject) => {
    const options = {
      hostname: parsedUrl.hostname,
      port: 443,
      path: parsedUrl.path,
      method: 'PUT',
      headers: {
        'Content-Type': '',
        'Content-Length': responseBody.length
      }
    };
    
    const request = https.request(options, (response) => {
      console.log(\`Status: \${response.statusCode}\`);
      resolve(data);
    });
    
    request.on('error', (error) => {
      console.error('Error:', error);
      reject(error);
    });
    
    request.write(responseBody);
    request.end();
  });
}
      `),
      timeout: cdk.Duration.minutes(15), // Lambda max timeout is 15 minutes
      memorySize: 256,
    });

    buildWaiterFunction.addToRolePolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: ['codebuild:BatchGetBuilds'],
      resources: [buildProjectArn],
    }));

    // Custom resource that invokes the waiter Lambda
    const buildWaiter = new cdk.CustomResource(this, 'BuildWaiter', {
      serviceToken: buildWaiterFunction.functionArn,
      properties: {
        BuildId: buildTrigger.getResponseField('build.id'),
      },
    });

    buildWaiter.node.addDependency(buildTrigger);

    // Create the AgentCore Runtime
    const agentRuntime = new bedrockagentcore.CfnRuntime(this, 'AgentRuntime', {
      agentRuntimeName: 'strands_agent',
      description: 'AgentCore runtime using Strands Agents framework',
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
        Application: 'strands-agent',
      },
    });

    // Ensure AgentCore runtime is created after build completes
    agentRuntime.node.addDependency(buildWaiter);

    // DEFAULT endpoint is automatically created by AgentCore

    // Lambda function to invoke the agent
    const invokeAgentLambda = new lambda.Function(this, 'InvokeAgentLambda', {
      runtime: lambda.Runtime.NODEJS_22_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('../lambda/invoke-agent'),
      timeout: cdk.Duration.seconds(300), // 5 minutes for agent processing
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
      description: 'REST API for AgentCore runtime invocation',
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
        allowHeaders: ['Content-Type', 'Authorization'],
      },
    });

    const invokeResource = api.root.addResource('invoke');
    invokeResource.addMethod('POST', new apigateway.LambdaIntegration(invokeAgentLambda));

    // Add CORS headers to gateway responses (for errors like 504)
    api.addGatewayResponse('Default4xx', {
      type: apigateway.ResponseType.DEFAULT_4XX,
      responseHeaders: {
        'Access-Control-Allow-Origin': "'*'",
        'Access-Control-Allow-Headers': "'Content-Type,Authorization'",
      },
    });

    api.addGatewayResponse('Default5xx', {
      type: apigateway.ResponseType.DEFAULT_5XX,
      responseHeaders: {
        'Access-Control-Allow-Origin': "'*'",
        'Access-Control-Allow-Headers': "'Content-Type,Authorization'",
      },
    });



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
