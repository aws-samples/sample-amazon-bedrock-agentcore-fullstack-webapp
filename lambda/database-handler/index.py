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

def initialize_database_tables():
    """Initialize database tables with schema."""
    try:
        db_cluster_arn = os.environ.get('DB_CLUSTER_ARN')
        secret_arn = os.environ.get('DB_SECRET_ARN')
        database_name = os.environ.get('DB_NAME', 'medical_records')
        
        if not db_cluster_arn or not secret_arn:
            return {
                'status': 'error',
                'message': 'Missing required environment variables (DB_CLUSTER_ARN or DB_SECRET_ARN)'
            }
        
        # SQL commands to create tables
        init_commands = [
            # Create patients table
            """
            CREATE TABLE IF NOT EXISTS patients (
                patient_id SERIAL PRIMARY KEY,
                medical_record_number VARCHAR(20) UNIQUE NOT NULL,
                first_name VARCHAR(100) NOT NULL,
                last_name VARCHAR(100) NOT NULL,
                date_of_birth DATE NOT NULL,
                gender VARCHAR(20),
                phone VARCHAR(20),
                email VARCHAR(255),
                address TEXT,
                primary_care_physician VARCHAR(200),
                allergies TEXT,
                medical_conditions TEXT,
                is_active BOOLEAN DEFAULT TRUE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
            """,
            
            # Create diabetes monitoring table
            """
            CREATE TABLE IF NOT EXISTS diabetes_monitoring (
                monitoring_id SERIAL PRIMARY KEY,
                patient_id INTEGER REFERENCES patients(patient_id) ON DELETE CASCADE,
                measurement_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                glucose_level INTEGER,
                glucose_test_type VARCHAR(50),
                hba1c DECIMAL(4,2),
                insulin_dosage DECIMAL(6,2),
                insulin_type VARCHAR(100),
                notes TEXT
            )
            """,
            
            # Insert sample patient
            """
            INSERT INTO patients (
                medical_record_number, first_name, last_name, date_of_birth, 
                gender, phone, email, primary_care_physician, medical_conditions
            ) VALUES 
            (
                'MRN001001', 'John', 'Smith', '1975-03-15', 
                'male', '555-0101', 'john.smith@email.com', 
                'Dr. Sarah Johnson', 'Type 2 Diabetes, Hypertension'
            )
            ON CONFLICT (medical_record_number) DO NOTHING
            """
        ]
        
        results = []
        for i, sql_command in enumerate(init_commands):
            try:
                response = rds_data_client.execute_statement(
                    resourceArn=db_cluster_arn,
                    secretArn=secret_arn,
                    database=database_name,
                    sql=sql_command
                )
                results.append(f"Command {i+1}: Success")
            except Exception as cmd_error:
                results.append(f"Command {i+1}: Error - {str(cmd_error)}")
        
        return {
            'status': 'success',
            'message': 'Database initialization completed',
            'results': results,
            'tables_created': ['patients', 'diabetes_monitoring']
        }
        
    except Exception as e:
        logger.error(f"Database initialization failed: {str(e)}")
        return {
            'status': 'error',
            'message': f'Database initialization failed: {str(e)}',
            'error_type': type(e).__name__
        }

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

def add_sample_patients():
    """Add additional sample patients to the database."""
    try:
        db_cluster_arn = os.environ.get('DB_CLUSTER_ARN')
        secret_arn = os.environ.get('DB_SECRET_ARN')
        database_name = os.environ.get('DB_NAME', 'medical_records')
        
        if not db_cluster_arn or not secret_arn:
            return {
                'status': 'error',
                'message': 'Missing required environment variables'
            }
        
        # Additional sample patients
        sample_patients = [
            """
            INSERT INTO patients (
                medical_record_number, first_name, last_name, date_of_birth, 
                gender, phone, email, primary_care_physician, medical_conditions
            ) VALUES 
            (
                'MRN001002', 'Maria', 'Garcia', '1982-07-22', 
                'female', '555-0102', 'maria.garcia@email.com', 
                'Dr. Michael Chen', 'Type 1 Diabetes'
            )
            ON CONFLICT (medical_record_number) DO NOTHING
            """,
            """
            INSERT INTO patients (
                medical_record_number, first_name, last_name, date_of_birth, 
                gender, phone, email, primary_care_physician, medical_conditions
            ) VALUES 
            (
                'MRN001003', 'Robert', 'Johnson', '1968-11-08', 
                'male', '555-0103', 'robert.johnson@email.com', 
                'Dr. Sarah Johnson', 'Hypertension, High Cholesterol'
            )
            ON CONFLICT (medical_record_number) DO NOTHING
            """,
            """
            INSERT INTO patients (
                medical_record_number, first_name, last_name, date_of_birth, 
                gender, phone, email, primary_care_physician, medical_conditions
            ) VALUES 
            (
                'MRN001004', 'Emily', 'Davis', '1990-05-14', 
                'female', '555-0104', 'emily.davis@email.com', 
                'Dr. Lisa Wong', 'Gestational Diabetes'
            )
            ON CONFLICT (medical_record_number) DO NOTHING
            """
        ]
        
        results = []
        for i, sql_command in enumerate(sample_patients):
            try:
                response = rds_data_client.execute_statement(
                    resourceArn=db_cluster_arn,
                    secretArn=secret_arn,
                    database=database_name,
                    sql=sql_command
                )
                results.append(f"Patient {i+1}: Added successfully")
            except Exception as cmd_error:
                results.append(f"Patient {i+1}: {str(cmd_error)}")
        
        return {
            'status': 'success',
            'message': 'Sample patients added',
            'results': results
        }
        
    except Exception as e:
        logger.error(f"Error adding sample patients: {str(e)}")
        return {
            'status': 'error',
            'message': f'Error adding sample patients: {str(e)}',
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
        
        # Query to get all patients
        response = rds_data_client.execute_statement(
            resourceArn=db_cluster_arn,
            secretArn=secret_arn,
            database=database_name,
            sql="SELECT patient_id, medical_record_number, first_name, last_name, date_of_birth, gender, phone, email, medical_conditions FROM patients WHERE is_active = true ORDER BY last_name, first_name"
        )
        
        # Parse the results
        patients = []
        if 'records' in response:
            for record in response['records']:
                patient = {}
                fields = ['patient_id', 'medical_record_number', 'first_name', 'last_name', 'date_of_birth', 'gender', 'phone', 'email', 'medical_conditions']
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
        
        # Initialize database tables
        if event.get('action') == 'init_database':
            init_result = initialize_database_tables()
            return {
                'statusCode': 200 if init_result['status'] != 'error' else 500,
                'headers': headers,
                'body': json.dumps(init_result)
            }
        
        # Get patients list
        if event.get('action') == 'get_patients':
            patients_result = get_patients()
            return {
                'statusCode': 200 if patients_result['status'] != 'error' else 500,
                'headers': headers,
                'body': json.dumps(patients_result)
            }
        
        # Add more sample patients
        if event.get('action') == 'add_sample_patients':
            sample_result = add_sample_patients()
            return {
                'statusCode': 200 if sample_result['status'] != 'error' else 500,
                'headers': headers,
                'body': json.dumps(sample_result)
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
                'available_actions': ['health_check', 'test_db_connection', 'init_database', 'get_patients'],
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