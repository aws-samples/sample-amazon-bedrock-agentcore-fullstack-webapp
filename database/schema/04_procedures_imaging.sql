-- Medical Procedures and Imaging Tables
-- Procedures, imaging studies, and clinical documents

-- Medical Procedures
CREATE TABLE medical_procedures (
    procedure_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id),
    encounter_id UUID REFERENCES medical_encounters(encounter_id),
    performed_by UUID REFERENCES healthcare_providers(provider_id),
    facility_id UUID REFERENCES medical_facilities(facility_id),
    
    -- Procedure Details
    procedure_name TEXT NOT NULL,
    cpt_code VARCHAR(10), -- Current Procedural Terminology code
    icd10_procedure_code VARCHAR(10),
    procedure_category TEXT, -- Surgical, Diagnostic, Therapeutic, etc.
    
    -- Scheduling and Timeline
    scheduled_date TIMESTAMP WITH TIME ZONE,
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER,
    
    -- Clinical Information
    indication TEXT, -- Why the procedure was performed
    technique_used TEXT,
    findings TEXT,
    complications TEXT,
    
    -- Anesthesia
    anesthesia_type TEXT, -- Local, General, Sedation, etc.
    anesthesia_provider UUID REFERENCES healthcare_providers(provider_id),
    
    -- Status and Results
    procedure_status VARCHAR(50) DEFAULT 'Scheduled', -- Scheduled, In Progress, Completed, Cancelled
    outcome TEXT, -- Successful, Complicated, etc.
    
    -- Post-procedure
    recovery_notes TEXT,
    discharge_instructions TEXT,
    follow_up_required BOOLEAN DEFAULT FALSE,
    follow_up_date DATE,
    
    -- Billing
    billable BOOLEAN DEFAULT TRUE,
    insurance_authorized BOOLEAN DEFAULT FALSE,
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Imaging Studies
CREATE TABLE imaging_studies (
    study_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id),
    encounter_id UUID REFERENCES medical_encounters(encounter_id),
    ordered_by UUID REFERENCES healthcare_providers(provider_id),
    performed_by UUID REFERENCES healthcare_providers(provider_id),
    facility_id UUID REFERENCES medical_facilities(facility_id),
    
    -- Study Details
    study_type TEXT NOT NULL, -- X-Ray, CT, MRI, Ultrasound, etc.
    body_part TEXT, -- Chest, Abdomen, Head, etc.
    study_description TEXT,
    
    -- DICOM Information
    study_instance_uid VARCHAR(255) UNIQUE,
    accession_number VARCHAR(50),
    modality VARCHAR(10), -- CR, CT, MR, US, etc.
    
    -- Scheduling and Timeline
    order_date DATE NOT NULL,
    scheduled_date TIMESTAMP WITH TIME ZONE,
    study_date TIMESTAMP WITH TIME ZONE,
    
    -- Clinical Information
    clinical_indication TEXT,
    contrast_used BOOLEAN DEFAULT FALSE,
    contrast_type TEXT,
    contrast_amount VARCHAR(50),
    
    -- Technical Parameters
    technique TEXT,
    image_count INTEGER,
    radiation_dose TEXT, -- For CT, X-Ray studies
    
    -- Results
    preliminary_report TEXT,
    final_report TEXT,
    impression TEXT,
    recommendations TEXT,
    
    -- Radiologist Information
    interpreting_radiologist UUID REFERENCES healthcare_providers(provider_id),
    report_date TIMESTAMP WITH TIME ZONE,
    
    -- Status
    study_status VARCHAR(50) DEFAULT 'Ordered', -- Ordered, Scheduled, In Progress, Completed, Cancelled
    report_status VARCHAR(50) DEFAULT 'Pending', -- Pending, Preliminary, Final
    
    -- Critical Results
    critical_result BOOLEAN DEFAULT FALSE,
    critical_result_notified BOOLEAN DEFAULT FALSE,
    critical_result_notification_time TIMESTAMP WITH TIME ZONE,
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Clinical Documents
CREATE TABLE clinical_documents (
    document_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id),
    encounter_id UUID REFERENCES medical_encounters(encounter_id),
    created_by_provider UUID REFERENCES healthcare_providers(provider_id),
    
    -- Document Details
    document_type TEXT NOT NULL, -- Progress Note, Discharge Summary, Consultation, etc.
    document_title TEXT,
    document_category TEXT, -- Clinical, Administrative, Legal, etc.
    
    -- Content
    document_content TEXT NOT NULL,
    template_used TEXT,
    
    -- Signatures and Authentication
    signed BOOLEAN DEFAULT FALSE,
    signed_by UUID REFERENCES healthcare_providers(provider_id),
    signature_timestamp TIMESTAMP WITH TIME ZONE,
    electronic_signature TEXT, -- Encrypted signature
    
    -- Document Status
    document_status VARCHAR(50) DEFAULT 'Draft', -- Draft, Final, Amended, Deleted
    version_number INTEGER DEFAULT 1,
    parent_document_id UUID REFERENCES clinical_documents(document_id), -- For amendments
    
    -- Access Control
    confidentiality_level VARCHAR(50) DEFAULT 'Normal', -- Normal, Restricted, Confidential
    access_restrictions TEXT,
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Appointments and Scheduling
CREATE TABLE appointments (
    appointment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id),
    provider_id UUID NOT NULL REFERENCES healthcare_providers(provider_id),
    facility_id UUID REFERENCES medical_facilities(facility_id),
    
    -- Appointment Details
    appointment_type TEXT NOT NULL, -- Office Visit, Follow-up, Procedure, etc.
    appointment_reason TEXT,
    
    -- Scheduling
    scheduled_date DATE NOT NULL,
    scheduled_time TIME NOT NULL,
    duration_minutes INTEGER DEFAULT 30,
    
    -- Status
    appointment_status VARCHAR(50) DEFAULT 'Scheduled', -- Scheduled, Confirmed, Checked In, Completed, Cancelled, No Show
    
    -- Check-in/Check-out
    check_in_time TIMESTAMP WITH TIME ZONE,
    check_out_time TIMESTAMP WITH TIME ZONE,
    
    -- Notes
    scheduling_notes TEXT,
    provider_notes TEXT,
    
    -- Reminders
    reminder_sent BOOLEAN DEFAULT FALSE,
    reminder_sent_date TIMESTAMP WITH TIME ZONE,
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Create triggers for updated_at timestamps
CREATE TRIGGER update_medical_procedures_modtime BEFORE UPDATE ON medical_procedures FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_imaging_studies_modtime BEFORE UPDATE ON imaging_studies FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_clinical_documents_modtime BEFORE UPDATE ON clinical_documents FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_appointments_modtime BEFORE UPDATE ON appointments FOR EACH ROW EXECUTE FUNCTION update_modified_column();

