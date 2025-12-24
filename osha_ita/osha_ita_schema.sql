-- =============================================================================
-- OSHA ITA (Injury Tracking Application) PostgreSQL Database Schema
-- Supports 300A Summary Data and Case Detail Data with Versioning & Audit
-- =============================================================================

-- Create database (run separately if needed)
-- CREATE DATABASE osha_ita_db;

-- Extensions for better functionality
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search
CREATE EXTENSION IF NOT EXISTS "btree_gin"; -- For better indexing

-- =============================================================================
-- AUDIT AND VERSIONING INFRASTRUCTURE
-- =============================================================================

-- Data Load Metadata Table
CREATE TABLE data_loads (
    load_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    load_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    load_type VARCHAR(50) NOT NULL, -- '300A_summary', 'case_detail', 'mixed'
    source_file_name VARCHAR(500),
    source_file_hash VARCHAR(64), -- SHA256 hash for duplicate detection
    data_year INTEGER NOT NULL,
    records_loaded INTEGER DEFAULT 0,
    records_updated INTEGER DEFAULT 0,
    records_failed INTEGER DEFAULT 0,
    load_status VARCHAR(20) DEFAULT 'in_progress', -- 'in_progress', 'completed', 'failed'
    load_notes TEXT,
    loaded_by VARCHAR(100) DEFAULT current_user,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Generic audit table for all data changes
CREATE TABLE audit_log (
    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(100) NOT NULL,
    record_id VARCHAR(100) NOT NULL, -- Can be UUID or numeric ID
    operation VARCHAR(10) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    old_values JSONB,
    new_values JSONB,
    changed_fields TEXT[], -- Array of field names that changed
    load_id UUID REFERENCES data_loads(load_id),
    changed_by VARCHAR(100) DEFAULT current_user,
    changed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- REFERENCE TABLES
-- =============================================================================

-- NAICS Codes Reference (for validation and lookups)
CREATE TABLE ref_naics_codes (
    naics_code VARCHAR(10) PRIMARY KEY,
    naics_year INTEGER NOT NULL,
    industry_title VARCHAR(500) NOT NULL,
    sector_code VARCHAR(5),
    sector_title VARCHAR(200),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- SOC Codes Reference
CREATE TABLE ref_soc_codes (
    soc_code VARCHAR(10) PRIMARY KEY,
    soc_year INTEGER NOT NULL DEFAULT 2018,
    title VARCHAR(500) NOT NULL,
    major_group VARCHAR(100),
    minor_group VARCHAR(100),
    broad_occupation VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- State/Territory Reference
CREATE TABLE ref_states (
    state_code VARCHAR(5) PRIMARY KEY,
    state_name VARCHAR(100) NOT NULL,
    is_territory BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true
);

-- =============================================================================
-- ESTABLISHMENT MASTER TABLE
-- =============================================================================

CREATE TABLE establishments (
    establishment_uuid UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    establishment_id BIGINT, -- OSHA assigned ID
    establishment_name VARCHAR(500) NOT NULL,
    ein VARCHAR(20), -- Employer Identification Number
    company_name VARCHAR(500),
    
    -- Address Information (flexible for changes over time)
    current_address JSONB, -- Store full address as JSON for flexibility
    street_address VARCHAR(500),
    city VARCHAR(100),
    state_code VARCHAR(5) REFERENCES ref_states(state_code),
    zip_code VARCHAR(20),
    
    -- Industry Classification
    current_naics JSONB, -- Store current NAICS info as JSON
    primary_naics_code VARCHAR(10) REFERENCES ref_naics_codes(naics_code),
    naics_year INTEGER,
    industry_description VARCHAR(500),
    
    -- Classification
    establishment_type INTEGER, -- 1=Private, 2=State Gov, 3=Local Gov
    size_category INTEGER, -- Size codes as per data dictionary
    
    -- Metadata
    first_seen_year INTEGER,
    last_seen_year INTEGER,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Create unique constraint for business logic
    CONSTRAINT unique_establishment_per_ein_name UNIQUE (ein, establishment_name)
);

-- =============================================================================
-- 300A SUMMARY DATA (Annual Establishment Summary)
-- =============================================================================

CREATE TABLE summary_300a_data (
    summary_uuid UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Reference to establishment and load
    establishment_uuid UUID NOT NULL REFERENCES establishments(establishment_uuid),
    load_id UUID NOT NULL REFERENCES data_loads(load_id),
    
    -- Original ITA identifiers
    ita_id BIGINT, -- Original ID from ITA system
    ita_establishment_id BIGINT,
    
    -- Establishment snapshot (at time of filing)
    establishment_snapshot JSONB, -- Store establishment info as it was when filed
    
    -- Employee Information
    annual_average_employees INTEGER,
    total_hours_worked BIGINT,
    
    -- Injury/Illness Summary Flags
    no_injuries_illnesses INTEGER, -- 1=had injuries, 2=no injuries
    
    -- Death and Case Counts
    total_deaths INTEGER DEFAULT 0,
    total_dafw_cases INTEGER DEFAULT 0, -- Days away from work
    total_djtr_cases INTEGER DEFAULT 0, -- Job transfer/restriction
    total_other_cases INTEGER DEFAULT 0,
    
    -- Day Counts
    total_dafw_days INTEGER DEFAULT 0,
    total_djtr_days INTEGER DEFAULT 0,
    
    -- Injury/Illness Type Counts
    total_injuries INTEGER DEFAULT 0,
    total_skin_disorders INTEGER DEFAULT 0,
    total_respiratory_conditions INTEGER DEFAULT 0,
    total_poisonings INTEGER DEFAULT 0,
    total_hearing_loss INTEGER DEFAULT 0,
    total_other_illnesses INTEGER DEFAULT 0,
    
    -- Filing Information
    year_filing_for INTEGER NOT NULL,
    created_timestamp VARCHAR(50), -- Original ITA timestamp format
    ita_created_at TIMESTAMPTZ, -- Parsed timestamp
    change_reason TEXT,
    
    -- Additional fields for newer data
    sector VARCHAR(200),
    zipcode VARCHAR(20), -- Sometimes different format than zip_code
    naics_char VARCHAR(20), -- Character version of NAICS
    
    -- Versioning and Audit
    data_version INTEGER DEFAULT 1,
    is_current BOOLEAN DEFAULT true,
    superseded_by UUID REFERENCES summary_300a_data(summary_uuid),
    effective_from TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    effective_until TIMESTAMPTZ,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure uniqueness per establishment per year per version
    CONSTRAINT unique_300a_per_establishment_year UNIQUE (establishment_uuid, year_filing_for, data_version)
);

-- =============================================================================
-- CASE DETAIL DATA (Individual Incident Records)
-- =============================================================================

CREATE TABLE case_detail_data (
    case_uuid UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Reference to establishment and load
    establishment_uuid UUID NOT NULL REFERENCES establishments(establishment_uuid),
    load_id UUID NOT NULL REFERENCES data_loads(load_id),
    
    -- Original ITA identifiers
    ita_id BIGINT, -- Original ID from ITA system
    ita_establishment_id BIGINT,
    
    -- Case Identification
    case_number VARCHAR(100), -- Employer assigned case number
    
    -- Establishment snapshot (at time of incident)
    establishment_snapshot JSONB,
    
    -- Employee Information
    job_description VARCHAR(500),
    soc_code VARCHAR(10) REFERENCES ref_soc_codes(soc_code),
    soc_description VARCHAR(500),
    soc_reviewed INTEGER, -- 0=not reviewed, 1=reviewed, 2=not coded
    soc_probability NUMERIC(5,4), -- NIOCCS probability score
    
    -- Incident Date/Time Information
    date_of_incident DATE,
    time_started_work TIME,
    time_of_incident TIME,
    time_unknown BOOLEAN DEFAULT false,
    
    -- Incident Classification
    incident_outcome INTEGER NOT NULL, -- 1=Death, 2=DAFW, 3=Job transfer, 4=Other
    type_of_incident INTEGER NOT NULL, -- 1=Injury, 2=Skin, 3=Respiratory, etc.
    
    -- Days Away/Transfer
    dafw_num_away INTEGER, -- Days away from work
    djtr_num_tr INTEGER, -- Days transferred/restricted
    
    -- Death Information
    date_of_death DATE,
    
    -- Incident Narratives (flexible text fields)
    incident_location TEXT,
    incident_description TEXT,
    narrative_before_incident TEXT,
    narrative_what_happened TEXT,
    narrative_injury_illness TEXT,
    narrative_object_substance TEXT,
    
    -- All narratives in structured format for analysis
    incident_narratives JSONB,
    
    -- Filing Information
    year_filing_for INTEGER NOT NULL,
    created_timestamp VARCHAR(50), -- Original ITA timestamp format
    ita_created_at TIMESTAMPTZ, -- Parsed timestamp
    
    -- Versioning and Audit
    data_version INTEGER DEFAULT 1,
    is_current BOOLEAN DEFAULT true,
    superseded_by UUID REFERENCES case_detail_data(case_uuid),
    effective_from TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    effective_until TIMESTAMPTZ,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Business logic constraints
    CONSTRAINT unique_case_per_establishment_year UNIQUE (establishment_uuid, case_number, year_filing_for, data_version)
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Establishments
CREATE INDEX idx_establishments_ein ON establishments(ein);
CREATE INDEX idx_establishments_naics ON establishments(primary_naics_code);
CREATE INDEX idx_establishments_state ON establishments(state_code);
CREATE INDEX idx_establishments_active_years ON establishments(first_seen_year, last_seen_year);
CREATE INDEX idx_establishments_name_gin ON establishments USING gin(establishment_name gin_trgm_ops);

-- 300A Summary Data
CREATE INDEX idx_300a_establishment ON summary_300a_data(establishment_uuid);
CREATE INDEX idx_300a_year ON summary_300a_data(year_filing_for);
CREATE INDEX idx_300a_load ON summary_300a_data(load_id);
CREATE INDEX idx_300a_current ON summary_300a_data(is_current) WHERE is_current = true;
CREATE INDEX idx_300a_ita_id ON summary_300a_data(ita_id);

-- Case Detail Data
CREATE INDEX idx_case_establishment ON case_detail_data(establishment_uuid);
CREATE INDEX idx_case_year ON case_detail_data(year_filing_for);
CREATE INDEX idx_case_load ON case_detail_data(load_id);
CREATE INDEX idx_case_current ON case_detail_data(is_current) WHERE is_current = true;
CREATE INDEX idx_case_incident_date ON case_detail_data(date_of_incident);
CREATE INDEX idx_case_outcome ON case_detail_data(incident_outcome);
CREATE INDEX idx_case_type ON case_detail_data(type_of_incident);
CREATE INDEX idx_case_soc ON case_detail_data(soc_code);
CREATE INDEX idx_case_narratives_gin ON case_detail_data USING gin(incident_narratives);

-- Audit and Load tracking
CREATE INDEX idx_audit_table_record ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_load ON audit_log(load_id);
CREATE INDEX idx_audit_timestamp ON audit_log(changed_at);
CREATE INDEX idx_loads_year_type ON data_loads(data_year, load_type);
CREATE INDEX idx_loads_timestamp ON data_loads(load_timestamp);

-- =============================================================================
-- VIEWS FOR EASY DATA ACCESS
-- =============================================================================

-- Current 300A data (latest version only)
CREATE VIEW v_current_300a_summary AS
SELECT 
    s.*,
    e.establishment_name,
    e.company_name,
    e.current_address,
    e.primary_naics_code,
    e.industry_description,
    dl.load_timestamp,
    dl.source_file_name
FROM summary_300a_data s
JOIN establishments e ON s.establishment_uuid = e.establishment_uuid
JOIN data_loads dl ON s.load_id = dl.load_id
WHERE s.is_current = true;

-- Current case detail data (latest version only)
CREATE VIEW v_current_case_details AS
SELECT 
    c.*,
    e.establishment_name,
    e.company_name,
    e.current_address,
    e.primary_naics_code,
    e.industry_description,
    dl.load_timestamp,
    dl.source_file_name
FROM case_detail_data c
JOIN establishments e ON c.establishment_uuid = e.establishment_uuid
JOIN data_loads dl ON c.load_id = dl.load_id
WHERE c.is_current = true;

-- Establishment summary with latest data
CREATE VIEW v_establishment_summary AS
SELECT 
    e.*,
    s_latest.year_filing_for as latest_300a_year,
    s_latest.annual_average_employees,
    s_latest.total_hours_worked,
    s_latest.total_injuries,
    c_counts.total_cases,
    c_counts.latest_case_year
FROM establishments e
LEFT JOIN (
    SELECT DISTINCT ON (establishment_uuid) 
        establishment_uuid,
        year_filing_for,
        annual_average_employees,
        total_hours_worked,
        total_injuries
    FROM summary_300a_data 
    WHERE is_current = true 
    ORDER BY establishment_uuid, year_filing_for DESC
) s_latest ON e.establishment_uuid = s_latest.establishment_uuid
LEFT JOIN (
    SELECT 
        establishment_uuid,
        COUNT(*) as total_cases,
        MAX(year_filing_for) as latest_case_year
    FROM case_detail_data 
    WHERE is_current = true 
    GROUP BY establishment_uuid
) c_counts ON e.establishment_uuid = c_counts.establishment_uuid;

-- =============================================================================
-- TRIGGERS FOR AUDIT TRAIL
-- =============================================================================

-- Generic audit trigger function
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    old_data JSONB;
    new_data JSONB;
    changed_fields TEXT[] := '{}';
    field_name TEXT;
BEGIN
    -- Convert OLD and NEW to JSONB
    IF TG_OP = 'DELETE' THEN
        old_data := to_jsonb(OLD);
        new_data := NULL;
    ELSIF TG_OP = 'INSERT' THEN
        old_data := NULL;
        new_data := to_jsonb(NEW);
    ELSE -- UPDATE
        old_data := to_jsonb(OLD);
        new_data := to_jsonb(NEW);
        
        -- Find changed fields
        FOR field_name IN SELECT jsonb_object_keys(new_data) LOOP
            IF old_data->field_name IS DISTINCT FROM new_data->field_name THEN
                changed_fields := array_append(changed_fields, field_name);
            END IF;
        END LOOP;
    END IF;
    
    -- Insert audit record
    INSERT INTO audit_log (
        table_name,
        record_id,
        operation,
        old_values,
        new_values,
        changed_fields
    ) VALUES (
        TG_TABLE_NAME,
        COALESCE(
            (new_data->>'establishment_uuid'),
            (new_data->>'summary_uuid'),
            (new_data->>'case_uuid'),
            (old_data->>'establishment_uuid'),
            (old_data->>'summary_uuid'),
            (old_data->>'case_uuid'),
            'unknown'
        ),
        TG_OP,
        old_data,
        new_data,
        changed_fields
    );
    
    -- Return appropriate record
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Apply audit triggers to main tables
CREATE TRIGGER establishments_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON establishments
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER summary_300a_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON summary_300a_data
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER case_detail_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON case_detail_data
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

-- Function to create new data version
CREATE OR REPLACE FUNCTION create_new_version(
    table_name TEXT,
    record_uuid UUID,
    load_id_param UUID
) RETURNS UUID AS $$
DECLARE
    new_uuid UUID;
BEGIN
    new_uuid := uuid_generate_v4();
    
    -- Mark current version as superseded
    IF table_name = 'summary_300a_data' THEN
        UPDATE summary_300a_data 
        SET is_current = false, 
            effective_until = CURRENT_TIMESTAMP,
            superseded_by = new_uuid
        WHERE summary_uuid = record_uuid;
    ELSIF table_name = 'case_detail_data' THEN
        UPDATE case_detail_data 
        SET is_current = false, 
            effective_until = CURRENT_TIMESTAMP,
            superseded_by = new_uuid
        WHERE case_uuid = record_uuid;
    END IF;
    
    RETURN new_uuid;
END;
$$ LANGUAGE plpgsql;

-- Function to update load statistics
CREATE OR REPLACE FUNCTION update_load_stats(
    load_id_param UUID,
    loaded_count INTEGER DEFAULT 0,
    updated_count INTEGER DEFAULT 0,
    failed_count INTEGER DEFAULT 0
) RETURNS VOID AS $$
BEGIN
    UPDATE data_loads 
    SET 
        records_loaded = records_loaded + loaded_count,
        records_updated = records_updated + updated_count,
        records_failed = records_failed + failed_count,
        updated_at = CURRENT_TIMESTAMP
    WHERE load_id = load_id_param;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- INITIAL REFERENCE DATA
-- =============================================================================

-- Insert common state codes
INSERT INTO ref_states (state_code, state_name, is_territory) VALUES
('AL', 'Alabama', false),
('AK', 'Alaska', false),
('AZ', 'Arizona', false),
('AR', 'Arkansas', false),
('CA', 'California', false),
('CO', 'Colorado', false),
('CT', 'Connecticut', false),
('DE', 'Delaware', false),
('FL', 'Florida', false),
('GA', 'Georgia', false),
('HI', 'Hawaii', false),
('ID', 'Idaho', false),
('IL', 'Illinois', false),
('IN', 'Indiana', false),
('IA', 'Iowa', false),
('KS', 'Kansas', false),
('KY', 'Kentucky', false),
('LA', 'Louisiana', false),
('ME', 'Maine', false),
('MD', 'Maryland', false),
('MA', 'Massachusetts', false),
('MI', 'Michigan', false),
('MN', 'Minnesota', false),
('MS', 'Mississippi', false),
('MO', 'Missouri', false),
('MT', 'Montana', false),
('NE', 'Nebraska', false),
('NV', 'Nevada', false),
('NH', 'New Hampshire', false),
('NJ', 'New Jersey', false),
('NM', 'New Mexico', false),
('NY', 'New York', false),
('NC', 'North Carolina', false),
('ND', 'North Dakota', false),
('OH', 'Ohio', false),
('OK', 'Oklahoma', false),
('OR', 'Oregon', false),
('PA', 'Pennsylvania', false),
('RI', 'Rhode Island', false),
('SC', 'South Carolina', false),
('SD', 'South Dakota', false),
('TN', 'Tennessee', false),
('TX', 'Texas', false),
('UT', 'Utah', false),
('VT', 'Vermont', false),
('VA', 'Virginia', false),
('WA', 'Washington', false),
('WV', 'West Virginia', false),
('WI', 'Wisconsin', false),
('WY', 'Wyoming', false),
('DC', 'District of Columbia', true),
('PR', 'Puerto Rico', true),
('VI', 'U.S. Virgin Islands', true),
('AS', 'American Samoa', true),
('GU', 'Guam', true),
('MP', 'Northern Mariana Islands', true);

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE establishments IS 'Master table for all establishments with versioning support';
COMMENT ON TABLE summary_300a_data IS 'Annual summary data from OSHA Form 300A with full versioning';
COMMENT ON TABLE case_detail_data IS 'Individual incident/case details from OSHA Forms 300/301 with versioning';
COMMENT ON TABLE data_loads IS 'Tracks all data load operations for audit and recovery';
COMMENT ON TABLE audit_log IS 'Complete audit trail for all data changes';

COMMENT ON COLUMN establishments.establishment_uuid IS 'Internal UUID for establishment - never changes';
COMMENT ON COLUMN establishments.establishment_id IS 'OSHA assigned establishment ID - may change over time';
COMMENT ON COLUMN summary_300a_data.establishment_snapshot IS 'JSON snapshot of establishment data at time of filing';
COMMENT ON COLUMN case_detail_data.incident_narratives IS 'JSON structure containing all narrative fields for easy analysis';

-- =============================================================================
-- SAMPLE USAGE EXAMPLES
-- =============================================================================

/*
-- Example: Start a new data load
INSERT INTO data_loads (load_type, source_file_name, data_year, load_notes)
VALUES ('300A_summary', 'ITA_300A_Summary_Data_2024.csv', 2024, 'Initial 2024 data load')
RETURNING load_id;

-- Example: Query current data for a specific year
SELECT * FROM v_current_300a_summary WHERE year_filing_for = 2024;

-- Example: Find all versions of data for an establishment
SELECT * FROM summary_300a_data 
WHERE establishment_uuid = 'some-uuid'
ORDER BY data_version DESC;

-- Example: Get audit trail for changes
SELECT * FROM audit_log 
WHERE table_name = 'summary_300a_data' 
AND record_id = 'some-uuid'
ORDER BY changed_at DESC;
*/