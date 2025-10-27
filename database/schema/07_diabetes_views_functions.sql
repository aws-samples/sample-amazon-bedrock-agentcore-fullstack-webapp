-- Diabetes-Specific Views and Functions
-- Specialized queries and calculations for diabetes management

-- Diabetes Patient Dashboard View
CREATE VIEW diabetes_patient_dashboard AS
SELECT 
    p.patient_id,
    p.medical_record_number,
    p.first_name || ' ' || p.last_name as patient_name,
    p.date_of_birth,
    EXTRACT(YEAR FROM AGE(p.date_of_birth)) as age,
    
    -- Latest HbA1c
    latest_hba1c.hba1c_percentage,
    latest_hba1c.test_date as last_hba1c_date,
    latest_hba1c.hba1c_target,
    CASE 
        WHEN latest_hba1c.hba1c_percentage <= latest_hba1c.hba1c_target THEN 'At Target'
        WHEN latest_hba1c.hba1c_percentage <= latest_hba1c.hba1c_target + 1 THEN 'Near Target'
        ELSE 'Above Target'
    END as hba1c_status,
    
    -- Recent glucose statistics (last 30 days)
    glucose_stats.avg_glucose,
    glucose_stats.glucose_readings_count,
    glucose_stats.readings_in_range_percent,
    glucose_stats.hypoglycemic_episodes,
    glucose_stats.hyperglycemic_episodes,
    
    -- Latest glucose reading
    latest_glucose.glucose_value as last_glucose_value,
    latest_glucose.reading_date as last_glucose_date,
    latest_glucose.reading_type as last_glucose_type,
    
    -- Active complications
    (SELECT COUNT(*) FROM diabetes_complications dc 
     WHERE dc.patient_id = p.patient_id AND dc.progression_status != 'Resolved') as active_complications_count,
    
    -- Medication adherence (insulin administrations vs prescribed)
    insulin_stats.daily_avg_insulin_units,
    insulin_stats.missed_doses_last_30_days

FROM patients p
LEFT JOIN LATERAL (
    SELECT hba1c_percentage, test_date, hba1c_target
    FROM diabetes_lab_results dlr
    WHERE dlr.patient_id = p.patient_id 
      AND dlr.hba1c_percentage IS NOT NULL
    ORDER BY test_date DESC
    LIMIT 1
) latest_hba1c ON true
LEFT JOIN LATERAL (
    SELECT 
        ROUND(AVG(glucose_value)) as avg_glucose,
        COUNT(*) as glucose_readings_count,
        ROUND(
            (COUNT(*) FILTER (WHERE glucose_value BETWEEN 70 AND 180) * 100.0 / COUNT(*)), 1
        ) as readings_in_range_percent,
        COUNT(*) FILTER (WHERE glucose_value < 70) as hypoglycemic_episodes,
        COUNT(*) FILTER (WHERE glucose_value > 250) as hyperglycemic_episodes
    FROM blood_glucose_readings bgr
    WHERE bgr.patient_id = p.patient_id 
      AND bgr.reading_date >= CURRENT_DATE - INTERVAL '30 days'
) glucose_stats ON true
LEFT JOIN LATERAL (
    SELECT glucose_value, reading_date, reading_type
    FROM blood_glucose_readings bgr
    WHERE bgr.patient_id = p.patient_id
    ORDER BY reading_date DESC
    LIMIT 1
) latest_glucose ON true
LEFT JOIN LATERAL (
    SELECT 
        ROUND(AVG(units_administered), 1) as daily_avg_insulin_units,
        COUNT(*) FILTER (WHERE missed_dose = true) as missed_doses_last_30_days
    FROM insulin_administrations ia
    WHERE ia.patient_id = p.patient_id 
      AND ia.administration_date >= CURRENT_DATE - INTERVAL '30 days'
) insulin_stats ON true
WHERE p.active = TRUE;

