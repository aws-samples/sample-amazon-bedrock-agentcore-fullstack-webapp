-- Diabetes-Specific Data Model Extensions
-- Specialized tables for comprehensive diabetes management

-- Blood Glucose Readings
CREATE TABLE blood_glucose_readings (
    reading_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id),
    
    -- Reading Details
    reading_date TIMESTAMP WITH TIME ZONE NOT NULL,
    glucose_value INTEGER NOT NULL, -- mg/dL
    glucose_value_mmol DECIMAL(4,1), -- mmol/L (calculated)
    
    -- Context
    reading_type VARCHAR(50) NOT NULL, -- Fasting, Pre-meal, Post-meal, Bedtime, Random
    meal_relation VARCHAR(50), -- Before Breakfast, After Lunch, etc.
    minutes_after_meal INTEGER, -- For post-meal readings
    
    -- Method and Device
    measurement_method TEXT, -- Glucometer, CGM, Lab
    device_serial_number VARCHAR(100),
    test_strip_lot VARCHAR(50),
    
    -- Patient State
    fasting_hours DECIMAL(3,1), -- Hours since last meal
    exercise_within_2hrs BOOLEAN DEFAULT FALSE,
    stress_level VARCHAR(20), -- Low, Normal, High
    illness_present BOOLEAN DEFAULT FALSE,
    
    -- Medication Context
    insulin_taken BOOLEAN DEFAULT FALSE,
    insulin_type TEXT,
    insulin_units DECIMAL(4,1),
    insulin_time_before_reading INTEGER, -- minutes
    
    -- Notes
    notes TEXT,
    symptoms TEXT, -- Hypoglycemic/hyperglycemic symptoms
    
    -- Quality Control
    control_solution_used BOOLEAN DEFAULT FALSE,
    reading_flagged BOOLEAN DEFAULT FALSE,
    flag_reason TEXT,
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Continuous Glucose Monitor (CGM) Data
CREATE TABLE cgm_readings (
    cgm_reading_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id),
    
    -- Device Information
    device_type TEXT NOT NULL, -- Dexcom G6, FreeStyle Libre, etc.
    device_serial VARCHAR(100),
    sensor_serial VARCHAR(100),
    
    -- Reading Data
    reading_timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    glucose_value INTEGER NOT NULL, -- mg/dL
    glucose_trend VARCHAR(20), -- Rising, Falling, Stable, etc.
    trend_arrow VARCHAR(10), -- ↑, ↓, →, etc.
    
    -- Data Quality
    signal_strength INTEGER, -- 1-5 scale
    calibration_required BOOLEAN DEFAULT FALSE,
    sensor_error BOOLEAN DEFAULT FALSE,
    
    -- Alerts
    low_glucose_alert BOOLEAN DEFAULT FALSE,
    high_glucose_alert BOOLEAN DEFAULT FALSE,
    predicted_low_alert BOOLEAN DEFAULT FALSE,
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Insulin Administration Records
CREATE TABLE insulin_administrations (
    administration_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id),
    
    -- Administration Details
    administration_date TIMESTAMP WITH TIME ZONE NOT NULL,
    insulin_type TEXT NOT NULL, -- Rapid-acting, Long-acting, etc.
    insulin_brand TEXT, -- Humalog, Lantus, etc.
    
    -- Dosage
    units_administered DECIMAL(4,1) NOT NULL,
    injection_site VARCHAR(50), -- Abdomen, Thigh, Arm, etc.
    
    -- Method
    delivery_method TEXT, -- Syringe, Pen, Pump
    pump_serial VARCHAR(100), -- If insulin pump used
    
    -- Context
    meal_bolus BOOLEAN DEFAULT FALSE,
    correction_bolus BOOLEAN DEFAULT FALSE,
    basal_insulin BOOLEAN DEFAULT FALSE,
    
    -- Pre-administration
    blood_glucose_before INTEGER, -- mg/dL
    carbs_to_cover INTEGER, -- grams
    correction_factor DECIMAL(3,1), -- units per mg/dL over target
    
    -- Notes
    notes TEXT,
    missed_dose BOOLEAN DEFAULT FALSE,
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Carbohydrate Intake Tracking
CREATE TABLE carb_intake (
    intake_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id),
    
    -- Meal Details
    meal_date TIMESTAMP WITH TIME ZONE NOT NULL,
    meal_type VARCHAR(50), -- Breakfast, Lunch, Dinner, Snack
    
    -- Carbohydrate Information
    total_carbs INTEGER NOT NULL, -- grams
    fiber_grams INTEGER,
    sugar_grams INTEGER,
    net_carbs INTEGER, -- total_carbs - fiber
    
    -- Food Details
    food_items TEXT[], -- Array of food descriptions
    portion_sizes TEXT[], -- Corresponding portion sizes
    
    -- Insulin Calculation
    carb_ratio DECIMAL(3,1), -- grams of carbs per unit of insulin
    insulin_units_calculated DECIMAL(4,1),
    insulin_units_taken DECIMAL(4,1),
    
    -- Method
    carb_counting_method TEXT, -- Estimated, Measured, App-calculated
    
    -- Notes
    notes TEXT,
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- HbA1c and Diabetes Lab Results
CREATE TABLE diabetes_lab_results (
    diabetes_lab_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id),
    lab_result_id UUID REFERENCES lab_results(lab_result_id),
    
    -- Test Details
    test_date DATE NOT NULL,
    test_type TEXT NOT NULL, -- HbA1c, Fructosamine, GAD, C-peptide, etc.
    
    -- HbA1c Specific
    hba1c_percentage DECIMAL(3,1), -- %
    hba1c_mmol_mol INTEGER, -- mmol/mol
    estimated_avg_glucose INTEGER, -- mg/dL
    
    -- Other Diabetes Tests
    fasting_glucose INTEGER, -- mg/dL
    random_glucose INTEGER, -- mg/dL
    ogtt_baseline INTEGER, -- Oral Glucose Tolerance Test baseline
    ogtt_2hour INTEGER, -- 2-hour OGTT result
    
    -- Ketones
    urine_ketones TEXT, -- Negative, Trace, Small, Moderate, Large
    blood_ketones DECIMAL(2,1), -- mmol/L
    
    -- Microalbumin (kidney function)
    microalbumin_mg DECIMAL(5,1),
    creatinine_mg DECIMAL(4,1),
    acr_ratio DECIMAL(6,1), -- Albumin-to-creatinine ratio
    
    -- Lipid Panel (cardiovascular risk)
    total_cholesterol INTEGER,
    ldl_cholesterol INTEGER,
    hdl_cholesterol INTEGER,
    triglycerides INTEGER,
    
    -- Target Ranges
    hba1c_target DECIMAL(3,1),
    glucose_target_range TEXT, -- "80-130 mg/dL"
    
    -- Clinical Significance
    result_interpretation TEXT,
    action_required TEXT,
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Diabetes Complications Tracking
CREATE TABLE diabetes_complications (
    complication_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id),
    
    -- Complication Details
    complication_type TEXT NOT NULL, -- Retinopathy, Nephropathy, Neuropathy, etc.
    complication_category TEXT, -- Microvascular, Macrovascular, Acute
    
    -- Severity and Stage
    severity VARCHAR(50), -- Mild, Moderate, Severe
    stage VARCHAR(50), -- Stage-specific classifications
    
    -- Timeline
    first_diagnosed_date DATE,
    last_assessment_date DATE,
    progression_status VARCHAR(50), -- Stable, Improving, Worsening
    
    -- Specific Details by Type
    -- Retinopathy
    eye_affected VARCHAR(20), -- Left, Right, Both
    visual_acuity_left VARCHAR(20),
    visual_acuity_right VARCHAR(20),
    
    -- Nephropathy
    egfr_value DECIMAL(5,1), -- Estimated glomerular filtration rate
    ckd_stage VARCHAR(10), -- CKD Stage 1-5
    
    -- Neuropathy
    neuropathy_type TEXT, -- Peripheral, Autonomic, Focal
    affected_areas TEXT[], -- Array of affected body areas
    
    -- Treatment
    current_treatment TEXT,
    medications TEXT[],
    
    -- Monitoring
    monitoring_frequency TEXT, -- Every 3 months, Annually, etc.
    next_assessment_due DATE,
    
    -- Notes
    clinical_notes TEXT,
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Diabetes Education and Self-Management
CREATE TABLE diabetes_education (
    education_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id),
    educator_id UUID REFERENCES healthcare_providers(provider_id),
    
    -- Session Details
    session_date DATE NOT NULL,
    session_type TEXT, -- Individual, Group, Online, etc.
    duration_minutes INTEGER,
    
    -- Topics Covered
    topics_covered TEXT[], -- Array of education topics
    materials_provided TEXT[],
    
    -- Specific Diabetes Education Areas
    carb_counting_taught BOOLEAN DEFAULT FALSE,
    insulin_administration_taught BOOLEAN DEFAULT FALSE,
    glucose_monitoring_taught BOOLEAN DEFAULT FALSE,
    hypoglycemia_management_taught BOOLEAN DEFAULT FALSE,
    sick_day_management_taught BOOLEAN DEFAULT FALSE,
    exercise_guidelines_taught BOOLEAN DEFAULT FALSE,
    
    -- Assessment
    pre_session_knowledge_score INTEGER, -- 1-10 scale
    post_session_knowledge_score INTEGER,
    competency_demonstrated BOOLEAN DEFAULT FALSE,
    
    -- Follow-up
    follow_up_required BOOLEAN DEFAULT FALSE,
    follow_up_date DATE,
    
    -- Notes
    educator_notes TEXT,
    patient_questions TEXT,
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID
);

