import json
import boto3
import logging
import os
from typing import Dict, Any

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
secrets_client = boto3.client('secretsmanager')
rds_data_client = boto3.client('rds-data')

def get_database_credentials():
    """Retrieve database credentials from AWS Secrets Manager."""
    try:
        secret_arn = os.environ.get('DB_SECRET_ARN')
        if not secret_arn:
            raise ValueError("DB_SECRET_ARN environment variable not set")
        
        response = secrets_client.get_secret_value(SecretId=secret_arn)
        secret = json.loads(response['SecretValue'])
        return secret
    except Exception as e:
        logger.error(f"Error retrieving database credentials: {str(e)}")
        raise



def list_tables():
    """List all tables in the database."""
    try:
        db_cluster_arn = os.environ.get('DB_CLUSTER_ARN')
        secret_arn = os.environ.get('DB_SECRET_ARN')
        database_name = os.environ.get('DB_NAME', 'medical_records')
        
        if not db_cluster_arn or not secret_arn:
            return {
                'status': 'error',
                'message': 'Missing required environment variables'
            }
        
        # Query to list all tables
        response = rds_data_client.execute_statement(
            resourceArn=db_cluster_arn,
            secretArn=secret_arn,
            database=database_name,
            sql="SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name"
        )
        
        # Parse the results
        tables = []
        if 'records' in response:
            for record in response['records']:
                if record and len(record) > 0:
                    table_name = record[0].get('stringValue', 'unknown')
                    tables.append(table_name)
        
        return {
            'status': 'success',
            'message': f'Found {len(tables)} tables in database "{database_name}"',
            'database': database_name,
            'tables': tables,
            'count': len(tables)
        }
        
    except Exception as e:
        logger.error(f"Error listing tables: {str(e)}")
        return {
            'status': 'error',
            'message': f'Error listing tables: {str(e)}',
            'error_type': type(e).__name__
        }



def get_patients():
    """Retrieve all patients from the database."""
    try:
        db_cluster_arn = os.environ.get('DB_CLUSTER_ARN')
        secret_arn = os.environ.get('DB_SECRET_ARN')
        database_name = os.environ.get('DB_NAME', 'medical_records')
        
        if not db_cluster_arn or not secret_arn:
            return {
                'status': 'error',
                'message': 'Missing required environment variables'
            }
        
        # Query to get all patients with correct field names
        response = rds_data_client.execute_statement(
            resourceArn=db_cluster_arn,
            secretArn=secret_arn,
            database=database_name,
            sql="SELECT patient_id, medical_record_number, first_name, last_name, middle_name, date_of_birth, gender, phone_primary, email, city, state FROM patients WHERE active = true ORDER BY last_name, first_name"
        )
        
        # Parse the results
        patients = []
        if 'records' in response:
            for record in response['records']:
                patient = {}
                fields = ['patient_id', 'medical_record_number', 'first_name', 'last_name', 'middle_name', 'date_of_birth', 'gender', 'phone_primary', 'email', 'city', 'state']
                for i, field in enumerate(fields):
                    if i < len(record):
                        value = record[i]
                        if 'stringValue' in value:
                            patient[field] = value['stringValue']
                        elif 'longValue' in value:
                            patient[field] = value['longValue']
                        elif 'isNull' in value:
                            patient[field] = None
                        else:
                            patient[field] = str(value)
                patients.append(patient)
        
        return {
            'status': 'success',
            'message': f'Retrieved {len(patients)} patients',
            'patients': patients,
            'count': len(patients)
        }
        
    except Exception as e:
        logger.error(f"Error retrieving patients: {str(e)}")
        return {
            'status': 'error',
            'message': f'Error retrieving patients: {str(e)}',
            'error_type': type(e).__name__
        }

