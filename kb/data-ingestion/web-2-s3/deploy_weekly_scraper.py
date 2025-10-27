#!/usr/bin/env python3
"""
Deployment script for weekly diabetes scraper
"""

import boto3
import json
import zipfile
import os
import time
from datetime import datetime, timedelta


def create_lambda_deployment_package():
    """Create a deployment package for Lambda with dependencies"""
    
    print("📦 Creating Lambda deployment package...")
    
    # Create a temporary directory for dependencies
    import tempfile
    import subprocess
    import shutil
    
    with tempfile.TemporaryDirectory() as temp_dir:
        print(f"📁 Using temporary directory: {temp_dir}")
        
        # Install dependencies to temp directory
        if os.path.exists('requirements_scraper.txt'):
            print("📥 Installing dependencies...")
            try:
                subprocess.run([
                    'pip', 'install', 
                    '-r', 'requirements_scraper.txt',
                    '-t', temp_dir,
                    '--platform', 'manylinux2014_x86_64',
                    '--only-binary=:all:',
                    '--upgrade'
                ], check=True, capture_output=True, text=True)
                print("  ✅ Dependencies installed")
            except subprocess.CalledProcessError as e:
                print(f"  ❌ Failed to install dependencies: {e}")
                print(f"  Error output: {e.stderr}")
                # Continue anyway, but warn
                print("  ⚠️  Continuing without dependencies - Lambda may fail")
        
        # Files to include in the package
        files_to_include = [
            'lambda_diabetes_scraper.py',
            'diabetes_scraper_scheduler_lambda.py'
        ]
        
        # Create zip file
        with zipfile.ZipFile('diabetes_scraper_lambda.zip', 'w', zipfile.ZIP_DEFLATED) as zipf:
            # Add Python files
            for file in files_to_include:
                if os.path.exists(file):
                    zipf.write(file)
                    print(f"  ✅ Added {file}")
                else:
                    print(f"  ⚠️  Warning: {file} not found")
            
            # Add dependencies from temp directory
            for root, dirs, files in os.walk(temp_dir):
                for file in files:
                    file_path = os.path.join(root, file)
                    arc_name = os.path.relpath(file_path, temp_dir)
                    zipf.write(file_path, arc_name)
            
            print(f"  ✅ Added dependencies from {temp_dir}")
    
    print("✅ Deployment package created: diabetes_scraper_lambda.zip")
    return 'diabetes_scraper_lambda.zip'


def create_lambda_function(
    function_name: str = "diabetes-scraper-weekly",
    bucket_name: str = None,
    role_arn: str = None
):
    """Create or update Lambda function"""
    
    lambda_client = boto3.client('lambda')
    
    # Read the deployment package
    with open('diabetes_scraper_lambda.zip', 'rb') as f:
        zip_content = f.read()
    
    # Environment variables - simplified without Tavily
    environment_vars = {
        'S3_BUCKET_NAME': bucket_name or 'mihc-diabetes-kb'
    }
    
    try:
        # Try to update existing function
        print(f"🔄 Updating Lambda function: {function_name}")
        
        # Wait for any pending updates to complete
        print("⏳ Waiting for any pending updates to complete...")
        waiter = lambda_client.get_waiter('function_updated')
        try:
            waiter.wait(
                FunctionName=function_name,
                WaiterConfig={'Delay': 5, 'MaxAttempts': 12}  # Wait up to 1 minute
            )
        except Exception as e:
            print(f"⚠️  Waiter failed: {e}, continuing anyway...")
        
        # Update code only (skip configuration to avoid conflicts)
        lambda_client.update_function_code(
            FunctionName=function_name,
            ZipFile=zip_content
        )
        
        print(f"✅ Lambda function code updated: {function_name}")
        print("⚠️  Skipped configuration update due to pending updates")
        print("💡 You can update environment variables later in AWS Console if needed")
        
    except lambda_client.exceptions.ResourceNotFoundException:
        # Create new function
        print(f"🆕 Creating new Lambda function: {function_name}")
        
        if not role_arn:
            print("❌ Error: role_arn is required for creating new Lambda function")
            return None
        
        response = lambda_client.create_function(
            FunctionName=function_name,
            Runtime='python3.9',
            Role=role_arn,
            Handler='lambda_diabetes_scraper.lambda_handler',
            Code={'ZipFile': zip_content},
            Description='Weekly diabetes content scraper from WebMD',
            Timeout=900,  # 15 minutes
            MemorySize=512,
            Environment={'Variables': environment_vars},
            Tags={
                'Project': 'DiabetesScraper',
                'Schedule': 'Weekly',
                'Source': 'WebMD'
            }
        )
        
        print(f"✅ Lambda function created: {function_name}")
        return response['FunctionArn']
    
    except Exception as e:
        print(f"❌ Error with Lambda function: {e}")
        return None


