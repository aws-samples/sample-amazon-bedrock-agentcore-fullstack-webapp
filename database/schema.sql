-- Medical Intelligent Healthcare Companion (MIHC) Database Schema
-- Simple Patient Database System for Healthcare Management

-- Enable UUID extension for generating unique identifiers
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create enum types for better data integrity
CREATE TYPE gender_type AS ENUM ('male', 'female', 'other', 'prefer_not_to_say');
CREATE TYPE blood_type AS ENUM ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'unknown');
CREATE TYPE appointment_status AS ENUM ('scheduled', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show');
CREATE TYPE severity_level AS ENUM ('low', 'medium', 'high', 'critical');

-- =====================================================
-- CORE PATIENT INFORMATION
-- =====================================================

-- Patients table - Core patient demographics and contact info
CREATE TABLE patients (
    patient_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    medical_record_number VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender gender_type,
    blood_type blood_type DEFAULT 'unknown',
    phone VARCHAR(20),
    email VARCHAR(255),
    emergency_contact_name VARCHAR(200),
    emergency_contact_phone VARCHAR(20),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'United States',
    insurance_provider VARCHAR(200),
    insurance_policy_number VARCHAR(100),
    primary_care_physician VARCHAR(200),
    allergies TEXT,
    medical_conditions TEXT,
    current_medications TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- MEDICAL RECORDS AND VISITS
-- =====================================================

-- Medical visits/encounters
CREATE TABLE medical_visits (
    visit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    visit_date TIMESTAMP WITH TIME ZONE NOT NULL,
    visit_type VARCHAR(100), -- 'routine_checkup', 'emergency', 'follow_up', 'consultation'
    chief_complaint TEXT,
    diagnosis TEXT,
    treatment_plan TEXT,
    notes TEXT,
    attending_physician VARCHAR(200),
    visit_duration_minutes INTEGER,
    follow_up_required BOOLEAN DEFAULT FALSE,
    follow_up_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Vital signs recorded during visits
CREATE TABLE vital_signs (
    vital_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    visit_id UUID NOT NULL REFERENCES medical_visits(visit_id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    systolic_bp INTEGER, -- mmHg
    diastolic_bp INTEGER, -- mmHg
    heart_rate INTEGER, -- bpm
    temperature DECIMAL(4,2), -- Fahrenheit
    respiratory_rate INTEGER, -- breaths per minute
    oxygen_saturation INTEGER, -- percentage
    weight DECIMAL(6,2), -- pounds
    height DECIMAL(5,2), -- inches
    bmi DECIMAL(4,2), -- calculated BMI
    pain_scale INTEGER CHECK (pain_scale >= 0 AND pain_scale <= 10),
    notes TEXT,
    recorded_by VARCHAR(200)
);

-- =====================================================
-- DIABETES-SPECIFIC TRACKING
-- =====================================================

-- Diabetes monitoring data
CREATE TABLE diabetes_monitoring (
    monitoring_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    visit_id UUID REFERENCES medical_visits(visit_id) ON DELETE SET NULL,
    measurement_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    glucose_level INTEGER, -- mg/dL
    glucose_test_type VARCHAR(50), -- 'fasting', 'random', 'post_meal', 'bedtime'
    hba1c DECIMAL(4,2), -- percentage
    insulin_dosage DECIMAL(6,2), -- units
    insulin_type VARCHAR(100),
    carb_intake INTEGER, -- grams
    exercise_minutes INTEGER,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- MEDICATIONS AND PRESCRIPTIONS
-- =====================================================

-- Medications prescribed to patients
CREATE TABLE prescriptions (
    prescription_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    visit_id UUID REFERENCES medical_visits(visit_id) ON DELETE SET NULL,
    medication_name VARCHAR(200) NOT NULL,
    dosage VARCHAR(100),
    frequency VARCHAR(100), -- 'once daily', 'twice daily', 'as needed'
    route VARCHAR(50), -- 'oral', 'injection', 'topical'
    start_date DATE NOT NULL,
    end_date DATE,
    quantity_prescribed INTEGER,
    refills_remaining INTEGER DEFAULT 0,
    prescribing_physician VARCHAR(200),
    pharmacy VARCHAR(200),
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- APPOINTMENTS AND SCHEDULING
-- =====================================================

-- Patient appointments
CREATE TABLE appointments (
    appointment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    appointment_date TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_minutes INTEGER DEFAULT 30,
    appointment_type VARCHAR(100), -- 'routine', 'follow_up', 'emergency', 'consultation'
    provider_name VARCHAR(200),
    department VARCHAR(100),
    status appointment_status DEFAULT 'scheduled',
    reason_for_visit TEXT,
    special_instructions TEXT,
    reminder_sent BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- LAB RESULTS AND TESTS
-- =====================================================

-- Laboratory test results
CREATE TABLE lab_results (
    lab_result_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    visit_id UUID REFERENCES medical_visits(visit_id) ON DELETE SET NULL,
    test_name VARCHAR(200) NOT NULL,
    test_category VARCHAR(100), -- 'blood', 'urine', 'imaging', 'biopsy'
    result_value VARCHAR(500),
    reference_range VARCHAR(200),
    unit_of_measure VARCHAR(50),
    is_abnormal BOOLEAN DEFAULT FALSE,
    severity severity_level,
    test_date DATE NOT NULL,
    result_date DATE,
    ordering_physician VARCHAR(200),
    lab_facility VARCHAR(200),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Indexes on frequently queried columns
CREATE INDEX idx_patients_mrn ON patients(medical_record_number);
CREATE INDEX idx_patients_name ON patients(last_name, first_name);
CREATE INDEX idx_patients_dob ON patients(date_of_birth);
CREATE INDEX idx_patients_active ON patients(is_active);

CREATE INDEX idx_medical_visits_patient ON medical_visits(patient_id);
CREATE INDEX idx_medical_visits_date ON medical_visits(visit_date);

CREATE INDEX idx_vital_signs_patient ON vital_signs(patient_id);
CREATE INDEX idx_vital_signs_visit ON vital_signs(visit_id);
CREATE INDEX idx_vital_signs_date ON vital_signs(recorded_at);

CREATE INDEX idx_diabetes_patient ON diabetes_monitoring(patient_id);
CREATE INDEX idx_diabetes_date ON diabetes_monitoring(measurement_date);

CREATE INDEX idx_prescriptions_patient ON prescriptions(patient_id);
CREATE INDEX idx_prescriptions_active ON prescriptions(is_active);

CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_appointments_date ON appointments(appointment_date);
CREATE INDEX idx_appointments_status ON appointments(status);

CREATE INDEX idx_lab_results_patient ON lab_results(patient_id);
CREATE INDEX idx_lab_results_date ON lab_results(test_date);
CREATE INDEX idx_lab_results_abnormal ON lab_results(is_abnormal);

-- =====================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =====================================================

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers to automatically update timestamps
CREATE TRIGGER update_patients_updated_at BEFORE UPDATE ON patients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_medical_visits_updated_at BEFORE UPDATE ON medical_visits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_prescriptions_updated_at BEFORE UPDATE ON prescriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================

-- View for patient summary with latest vital signs
CREATE VIEW patient_summary AS
SELECT 
    p.patient_id,
    p.medical_record_number,
    p.first_name,
    p.last_name,
    p.date_of_birth,
    EXTRACT(YEAR FROM AGE(p.date_of_birth)) as age,
    p.gender,
    p.blood_type,
    p.phone,
    p.email,
    p.primary_care_physician,
    p.allergies,
    p.medical_conditions,
    p.is_active,
    vs.systolic_bp,
    vs.diastolic_bp,
    vs.heart_rate,
    vs.weight,
    vs.height,
    vs.bmi,
    vs.recorded_at as last_vitals_date
FROM patients p
LEFT JOIN LATERAL (
    SELECT * FROM vital_signs v 
    WHERE v.patient_id = p.patient_id 
    ORDER BY v.recorded_at DESC 
    LIMIT 1
) vs ON true;

-- View for diabetes patients with latest glucose readings
CREATE VIEW diabetes_patients AS
SELECT 
    p.patient_id,
    p.medical_record_number,
    p.first_name,
    p.last_name,
    p.date_of_birth,
    EXTRACT(YEAR FROM AGE(p.date_of_birth)) as age,
    dm.glucose_level as latest_glucose,
    dm.hba1c as latest_hba1c,
    dm.measurement_date as last_measurement_date
FROM patients p
INNER JOIN LATERAL (
    SELECT * FROM diabetes_monitoring d 
    WHERE d.patient_id = p.patient_id 
    ORDER BY d.measurement_date DESC 
    LIMIT 1
) dm ON true
WHERE p.is_active = true;

-- =====================================================
-- SAMPLE DATA INSERTION
-- =====================================================

-- Insert sample patients
INSERT INTO patients (
    medical_record_number, first_name, last_name, date_of_birth, gender, 
    blood_type, phone, email, address_line1, city, state, zip_code,
    primary_care_physician, allergies, medical_conditions
) VALUES 
(
    'MRN001001', 'John', 'Smith', '1975-03-15', 'male', 
    'O+', '555-0101', 'john.smith@email.com', '123 Main St', 
    'Springfield', 'IL', '62701', 'Dr. Sarah Johnson', 
    'Penicillin', 'Type 2 Diabetes, Hypertension'
),
(
    'MRN001002', 'Maria', 'Garcia', '1982-07-22', 'female', 
    'A+', '555-0102', 'maria.garcia@email.com', '456 Oak Ave', 
    'Springfield', 'IL', '62702', 'Dr. Michael Chen', 
    'None known', 'Type 1 Diabetes'
),
(
    'MRN001003', 'Robert', 'Johnson', '1968-11-08', 'male', 
    'B+', '555-0103', 'robert.johnson@email.com', '789 Pine St', 
    'Springfield', 'IL', '62703', 'Dr. Sarah Johnson', 
    'Shellfish', 'Hypertension, High Cholesterol'
);

-- Insert sample medical visits
INSERT INTO medical_visits (
    patient_id, visit_date, visit_type, chief_complaint, 
    diagnosis, treatment_plan, attending_physician
) VALUES 
(
    (SELECT patient_id FROM patients WHERE medical_record_number = 'MRN001001'),
    '2024-10-20 10:00:00-05', 'routine_checkup', 'Annual physical exam',
    'Type 2 Diabetes - well controlled, Hypertension - stable',
    'Continue current medications, follow up in 3 months',
    'Dr. Sarah Johnson'
);

-- Insert sample vital signs
INSERT INTO vital_signs (
    visit_id, patient_id, systolic_bp, diastolic_bp, heart_rate, 
    temperature, weight, height, bmi, recorded_by
) VALUES 
(
    (SELECT visit_id FROM medical_visits ORDER BY created_at DESC LIMIT 1),
    (SELECT patient_id FROM patients WHERE medical_record_number = 'MRN001001'),
    128, 82, 72, 98.6, 185.5, 70, 26.6, 'Nurse Jennifer'
);

-- Insert sample diabetes monitoring data
INSERT INTO diabetes_monitoring (
    patient_id, glucose_level, glucose_test_type, hba1c, 
    insulin_dosage, insulin_type
) VALUES 
(
    (SELECT patient_id FROM patients WHERE medical_record_number = 'MRN001001'),
    145, 'fasting', 7.2, 25.0, 'Lantus'
),
(
    (SELECT patient_id FROM patients WHERE medical_record_number = 'MRN001002'),
    110, 'fasting', 6.8, 18.0, 'Humalog'
);

-- Grant permissions (adjust as needed for your application)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO your_app_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO your_app_user;