import * as cdk from 'aws-cdk-lib';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

export class AuthStack extends cdk.Stack {
    public readonly userPool: cognito.UserPool;
    public readonly userPoolClient: cognito.UserPoolClient;
    public readonly identityPool: cognito.CfnIdentityPool;

    constructor(scope: Construct, id: string, props?: cdk.StackProps) {
        super(scope, id, props);

        // Cognito User Pool
        this.userPool = new cognito.UserPool(this, 'AgentCoreUserPool', {
            userPoolName: 'agentcore-users',
            selfSignUpEnabled: true,
            signInAliases: {
                email: true,
            },
            autoVerify: {
                email: true,
            },
            standardAttributes: {
                email: {
                    required: true,
                    mutable: false,
                },
            },
            passwordPolicy: {
                minLength: 8,
                requireLowercase: true,
                requireUppercase: true,
                requireDigits: true,
                requireSymbols: false,
            },
            accountRecovery: cognito.AccountRecovery.EMAIL_ONLY,
            removalPolicy: cdk.RemovalPolicy.DESTROY, // For dev - change to RETAIN for prod
        });

        // User Pool Client for frontend
        this.userPoolClient = new cognito.UserPoolClient(this, 'AgentCoreUserPoolClient', {
            userPool: this.userPool,
            userPoolClientName: 'agentcore-web-client',
            authFlows: {
                userPassword: true,
                userSrp: true,
            },
            generateSecret: false, // Public client (frontend)
            preventUserExistenceErrors: true,
        });

        // Cognito Identity Pool for AWS SDK access
        this.identityPool = new cognito.CfnIdentityPool(this, 'AgentCoreIdentityPool', {
            identityPoolName: 'agentcore-identity-pool',
            allowUnauthenticatedIdentities: false,
            cognitoIdentityProviders: [{
                clientId: this.userPoolClient.userPoolClientId,
                providerName: this.userPool.userPoolProviderName,
            }],
        });

        // IAM Role for authenticated users (frontend)
        const authenticatedRole = new iam.Role(this, 'CognitoAuthenticatedRole', {
            roleName: 'AgentCoreAuthenticatedRole',
            description: 'Role for authenticated Cognito users to access AgentCore Memory',
            assumedBy: new iam.FederatedPrincipal(
                'cognito-identity.amazonaws.com',
                {
                    'StringEquals': {
                        'cognito-identity.amazonaws.com:aud': this.identityPool.ref,
                    },
                    'ForAnyValue:StringLike': {
                        'cognito-identity.amazonaws.com:amr': 'authenticated',
                    },
                },
                'sts:AssumeRoleWithWebIdentity'
            ),
        });

        // Add policy for AgentCore Memory read-only access
        const region = cdk.Stack.of(this).region;
        const account = cdk.Stack.of(this).account;
        
        authenticatedRole.addToPolicy(new iam.PolicyStatement({
            sid: 'AgentCoreMemoryReadAccess',
            effect: iam.Effect.ALLOW,
            actions: [
                'bedrock-agentcore:ListSessions',
                'bedrock-agentcore:ListEvents',
            ],
            resources: [
                `arn:aws:bedrock-agentcore:${region}:${account}:memory/*`,
            ],
        }));

        // Attach roles to Identity Pool
        new cognito.CfnIdentityPoolRoleAttachment(this, 'IdentityPoolRoleAttachment', {
            identityPoolId: this.identityPool.ref,
            roles: {
                authenticated: authenticatedRole.roleArn,
            },
        });

        // Outputs
        new cdk.CfnOutput(this, 'UserPoolId', {
            value: this.userPool.userPoolId,
            description: 'Cognito User Pool ID',
            exportName: 'AgentCoreUserPoolId',
        });

        new cdk.CfnOutput(this, 'UserPoolArn', {
            value: this.userPool.userPoolArn,
            description: 'Cognito User Pool ARN',
            exportName: 'AgentCoreUserPoolArn',
        });

        new cdk.CfnOutput(this, 'UserPoolClientId', {
            value: this.userPoolClient.userPoolClientId,
            description: 'Cognito User Pool Client ID',
            exportName: 'AgentCoreUserPoolClientId',
        });

        new cdk.CfnOutput(this, 'IdentityPoolId', {
            value: this.identityPool.ref,
            description: 'Cognito Identity Pool ID',
            exportName: 'AgentCoreIdentityPoolId',
        });
    }
}
