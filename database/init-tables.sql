-- Simple initialization script for MIHC database
-- This can be executed via RDS Data API

-- Create basic patients table
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
);

-- Create medical visits table
CREATE TABLE IF NOT EXISTS medical_visits (
    visit_id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(patient_id) ON DELETE CASCADE,
    visit_date TIMESTAMP NOT NULL,
    visit_type VARCHAR(100),
    chief_complaint TEXT,
    diagnosis TEXT,
    treatment_plan TEXT,
    attending_physician VARCHAR(200),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create vital signs table
CREATE TABLE IF NOT EXISTS vital_signs (
    vital_id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(patient_id) ON DELETE CASCADE,
    visit_id INTEGER REFERENCES medical_visits(visit_id) ON DELETE CASCADE,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    systolic_bp INTEGER,
    diastolic_bp INTEGER,
    heart_rate INTEGER,
    temperature DECIMAL(4,2),
    weight DECIMAL(6,2),
    height DECIMAL(5,2),
    bmi DECIMAL(4,2),
    recorded_by VARCHAR(200)
);

-- Create diabetes monitoring table
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
);

-- Create prescriptions table
CREATE TABLE IF NOT EXISTS prescriptions (
    prescription_id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(patient_id) ON DELETE CASCADE,
    medication_name VARCHAR(200) NOT NULL,
    dosage VARCHAR(100),
    frequency VARCHAR(100),
    start_date DATE NOT NULL,
    end_date DATE,
    prescribing_physician VARCHAR(200),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO patients (
    medical_record_number, first_name, last_name, date_of_birth, 
    gender, phone, email, primary_care_physician, medical_conditions
) VALUES 
(
    'MRN001001', 'John', 'Smith', '1975-03-15', 
    'male', '555-0101', 'john.smith@email.com', 
    'Dr. Sarah Johnson', 'Type 2 Diabetes, Hypertension'
),
(
    'MRN001002', 'Maria', 'Garcia', '1982-07-22', 
    'female', '555-0102', 'maria.garcia@email.com', 
    'Dr. Michael Chen', 'Type 1 Diabetes'
)
ON CONFLICT (medical_record_number) DO NOTHING;

-- Insert sample diabetes monitoring data
INSERT INTO diabetes_monitoring (
    patient_id, glucose_level, glucose_test_type, hba1c, insulin_dosage, insulin_type
) 
SELECT p.patient_id, 145, 'fasting', 7.2, 25.0, 'Lantus'
FROM patients p WHERE p.medical_record_number = 'MRN001001'
AND NOT EXISTS (SELECT 1 FROM diabetes_monitoring WHERE patient_id = p.patient_id);

INSERT INTO diabetes_monitoring (
    patient_id, glucose_level, glucose_test_type, hba1c, insulin_dosage, insulin_type
) 
SELECT p.patient_id, 110, 'fasting', 6.8, 18.0, 'Humalog'
FROM patients p WHERE p.medical_record_number = 'MRN001002'
AND NOT EXISTS (SELECT 1 FROM diabetes_monitoring WHERE patient_id = p.patient_id);