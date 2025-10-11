import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

interface AgentCoreApiStackProps extends cdk.StackProps {
  agentRuntimeArn: string;
}

export class AgentCoreApiStack extends cdk.Stack {
  public readonly apiUrl: string;

  constructor(scope: Construct, id: string, props: AgentCoreApiStackProps) {
    super(scope, id, props);

    const invokeAgentLambda = new lambda.Function(this, 'InvokeAgentLambda', {
      runtime: lambda.Runtime.NODEJS_22_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/invoke-agent'),
      timeout: cdk.Duration.seconds(30),
      environment: {
        AGENT_RUNTIME_ARN: props.agentRuntimeArn
      }
    });

    invokeAgentLambda.addToRolePolicy(new iam.PolicyStatement({
      actions: ['bedrock-agentcore:InvokeAgentRuntime'],
      resources: [props.agentRuntimeArn]
    }));

    const api = new apigateway.RestApi(this, 'AgentCoreApi', {
      restApiName: 'AgentCore Demo API',
      description: 'API for invoking AgentCore agents',
      defaultCorsPreflightOptions: {
        allowOrigins: apigateway.Cors.ALL_ORIGINS,
        allowMethods: apigateway.Cors.ALL_METHODS,
        allowHeaders: ['Content-Type', 'Authorization']
      }
    });

    const invokeResource = api.root.addResource('invoke');
    invokeResource.addMethod('POST', new apigateway.LambdaIntegration(invokeAgentLambda));

    this.apiUrl = api.url;

    new cdk.CfnOutput(this, 'ApiUrl', {
      value: api.url,
      description: 'API Gateway URL'
    });

    new cdk.CfnOutput(this, 'InvokeEndpoint', {
      value: `${api.url}invoke`,
      description: 'Agent Invoke Endpoint'
    });
  }
}
