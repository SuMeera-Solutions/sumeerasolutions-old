-- 29 CFR Part 1904 PostgreSQL Data Model (PostgreSQL 15.12 Compatible)
-- Designed for versioning, performance, and UI query efficiency

-- ============================================================================
-- CORE VERSIONING AND METADATA TABLES
-- ============================================================================

-- Main regulation versions table
CREATE TABLE regulation_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    regulation_id VARCHAR(50) NOT NULL, -- e.g., '29_CFR_1904'
    version_number VARCHAR(20) NOT NULL, -- e.g., 'v1.0'
    effective_date DATE NOT NULL,
    last_updated TIMESTAMP NOT NULL,
    parsing_date TIMESTAMP NOT NULL,
    content_hash VARCHAR(128) NOT NULL,
    source_url TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    is_current BOOLEAN DEFAULT FALSE,
    
    UNIQUE(regulation_id, version_number)
);

-- Legal basis and authority
CREATE TABLE regulation_authorities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    authority_type VARCHAR(50), -- 'USC', 'CFR', 'Executive_Order', etc.
    citation VARCHAR(100) NOT NULL,
    description TEXT
);

-- Editorial notes and amendments
CREATE TABLE regulation_amendments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    amendment_date DATE NOT NULL,
    federal_register_citation VARCHAR(50),
    amendment_type VARCHAR(50), -- 'addition', 'removal', 'modification'
    description TEXT NOT NULL
);

-- ============================================================================
-- COMPANY APPLICABILITY TABLES
-- ============================================================================

-- Size-based exemptions
CREATE TABLE size_exemptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    exemption_id VARCHAR(100) NOT NULL,
    regulation_ref VARCHAR(50) NOT NULL,
    employee_threshold INTEGER NOT NULL,
    condition_description TEXT NOT NULL,
    scope VARCHAR(50), -- 'entire_company', 'establishment'
    result_description TEXT NOT NULL,
    verbatim_text TEXT
);

-- Exceptions to size exemptions
CREATE TABLE size_exemption_exceptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    size_exemption_id UUID REFERENCES size_exemptions(id) ON DELETE CASCADE,
    exception_type VARCHAR(100) NOT NULL,
    requirement_description TEXT NOT NULL,
    regulation_ref VARCHAR(50)
);

-- NAICS industry codes and exemptions
CREATE TABLE naics_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    naics_code VARCHAR(10) NOT NULL,
    industry_description TEXT NOT NULL,
    exemption_type VARCHAR(100), -- 'partial_exemption', 'electronic_submission_20_249', etc.
    appendix_reference VARCHAR(10) -- 'A', 'B', etc.
);

-- Industry exemption details
CREATE TABLE industry_exemptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    exemption_id VARCHAR(100) NOT NULL,
    regulation_ref VARCHAR(50) NOT NULL,
    scope VARCHAR(50), -- 'individual_business_establishments'
    result_description TEXT NOT NULL,
    verbatim_text TEXT
);

-- Exceptions to industry exemptions
CREATE TABLE industry_exemption_exceptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    industry_exemption_id UUID REFERENCES industry_exemptions(id) ON DELETE CASCADE,
    exception_description TEXT NOT NULL
);

-- ============================================================================
-- RECORDING CRITERIA TABLES
-- ============================================================================

-- Decision tree steps
CREATE TABLE decision_tree_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    step_number INTEGER NOT NULL,
    question TEXT NOT NULL,
    regulation_ref VARCHAR(50),
    yes_path_action VARCHAR(100),
    no_path_action VARCHAR(100),
    determination_method VARCHAR(100),
    notes TEXT
);

-- Work-relatedness criteria
CREATE TABLE work_relatedness_criteria (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    regulation_ref VARCHAR(50) NOT NULL,
    basic_requirement TEXT NOT NULL,
    presumption_rule TEXT,
    work_environment_definition TEXT
);

-- Work-relatedness exceptions
CREATE TABLE work_relatedness_exceptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    criteria_id UUID REFERENCES work_relatedness_criteria(id) ON DELETE CASCADE,
    exception_type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    notes TEXT
);

-- General recording criteria
CREATE TABLE general_recording_criteria (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    criterion_name VARCHAR(100) NOT NULL, -- 'death', 'days_away', etc.
    regulation_ref VARCHAR(50) NOT NULL,
    condition_description TEXT NOT NULL,
    form_name VARCHAR(50), -- 'OSHA_300_Log'
    form_action TEXT
);

