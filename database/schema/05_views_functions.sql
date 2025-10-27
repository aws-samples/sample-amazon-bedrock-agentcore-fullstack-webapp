-- Views and Functions for Medical Data Model
-- Commonly used views and utility functions

-- Patient Summary View - Comprehensive patient overview
CREATE VIEW patient_summary AS
SELECT 
    p.patient_id,
    p.medical_record_number,
    p.first_name,
    p.last_name,
    p.date_of_birth,
    EXTRACT(YEAR FROM AGE(p.date_of_birth)) as age,
    p.gender,
    p.phone_primary,
    p.email,
    p.insurance_provider,
    
    -- Latest encounter
    le.encounter_date as last_visit_date,
    le.encounter_type as last_visit_type,
    hp.first_name || ' ' || hp.last_name as last_provider,
    
    -- Active conditions count
    (SELECT COUNT(*) FROM medical_conditions mc 
     WHERE mc.patient_id = p.patient_id AND mc.condition_status = 'Active') as active_conditions_count,
    
    -- Active medications count
    (SELECT COUNT(*) FROM medications m 
     WHERE m.patient_id = p.patient_id AND m.medication_status = 'Active') as active_medications_count,
    
    -- Known allergies count
    (SELECT COUNT(*) FROM allergies a 
     WHERE a.patient_id = p.patient_id AND a.active = TRUE) as known_allergies_count,
    
    -- Latest vital signs
    vs.measurement_date as last_vitals_date,
    vs.systolic_bp,
    vs.diastolic_bp,
    vs.heart_rate,
    vs.temperature,
    vs.weight,
    vs.bmi

FROM patients p
LEFT JOIN LATERAL (
    SELECT encounter_date, encounter_type, provider_id
    FROM medical_encounters me
    WHERE me.patient_id = p.patient_id
    ORDER BY encounter_date DESC
    LIMIT 1
) le ON true
LEFT JOIN healthcare_providers hp ON le.provider_id = hp.provider_id
LEFT JOIN LATERAL (
    SELECT measurement_date, systolic_bp, diastolic_bp, heart_rate, temperature, weight, bmi
    FROM vital_signs vs
    WHERE vs.patient_id = p.patient_id
    ORDER BY measurement_date DESC
    LIMIT 1
) vs ON true
WHERE p.active = TRUE;

-- Active Medications View
CREATE VIEW active_medications AS
SELECT 
    m.medication_id,
    m.patient_id,
    p.medical_record_number,
    p.first_name || ' ' || p.last_name as patient_name,
    m.medication_name,
    m.generic_name,
    m.dosage,
    m.frequency,
    m.route,
    m.start_date,
    m.end_date,
    hp.first_name || ' ' || hp.last_name as prescribed_by,
    m.prescription_date,
    m.refills_remaining,
    m.instructions
FROM medications m
JOIN patients p ON m.patient_id = p.patient_id
LEFT JOIN healthcare_providers hp ON m.prescribed_by = hp.provider_id
WHERE m.medication_status = 'Active'
  AND p.active = TRUE
  AND (m.end_date IS NULL OR m.end_date >= CURRENT_DATE);

-- Critical Lab Results View
CREATE VIEW critical_lab_results AS
SELECT 
    lr.lab_result_id,
    lr.patient_id,
    p.medical_record_number,
    p.first_name || ' ' || p.last_name as patient_name,
    lr.test_name,
    lr.result_value,
    lr.result_unit,
    lr.reference_range,
    lr.abnormal_flag,
    lr.result_date,
    hp.first_name || ' ' || hp.last_name as ordered_by,
    lr.clinical_significance
FROM lab_results lr
JOIN patients p ON lr.patient_id = p.patient_id
LEFT JOIN healthcare_providers hp ON lr.ordered_by = hp.provider_id
WHERE lr.abnormal_flag IN ('H', 'L', 'CRITICAL')
  AND lr.result_status = 'Completed'
  AND lr.result_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY lr.result_date DESC;

-- Upcoming Appointments View
CREATE VIEW upcoming_appointments AS
SELECT 
    a.appointment_id,
    a.patient_id,
    p.medical_record_number,
    p.first_name || ' ' || p.last_name as patient_name,
    p.phone_primary,
    a.scheduled_date,
    a.scheduled_time,
    a.appointment_type,
    a.appointment_reason,
    hp.first_name || ' ' || hp.last_name as provider_name,
    mf.facility_name,
    a.appointment_status,
    a.reminder_sent
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
JOIN healthcare_providers hp ON a.provider_id = hp.provider_id
LEFT JOIN medical_facilities mf ON a.facility_id = mf.facility_id
WHERE a.scheduled_date >= CURRENT_DATE
  AND a.appointment_status IN ('Scheduled', 'Confirmed')
ORDER BY a.scheduled_date, a.scheduled_time;

-- Patient Access Summary for HIPAA Compliance
CREATE VIEW patient_access_summary AS
SELECT 
    pal.patient_id,
    p.medical_record_number,
    p.first_name || ' ' || p.last_name as patient_name,
    COUNT(*) as total_accesses,
    COUNT(DISTINCT pal.user_id) as unique_users,
    MIN(pal.access_start) as first_access,
    MAX(pal.access_start) as last_access,
    array_agg(DISTINCT u.first_name || ' ' || u.last_name) as accessing_users
FROM patient_access_log pal
JOIN patients p ON pal.patient_id = p.patient_id
JOIN users u ON pal.user_id = u.user_id
WHERE pal.access_start >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY pal.patient_id, p.medical_record_number, p.first_name, p.last_name
ORDER BY total_accesses DESC;

-- Function to calculate BMI
CREATE OR REPLACE FUNCTION calculate_bmi(weight_lbs DECIMAL, height_inches DECIMAL)
RETURNS DECIMAL(4,1) AS $$
BEGIN
    IF weight_lbs IS NULL OR height_inches IS NULL OR height_inches = 0 THEN
        RETURN NULL;
    END IF;
    
    -- BMI = (weight in pounds / (height in inches)^2) * 703
    RETURN ROUND((weight_lbs / (height_inches * height_inches)) * 703, 1);
END;
$$ LANGUAGE plpgsql;

-- Function to get patient age
CREATE OR REPLACE FUNCTION get_patient_age(birth_date DATE)
RETURNS INTEGER AS $$
BEGIN
    IF birth_date IS NULL THEN
        RETURN NULL;
    END IF;
    
    RETURN EXTRACT(YEAR FROM AGE(birth_date));
END;
$$ LANGUAGE plpgsql;

-- Function to check for drug interactions (simplified)
CREATE OR REPLACE FUNCTION check_drug_interactions(patient_uuid UUID, new_medication VARCHAR)
RETURNS TABLE(
    interaction_severity VARCHAR,
    interacting_medication VARCHAR,
    interaction_description TEXT
) AS $$
BEGIN
    -- This is a simplified example - in practice, you'd have a comprehensive drug interaction database
    RETURN QUERY
    SELECT 
        'MODERATE'::VARCHAR as interaction_severity,
        m.medication_name as interacting_medication,
        'Potential interaction detected - consult pharmacist'::TEXT as interaction_description
    FROM medications m
    WHERE m.patient_id = patient_uuid
      AND m.medication_status = 'Active'
      AND (
          (LOWER(m.medication_name) LIKE '%warfarin%' AND LOWER(new_medication) LIKE '%aspirin%') OR
          (LOWER(m.medication_name) LIKE '%aspirin%' AND LOWER(new_medication) LIKE '%warfarin%') OR
          (LOWER(m.medication_name) LIKE '%metformin%' AND LOWER(new_medication) LIKE '%contrast%')
      );
END;
$$ LANGUAGE plpgsql;

-- Function to log patient data access (HIPAA requirement)
CREATE OR REPLACE FUNCTION log_patient_access(
    p_patient_id UUID,
    p_user_id UUID,
    p_access_type VARCHAR,
    p_data_accessed TEXT[],
    p_access_reason VARCHAR,
    p_session_id VARCHAR DEFAULT NULL,
    p_ip_address INET DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    access_id UUID;
BEGIN
    INSERT INTO patient_access_log (
        patient_id,
        user_id,
        access_type,
        data_accessed,
        access_reason,
        session_id,
        ip_address
    ) VALUES (
        p_patient_id,
        p_user_id,
        p_access_type,
        p_data_accessed,
        p_access_reason,
        p_session_id,
        p_ip_address
    ) RETURNING access_id INTO access_id;
    
    RETURN access_id;
END;
$$ LANGUAGE plpgsql;

-- Function to encrypt sensitive data (SSN example)
CREATE OR REPLACE FUNCTION encrypt_ssn(ssn_plain TEXT, encryption_key TEXT)
RETURNS TEXT AS $$
BEGIN
    IF ssn_plain IS NULL OR ssn_plain = '' THEN
        RETURN NULL;
    END IF;
    
    -- Use pgcrypto extension for encryption
    RETURN encode(encrypt(ssn_plain::bytea, encryption_key::bytea, 'aes'), 'base64');
END;
$$ LANGUAGE plpgsql;

-- Function to decrypt sensitive data
CREATE OR REPLACE FUNCTION decrypt_ssn(ssn_encrypted TEXT, encryption_key TEXT)
RETURNS TEXT AS $$
BEGIN
    IF ssn_encrypted IS NULL OR ssn_encrypted = '' THEN
        RETURN NULL;
    END IF;
    
    -- Use pgcrypto extension for decryption
    RETURN convert_from(decrypt(decode(ssn_encrypted, 'base64'), encryption_key::bytea, 'aes'), 'UTF8');
END;
$$ LANGUAGE plpgsql;

-- Trigger function to automatically calculate BMI when vital signs are inserted/updated
CREATE OR REPLACE FUNCTION calculate_bmi_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.weight IS NOT NULL AND NEW.height IS NOT NULL THEN
        NEW.bmi := calculate_bmi(NEW.weight, NEW.height);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for BMI calculation
CREATE TRIGGER trigger_calculate_bmi
    BEFORE INSERT OR UPDATE ON vital_signs
    FOR EACH ROW
    EXECUTE FUNCTION calculate_bmi_trigger();