def get_patient_by_id(patient_id=None, medical_record_number=None):
    """Retrieve a specific patient by patient_id or medical_record_number."""
    try:
        db_cluster_arn = os.environ.get('DB_CLUSTER_ARN')
        secret_arn = os.environ.get('DB_SECRET_ARN')
        database_name = os.environ.get('DB_NAME', 'medical_records')
        
        if not db_cluster_arn or not secret_arn:
            return {
                'status': 'error',
                'message': 'Missing required environment variables'
            }
        
        if not patient_id and not medical_record_number:
            return {
                'status': 'error',
                'message': 'Either patient_id or medical_record_number is required'
            }
        
        # Build query based on provided identifier
        if patient_id:
            sql_query = """
                SELECT patient_id, medical_record_number, first_name, last_name, middle_name, 
                       date_of_birth, gender, phone_primary, phone_secondary, email,
                       address_line1, address_line2, city, state, zip_code, country,
                       emergency_contact_name, emergency_contact_phone, emergency_contact_relationship,
                       insurance_provider, insurance_policy_number, insurance_group_number,
                       active, created_at, updated_at
                FROM patients 
                WHERE patient_id = :patient_id::uuid AND active = true
            """
            parameters = [{'name': 'patient_id', 'value': {'stringValue': str(patient_id)}}]
        else:
            sql_query = """
                SELECT patient_id, medical_record_number, first_name, last_name, middle_name, 
                       date_of_birth, gender, phone_primary, phone_secondary, email,
                       address_line1, address_line2, city, state, zip_code, country,
                       emergency_contact_name, emergency_contact_phone, emergency_contact_relationship,
                       insurance_provider, insurance_policy_number, insurance_group_number,
                       active, created_at, updated_at
                FROM patients 
                WHERE medical_record_number = :medical_record_number AND active = true
            """
            parameters = [{'name': 'medical_record_number', 'value': {'stringValue': medical_record_number}}]
        
        # Execute query
        response = rds_data_client.execute_statement(
            resourceArn=db_cluster_arn,
            secretArn=secret_arn,
            database=database_name,
            sql=sql_query,
            parameters=parameters
        )
        
        # Parse the results
        if 'records' in response and len(response['records']) > 0:
            record = response['records'][0]
            patient = {}
            fields = [
                'patient_id', 'medical_record_number', 'first_name', 'last_name', 'middle_name',
                'date_of_birth', 'gender', 'phone_primary', 'phone_secondary', 'email',
                'address_line1', 'address_line2', 'city', 'state', 'zip_code', 'country',
                'emergency_contact_name', 'emergency_contact_phone', 'emergency_contact_relationship',
                'insurance_provider', 'insurance_policy_number', 'insurance_group_number',
                'active', 'created_at', 'updated_at'
            ]
            
            for i, field in enumerate(fields):
                if i < len(record):
                    value = record[i]
                    if 'stringValue' in value:
                        patient[field] = value['stringValue']
                    elif 'longValue' in value:
                        patient[field] = value['longValue']
                    elif 'booleanValue' in value:
                        patient[field] = value['booleanValue']
                    elif 'isNull' in value:
                        patient[field] = None
                    else:
                        patient[field] = str(value)
            
            return {
                'status': 'success',
                'message': 'Patient retrieved successfully',
                'patient': patient
            }
        else:
            return {
                'status': 'not_found',
                'message': 'Patient not found',
                'patient': None
            }
        
    except Exception as e:
        logger.error(f"Error retrieving patient: {str(e)}")
        return {
            'status': 'error',
            'message': f'Error retrieving patient: {str(e)}',
            'error_type': type(e).__name__
        }

def test_database_connection():
    """Test database connectivity using RDS Data API."""
    try:
        # Get database info from environment
        db_cluster_arn = os.environ.get('DB_CLUSTER_ARN')
        secret_arn = os.environ.get('DB_SECRET_ARN')
        database_name = os.environ.get('DB_NAME', 'medical_records')
        
        if not db_cluster_arn:
            # If no cluster ARN, try basic secret retrieval test
            credentials = get_database_credentials()
            return {
                'status': 'partial_success',
                'message': 'Successfully retrieved database credentials',
                'has_credentials': True,
                'username': credentials.get('username', 'unknown'),
                'note': 'DB_CLUSTER_ARN not set - cannot test actual connection'
            }
        
        # Test actual database connection using RDS Data API
        response = rds_data_client.execute_statement(
            resourceArn=db_cluster_arn,
            secretArn=secret_arn,
            database=database_name,
            sql="SELECT 1 as test_connection"
        )
        
        return {
            'status': 'success',
            'message': 'Database connection successful',
            'query_result': response.get('records', []),
            'database': database_name
        }
        
    except Exception as e:
        logger.error(f"Database connection test failed: {str(e)}")
        return {
            'status': 'error',
            'message': f'Database connection failed: {str(e)}',
            'error_type': type(e).__name__
        }