-- Additional requirements for criteria
CREATE TABLE criterion_additional_requirements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    criterion_id UUID REFERENCES general_recording_criteria(id) ON DELETE CASCADE,
    requirement_type VARCHAR(100) NOT NULL,
    timing VARCHAR(50),
    regulation_ref VARCHAR(50),
    description TEXT
);

-- Specific recording criteria (needlestick, hearing loss, etc.)
CREATE TABLE specific_recording_criteria (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    criterion_type VARCHAR(100) NOT NULL, -- 'needlestick', 'hearing_loss', etc.
    regulation_ref VARCHAR(50) NOT NULL,
    requirement_description TEXT NOT NULL,
    form_entry_instructions TEXT,
    privacy_protection_required BOOLEAN DEFAULT FALSE
);

-- ============================================================================
-- FORM REQUIREMENTS TABLES
-- ============================================================================

-- Required forms
CREATE TABLE required_forms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    form_id VARCHAR(20) NOT NULL, -- 'OSHA_300', 'OSHA_300A', 'OSHA_301'
    form_name TEXT NOT NULL,
    regulation_ref VARCHAR(50) NOT NULL,
    purpose_description TEXT NOT NULL,
    completion_deadline VARCHAR(50),
    completion_trigger TEXT
);

-- Form required information
CREATE TABLE form_required_information (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_id UUID REFERENCES required_forms(id) ON DELETE CASCADE,
    information_type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    is_required BOOLEAN DEFAULT TRUE
);

-- Privacy concern cases
CREATE TABLE privacy_concern_cases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    case_type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    handling_instructions TEXT
);

-- ============================================================================
-- ONGOING OBLIGATIONS TABLES
-- ============================================================================

-- Retention requirements
CREATE TABLE retention_requirements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    record_type VARCHAR(100) NOT NULL, -- 'OSHA_300_Log', 'annual_summary', etc.
    retention_period_years INTEGER NOT NULL,
    regulation_ref VARCHAR(50) NOT NULL,
    update_required_during_retention BOOLEAN DEFAULT FALSE
);

-- Annual summary requirements
CREATE TABLE annual_summary_requirements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    requirement_type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    deadline VARCHAR(50),
    regulation_ref VARCHAR(50)
);

-- Authorized signatories for certification
CREATE TABLE authorized_signatories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    signatory_type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    conditions TEXT
);

-- Employee access rights
CREATE TABLE employee_access_rights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    accessor_type VARCHAR(100) NOT NULL, -- 'employee', 'former_employee', etc.
    record_type VARCHAR(50) NOT NULL, -- 'OSHA_300', 'OSHA_301'
    access_deadline VARCHAR(50),
    scope_limitations TEXT,
    information_restrictions TEXT
);

-- ============================================================================
-- GOVERNMENT REPORTING TABLES
-- ============================================================================

-- Immediate reporting requirements
CREATE TABLE immediate_reporting_requirements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    trigger_event VARCHAR(100) NOT NULL,
    regulation_ref VARCHAR(50) NOT NULL,
    deadline VARCHAR(50) NOT NULL,
    recipient VARCHAR(50) NOT NULL
);

-- Reporting methods
CREATE TABLE reporting_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporting_requirement_id UUID REFERENCES immediate_reporting_requirements(id) ON DELETE CASCADE,
    method_description TEXT NOT NULL,
    contact_info TEXT
);

-- Required reporting information
CREATE TABLE required_reporting_information (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporting_requirement_id UUID REFERENCES immediate_reporting_requirements(id) ON DELETE CASCADE,
    information_type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    is_required BOOLEAN DEFAULT TRUE
);

-- Reporting exceptions
CREATE TABLE reporting_exceptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    exception_type VARCHAR(100) NOT NULL,
    condition_description TEXT NOT NULL,
    result_description TEXT NOT NULL
);

-- Electronic submission requirements
CREATE TABLE electronic_submission_requirements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    submission_category VARCHAR(100) NOT NULL,
    employee_threshold_min INTEGER,
    employee_threshold_max INTEGER,
    industry_restriction VARCHAR(10), -- 'appendix_A', 'appendix_B', etc.
    forms_required TEXT[], -- Array of form names
    deadline VARCHAR(50) NOT NULL,
    regulation_ref VARCHAR(50)
);

-- ============================================================================
-- DEFINITIONS AND REFERENCE DATA TABLES
-- ============================================================================

-- Regulatory definitions
CREATE TABLE regulatory_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    term VARCHAR(100) NOT NULL,
    regulation_ref VARCHAR(50),
    definition_type VARCHAR(50), -- 'complete_list', 'basic_definition', etc.
    definition_text TEXT NOT NULL,
    examples TEXT,
    exceptions TEXT
);

