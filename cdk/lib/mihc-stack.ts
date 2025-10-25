import * as cdk from "aws-cdk-lib";
import { Construct } from "constructs";
import * as iam from "aws-cdk-lib/aws-iam";
import * as s3 from "aws-cdk-lib/aws-s3";
import * as rds from "aws-cdk-lib/aws-rds";
import * as ec2 from "aws-cdk-lib/aws-ec2";
import * as kms from "aws-cdk-lib/aws-kms";
import * as logs from "aws-cdk-lib/aws-logs";
import * as lambda from "aws-cdk-lib/aws-lambda";
// import * as glue from "@aws-cdk/aws-glue-alpha";

// export interface MihcStackProps extends cdk.StackProps {
//   stageName: string;
// }

export class MihcStack extends cdk.Stack {
  public readonly rawBucket: s3.Bucket;
  public readonly processedBucket: s3.Bucket;
  public readonly curatedBucket: s3.Bucket;
  public readonly archiveBucket: s3.Bucket;
  public readonly scriptBucket: s3.Bucket;
  public readonly vpc: ec2.Vpc;
  public readonly auroraCluster: rds.DatabaseCluster;
  public readonly databaseKmsKey: kms.Key;
  public readonly databaseSecurityGroup: ec2.SecurityGroup;
  public readonly databaseLambda: lambda.Function;
  public readonly lambdaSecurityGroup: ec2.SecurityGroup;

  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // constructor(scope: Construct, id: string, props: MihcStackProps) {
    //   super(scope, id, props);



    this.rawBucket = new s3.Bucket(
      this,
      "RawBucket"
      // , {
      // bucketName: `dl-rawbucket-${account}`,
      // }
    );
    this.processedBucket = new s3.Bucket(
      this,
      "ProcessedBucket"
    );
    this.curatedBucket = new s3.Bucket(
      this,
      "CuratedBucket"
    );
    this.archiveBucket = new s3.Bucket(
      this,
      "ArchiveBucket"
    );
    this.scriptBucket = new s3.Bucket(
      this,
      "ScriptBucket"
    );

    // Create simplified VPC for development
    this.vpc = new ec2.Vpc(this, "MihcVpc", {
      maxAzs: 2, // 2 AZs for development
      natGateways: 1, // Single NAT gateway for cost optimization in dev
      enableDnsHostnames: true,
      enableDnsSupport: true,
      subnetConfiguration: [
        {
          cidrMask: 24,
          name: "public",
          subnetType: ec2.SubnetType.PUBLIC,
        },
        {
          cidrMask: 24,
          name: "private",
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
        },
      ],
    });

    // Create KMS key for database encryption
    this.databaseKmsKey = new kms.Key(this, "DatabaseKmsKey", {
      description: "KMS key for medical database encryption (development)",
      enableKeyRotation: true,
      removalPolicy: cdk.RemovalPolicy.DESTROY, // Allow destruction in development
      policy: new iam.PolicyDocument({
        statements: [
          new iam.PolicyStatement({
            sid: "Enable IAM User Permissions",
            effect: iam.Effect.ALLOW,
            principals: [new iam.AccountRootPrincipal()],
            actions: ["kms:*"],
            resources: ["*"],
          }),
          new iam.PolicyStatement({
            sid: "Allow RDS Service",
            effect: iam.Effect.ALLOW,
            principals: [new iam.ServicePrincipal("rds.amazonaws.com")],
            actions: [
              "kms:Decrypt",
              "kms:GenerateDataKey",
              "kms:CreateGrant",
              "kms:DescribeKey",
            ],
            resources: ["*"],
          }),
          new iam.PolicyStatement({
            sid: "Allow CloudWatch Logs Service",
            effect: iam.Effect.ALLOW,
            principals: [new iam.ServicePrincipal(`logs.${cdk.Stack.of(this).region}.amazonaws.com`)],
            actions: [
              "kms:Encrypt",
              "kms:Decrypt",
              "kms:ReEncrypt*",
              "kms:GenerateDataKey*",
              "kms:DescribeKey",
            ],
            resources: ["*"],
            conditions: {
              ArnEquals: {
                "kms:EncryptionContext:aws:logs:arn": `arn:aws:logs:${cdk.Stack.of(this).region}:${cdk.Stack.of(this).account}:log-group:/aws/rds/cluster/mihc-medical-database/postgresql`,
              },
            },
          }),
        ],
      }),
    });