def create_eventbridge_schedule(
    function_name: str = "diabetes-scraper-weekly",
    bucket_name: str = None,
    schedule_expression: str = "rate(7 days)"
):
    """Create EventBridge rule for weekly scheduling"""
    
    events_client = boto3.client('events')
    lambda_client = boto3.client('lambda')
    
    rule_name = f"{function_name}-weekly-schedule"
    
    try:
        print(f"📅 Creating EventBridge schedule: {rule_name}")
        
        # Create the rule
        events_client.put_rule(
            Name=rule_name,
            ScheduleExpression=schedule_expression,
            Description=f"Weekly trigger for {function_name}",
            State='ENABLED'
        )
        
        # Get Lambda function ARN
        lambda_response = lambda_client.get_function(FunctionName=function_name)
        function_arn = lambda_response['Configuration']['FunctionArn']
        
        # Add Lambda as target
        events_client.put_targets(
            Rule=rule_name,
            Targets=[
                {
                    'Id': '1',
                    'Arn': function_arn,
                    'Input': json.dumps({
                        'bucket_name': bucket_name or 'mihc-diabetes-kb',
                        'scheduled_run': True,
                        'search_queries': [
                            'diabetes symptoms',
                            'diabetes treatment',
                            'diabetes diet',
                            'type 1 diabetes',
                            'type 2 diabetes',
                            'diabetes medication'
                        ],
                        'max_results_per_query': 5
                    })
                }
            ]
        )
        
        # Add permission for EventBridge to invoke Lambda
        try:
            lambda_client.add_permission(
                FunctionName=function_name,
                StatementId=f"{rule_name}-permission",
                Action='lambda:InvokeFunction',
                Principal='events.amazonaws.com',
                SourceArn=f"arn:aws:events:{boto3.Session().region_name}:{boto3.client('sts').get_caller_identity()['Account']}:rule/{rule_name}"
            )
        except lambda_client.exceptions.ResourceConflictException:
            print("  ℹ️  Permission already exists")
        
        print(f"✅ EventBridge schedule created: {rule_name}")
        print(f"📅 Next run: {(datetime.now() + timedelta(days=7)).strftime('%Y-%m-%d %H:%M:%S')}")
        
        return rule_name
        
    except Exception as e:
        print(f"❌ Error creating EventBridge schedule: {e}")
        return None