-- First aid treatments (specific detailed list)
CREATE TABLE first_aid_treatments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    treatment_name VARCHAR(100) NOT NULL,
    treatment_details TEXT NOT NULL,
    exceptions TEXT
);

-- Cross-references between regulations
CREATE TABLE regulation_cross_references (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_regulation VARCHAR(50) NOT NULL,
    target_regulation VARCHAR(50) NOT NULL,
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    relationship_type VARCHAR(50), -- 'depends_on', 'references', 'conflicts_with'
    description TEXT
);

-- ============================================================================
-- BUSINESS CHANGE AND VARIANCE PROVISIONS
-- ============================================================================

-- Transition provisions
CREATE TABLE transition_provisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    provision_type VARCHAR(100) NOT NULL,
    regulation_ref VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    effective_period VARCHAR(100),
    requirements TEXT[]
);

-- Variance provisions
CREATE TABLE variance_provisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    variance_type VARCHAR(100) NOT NULL,
    regulation_ref VARCHAR(50) NOT NULL,
    approval_criteria TEXT[],
    petition_requirements TEXT[],
    processing_steps TEXT[]
);

-- State plan provisions
CREATE TABLE state_plan_provisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID REFERENCES regulation_versions(id) ON DELETE CASCADE,
    provision_type VARCHAR(100) NOT NULL,
    regulation_ref VARCHAR(50) NOT NULL,
    requirement_description TEXT NOT NULL,
    state_flexibility_allowed BOOLEAN DEFAULT FALSE
);

-- ============================================================================
-- CREATE ALL INDEXES SEPARATELY (PostgreSQL 15.12 Compatible)
-- ============================================================================

-- Primary performance indexes
CREATE INDEX idx_regulation_current ON regulation_versions (regulation_id, is_current) WHERE is_current = TRUE;
CREATE INDEX idx_authority_version ON regulation_authorities (version_id);
CREATE INDEX idx_amendment_version_date ON regulation_amendments (version_id, amendment_date);
CREATE INDEX idx_size_exemption_threshold ON size_exemptions (version_id, employee_threshold);
CREATE INDEX idx_size_exception_type ON size_exemption_exceptions (size_exemption_id, exception_type);
CREATE INDEX idx_naics_code ON naics_codes (version_id, naics_code);
CREATE INDEX idx_naics_exemption_type ON naics_codes (version_id, exemption_type);
CREATE INDEX idx_industry_exemption ON industry_exemptions (version_id, exemption_id);
CREATE INDEX idx_decision_step ON decision_tree_steps (version_id, step_number);
CREATE INDEX idx_work_exception_type ON work_relatedness_exceptions (criteria_id, exception_type);
CREATE INDEX idx_general_criterion ON general_recording_criteria (version_id, criterion_name);
CREATE INDEX idx_form_id ON required_forms (version_id, form_id);
CREATE INDEX idx_privacy_case_type ON privacy_concern_cases (version_id, case_type);
CREATE INDEX idx_retention_type ON retention_requirements (version_id, record_type);
CREATE INDEX idx_reporting_trigger ON immediate_reporting_requirements (version_id, trigger_event);
CREATE INDEX idx_definition_term ON regulatory_definitions (version_id, term);
CREATE INDEX idx_first_aid_treatment ON first_aid_treatments (version_id, treatment_name);
CREATE INDEX idx_cross_ref_source ON regulation_cross_references (version_id, source_regulation);

-- Composite indexes for common query patterns
CREATE INDEX idx_naics_version_type ON naics_codes(version_id, exemption_type, naics_code);
CREATE INDEX idx_criteria_version_type ON general_recording_criteria(version_id, criterion_name);
CREATE INDEX idx_forms_version_purpose ON required_forms(version_id, purpose_description);
CREATE INDEX idx_reporting_version_event ON immediate_reporting_requirements(version_id, trigger_event);
CREATE INDEX idx_definitions_version_term ON regulatory_definitions(version_id, term);

-- Full-text search indexes for UI search functionality
CREATE INDEX idx_definitions_fts ON regulatory_definitions USING gin(to_tsvector('english', definition_text));
CREATE INDEX idx_criteria_fts ON general_recording_criteria USING gin(to_tsvector('english', condition_description));
CREATE INDEX idx_naics_fts ON naics_codes USING gin(to_tsvector('english', industry_description));

-- ============================================================================
-- VIEWS FOR COMMON UI QUERIES
-- ============================================================================