-- Glucose Trends View (for charts and analysis)
CREATE VIEW glucose_trends AS
SELECT 
    bgr.patient_id,
    p.medical_record_number,
    DATE(bgr.reading_date) as reading_date,
    bgr.reading_type,
    
    -- Daily statistics
    COUNT(*) as readings_count,
    ROUND(AVG(bgr.glucose_value)) as avg_glucose,
    MIN(bgr.glucose_value) as min_glucose,
    MAX(bgr.glucose_value) as max_glucose,
    
    -- Time in range calculations
    COUNT(*) FILTER (WHERE bgr.glucose_value < 70) as hypoglycemic_readings,
    COUNT(*) FILTER (WHERE bgr.glucose_value BETWEEN 70 AND 180) as in_range_readings,
    COUNT(*) FILTER (WHERE bgr.glucose_value > 180) as hyperglycemic_readings,
    
    -- Percentages
    ROUND((COUNT(*) FILTER (WHERE bgr.glucose_value < 70) * 100.0 / COUNT(*)), 1) as hypoglycemic_percent,
    ROUND((COUNT(*) FILTER (WHERE bgr.glucose_value BETWEEN 70 AND 180) * 100.0 / COUNT(*)), 1) as in_range_percent,
    ROUND((COUNT(*) FILTER (WHERE bgr.glucose_value > 180) * 100.0 / COUNT(*)), 1) as hyperglycemic_percent

FROM blood_glucose_readings bgr
JOIN patients p ON bgr.patient_id = p.patient_id
WHERE bgr.reading_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY bgr.patient_id, p.medical_record_number, DATE(bgr.reading_date), bgr.reading_type
ORDER BY bgr.patient_id, reading_date DESC;

-- Insulin-to-Carb Ratio Analysis
CREATE VIEW insulin_carb_analysis AS
SELECT 
    ci.patient_id,
    p.medical_record_number,
    p.first_name || ' ' || p.last_name as patient_name,
    DATE(ci.meal_date) as meal_date,
    ci.meal_type,
    ci.total_carbs,
    ci.insulin_units_taken,
    
    -- Calculate actual ratio
    CASE 
        WHEN ci.insulin_units_taken > 0 THEN ROUND(ci.total_carbs / ci.insulin_units_taken, 1)
        ELSE NULL
    END as actual_carb_ratio,
    
    ci.carb_ratio as prescribed_carb_ratio,
    
    -- Variance from prescribed ratio
    CASE 
        WHEN ci.insulin_units_taken > 0 AND ci.carb_ratio > 0 THEN 
            ROUND(ABS((ci.total_carbs / ci.insulin_units_taken) - ci.carb_ratio), 1)
        ELSE NULL
    END as ratio_variance,
    
    -- Post-meal glucose (if available within 2 hours)
    post_meal_glucose.glucose_value as post_meal_glucose,
    post_meal_glucose.minutes_after_meal

FROM carb_intake ci
JOIN patients p ON ci.patient_id = p.patient_id
LEFT JOIN LATERAL (
    SELECT glucose_value, minutes_after_meal
    FROM blood_glucose_readings bgr
    WHERE bgr.patient_id = ci.patient_id
      AND bgr.reading_date BETWEEN ci.meal_date AND ci.meal_date + INTERVAL '3 hours'
      AND bgr.reading_type = 'Post-meal'
    ORDER BY ABS(EXTRACT(EPOCH FROM (bgr.reading_date - ci.meal_date)) / 60 - 120) -- Closest to 2 hours
    LIMIT 1
) post_meal_glucose ON true
WHERE ci.meal_date >= CURRENT_DATE - INTERVAL '30 days'
  AND ci.insulin_units_taken > 0
ORDER BY ci.patient_id, ci.meal_date DESC;

-- Hypoglycemic Episodes View
CREATE VIEW hypoglycemic_episodes AS
SELECT 
    bgr.patient_id,
    p.medical_record_number,
    p.first_name || ' ' || p.last_name as patient_name,
    bgr.reading_date,
    bgr.glucose_value,
    bgr.reading_type,
    
    -- Severity classification
    CASE 
        WHEN bgr.glucose_value < 54 THEN 'Severe'
        WHEN bgr.glucose_value < 70 THEN 'Mild'
        ELSE 'Normal'
    END as hypoglycemia_severity,
    
    -- Context
    bgr.fasting_hours,
    bgr.exercise_within_2hrs,
    bgr.insulin_taken,
    bgr.insulin_type,
    bgr.insulin_units,
    bgr.symptoms,
    bgr.notes,
    
    -- Recent insulin (within 4 hours)
    recent_insulin.units_administered as recent_insulin_units,
    recent_insulin.insulin_type as recent_insulin_type,
    EXTRACT(EPOCH FROM (bgr.reading_date - recent_insulin.administration_date)) / 3600 as hours_since_insulin

