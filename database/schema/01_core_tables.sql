-- HIPAA-Compliant Medical Data Model
-- Core Tables for Medical Records System

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Audit trail function for HIPAA compliance
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Patients table - Core patient information
CREATE TABLE patients (
    patient_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(), --Should be cognito user pool id
    medical_record_number VARCHAR(50) UNIQUE NOT NULL,
    
    -- Demographics
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    date_of_birth DATE NOT NULL,
    gender VARCHAR(20),
    ssn_encrypted TEXT, -- Encrypted SSN for HIPAA compliance
    
    -- Contact Information
    phone_primary VARCHAR(20),
    phone_secondary VARCHAR(20),
    email VARCHAR(255),
    
    -- Address
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'USA',
    
    -- Emergency Contact
    emergency_contact_name VARCHAR(200),
    emergency_contact_phone VARCHAR(20),
    emergency_contact_relationship VARCHAR(50),
    
    -- Insurance Information
    insurance_provider VARCHAR(200),
    insurance_policy_number VARCHAR(100),
    insurance_group_number VARCHAR(100),
    
    -- System fields
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Healthcare Providers table
CREATE TABLE healthcare_providers (
    provider_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    npi_number VARCHAR(10) UNIQUE, -- National Provider Identifier
    
    -- Provider Information
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    title VARCHAR(50),
    specialty VARCHAR(100),
    license_number VARCHAR(50),
    license_state VARCHAR(50),
    
    -- Contact Information
    phone VARCHAR(20),
    email VARCHAR(255),
    
    -- System fields
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Medical Facilities table
CREATE TABLE medical_facilities (
    facility_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    facility_name VARCHAR(200) NOT NULL,
    facility_type VARCHAR(50), -- Hospital, Clinic, Lab, etc.
    
    -- Address
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),
    
    -- Contact
    phone VARCHAR(20),
    fax VARCHAR(20),
    
    -- System fields
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Medical Encounters/Visits
CREATE TABLE medical_encounters (
    encounter_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id),
    provider_id UUID NOT NULL REFERENCES healthcare_providers(provider_id),
    facility_id UUID REFERENCES medical_facilities(facility_id),
    
    -- Encounter Details
    encounter_type VARCHAR(50) NOT NULL, -- Inpatient, Outpatient, Emergency, etc.
    encounter_date TIMESTAMP WITH TIME ZONE NOT NULL,
    discharge_date TIMESTAMP WITH TIME ZONE,
    
    -- Clinical Information
    chief_complaint TEXT,
    diagnosis_primary TEXT,
    diagnosis_secondary TEXT[],
    
    -- Status
    encounter_status VARCHAR(50) DEFAULT 'Active', -- Active, Completed, Cancelled
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Create triggers for updated_at timestamps
CREATE TRIGGER update_patients_modtime BEFORE UPDATE ON patients FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_healthcare_providers_modtime BEFORE UPDATE ON healthcare_providers FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_medical_facilities_modtime BEFORE UPDATE ON medical_facilities FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_medical_encounters_modtime BEFORE UPDATE ON medical_encounters FOR EACH ROW EXECUTE FUNCTION update_modified_column();

-- Indexes for performance
CREATE INDEX idx_patients_mrn ON patients(medical_record_number);
CREATE INDEX idx_patients_name ON patients(last_name, first_name);
CREATE INDEX idx_patients_dob ON patients(date_of_birth);
CREATE INDEX idx_providers_npi ON healthcare_providers(npi_number);
CREATE INDEX idx_encounters_patient ON medical_encounters(patient_id);
CREATE INDEX idx_encounters_provider ON medical_encounters(provider_id);
CREATE INDEX idx_encounters_date ON medical_encounters(encounter_date);