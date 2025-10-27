#!/usr/bin/env python3
"""
Local test script for the database handler Lambda function.
This script simulates Lambda events for testing purposes.
"""

import json
import os
from index import lambda_handler

def test_wiz_ehr():
    """Test database initialization."""
    event = {
        'action': 'wiz_ehr'
    }
    
    print("Testing database initialization...")
    response = lambda_handler(event, None)
    print(f"Response: {json.dumps(response, indent=2)}")
    return response

def test_create_patient():
    """Test patient creation."""
    event = {
        'httpMethod': 'POST',
        'resource': '/patients',
        'body': json.dumps({
            'first_name': 'John',
            'last_name': 'Doe',
            'date_of_birth': '1980-01-15',
            'gender': 'Male',
            'phone': '+1-555-0123',
            'email': 'john.doe@example.com',
            'address': '123 Main St, Anytown, USA'
        })
    }
    
    print("\nTesting patient creation...")
    response = lambda_handler(event, None)
    print(f"Response: {json.dumps(response, indent=2)}")
    return response

def test_get_patients():
    """Test getting all patients."""
    event = {
        'httpMethod': 'GET',
        'resource': '/patients'
    }
    
    print("\nTesting get patients...")
    response = lambda_handler(event, None)
    print(f"Response: {json.dumps(response, indent=2)}")
    return response

def test_create_diabetes_data():
    """Test diabetes data creation."""
    event = {
        'httpMethod': 'POST',
        'resource': '/diabetes-data',
        'body': json.dumps({
            'patient_id': 1,
            'glucose_level': 120.5,
            'hba1c': 6.8,
            'blood_pressure_systolic': 130,
            'blood_pressure_diastolic': 80,
            'weight': 75.5,
            'height': 175.0,
            'bmi': 24.6,
            'measurement_date': '2024-01-15'
        })
    }
    
    print("\nTesting diabetes data creation...")
    response = lambda_handler(event, None)
    print(f"Response: {json.dumps(response, indent=2)}")
    return response

def test_get_diabetes_data():
    """Test getting diabetes data."""
    event = {
        'httpMethod': 'GET',
        'resource': '/diabetes-data'
    }
    
    print("\nTesting get diabetes data...")
    response = lambda_handler(event, None)
    print(f"Response: {json.dumps(response, indent=2)}")
    return response

if __name__ == "__main__":
    print("=== Database Handler Lambda Function Tests ===")
    print("Note: These tests require proper AWS credentials and environment variables.")
    print("Set the following environment variables before running:")
    print("- DB_HOST")
    print("- DB_PORT") 
    print("- DB_NAME")
    print("- DB_SECRET_ARN")
    print()
    
    # Check if environment variables are set
    required_vars = ['DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_SECRET_ARN']
    missing_vars = [var for var in required_vars if not os.environ.get(var)]
    
    if missing_vars:
        print(f"Missing environment variables: {', '.join(missing_vars)}")
        print("Please set these variables before running tests.")
        exit(1)
    
    try:
        # Run tests in sequence
        test_wiz_ehr()
        test_create_patient()
        test_get_patients()
        test_create_diabetes_data()
        test_get_diabetes_data()
        
        print("\n=== All tests completed ===")
        
    except Exception as e:
        print(f"Test failed with error: {str(e)}")
        exit(1)