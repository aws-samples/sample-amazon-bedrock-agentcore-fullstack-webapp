import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
import * as cr from 'aws-cdk-lib/custom-resources';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

export class BuildTriggerStack extends cdk.Stack {
  public readonly buildId: string;

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

    // Step 1: Upload agent source code to S3
    const agentSourceUpload = new s3deploy.BucketDeployment(this, 'AgentSourceUpload', {
      sources: [s3deploy.Source.asset('../agent')],
      destinationBucket: sourceBucket,
      destinationKeyPrefix: 'agent-source/',
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

    buildTrigger.node.addDependency(agentSourceUpload);

    // Output the build ID for the script to monitor
    new cdk.CfnOutput(this, 'BuildProjectName', {
      value: buildProjectName,
      description: 'CodeBuild project name for monitoring',
    });
  }
}
