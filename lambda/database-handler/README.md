# Database Handler Lambda Function

This Lambda function provides database operations for the medical records system, specifically designed for diabetes patient management.

## Features

- **Patient Management**: Create and retrieve patient records
- **Diabetes Data**: Store and retrieve diabetes-related measurements
- **Security**: Uses AWS Secrets Manager for database credentials
- **Database**: PostgreSQL with SSL/TLS encryption
- **CORS Support**: Handles cross-origin requests for web frontend

## Database Schema

### Patients Table
- `patient_id` (Primary Key)
- `first_name`, `last_name`
- `date_of_birth`, `gender`
- `phone`, `email`, `address`
- `created_at`, `updated_at`

### Medical Records Table
- `record_id` (Primary Key)
- `patient_id` (Foreign Key)
- `diagnosis`, `treatment`, `medications`, `notes`
- `record_date`
- `created_at`, `updated_at`

### Diabetes Data Table
- `data_id` (Primary Key)
- `patient_id` (Foreign Key)
- `glucose_level`, `hba1c`
- `blood_pressure_systolic`, `blood_pressure_diastolic`
- `weight`, `height`, `bmi`
- `measurement_date`
- `created_at`

## API Endpoints

### Initialize Database
- **Action**: `wiz_ehr`
- **Description**: Creates database tables if they don't exist

### Patients
- **GET /patients**: Retrieve all patients
- **POST /patients**: Create a new patient

### Diabetes Data
- **GET /diabetes-data**: Retrieve all diabetes data
- **GET /diabetes-data/{patient_id}**: Retrieve diabetes data for specific patient
- **POST /diabetes-data**: Create new diabetes measurement

## Environment Variables

- `DB_HOST`: Database hostname
- `DB_PORT`: Database port (usually 5432)
- `DB_NAME`: Database name
- `DB_SECRET_ARN`: ARN of the AWS Secrets Manager secret containing database credentials

## Dependencies

- `psycopg2-binary`: PostgreSQL adapter for Python
- `boto3`: AWS SDK for Python
- `botocore`: Low-level AWS service access

## Testing

Use the `test_local.py` script to test the Lambda function locally:

```bash
# Set environment variables
export DB_HOST=your-db-host
export DB_PORT=5432
export DB_NAME=medical_records
export DB_SECRET_ARN=arn:aws:secretsmanager:region:account:secret:name

# Run tests
python test_local.py
```

## Deployment

This Lambda function is deployed via AWS CDK as part of the MIHC stack. The CDK stack handles:

- VPC configuration
- Security groups
- IAM permissions
- Environment variables
- Database connectivity

## Security Features

- SSL/TLS encryption for database connections
- AWS Secrets Manager for credential management
- VPC isolation
- Security group restrictions
- KMS encryption for secrets
- Input validation and error handling

## Error Handling

The function includes comprehensive error handling:
- Database connection errors
- Query execution errors
- Invalid input validation
- AWS service errors
- Proper HTTP status codes and error messages