-- Current regulation summary view
CREATE VIEW current_regulation_summary AS
SELECT 
    rv.regulation_id,
    rv.version_number,
    rv.effective_date,
    rv.last_updated,
    COUNT(DISTINCT nc.id) as total_naics_codes,
    COUNT(DISTINCT se.id) as size_exemptions_count,
    COUNT(DISTINCT ie.id) as industry_exemptions_count,
    COUNT(DISTINCT grc.id) as recording_criteria_count,
    COUNT(DISTINCT rf.id) as required_forms_count
FROM regulation_versions rv
LEFT JOIN naics_codes nc ON rv.id = nc.version_id
LEFT JOIN size_exemptions se ON rv.id = se.version_id
LEFT JOIN industry_exemptions ie ON rv.id = ie.version_id  
LEFT JOIN general_recording_criteria grc ON rv.id = grc.version_id
LEFT JOIN required_forms rf ON rv.id = rf.version_id
WHERE rv.is_current = TRUE
GROUP BY rv.id, rv.regulation_id, rv.version_number, rv.effective_date, rv.last_updated;

-- Company applicability checker view
CREATE VIEW company_applicability_check AS
SELECT 
    rv.regulation_id,
    nc.naics_code,
    nc.industry_description,
    nc.exemption_type,
    se.employee_threshold,
    se.condition_description as size_exemption_condition,
    ARRAY_AGG(DISTINCT see.requirement_description) as exemption_exceptions
FROM regulation_versions rv
LEFT JOIN naics_codes nc ON rv.id = nc.version_id
LEFT JOIN size_exemptions se ON rv.id = se.version_id
LEFT JOIN size_exemption_exceptions see ON se.id = see.size_exemption_id
WHERE rv.is_current = TRUE
GROUP BY rv.regulation_id, nc.naics_code, nc.industry_description, nc.exemption_type, 
         se.employee_threshold, se.condition_description;

-- Recording decision helper view
CREATE VIEW recording_decision_helper AS
SELECT 
    rv.regulation_id,
    dts.step_number,
    dts.question,
    dts.regulation_ref,
    dts.yes_path_action,
    dts.no_path_action,
    dts.determination_method,
    dts.notes
FROM regulation_versions rv
JOIN decision_tree_steps dts ON rv.id = dts.version_id
WHERE rv.is_current = TRUE
ORDER BY dts.step_number;

-- Form requirements summary view
CREATE VIEW form_requirements_summary AS
SELECT 
    rv.regulation_id,
    rf.form_id,
    rf.form_name,
    rf.purpose_description,
    rf.completion_deadline,
    rf.completion_trigger,
    ARRAY_AGG(fri.description) as required_information
FROM regulation_versions rv
JOIN required_forms rf ON rv.id = rf.version_id
LEFT JOIN form_required_information fri ON rf.id = fri.form_id
WHERE rv.is_current = TRUE
GROUP BY rv.regulation_id, rf.form_id, rf.form_name, rf.purpose_description, 
         rf.completion_deadline, rf.completion_trigger;

-- ============================================================================
-- FUNCTIONS FOR VERSION MANAGEMENT
-- ============================================================================

-- Function to create new regulation version
CREATE OR REPLACE FUNCTION create_regulation_version(
    p_regulation_id VARCHAR(50),
    p_version_number VARCHAR(20),
    p_effective_date DATE,
    p_content_hash VARCHAR(128),
    p_source_url TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_version_id UUID;
BEGIN
    -- Set all existing versions to not current
    UPDATE regulation_versions 
    SET is_current = FALSE 
    WHERE regulation_id = p_regulation_id;
    
    -- Insert new version
    INSERT INTO regulation_versions (
        regulation_id, version_number, effective_date, 
        last_updated, parsing_date, content_hash, source_url, is_current
    ) VALUES (
        p_regulation_id, p_version_number, p_effective_date,
        NOW(), NOW(), p_content_hash, p_source_url, TRUE
    ) RETURNING id INTO v_version_id;
    
    RETURN v_version_id;
END;
$$ LANGUAGE plpgsql;

-- Function to get current version ID
CREATE OR REPLACE FUNCTION get_current_version_id(p_regulation_id VARCHAR(50)) 
RETURNS UUID AS $$
DECLARE
    v_version_id UUID;
BEGIN
    SELECT id INTO v_version_id
    FROM regulation_versions
    WHERE regulation_id = p_regulation_id AND is_current = TRUE;
    
    RETURN v_version_id;
END;
$$ LANGUAGE plpgsql;