    // Add alias for the KMS key
    new kms.Alias(this, "DatabaseKmsKeyAlias", {
      aliasName: "alias/mihc-medical-database",
      targetKey: this.databaseKmsKey,
    });

    // Create security group for database
    this.databaseSecurityGroup = new ec2.SecurityGroup(this, "DatabaseSecurityGroup", {
      vpc: this.vpc,
      description: "Security group for medical database (development)",
      allowAllOutbound: false, // Explicit outbound rules only
    });

    // Only allow PostgreSQL traffic from within VPC
    this.databaseSecurityGroup.addIngressRule(
      ec2.Peer.ipv4(this.vpc.vpcCidrBlock),
      ec2.Port.tcp(5432),
      "PostgreSQL access from VPC only"
    );

    // Create CloudWatch log group for database logs with encryption
    new logs.LogGroup(this, "DatabaseLogGroup", {
      logGroupName: "/aws/rds/cluster/mihc-medical-database/postgresql",
      retention: logs.RetentionDays.ONE_MONTH, // Reduced retention for development
      encryptionKey: this.databaseKmsKey,
      removalPolicy: cdk.RemovalPolicy.DESTROY, // Allow destruction in development
    });

    // Create Aurora Serverless v2 PostgreSQL cluster for development
    this.auroraCluster = new rds.DatabaseCluster(this, "MedicalDatabase", {
      engine: rds.DatabaseClusterEngine.auroraPostgres({
        version: rds.AuroraPostgresEngineVersion.VER_15_4,
      }),
      credentials: rds.Credentials.fromGeneratedSecret("postgres", {
        secretName: "mihc-medical-database-credentials",
        encryptionKey: this.databaseKmsKey,
      }),
      serverlessV2MinCapacity: 0.5, // Minimum ACUs for Serverless v2
      serverlessV2MaxCapacity: 2, // Maximum ACUs for development
      enableDataApi: true, // Enable RDS Data API for HTTP endpoint access
      writer: rds.ClusterInstance.serverlessV2("writer", {
        enablePerformanceInsights: true,
        performanceInsightEncryptionKey: this.databaseKmsKey,
        performanceInsightRetention: rds.PerformanceInsightRetention.MONTHS_12,
      }),
      // No readers for development - just single writer instance
      vpc: this.vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS, // Use private subnets with egress
      },
      securityGroups: [this.databaseSecurityGroup],
      backup: {
        retention: cdk.Duration.days(7), // Reduced retention for development
        preferredWindow: "03:00-04:00",
      },
      preferredMaintenanceWindow: "sun:04:00-sun:05:00",
      cloudwatchLogsExports: ["postgresql"],
      storageEncrypted: true,
      storageEncryptionKey: this.databaseKmsKey,
      monitoringInterval: cdk.Duration.seconds(60),
      monitoringRole: new iam.Role(this, "DatabaseMonitoringRole", {
        assumedBy: new iam.ServicePrincipal("monitoring.rds.amazonaws.com"),
        managedPolicies: [
          iam.ManagedPolicy.fromAwsManagedPolicyName("service-role/AmazonRDSEnhancedMonitoringRole"),
        ],
      }),
      deletionProtection: false, // Allow deletion in development
      removalPolicy: cdk.RemovalPolicy.DESTROY, // Allow destruction in development
      defaultDatabaseName: "medical_records",
      parameterGroup: new rds.ParameterGroup(this, "DatabaseParameterGroup", {
        engine: rds.DatabaseClusterEngine.auroraPostgres({
          version: rds.AuroraPostgresEngineVersion.VER_15_4,
        }),
        description: "Parameter group for development medical database",
        parameters: {
          // Enable SSL/TLS encryption in transit
          "rds.force_ssl": "1",
          // Enable logging for audit trail
          "log_statement": "all",
          "log_min_duration_statement": "0",
          "log_connections": "1",
          "log_disconnections": "1",
          "log_lock_waits": "1",
          // Set timezone
          "timezone": "UTC",
        },
      }),
    });

    // Create security group for Lambda function
    this.lambdaSecurityGroup = new ec2.SecurityGroup(this, "LambdaSecurityGroup", {
      vpc: this.vpc,
      description: "Security group for Lambda function accessing medical database (development)",
      allowAllOutbound: true, // Lambda needs outbound access for AWS services
    });

    // Allow Lambda to connect to the database
    this.databaseSecurityGroup.addIngressRule(
      this.lambdaSecurityGroup,
      ec2.Port.tcp(5432),
      "Allow Lambda access to PostgreSQL"
    );

    // Create Lambda function for database operations
    this.databaseLambda = new lambda.Function(this, "DatabaseLambda", {
      runtime: lambda.Runtime.PYTHON_3_11,
      handler: "index.lambda_handler",
      code: lambda.Code.fromAsset("../lambda/database-handler"),
      environment: {
        DB_HOST: this.auroraCluster.clusterEndpoint.hostname,
        DB_PORT: this.auroraCluster.clusterEndpoint.port.toString(),
        DB_NAME: "medical_records",
        DB_SECRET_ARN: this.auroraCluster.secret!.secretArn,
        DB_CLUSTER_ARN: this.auroraCluster.clusterArn,
      },
      vpc: this.vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS, // Lambda needs internet for AWS services
      },
      securityGroups: [this.lambdaSecurityGroup],
      timeout: cdk.Duration.minutes(5),
      memorySize: 512,
      description: "Lambda function for diabetes database operations (development)",
    });

    // Grant Lambda permission to read database secrets
    this.auroraCluster.secret!.grantRead(this.databaseLambda);
    
    // Add explicit Secrets Manager permissions for all RDS secrets
    this.databaseLambda.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        resources: [
          this.auroraCluster.secret!.secretArn,
          `arn:aws:secretsmanager:${cdk.Stack.of(this).region}:${cdk.Stack.of(this).account}:secret:rds-db-credentials/*`
        ]
      })
    );

    // Grant Lambda permission to use KMS key for decryption
    this.databaseKmsKey.grantDecrypt(this.databaseLambda);

    // Grant Lambda permission to use RDS Data API
    this.databaseLambda.addToRolePolicy(
      new iam.PolicyStatement({
        effect: iam.Effect.ALLOW,
        actions: [
          "rds-data:ExecuteStatement",
          "rds-data:BatchExecuteStatement",
          "rds-data:BeginTransaction",
          "rds-data:CommitTransaction",
          "rds-data:RollbackTransaction"
        ],
        resources: [this.auroraCluster.clusterArn]
      })
    );

    new cdk.CfnOutput(this, "RawBucketName", {
      value: this.rawBucket.bucketName,
    });
    new cdk.CfnOutput(this, "ProcessedBucketName", {
      value: this.processedBucket.bucketName,
    });
    new cdk.CfnOutput(this, "curatedBucketName", {
      value: this.curatedBucket.bucketName,
    });
    new cdk.CfnOutput(this, "archiveBucket", {
      value: this.archiveBucket.bucketName,
    });
    new cdk.CfnOutput(this, "scriptBucketName", {
      value: this.scriptBucket.bucketName,
    });

    // Medical database outputs
    new cdk.CfnOutput(this, "MedicalDatabaseEndpoint", {
      value: this.auroraCluster.clusterEndpoint.hostname,
      description: "Medical database cluster endpoint (development)",
    });
    new cdk.CfnOutput(this, "MedicalDatabaseSecretArn", {
      value: this.auroraCluster.secret!.secretArn,
      description: "ARN of the encrypted medical database credentials",
    });
    
    new cdk.CfnOutput(this, "MedicalDatabaseSecretName", {
      value: this.auroraCluster.secret!.secretName,
      description: "Name of the encrypted medical database credentials",
    });
    new cdk.CfnOutput(this, "DatabaseKmsKeyId", {
      value: this.databaseKmsKey.keyId,
      description: "KMS key ID for database encryption",
    });
    new cdk.CfnOutput(this, "DatabaseKmsKeyArn", {
      value: this.databaseKmsKey.keyArn,
      description: "KMS key ARN for database encryption",
    });
    new cdk.CfnOutput(this, "VpcId", {
      value: this.vpc.vpcId,
      description: "VPC ID for the medical database cluster",
    });
    new cdk.CfnOutput(this, "DatabaseSecurityGroupId", {
      value: this.databaseSecurityGroup.securityGroupId,
      description: "Security group ID for database access control",
    });

    // Lambda function outputs
    new cdk.CfnOutput(this, "DatabaseLambdaFunctionName", {
      value: this.databaseLambda.functionName,
      description: "Name of the database Lambda function",
    });
    new cdk.CfnOutput(this, "DatabaseLambdaFunctionArn", {
      value: this.databaseLambda.functionArn,
      description: "ARN of the database Lambda function",
    });
  }
}