-- Create triggers for updated_at timestamps
CREATE TRIGGER update_blood_glucose_readings_modtime BEFORE UPDATE ON blood_glucose_readings FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_insulin_administrations_modtime BEFORE UPDATE ON insulin_administrations FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_carb_intake_modtime BEFORE UPDATE ON carb_intake FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_diabetes_lab_results_modtime BEFORE UPDATE ON diabetes_lab_results FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_diabetes_complications_modtime BEFORE UPDATE ON diabetes_complications FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_diabetes_education_modtime BEFORE UPDATE ON diabetes_education FOR EACH ROW EXECUTE FUNCTION update_modified_column();

-- Indexes for performance
CREATE INDEX idx_glucose_readings_patient ON blood_glucose_readings(patient_id);
CREATE INDEX idx_glucose_readings_date ON blood_glucose_readings(reading_date);
CREATE INDEX idx_glucose_readings_type ON blood_glucose_readings(reading_type);
CREATE INDEX idx_glucose_readings_value ON blood_glucose_readings(glucose_value);

CREATE INDEX idx_cgm_readings_patient ON cgm_readings(patient_id);
CREATE INDEX idx_cgm_readings_timestamp ON cgm_readings(reading_timestamp);
CREATE INDEX idx_cgm_readings_device ON cgm_readings(device_type);