FROM blood_glucose_readings bgr
JOIN patients p ON bgr.patient_id = p.patient_id
LEFT JOIN LATERAL (
    SELECT units_administered, insulin_type, administration_date
    FROM insulin_administrations ia
    WHERE ia.patient_id = bgr.patient_id
      AND ia.administration_date <= bgr.reading_date
      AND ia.administration_date >= bgr.reading_date - INTERVAL '4 hours'
    ORDER BY ia.administration_date DESC
    LIMIT 1
) recent_insulin ON true
WHERE bgr.glucose_value < 70
  AND bgr.reading_date >= CURRENT_DATE - INTERVAL '90 days'
ORDER BY bgr.patient_id, bgr.reading_date DESC;

-- Function to calculate Time in Range (TIR)
CREATE OR REPLACE FUNCTION calculate_time_in_range(
    p_patient_id UUID,
    p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    p_end_date DATE DEFAULT CURRENT_DATE,
    p_target_low INTEGER DEFAULT 70,
    p_target_high INTEGER DEFAULT 180
)
RETURNS TABLE(
    total_readings INTEGER,
    readings_below_range INTEGER,
    readings_in_range INTEGER,
    readings_above_range INTEGER,
    time_below_range_percent DECIMAL(5,2),
    time_in_range_percent DECIMAL(5,2),
    time_above_range_percent DECIMAL(5,2),
    average_glucose DECIMAL(5,1),
    glucose_management_indicator DECIMAL(3,1)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_readings,
        COUNT(*) FILTER (WHERE glucose_value < p_target_low)::INTEGER as readings_below_range,
        COUNT(*) FILTER (WHERE glucose_value BETWEEN p_target_low AND p_target_high)::INTEGER as readings_in_range,
        COUNT(*) FILTER (WHERE glucose_value > p_target_high)::INTEGER as readings_above_range,
        
        ROUND((COUNT(*) FILTER (WHERE glucose_value < p_target_low) * 100.0 / COUNT(*)), 2) as time_below_range_percent,
        ROUND((COUNT(*) FILTER (WHERE glucose_value BETWEEN p_target_low AND p_target_high) * 100.0 / COUNT(*)), 2) as time_in_range_percent,
        ROUND((COUNT(*) FILTER (WHERE glucose_value > p_target_high) * 100.0 / COUNT(*)), 2) as time_above_range_percent,
        
        ROUND(AVG(glucose_value), 1) as average_glucose,
        
        -- Glucose Management Indicator (GMI) calculation: 3.31 + (0.02392 × mean glucose)
        ROUND((3.31 + (0.02392 * AVG(glucose_value)))::NUMERIC, 1) as glucose_management_indicator
        
    FROM blood_glucose_readings bgr
    WHERE bgr.patient_id = p_patient_id
      AND DATE(bgr.reading_date) BETWEEN p_start_date AND p_end_date;
END;
$$ LANGUAGE plpgsql;

-- Function to detect glucose patterns
CREATE OR REPLACE FUNCTION detect_glucose_patterns(
    p_patient_id UUID,
    p_days_back INTEGER DEFAULT 14
)
RETURNS TABLE(
    pattern_type VARCHAR,
    pattern_description TEXT,
    occurrences INTEGER,
    avg_glucose_during_pattern DECIMAL(5,1),
    recommendation TEXT
) AS $$
BEGIN
    -- Dawn Phenomenon (high morning glucose)
    RETURN QUERY
    SELECT 
        'Dawn Phenomenon'::VARCHAR as pattern_type,
        'Consistently elevated morning glucose levels'::TEXT as pattern_description,
        COUNT(*)::INTEGER as occurrences,
        ROUND(AVG(glucose_value), 1) as avg_glucose_during_pattern,
        'Consider adjusting basal insulin or evening medication timing'::TEXT as recommendation
    FROM blood_glucose_readings bgr
    WHERE bgr.patient_id = p_patient_id
      AND bgr.reading_date >= CURRENT_DATE - (p_days_back || ' days')::INTERVAL
      AND bgr.reading_type = 'Fasting'
      AND EXTRACT(HOUR FROM bgr.reading_date) BETWEEN 6 AND 9
      AND bgr.glucose_value > 130
    HAVING COUNT(*) >= 3;
    
    -- Post-meal spikes
    RETURN QUERY
    SELECT 
        'Post-meal Spikes'::VARCHAR as pattern_type,
        'Frequent high glucose readings after meals'::TEXT as pattern_description,
        COUNT(*)::INTEGER as occurrences,
        ROUND(AVG(glucose_value), 1) as avg_glucose_during_pattern,
        'Review carbohydrate counting and meal insulin timing'::TEXT as recommendation
    FROM blood_glucose_readings bgr
    WHERE bgr.patient_id = p_patient_id
      AND bgr.reading_date >= CURRENT_DATE - (p_days_back || ' days')::INTERVAL
      AND bgr.reading_type = 'Post-meal'
      AND bgr.glucose_value > 180
    HAVING COUNT(*) >= 5;
    
    -- Nocturnal hypoglycemia
    RETURN QUERY
    SELECT 
        'Nocturnal Hypoglycemia'::VARCHAR as pattern_type,
        'Low glucose readings during nighttime hours'::TEXT as pattern_description,
        COUNT(*)::INTEGER as occurrences,
        ROUND(AVG(glucose_value), 1) as avg_glucose_during_pattern,
        'Consider reducing evening insulin or adding bedtime snack'::TEXT as recommendation
    FROM blood_glucose_readings bgr
    WHERE bgr.patient_id = p_patient_id
      AND bgr.reading_date >= CURRENT_DATE - (p_days_back || ' days')::INTERVAL
      AND EXTRACT(HOUR FROM bgr.reading_date) BETWEEN 22 AND 6
      AND bgr.glucose_value < 70
    HAVING COUNT(*) >= 2;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate insulin sensitivity factor
CREATE OR REPLACE FUNCTION calculate_insulin_sensitivity(
    p_patient_id UUID,
    p_days_back INTEGER DEFAULT 30
)
RETURNS TABLE(
    correction_episodes INTEGER,
    avg_glucose_drop_per_unit DECIMAL(5,1),
    recommended_correction_factor DECIMAL(3,1)
) AS $$
BEGIN
    RETURN QUERY
    WITH correction_analysis AS (
        SELECT 
            ia.units_administered,
            pre_glucose.glucose_value as pre_correction_glucose,
            post_glucose.glucose_value as post_correction_glucose,
            (pre_glucose.glucose_value - post_glucose.glucose_value) as glucose_drop,
            (pre_glucose.glucose_value - post_glucose.glucose_value) / ia.units_administered as drop_per_unit
        FROM insulin_administrations ia
        JOIN LATERAL (
            SELECT glucose_value
            FROM blood_glucose_readings bgr
            WHERE bgr.patient_id = ia.patient_id
              AND bgr.reading_date <= ia.administration_date
              AND bgr.reading_date >= ia.administration_date - INTERVAL '30 minutes'
            ORDER BY ABS(EXTRACT(EPOCH FROM (bgr.reading_date - ia.administration_date)))
            LIMIT 1
        ) pre_glucose ON true
        JOIN LATERAL (
            SELECT glucose_value
            FROM blood_glucose_readings bgr
            WHERE bgr.patient_id = ia.patient_id
              AND bgr.reading_date >= ia.administration_date + INTERVAL '2 hours'
              AND bgr.reading_date <= ia.administration_date + INTERVAL '4 hours'
            ORDER BY ABS(EXTRACT(EPOCH FROM (bgr.reading_date - (ia.administration_date + INTERVAL '3 hours'))))
            LIMIT 1
        ) post_glucose ON true
        WHERE ia.patient_id = p_patient_id
          AND ia.correction_bolus = true
          AND ia.administration_date >= CURRENT_DATE - (p_days_back || ' days')::INTERVAL
          AND ia.units_administered > 0
    )
    SELECT 
        COUNT(*)::INTEGER as correction_episodes,
        ROUND(AVG(drop_per_unit), 1) as avg_glucose_drop_per_unit,
        ROUND(AVG(drop_per_unit), 1) as recommended_correction_factor
    FROM correction_analysis
    WHERE glucose_drop > 0 AND drop_per_unit BETWEEN 10 AND 100; -- Reasonable range
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically convert glucose units
CREATE OR REPLACE FUNCTION convert_glucose_units()
RETURNS TRIGGER AS $$
BEGIN
    -- Convert mg/dL to mmol/L (divide by 18.018)
    IF NEW.glucose_value IS NOT NULL THEN
        NEW.glucose_value_mmol := ROUND((NEW.glucose_value / 18.018)::NUMERIC, 1);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for glucose unit conversion
CREATE TRIGGER trigger_convert_glucose_units
    BEFORE INSERT OR UPDATE ON blood_glucose_readings
    FOR EACH ROW
    EXECUTE FUNCTION convert_glucose_units();