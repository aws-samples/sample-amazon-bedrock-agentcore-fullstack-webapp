-- HIPAA Audit and Security Tables
-- User management, access logs, and audit trails

-- Users and Roles for HIPAA compliance
CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    
    -- User Information
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    employee_id VARCHAR(50),
    department VARCHAR(100),
    job_title VARCHAR(100),
    
    -- Authentication
    password_hash TEXT NOT NULL,
    password_salt TEXT NOT NULL,
    last_password_change TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    password_expiry_date DATE,
    
    -- Account Status
    active BOOLEAN DEFAULT TRUE,
    locked BOOLEAN DEFAULT FALSE,
    failed_login_attempts INTEGER DEFAULT 0,
    last_login TIMESTAMP WITH TIME ZONE,
    
    -- HIPAA Training
    hipaa_training_completed BOOLEAN DEFAULT FALSE,
    hipaa_training_date DATE,
    hipaa_training_expiry DATE,
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

-- Roles for Role-Based Access Control (RBAC)
CREATE TABLE roles (
    role_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_name VARCHAR(100) UNIQUE NOT NULL,
    role_description TEXT,
    
    -- Permissions
    can_read_patient_data BOOLEAN DEFAULT FALSE,
    can_write_patient_data BOOLEAN DEFAULT FALSE,
    can_delete_patient_data BOOLEAN DEFAULT FALSE,
    can_access_sensitive_data BOOLEAN DEFAULT FALSE, -- SSN, Mental Health, etc.
    can_manage_users BOOLEAN DEFAULT FALSE,
    can_view_audit_logs BOOLEAN DEFAULT FALSE,
    
    -- System fields
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User-Role assignments
CREATE TABLE user_roles (
    user_role_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(user_id),
    role_id UUID NOT NULL REFERENCES roles(role_id),
    
    -- Assignment details
    assigned_date DATE NOT NULL DEFAULT CURRENT_DATE,
    assigned_by UUID REFERENCES users(user_id),
    expiry_date DATE,
    
    -- Status
    active BOOLEAN DEFAULT TRUE,
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, role_id)
);

-- HIPAA Audit Log - All data access must be logged
CREATE TABLE audit_log (
    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- User and Session Information
    user_id UUID REFERENCES users(user_id),
    session_id VARCHAR(255),
    ip_address INET,
    user_agent TEXT,
    
    -- Action Details
    action_type VARCHAR(50) NOT NULL, -- CREATE, READ, UPDATE, DELETE, LOGIN, LOGOUT
    table_name VARCHAR(100),
    record_id UUID,
    patient_id UUID, -- Always log which patient's data was accessed
    
    -- Data Changes (for UPDATE/DELETE operations)
    old_values JSONB,
    new_values JSONB,
    
    -- Request Details
    endpoint VARCHAR(255),
    http_method VARCHAR(10),
    request_body TEXT,
    
    -- Result
    success BOOLEAN NOT NULL,
    error_message TEXT,
    
    -- Timing
    action_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    duration_ms INTEGER,
    
    -- Business Context
    business_justification TEXT, -- Why was this data accessed?
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Patient Access Log - Track who accessed which patient's data
CREATE TABLE patient_access_log (
    access_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(patient_id),
    user_id UUID NOT NULL REFERENCES users(user_id),
    
    -- Access Details
    access_type VARCHAR(50) NOT NULL, -- VIEW, EDIT, PRINT, EXPORT
    data_accessed TEXT[], -- Array of fields/sections accessed
    access_reason TEXT, -- Treatment, Payment, Operations, etc.
    
    -- Session Information
    session_id VARCHAR(255),
    ip_address INET,
    
    -- Timing
    access_start TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    access_end TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Data Breach Incidents (HIPAA requirement)
CREATE TABLE security_incidents (
    incident_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Incident Details
    incident_type TEXT NOT NULL, -- Unauthorized Access, Data Breach, etc.
    severity VARCHAR(50) NOT NULL, -- Low, Medium, High, Critical
    description TEXT NOT NULL,
    
    -- Affected Data
    patients_affected INTEGER,
    data_types_affected TEXT[], -- PHI, Financial, etc.
    
    -- Timeline
    incident_date TIMESTAMP WITH TIME ZONE NOT NULL,
    discovered_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    resolved_date TIMESTAMP WITH TIME ZONE,
    
    -- Response
    reported_to_authorities BOOLEAN DEFAULT FALSE,
    patients_notified BOOLEAN DEFAULT FALSE,
    mitigation_actions TEXT,
    
    -- Investigation
    investigated_by UUID REFERENCES users(user_id),
    root_cause TEXT,
    
    -- Status
    status VARCHAR(50) DEFAULT 'Open', -- Open, Under Investigation, Resolved, Closed
    
    -- System fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL REFERENCES users(user_id),
    updated_by UUID REFERENCES users(user_id)
);

-- Create triggers for updated_at timestamps
CREATE TRIGGER update_users_modtime BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_roles_modtime BEFORE UPDATE ON roles FOR EACH ROW EXECUTE FUNCTION update_modified_column();
CREATE TRIGGER update_security_incidents_modtime BEFORE UPDATE ON security_incidents FOR EACH ROW EXECUTE FUNCTION update_modified_column();

-- Indexes for performance and security
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_active ON users(active);
CREATE INDEX idx_audit_log_user ON audit_log(user_id);
CREATE INDEX idx_audit_log_patient ON audit_log(patient_id);
CREATE INDEX idx_audit_log_timestamp ON audit_log(action_timestamp);
CREATE INDEX idx_audit_log_action ON audit_log(action_type);
CREATE INDEX idx_patient_access_patient ON patient_access_log(patient_id);
CREATE INDEX idx_patient_access_user ON patient_access_log(user_id);
CREATE INDEX idx_patient_access_timestamp ON patient_access_log(access_start);
CREATE INDEX idx_security_incidents_date ON security_incidents(incident_date);
CREATE INDEX idx_security_incidents_status ON security_incidents(status);

-- Insert default roles
INSERT INTO roles (role_name, role_description, can_read_patient_data, can_write_patient_data, can_delete_patient_data, can_access_sensitive_data, can_manage_users, can_view_audit_logs) VALUES
('Physician', 'Licensed physician with full patient care access', TRUE, TRUE, FALSE, TRUE, FALSE, FALSE),
('Nurse', 'Registered nurse with patient care access', TRUE, TRUE, FALSE, FALSE, FALSE, FALSE),
('Medical Assistant', 'Medical assistant with limited patient access', TRUE, TRUE, FALSE, FALSE, FALSE, FALSE),
('Administrator', 'System administrator with user management access', TRUE, FALSE, FALSE, FALSE, TRUE, TRUE),
('Billing', 'Billing staff with financial data access', TRUE, FALSE, FALSE, FALSE, FALSE, FALSE),
('IT Support', 'IT support with system access but no patient data', FALSE, FALSE, FALSE, FALSE, FALSE, TRUE),
('Auditor', 'Compliance auditor with read-only access to audit logs', FALSE, FALSE, FALSE, FALSE, FALSE, TRUE);