CREATE INDEX idx_insulin_admin_patient ON insulin_administrations(patient_id);
CREATE INDEX idx_insulin_admin_date ON insulin_administrations(administration_date);
CREATE INDEX idx_insulin_admin_type ON insulin_administrations(insulin_type);

CREATE INDEX idx_carb_intake_patient ON carb_intake(patient_id);
CREATE INDEX idx_carb_intake_date ON carb_intake(meal_date);
CREATE INDEX idx_carb_intake_meal_type ON carb_intake(meal_type);

CREATE INDEX idx_diabetes_labs_patient ON diabetes_lab_results(patient_id);
CREATE INDEX idx_diabetes_labs_date ON diabetes_lab_results(test_date);
CREATE INDEX idx_diabetes_labs_type ON diabetes_lab_results(test_type);
CREATE INDEX idx_diabetes_labs_hba1c ON diabetes_lab_results(hba1c_percentage);

CREATE INDEX idx_complications_patient ON diabetes_complications(patient_id);
CREATE INDEX idx_complications_type ON diabetes_complications(complication_type);
CREATE INDEX idx_complications_severity ON diabetes_complications(severity);

CREATE INDEX idx_education_patient ON diabetes_education(patient_id);
CREATE INDEX idx_education_date ON diabetes_education(session_date);
CREATE INDEX idx_education_educator ON diabetes_education(educator_id);