def create_iam_role_for_lambda():
    """Create IAM role for Lambda function"""
    
    iam_client = boto3.client('iam')
    role_name = "DiabetesScraperLambdaRole"
    
    # Trust policy for Lambda
    trust_policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": "lambda.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }
    
    # Permissions policy
    permissions_policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ],
                "Resource": "arn:aws:logs:*:*:*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "s3:GetObject",
                    "s3:PutObject",
                    "s3:DeleteObject",
                    "s3:ListBucket"
                ],
                "Resource": [
                    "arn:aws:s3:::*diabetes*",
                    "arn:aws:s3:::*diabetes*/*"
                ]
            }
        ]
    }
    
    try:
        # Create role
        print(f"🔐 Creating IAM role: {role_name}")
        
        role_response = iam_client.create_role(
            RoleName=role_name,
            AssumeRolePolicyDocument=json.dumps(trust_policy),
            Description="Role for diabetes scraper Lambda function"
        )
        
        # Attach basic Lambda execution policy
        iam_client.attach_role_policy(
            RoleName=role_name,
            PolicyArn='arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole'
        )
        
        # Create and attach custom policy
        policy_name = f"{role_name}Policy"
        
        policy_response = iam_client.create_policy(
            PolicyName=policy_name,
            PolicyDocument=json.dumps(permissions_policy),
            Description="Permissions for diabetes scraper Lambda"
        )
        
        iam_client.attach_role_policy(
            RoleName=role_name,
            PolicyArn=policy_response['Policy']['Arn']
        )
        
        print(f"✅ IAM role created: {role_name}")
        
        # Wait for role to be available
        print("⏳ Waiting for IAM role to be available...")
        time.sleep(10)
        
        return role_response['Role']['Arn']
        
    except iam_client.exceptions.EntityAlreadyExistsException:
        # Role already exists
        role_response = iam_client.get_role(RoleName=role_name)
        print(f"ℹ️  Using existing IAM role: {role_name}")
        return role_response['Role']['Arn']
        
    except Exception as e:
        print(f"❌ Error creating IAM role: {e}")
        return None


def deploy_weekly_scraper(bucket_name: str):
    """Complete deployment of weekly diabetes scraper"""
    
    print("🚀 Deploying Weekly Diabetes Scraper (Simplified)")
    print("=" * 50)
    
    print(f"📦 Target S3 bucket: {bucket_name}")
    print("🔍 Using direct WebMD scraping (no external APIs required)")
    
    try:
        # Step 1: Create deployment package
        create_lambda_deployment_package()
        
        # Step 2: Create IAM role
        role_arn = create_iam_role_for_lambda()
        if not role_arn:
            return False
        
        # Step 3: Create/update Lambda function
        function_arn = create_lambda_function(
            bucket_name=bucket_name,
            role_arn=role_arn
        )
        
        # Step 4: Create EventBridge schedule
        schedule_name = create_eventbridge_schedule(bucket_name=bucket_name)
        
        if schedule_name:
            print("\n🎉 Deployment completed successfully!")
            print("=" * 50)
            print(f"📦 Lambda Function: diabetes-scraper-weekly")
            print(f"🗄️  S3 Bucket: {bucket_name}")
            print(f"📅 Schedule: Every 7 days")
            print(f"🔄 EventBridge Rule: {schedule_name}")
            print(f"📅 Next Run: {(datetime.now() + timedelta(days=7)).strftime('%Y-%m-%d %H:%M:%S')}")
            print("\n💡 The scraper will now run automatically every week!")
            print("💡 Check CloudWatch logs for execution details")
            print(f"💡 Scraped content will be stored in s3://{bucket_name}/diabetes-webmd-weekly/")
            
            return True
        else:
            print("❌ Deployment failed")
            return False
            
    except Exception as e:
        print(f"❌ Deployment error: {e}")
        return False


if __name__ == "__main__":
    import sys
    import os
    from dotenv import load_dotenv
    
    load_dotenv()
    
    # Try to get bucket name from environment variable first
    bucket_name = os.getenv('S3_BUCKET_NAME')
    
    if not bucket_name:
        if len(sys.argv) < 2:
            print("Usage: python deploy_weekly_scraper.py [bucket_name]")
            print("Or set S3_BUCKET_NAME environment variable")
            print("Example: python deploy_weekly_scraper.py mihc-diabetes-kb")
            sys.exit(1)
        bucket_name = sys.argv[1]
    else:
        print(f"Using bucket from environment: {bucket_name}")
    
    success = deploy_weekly_scraper(bucket_name)
    sys.exit(0 if success else 1)