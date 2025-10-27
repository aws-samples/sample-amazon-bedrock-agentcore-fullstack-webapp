-- Clinical Data Tables
-- Medical conditions, medications, allergies, vital signs, lab results

-- Medical Conditions/Diagnoses
CREATE TABLE medical_conditions (
    condition_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id),
    encounter_id UUID REFERENCES medical_encounters(encounter_id),
    
    -- Condition Details
    condition_name TEXT NOT NULL,
    icd10_code VARCHAR(10), -- ICD-10 diagnosis code
    condition_category TEXT,
    severity VARCHAR(50), -- Mild, Moderate, Severe
    
    -- Timeline
    onset_date DATE,
    resolution_date DATE,
    condition_status VARCHAR(50) DEFAULT 'Active', -- Active, Resolved, Chronic
    
    -- Clinical Notes
    notes TEXT,
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Medications
CREATE TABLE medications (
    medication_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id),
    encounter_id UUID REFERENCES medical_encounters(encounter_id),
    prescribed_by UUID REFERENCES healthcare_providers(provider_id),
    
    -- Medication Details
    medication_name TEXT NOT NULL,
    generic_name TEXT,
    ndc_code VARCHAR(20), -- National Drug Code
    dosage TEXT,
    frequency TEXT,
    route VARCHAR(50), -- Oral, IV, IM, etc.
    
    -- Prescription Details
    quantity_prescribed INTEGER,
    refills_remaining INTEGER,
    prescription_date DATE NOT NULL,
    start_date DATE,
    end_date DATE,
    
    -- Status
    medication_status VARCHAR(50) DEFAULT 'Active', -- Active, Discontinued, Completed
    discontinuation_reason TEXT,
    
    -- Clinical Notes
    instructions TEXT,
    notes TEXT,
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Allergies and Adverse Reactions
CREATE TABLE allergies (
    allergy_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id),
    
    -- Allergy Details
    allergen TEXT NOT NULL,
    allergy_type VARCHAR(50), -- Drug, Food, Environmental, etc.
    reaction_type TEXT, -- Rash, Anaphylaxis, etc.
    severity VARCHAR(50), -- Mild, Moderate, Severe, Life-threatening
    
    -- Timeline
    onset_date DATE,
    
    -- Clinical Information
    symptoms TEXT,
    treatment_given TEXT,
    notes TEXT,
    
    -- Status
    verified BOOLEAN DEFAULT FALSE,
    active BOOLEAN DEFAULT TRUE,
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Vital Signs
CREATE TABLE vital_signs (
    vital_sign_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id),
    encounter_id UUID REFERENCES medical_encounters(encounter_id),
    
    -- Measurement Details
    measurement_date TIMESTAMP WITH TIME ZONE NOT NULL,
    measured_by UUID REFERENCES healthcare_providers(provider_id),
    
    -- Vital Sign Values
    systolic_bp INTEGER, -- mmHg
    diastolic_bp INTEGER, -- mmHg
    heart_rate INTEGER, -- bpm
    respiratory_rate INTEGER, -- breaths per minute
    temperature DECIMAL(4,1), -- Fahrenheit
    oxygen_saturation INTEGER, -- percentage
    weight DECIMAL(5,2), -- pounds
    height DECIMAL(5,2), -- inches
    bmi DECIMAL(4,1), -- calculated BMI
    
    -- Additional Measurements
    pain_scale INTEGER CHECK (pain_scale >= 0 AND pain_scale <= 10),
    
    -- Notes
    notes TEXT,
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL
);

-- Laboratory Results
CREATE TABLE lab_results (
    lab_result_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id),
    encounter_id UUID REFERENCES medical_encounters(encounter_id),
    ordered_by UUID REFERENCES healthcare_providers(provider_id),
    
    -- Test Information
    test_name TEXT NOT NULL,
    test_code VARCHAR(50), -- LOINC code
    test_category TEXT, -- Chemistry, Hematology, Microbiology, etc.
    
    -- Results
    result_value TEXT,
    result_unit VARCHAR(50),
    reference_range TEXT,
    abnormal_flag VARCHAR(10), -- H (High), L (Low), N (Normal)
    
    -- Timeline
    order_date DATE NOT NULL,
    collection_date TIMESTAMP WITH TIME ZONE,
    result_date TIMESTAMP WITH TIME ZONE,
    
    -- Status
    result_status VARCHAR(50) DEFAULT 'Pending', -- Pending, Completed, Cancelled
    
    -- Clinical Information
    clinical_significance TEXT,
    notes TEXT,
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Create triggers for updated_at timestamps
CREATE TRIGGER update_medical_conditions_modtime BEFORE UPDATE ON medical_conditions FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_medications_modtime BEFORE UPDATE ON medications FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_allergies_modtime BEFORE UPDATE ON allergies FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_vital_signs_modtime BEFORE UPDATE ON vital_signs FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_lab_results_modtime BEFORE UPDATE ON lab_results FOR EACH ROW EXECUTE FUNCTION update_modified_column();

-- Indexes for performance
CREATE INDEX idx_conditions_patient ON medical_conditions(patient_id);
CREATE INDEX idx_conditions_icd10 ON medical_conditions(icd10_code);
CREATE INDEX idx_medications_patient ON medications(patient_id);
CREATE INDEX idx_medications_status ON medications(medication_status);
CREATE INDEX idx_allergies_patient ON allergies(patient_id);
CREATE INDEX idx_allergies_active ON allergies(active);
CREATE INDEX idx_vitals_patient ON vital_signs(patient_id);
CREATE INDEX idx_vitals_date ON vital_signs(measurement_date);
CREATE INDEX idx_lab_results_patient ON lab_results(patient_id);
CREATE INDEX idx_lab_results_date ON lab_results(result_date);