def lambda_handler(event: Dict[str, Any], context) -> Dict[str, Any]:
    """
    Lambda function for database operations with connectivity testing
    """
    
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Add CORS headers
        headers = {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
        }
        
        # Handle preflight OPTIONS requests
        if event.get('httpMethod') == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({'message': 'CORS preflight'})
            }
        
        # Database connectivity test
        if event.get('action') == 'test_db_connection':
            db_test_result = test_database_connection()
            return {
                'statusCode': 200 if db_test_result['status'] != 'error' else 500,
                'headers': headers,
                'body': json.dumps(db_test_result)
            }
        

        
        # Get patients list
        if event.get('action') == 'get_patients':
            patients_result = get_patients()
            return {
                'statusCode': 200 if patients_result['status'] != 'error' else 500,
                'headers': headers,
                'body': json.dumps(patients_result)
            }
        
        # Get specific patient by ID
        if event.get('action') == 'get_patient_by_id':
            patient_id = event.get('patient_id')
            medical_record_number = event.get('medical_record_number')
            
            # Also check in pathParameters for API Gateway integration
            if not patient_id and not medical_record_number:
                path_params = event.get('pathParameters', {})
                if path_params:
                    patient_id = path_params.get('patient_id') or path_params.get('id')
                    medical_record_number = path_params.get('medical_record_number') or path_params.get('mrn')
            
            # Also check in queryStringParameters
            if not patient_id and not medical_record_number:
                query_params = event.get('queryStringParameters', {})
                if query_params:
                    patient_id = query_params.get('patient_id') or query_params.get('id')
                    medical_record_number = query_params.get('medical_record_number') or query_params.get('mrn')
            
            patient_result = get_patient_by_id(patient_id=patient_id, medical_record_number=medical_record_number)
            status_code = 200
            if patient_result['status'] == 'error':
                status_code = 500
            elif patient_result['status'] == 'not_found':
                status_code = 404
            
            return {
                'statusCode': status_code,
                'headers': headers,
                'body': json.dumps(patient_result)
            }
        

        
        # List all tables in the database
        if event.get('action') == 'list_tables':
            tables_result = list_tables()
            return {
                'statusCode': 200 if tables_result['status'] != 'error' else 500,
                'headers': headers,
                'body': json.dumps(tables_result)
            }
        
        # Environment info check
        if event.get('action') == 'health_check':
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({
                    'message': 'Database handler is healthy',
                    'environment': {
                        'db_host': os.environ.get('DB_HOST', 'not_set'),
                        'db_name': os.environ.get('DB_NAME', 'not_set'),
                        'db_port': os.environ.get('DB_PORT', 'not_set'),
                        'db_secret_arn': os.environ.get('DB_SECRET_ARN', 'not_set'),
                        'db_cluster_arn': os.environ.get('DB_CLUSTER_ARN', 'not_set'),
                        'has_secret': bool(os.environ.get('DB_SECRET_ARN')),
                        'has_cluster_arn': bool(os.environ.get('DB_CLUSTER_ARN'))
                    }
                })
            }
        
        # Default response for unhandled requests
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'message': 'Database handler ready',
                'available_actions': ['health_check', 'test_db_connection', 'get_patients', 'get_patient_by_id', 'list_tables'],
                'event_keys': list(event.keys()),
                'method': event.get('httpMethod', 'unknown'),
                'resource': event.get('resource', 'unknown')
            })
        }
        
    except Exception as e:
        logger.error(f"Error in lambda_handler: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }