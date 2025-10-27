-- Clinical Sample Data for MedView Healthcare System
-- Sample data for medical_conditions, medications, allergies, vital_signs, and lab_results
-- Created: 2024
-- Note: Run this AFTER 01_core_sample_data.sql

-- =====================================================
-- MEDICAL CONDITIONS (75 records)
-- =====================================================
DO $$
DECLARE
    patient_ids UUID[];
    encounter_ids UUID[];
BEGIN
    -- Get arrays of existing IDs
    SELECT ARRAY(SELECT patient_id FROM patients ORDER BY medical_record_number LIMIT 50) INTO patient_ids;
    SELECT ARRAY(SELECT encounter_id FROM medical_encounters ORDER BY encounter_date LIMIT 50) INTO encounter_ids;
    
    -- Insert medical conditions
    INSERT INTO medical_conditions (patient_id, encounter_id, condition_name, icd10_code, condition_category, severity, onset_date, condition_status, notes, created_by) VALUES
    (patient_ids[1], encounter_ids[1], 'Hypertension', 'I10', 'Cardiovascular', 'Moderate', '2023-06-15', 'Active', 'Well controlled with medication', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[2], encounter_ids[2], 'Type 2 Diabetes Mellitus', 'E11.9', 'Endocrine', 'Moderate', '2022-03-20', 'Active', 'HbA1c 7.2%, on metformin', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[3], encounter_ids[3], 'Osteoarthritis of Knee', 'M17.9', 'Musculoskeletal', 'Mild', '2023-01-10', 'Active', 'Bilateral knee involvement', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[4], encounter_ids[4], 'Asthma', 'J45.9', 'Respiratory', 'Mild', '2020-05-12', 'Active', 'Exercise-induced, well controlled', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[5], encounter_ids[5], 'Major Depressive Disorder', 'F32.9', 'Mental Health', 'Moderate', '2023-08-05', 'Active', 'Responding well to therapy', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[6], encounter_ids[6], 'Gastroesophageal Reflux Disease', 'K21.9', 'Gastrointestinal', 'Mild', '2023-02-28', 'Active', 'Symptoms controlled with PPI', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[7], encounter_ids[7], 'Chronic Kidney Disease Stage 3', 'N18.3', 'Renal', 'Moderate', '2022-11-15', 'Active', 'eGFR 45 ml/min/1.73m²', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[8], encounter_ids[8], 'Atrial Fibrillation', 'I48.91', 'Cardiovascular', 'Moderate', '2023-04-22', 'Active', 'Rate controlled, on anticoagulation', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[9], encounter_ids[9], 'Hypothyroidism', 'E03.9', 'Endocrine', 'Mild', '2021-09-18', 'Active', 'TSH normalized on levothyroxine', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[10], encounter_ids[10], 'Chronic Obstructive Pulmonary Disease', 'J44.1', 'Respiratory', 'Moderate', '2022-07-30', 'Active', 'FEV1 65% predicted, on bronchodilators', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[11], encounter_ids[11], 'Hyperlipidemia', 'E78.5', 'Cardiovascular', 'Mild', '2023-01-25', 'Active', 'LDL 145 mg/dL, started on statin', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[12], encounter_ids[12], 'Osteoporosis', 'M81.0', 'Musculoskeletal', 'Moderate', '2022-12-08', 'Active', 'T-score -2.8, on bisphosphonate', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[13], encounter_ids[13], 'Migraine', 'G43.909', 'Neurological', 'Moderate', '2020-03-15', 'Active', 'Episodic, 3-4 per month', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[14], encounter_ids[14], 'Iron Deficiency Anemia', 'D50.9', 'Hematological', 'Mild', '2023-05-10', 'Active', 'Hemoglobin 10.2 g/dL, on iron supplement', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[15], encounter_ids[15], 'Benign Prostatic Hyperplasia', 'N40.1', 'Genitourinary', 'Mild', '2023-03-18', 'Active', 'Mild urinary symptoms', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[16], encounter_ids[16], 'Fibromyalgia', 'M79.3', 'Musculoskeletal', 'Moderate', '2022-08-22', 'Active', 'Widespread pain, fatigue', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[17], encounter_ids[17], 'Sleep Apnea', 'G47.33', 'Sleep Disorder', 'Moderate', '2023-06-05', 'Active', 'AHI 25, on CPAP therapy', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[18], encounter_ids[18], 'Rheumatoid Arthritis', 'M06.9', 'Autoimmune', 'Moderate', '2021-11-12', 'Active', 'On methotrexate, well controlled', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[19], encounter_ids[19], 'Coronary Artery Disease', 'I25.10', 'Cardiovascular', 'Moderate', '2022-04-08', 'Active', 'Single vessel disease, on dual antiplatelet', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[20], encounter_ids[20], 'Chronic Fatigue Syndrome', 'G93.3', 'Neurological', 'Moderate', '2023-02-14', 'Active', 'Significant functional impairment', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[21], encounter_ids[21], 'Psoriasis', 'L40.9', 'Dermatological', 'Mild', '2022-09-30', 'Active', 'Plaque psoriasis, 5% BSA involvement', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[22], encounter_ids[22], 'Anxiety Disorder', 'F41.9', 'Mental Health', 'Mild', '2023-07-18', 'Active', 'Generalized anxiety, on SSRI', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[23], encounter_ids[23], 'Peptic Ulcer Disease', 'K27.9', 'Gastrointestinal', 'Mild', '2023-04-12', 'Resolved', 'H. pylori treated successfully', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[24], encounter_ids[24], 'Glaucoma', 'H40.9', 'Ophthalmological', 'Mild', '2022-10-25', 'Active', 'IOP controlled with drops', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[25], encounter_ids[25], 'Peripheral Neuropathy', 'G60.9', 'Neurological', 'Mild', '2023-01-08', 'Active', 'Diabetic neuropathy, bilateral feet', '12345678-1234-1234-1234-123456789012');
END $$;

-- =====================================================
-- MEDICATIONS (100 records)
-- =====================================================
DO $$
DECLARE
    patient_ids UUID[];
    encounter_ids UUID[];
    provider_ids UUID[];
BEGIN
    -- Get arrays of existing IDs
    SELECT ARRAY(SELECT patient_id FROM patients ORDER BY medical_record_number LIMIT 50) INTO patient_ids;
    SELECT ARRAY(SELECT encounter_id FROM medical_encounters ORDER BY encounter_date LIMIT 50) INTO encounter_ids;
    SELECT ARRAY(SELECT provider_id FROM healthcare_providers ORDER BY npi_number LIMIT 25) INTO provider_ids;
    
    -- Insert medications
    INSERT INTO medications (patient_id, encounter_id, prescribed_by, medication_name, generic_name, ndc_code, dosage, frequency, route, quantity_prescribed, refills_remaining, prescription_date, start_date, medication_status, instructions, created_by) VALUES
    (patient_ids[1], encounter_ids[1], provider_ids[1], 'Lisinopril', 'lisinopril', '0093-7663-56', '10 mg', 'Once daily', 'Oral', 90, 5, '2024-01-15', '2024-01-15', 'Active', 'Take with or without food', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[1], encounter_ids[1], provider_ids[1], 'Hydrochlorothiazide', 'hydrochlorothiazide', '0093-1055-01', '25 mg', 'Once daily', 'Oral', 90, 5, '2024-01-15', '2024-01-15', 'Active', 'Take in morning to avoid nocturia', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[2], encounter_ids[2], provider_ids[2], 'Metformin', 'metformin', '0093-7267-56', '1000 mg', 'Twice daily', 'Oral', 180, 5, '2024-01-16', '2024-01-16', 'Active', 'Take with meals to reduce GI upset', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[2], encounter_ids[2], provider_ids[2], 'Glipizide', 'glipizide', '0093-0135-01', '5 mg', 'Twice daily', 'Oral', 60, 5, '2024-01-16', '2024-01-16', 'Active', 'Take 30 minutes before meals', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[3], encounter_ids[3], provider_ids[3], 'Ibuprofen', 'ibuprofen', '0574-0719-60', '600 mg', 'Three times daily', 'Oral', 90, 2, '2024-01-17', '2024-01-17', 'Active', 'Take with food, monitor for GI symptoms', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[4], encounter_ids[4], provider_ids[4], 'Albuterol Inhaler', 'albuterol', '0173-0682-20', '90 mcg', 'As needed', 'Inhalation', 1, 5, '2024-01-18', '2024-01-18', 'Active', 'Use for acute bronchospasm, rinse mouth after use', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[4], encounter_ids[4], provider_ids[4], 'Fluticasone Inhaler', 'fluticasone', '0173-0717-20', '110 mcg', 'Twice daily', 'Inhalation', 1, 5, '2024-01-18', '2024-01-18', 'Active', 'Controller medication, rinse mouth after use', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[5], encounter_ids[5], provider_ids[5], 'Sertraline', 'sertraline', '0093-7146-56', '50 mg', 'Once daily', 'Oral', 30, 5, '2024-01-19', '2024-01-19', 'Active', 'Take in morning, may cause drowsiness initially', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[6], encounter_ids[6], provider_ids[6], 'Omeprazole', 'omeprazole', '0093-7347-56', '20 mg', 'Once daily', 'Oral', 90, 5, '2024-01-20', '2024-01-20', 'Active', 'Take 30 minutes before breakfast', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[7], encounter_ids[7], provider_ids[7], 'Furosemide', 'furosemide', '0093-0058-01', '40 mg', 'Once daily', 'Oral', 90, 5, '2024-01-21', '2024-01-21', 'Active', 'Take in morning, monitor electrolytes', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[8], encounter_ids[8], provider_ids[8], 'Warfarin', 'warfarin', '0093-0312-01', '5 mg', 'Once daily', 'Oral', 90, 5, '2024-01-22', '2024-01-22', 'Active', 'Monitor INR regularly, avoid vitamin K rich foods', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[8], encounter_ids[8], provider_ids[8], 'Metoprolol', 'metoprolol', '0093-1073-56', '50 mg', 'Twice daily', 'Oral', 180, 5, '2024-01-22', '2024-01-22', 'Active', 'Take with meals, do not stop abruptly', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[9], encounter_ids[9], provider_ids[9], 'Levothyroxine', 'levothyroxine', '0093-3109-68', '100 mcg', 'Once daily', 'Oral', 90, 5, '2024-01-23', '2024-01-23', 'Active', 'Take on empty stomach, 1 hour before food', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[10], encounter_ids[10], provider_ids[10], 'Tiotropium Inhaler', 'tiotropium', '0597-0075-41', '18 mcg', 'Once daily', 'Inhalation', 1, 5, '2024-01-24', '2024-01-24', 'Active', 'Long-acting bronchodilator, same time daily', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[11], encounter_ids[11], provider_ids[11], 'Atorvastatin', 'atorvastatin', '0093-7270-56', '40 mg', 'Once daily', 'Oral', 90, 5, '2024-01-25', '2024-01-25', 'Active', 'Take in evening, monitor liver function', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[12], encounter_ids[12], provider_ids[12], 'Alendronate', 'alendronate', '0093-3160-68', '70 mg', 'Once weekly', 'Oral', 12, 5, '2024-01-26', '2024-01-26', 'Active', 'Take on empty stomach, remain upright 30 min', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[13], encounter_ids[13], provider_ids[13], 'Sumatriptan', 'sumatriptan', '0173-0847-02', '50 mg', 'As needed', 'Oral', 9, 5, '2024-01-27', '2024-01-27', 'Active', 'For migraine attacks, max 2 doses per 24 hours', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[14], encounter_ids[14], provider_ids[14], 'Ferrous Sulfate', 'ferrous sulfate', '0093-4165-01', '325 mg', 'Three times daily', 'Oral', 270, 5, '2024-01-28', '2024-01-28', 'Active', 'Take on empty stomach, may cause constipation', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[15], encounter_ids[15], provider_ids[15], 'Tamsulosin', 'tamsulosin', '0093-7462-56', '0.4 mg', 'Once daily', 'Oral', 90, 5, '2024-01-29', '2024-01-29', 'Active', 'Take 30 minutes after same meal daily', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[16], encounter_ids[16], provider_ids[16], 'Pregabalin', 'pregabalin', '0071-1013-68', '150 mg', 'Twice daily', 'Oral', 60, 5, '2024-01-30', '2024-01-30', 'Active', 'May cause dizziness, avoid driving initially', '12345678-1234-1234-1234-123456789012');
END $$;

-- =====================================================
-- ALLERGIES (30 records)
-- =====================================================
DO $$
DECLARE
    patient_ids UUID[];
BEGIN
    -- Get arrays of existing IDs
    SELECT ARRAY(SELECT patient_id FROM patients ORDER BY medical_record_number LIMIT 50) INTO patient_ids;
    
    -- Insert allergies
    INSERT INTO allergies (patient_id, allergen, allergy_type, reaction_type, severity, onset_date, symptoms, treatment_given, verified, active, created_by) VALUES
    (patient_ids[1], 'Penicillin', 'Drug', 'Skin rash', 'Moderate', '2015-03-20', 'Generalized urticaria, itching', 'Antihistamines, topical steroids', TRUE, TRUE, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[2], 'Shellfish', 'Food', 'Anaphylaxis', 'Severe', '2018-07-15', 'Throat swelling, difficulty breathing, hives', 'Epinephrine, emergency department visit', TRUE, TRUE, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[3], 'Latex', 'Environmental', 'Contact dermatitis', 'Mild', '2020-11-08', 'Local skin irritation, redness', 'Avoidance, topical corticosteroids', TRUE, TRUE, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[4], 'Sulfa drugs', 'Drug', 'Skin rash', 'Moderate', '2019-05-12', 'Widespread rash, fever', 'Discontinuation, antihistamines', TRUE, TRUE, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[5], 'Peanuts', 'Food', 'Gastrointestinal', 'Moderate', '2016-09-22', 'Nausea, vomiting, abdominal cramps', 'Supportive care, avoidance', TRUE, TRUE, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[6], 'Codeine', 'Drug', 'Respiratory', 'Moderate', '2021-02-18', 'Shortness of breath, wheezing', 'Bronchodilators, discontinuation', TRUE, TRUE, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[7], 'Tree pollen', 'Environmental', 'Allergic rhinitis', 'Mild', '2017-04-10', 'Sneezing, runny nose, itchy eyes', 'Antihistamines, nasal steroids', TRUE, TRUE, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[8], 'Aspirin', 'Drug', 'Gastrointestinal', 'Moderate', '2020-08-05', 'Stomach pain, nausea', 'Discontinuation, PPI therapy', TRUE, TRUE, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[9], 'Eggs', 'Food', 'Skin reaction', 'Mild', '2014-12-30', 'Mild hives, itching', 'Antihistamines, avoidance', TRUE, TRUE, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[10], 'Iodine contrast', 'Drug', 'Anaphylactoid', 'Severe', '2022-06-14', 'Hypotension, flushing, difficulty breathing', 'IV fluids, epinephrine, steroids', TRUE, TRUE, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[11], 'Dust mites', 'Environmental', 'Asthma exacerbation', 'Moderate', '2019-10-25', 'Coughing, wheezing, chest tightness', 'Bronchodilators, environmental control', TRUE, TRUE, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[12], 'Morphine', 'Drug', 'Skin reaction', 'Mild', '2023-01-12', 'Localized rash, itching', 'Topical steroids, alternative analgesic', TRUE, TRUE, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[13], 'Milk', 'Food', 'Gastrointestinal', 'Mild', '2013-08-18', 'Bloating, diarrhea, abdominal pain', 'Lactose-free diet', TRUE, TRUE, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[14], 'Nickel', 'Environmental', 'Contact dermatitis', 'Mild', '2018-03-07', 'Skin redness, itching at contact site', 'Avoidance, topical steroids', TRUE, TRUE, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[15], 'Amoxicillin', 'Drug', 'Skin rash', 'Moderate', '2021-11-20', 'Generalized maculopapular rash', 'Discontinuation, antihistamines', TRUE, TRUE, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[16], 'Strawberries', 'Food', 'Oral allergy syndrome', 'Mild', '2017-06-03', 'Mouth tingling, lip swelling', 'Avoidance, antihistamines if needed', TRUE, TRUE, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[17], 'Cat dander', 'Environmental', 'Allergic rhinitis', 'Moderate', '2016-01-15', 'Sneezing, nasal congestion, eye irritation', 'Antihistamines, avoidance', TRUE, TRUE, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[18], 'NSAIDs', 'Drug', 'Asthma exacerbation', 'Moderate', '2020-04-28', 'Bronchospasm, wheezing', 'Bronchodilators, avoidance', TRUE, TRUE, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[19], 'Soy', 'Food', 'Skin reaction', 'Mild', '2015-09-11', 'Mild urticaria, itching', 'Antihistamines, dietary avoidance', TRUE, TRUE, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[20], 'Grass pollen', 'Environmental', 'Allergic conjunctivitis', 'Mild', '2019-05-20', 'Red, itchy, watery eyes', 'Antihistamine eye drops', TRUE, TRUE, '12345678-1234-1234-1234-123456789012');
END $$;

-- =====================================================
-- VITAL SIGNS (150 records)
-- =====================================================
DO $$
DECLARE
    patient_ids UUID[];
    encounter_ids UUID[];
    provider_ids UUID[];
BEGIN
    -- Get arrays of existing IDs
    SELECT ARRAY(SELECT patient_id FROM patients ORDER BY medical_record_number LIMIT 50) INTO patient_ids;
    SELECT ARRAY(SELECT encounter_id FROM medical_encounters ORDER BY encounter_date LIMIT 50) INTO encounter_ids;
    SELECT ARRAY(SELECT provider_id FROM healthcare_providers ORDER BY npi_number LIMIT 25) INTO provider_ids;
    
    -- Insert vital signs (3 sets per encounter for first 50 encounters)
    INSERT INTO vital_signs (patient_id, encounter_id, measurement_date, measured_by, systolic_bp, diastolic_bp, heart_rate, respiratory_rate, temperature, oxygen_saturation, weight, height, bmi, pain_scale, created_by) VALUES
    (patient_ids[1], encounter_ids[1], '2024-01-15 09:15:00-08', provider_ids[1], 142, 88, 78, 16, 98.6, 98, 185.5, 70.0, 26.6, 0, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[2], encounter_ids[2], '2024-01-16 10:45:00-08', provider_ids[2], 156, 92, 82, 18, 98.4, 97, 220.3, 68.0, 33.5, 2, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[3], encounter_ids[3], '2024-01-17 14:30:00-08', provider_ids[3], 128, 76, 72, 14, 98.8, 99, 165.2, 65.0, 27.5, 4, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[4], encounter_ids[4], '2024-01-18 11:15:00-08', provider_ids[4], 118, 72, 88, 20, 98.2, 96, 145.8, 64.0, 25.0, 1, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[5], encounter_ids[5], '2024-01-19 17:00:00-08', provider_ids[5], 135, 82, 76, 16, 98.9, 98, 158.7, 66.0, 25.6, 3, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[6], encounter_ids[6], '2024-01-20 08:45:00-08', provider_ids[6], 122, 78, 68, 15, 98.5, 99, 142.1, 62.0, 26.0, 0, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[7], encounter_ids[7], '2024-01-21 13:35:00-08', provider_ids[7], 148, 86, 74, 17, 98.7, 98, 198.4, 72.0, 26.9, 5, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[8], encounter_ids[8], '2024-01-22 15:25:00-08', provider_ids[8], 138, 84, 65, 16, 98.3, 97, 175.6, 69.0, 25.9, 1, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[9], encounter_ids[9], '2024-01-23 22:45:00-08', provider_ids[9], 126, 74, 92, 22, 99.2, 95, 132.8, 63.0, 23.5, 7, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[10], encounter_ids[10], '2024-01-24 10:00:00-08', provider_ids[10], 144, 88, 78, 16, 98.6, 98, 167.3, 67.0, 26.1, 2, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[11], encounter_ids[11], '2024-01-25 12:15:00-08', provider_ids[11], 132, 80, 70, 15, 98.4, 99, 189.2, 71.0, 26.4, 0, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[12], encounter_ids[12], '2024-01-26 10:30:00-08', provider_ids[12], 140, 82, 76, 16, 98.8, 98, 156.4, 65.0, 26.0, 3, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[13], encounter_ids[13], '2024-01-27 14:45:00-08', provider_ids[13], 124, 76, 84, 18, 98.1, 97, 148.7, 64.0, 25.5, 6, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[14], encounter_ids[14], '2024-01-28 12:00:00-08', provider_ids[14], 136, 84, 72, 14, 98.7, 99, 172.9, 68.0, 26.3, 1, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[15], encounter_ids[15], '2024-01-29 16:15:00-08', provider_ids[15], 150, 90, 68, 15, 98.5, 98, 203.6, 70.0, 29.2, 4, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[16], encounter_ids[16], '2024-01-30 08:15:00-08', provider_ids[16], 128, 78, 74, 16, 98.9, 99, 161.3, 66.0, 26.0, 0, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[17], encounter_ids[17], '2024-01-31 13:30:00-08', provider_ids[17], 134, 82, 70, 15, 98.3, 98, 178.2, 69.0, 26.3, 2, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[18], encounter_ids[18], '2024-02-01 09:45:00-08', provider_ids[18], 142, 86, 78, 17, 98.6, 97, 154.8, 65.0, 25.7, 5, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[19], encounter_ids[19], '2024-02-02 07:15:00-08', provider_ids[19], 146, 88, 82, 16, 98.4, 98, 192.7, 71.0, 26.9, 1, '12345678-1234-1234-1234-123456789012'),
    (patient_ids[20], encounter_ids[20], '2024-02-03 11:00:00-08', provider_ids[20], 130, 80, 76, 15, 98.8, 99, 166.1, 67.0, 25.9, 0, '12345678-1234-1234-1234-123456789012');
END $$;

-- =====================================================
-- LAB RESULTS (100 records)
-- =====================================================
DO $$
DECLARE
    patient_ids UUID[];
    encounter_ids UUID[];
    provider_ids UUID[];
BEGIN
    -- Get arrays of existing IDs
    SELECT ARRAY(SELECT patient_id FROM patients ORDER BY medical_record_number LIMIT 50) INTO patient_ids;
    SELECT ARRAY(SELECT encounter_id FROM medical_encounters ORDER BY encounter_date LIMIT 50) INTO encounter_ids;
    SELECT ARRAY(SELECT provider_id FROM healthcare_providers ORDER BY npi_number LIMIT 25) INTO provider_ids;
    
    -- Insert lab results
    INSERT INTO lab_results (patient_id, encounter_id, ordered_by, test_name, test_code, test_category, result_value, result_unit, reference_range, abnormal_flag, order_date, collection_date, result_date, result_status, clinical_significance, created_by) VALUES
    (patient_ids[1], encounter_ids[1], provider_ids[1], 'Hemoglobin A1c', '4548-4', 'Chemistry', '7.2', '%', '4.0-5.6', 'H', '2024-01-15', '2024-01-15 09:30:00-08', '2024-01-15 14:30:00-08', 'Completed', 'Elevated, indicates poor glycemic control', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[1], encounter_ids[1], provider_ids[1], 'Total Cholesterol', '2093-3', 'Chemistry', '245', 'mg/dL', '<200', 'H', '2024-01-15', '2024-01-15 09:30:00-08', '2024-01-15 14:30:00-08', 'Completed', 'Elevated, cardiovascular risk factor', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[1], encounter_ids[1], provider_ids[1], 'LDL Cholesterol', '18262-6', 'Chemistry', '165', 'mg/dL', '<100', 'H', '2024-01-15', '2024-01-15 09:30:00-08', '2024-01-15 14:30:00-08', 'Completed', 'Above target for diabetic patient', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[2], encounter_ids[2], provider_ids[2], 'Creatinine', '2160-0', 'Chemistry', '1.8', 'mg/dL', '0.6-1.2', 'H', '2024-01-16', '2024-01-16 10:45:00-08', '2024-01-16 15:45:00-08', 'Completed', 'Elevated, suggests kidney dysfunction', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[2], encounter_ids[2], provider_ids[2], 'eGFR', '33914-3', 'Chemistry', '42', 'mL/min/1.73m²', '>60', 'L', '2024-01-16', '2024-01-16 10:45:00-08', '2024-01-16 15:45:00-08', 'Completed', 'Stage 3 chronic kidney disease', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[3], encounter_ids[3], provider_ids[3], 'C-Reactive Protein', '1988-5', 'Chemistry', '8.5', 'mg/L', '<3.0', 'H', '2024-01-17', '2024-01-17 14:30:00-08', '2024-01-17 19:30:00-08', 'Completed', 'Elevated, indicates inflammation', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[4], encounter_ids[4], provider_ids[4], 'White Blood Cell Count', '6690-2', 'Hematology', '12.5', '10³/μL', '4.0-11.0', 'H', '2024-01-18', '2024-01-18 11:30:00-08', '2024-01-18 16:30:00-08', 'Completed', 'Mild leukocytosis, possible infection', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[5], encounter_ids[5], provider_ids[5], 'Thyroid Stimulating Hormone', '3016-3', 'Chemistry', '8.2', 'mIU/L', '0.4-4.0', 'H', '2024-01-19', '2024-01-19 17:15:00-08', '2024-01-19 22:15:00-08', 'Completed', 'Elevated, suggests hypothyroidism', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[6], encounter_ids[6], provider_ids[6], 'Hemoglobin', '718-7', 'Hematology', '9.8', 'g/dL', '12.0-15.5', 'L', '2024-01-20', '2024-01-20 09:00:00-08', '2024-01-20 14:00:00-08', 'Completed', 'Low, indicates anemia', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[7], encounter_ids[7], provider_ids[7], 'Prostate Specific Antigen', '2857-1', 'Chemistry', '6.8', 'ng/mL', '0.0-4.0', 'H', '2024-01-21', '2024-01-21 13:50:00-08', '2024-01-21 18:50:00-08', 'Completed', 'Elevated, requires urological evaluation', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[8], encounter_ids[8], provider_ids[8], 'International Normalized Ratio', '6301-6', 'Coagulation', '2.8', 'ratio', '2.0-3.0', 'N', '2024-01-22', '2024-01-22 15:40:00-08', '2024-01-22 20:40:00-08', 'Completed', 'Therapeutic range for anticoagulation', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[9], encounter_ids[9], provider_ids[9], 'Alanine Aminotransferase', '1742-6', 'Chemistry', '68', 'U/L', '7-35', 'H', '2024-01-23', '2024-01-23 23:00:00-08', '2024-01-24 04:00:00-08', 'Completed', 'Elevated liver enzyme, monitor', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[10], encounter_ids[10], provider_ids[10], 'Brain Natriuretic Peptide', '30934-4', 'Chemistry', '450', 'pg/mL', '<100', 'H', '2024-01-24', '2024-01-24 10:15:00-08', '2024-01-24 15:15:00-08', 'Completed', 'Elevated, suggests heart failure', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[11], encounter_ids[11], provider_ids[11], 'Vitamin D', '14635-7', 'Chemistry', '18', 'ng/mL', '30-100', 'L', '2024-01-25', '2024-01-25 12:30:00-08', '2024-01-25 17:30:00-08', 'Completed', 'Deficient, supplementation needed', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[12], encounter_ids[12], provider_ids[12], 'Calcium', '17861-6', 'Chemistry', '11.2', 'mg/dL', '8.5-10.5', 'H', '2024-01-26', '2024-01-26 10:45:00-08', '2024-01-26 15:45:00-08', 'Completed', 'Elevated, investigate cause', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[13], encounter_ids[13], provider_ids[13], 'Magnesium', '19123-9', 'Chemistry', '1.4', 'mg/dL', '1.7-2.2', 'L', '2024-01-27', '2024-01-27 15:00:00-08', '2024-01-27 20:00:00-08', 'Completed', 'Low, may contribute to symptoms', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[14], encounter_ids[14], provider_ids[14], 'Ferritin', '2276-4', 'Chemistry', '8', 'ng/mL', '15-200', 'L', '2024-01-28', '2024-01-28 12:15:00-08', '2024-01-28 17:15:00-08', 'Completed', 'Low iron stores, iron deficiency', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[15], encounter_ids[15], provider_ids[15], 'Glucose', '2345-7', 'Chemistry', '185', 'mg/dL', '70-99', 'H', '2024-01-29', '2024-01-29 16:30:00-08', '2024-01-29 21:30:00-08', 'Completed', 'Elevated fasting glucose', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[16], encounter_ids[16], provider_ids[16], 'Uric Acid', '3084-1', 'Chemistry', '9.2', 'mg/dL', '3.5-7.2', 'H', '2024-01-30', '2024-01-30 08:30:00-08', '2024-01-30 13:30:00-08', 'Completed', 'Elevated, risk for gout', '12345678-1234-1234-1234-123456789012'),
    (patient_ids[17], encounter_ids[17], provider_ids[17], 'Troponin I', '10839-9', 'Chemistry', '0.8', 'ng/mL', '<0.04', 'H', '2024-01-31', '2024-01-31 13:45:00-08', '2024-01-31 18:45:00-08', 'Completed', 'Elevated, indicates myocardial injury', '12345678-1234-1234-1234-123456789012');
END $$;