-- Indexes for performance
CREATE INDEX idx_procedures_patient ON medical_procedures(patient_id);
CREATE INDEX idx_procedures_provider ON medical_procedures(performed_by);
CREATE INDEX idx_procedures_date ON medical_procedures(scheduled_date);
CREATE INDEX idx_procedures_cpt ON medical_procedures(cpt_code);

CREATE INDEX idx_imaging_patient ON imaging_studies(patient_id);
CREATE INDEX idx_imaging_provider ON imaging_studies(ordered_by);
CREATE INDEX idx_imaging_date ON imaging_studies(study_date);
CREATE INDEX idx_imaging_modality ON imaging_studies(modality);
CREATE INDEX idx_imaging_status ON imaging_studies(study_status);

CREATE INDEX idx_documents_patient ON clinical_documents(patient_id);
CREATE INDEX idx_documents_provider ON clinical_documents(created_by_provider);
CREATE INDEX idx_documents_type ON clinical_documents(document_type);
CREATE INDEX idx_documents_status ON clinical_documents(document_status);

CREATE INDEX idx_appointments_patient ON appointments(patient_id);
CREATE INDEX idx_appointments_provider ON appointments(provider_id);
CREATE INDEX idx_appointments_date ON appointments(scheduled_date);
CREATE INDEX idx_appointments_status ON appointments(appointment_status);