-- ===============================
-- CFR EXTENSION TO OSHA RULES SCHEMA
-- Extends existing schema to handle CFR content types
-- ===============================

SET search_path TO osha_rules_v2;

-- ===============================
-- NEW TABLES FOR CFR CONTENT
-- ===============================

-- 1. CFR_CONTENT_TYPE (Lookup table for content types)
CREATE TABLE cfr_content_type (
    content_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL UNIQUE, -- definition, training, procedure, reference, appendix
    description TEXT,
    is_rule_based BOOLEAN DEFAULT FALSE,    -- TRUE if maps to rule table, FALSE if standalone
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. CFR_CONTENT (Master table for all CFR content)
CREATE TABLE cfr_content (
    content_id SERIAL PRIMARY KEY,
    regulation_id INTEGER NOT NULL REFERENCES regulation(regulation_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    content_type_id INTEGER NOT NULL REFERENCES cfr_content_type(content_type_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    
    -- Content identification
    content_code VARCHAR(300) NOT NULL,     -- e.g., "1910.155(c)(1)", "1910.156(c)(1)"
    title TEXT,
    
    -- Hierarchy (flexible for CFR structure)
    section_number VARCHAR(200),
    subsection VARCHAR(300),
    paragraph VARCHAR(200),
    page_number VARCHAR(50),
    line_reference VARCHAR(100),
    hierarchy_path TEXT,                    -- "Part 1910 → Subpart L → 1910.155(c)(1)"
    
    -- Content
    content_text TEXT NOT NULL,
    summary TEXT,
    category VARCHAR(200),
    status VARCHAR(100),                    -- mandatory, guidance, informational
    
    -- Source tracking
    source_location JSONB,                  -- Complete source location data
    cross_references JSONB,                 -- Array of cross-references
    related_terms TEXT[],                   -- Array of related terms
    
    -- Linking to existing rule system (optional)
    rule_id INTEGER REFERENCES rule(rule_id) ON DELETE SET NULL ON UPDATE CASCADE,
    
    -- Version control
    is_current BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,
    
    -- Audit fields
    created_by VARCHAR(200) DEFAULT 'system',
    updated_by VARCHAR(200) DEFAULT 'system',
    source_data JSONB,                      -- Original extraction data
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. CFR_TRAINING_DETAILS (Specialized table for training content)
CREATE TABLE cfr_training_details (
    training_detail_id SERIAL PRIMARY KEY,
    content_id INTEGER NOT NULL REFERENCES cfr_content(content_id) ON DELETE CASCADE ON UPDATE CASCADE,
    
    -- Training specifics
    frequency VARCHAR(200),
    scope TEXT,
    trainer_requirements TEXT,
    audience TEXT,
    quality_benchmark TEXT,
    example_institutions TEXT[],
    industry_specific TEXT,
    trigger_condition TEXT,
    performance_standard TEXT,
    
    -- Procedure steps (for training procedures)
    procedure_steps TEXT[],
    required_elements TEXT[],
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. CFR_REFERENCE_DETAILS (For standards and references)
CREATE TABLE cfr_reference_details (
    reference_detail_id SERIAL PRIMARY KEY,
    content_id INTEGER NOT NULL REFERENCES cfr_content(content_id) ON DELETE CASCADE ON UPDATE CASCADE,
    
    -- Reference specifics
    standard_id VARCHAR(200),
    reference_title TEXT,
    organization VARCHAR(300),
    publication_year VARCHAR(20),
    purpose TEXT,
    incorporation_method VARCHAR(200),
    publication_title TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. CFR_APPENDIX_DETAILS (For appendix content)
CREATE TABLE cfr_appendix_details (
    appendix_detail_id SERIAL PRIMARY KEY,
    content_id INTEGER NOT NULL REFERENCES cfr_content(content_id) ON DELETE CASCADE ON UPDATE CASCADE,
    
    -- Appendix specifics
    appendix_type VARCHAR(200),             -- mandatory, non-mandatory, informational
    purpose TEXT,
    scope TEXT,
    content_areas TEXT[],
    organizations TEXT[],
    coverage TEXT,
    test_methods TEXT[],
    includes TEXT[],
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===============================
-- INDEXES FOR CFR TABLES
-- ===============================

-- Primary business indexes
CREATE UNIQUE INDEX idx_cfr_content_code ON cfr_content(content_code) WHERE is_current = TRUE AND is_deleted = FALSE;
CREATE INDEX idx_cfr_content_regulation ON cfr_content(regulation_id);
CREATE INDEX idx_cfr_content_type ON cfr_content(content_type_id);
CREATE INDEX idx_cfr_content_rule ON cfr_content(rule_id) WHERE rule_id IS NOT NULL;

-- Content filtering
CREATE INDEX idx_cfr_content_status ON cfr_content(status);
CREATE INDEX idx_cfr_content_category ON cfr_content(category);
CREATE INDEX idx_cfr_content_section ON cfr_content(section_number);
CREATE INDEX idx_cfr_content_current ON cfr_content(is_current, is_deleted);

-- JSONB indexes
CREATE INDEX idx_cfr_source_location ON cfr_content USING GIN(source_location);
CREATE INDEX idx_cfr_cross_references ON cfr_content USING GIN(cross_references);
CREATE INDEX idx_cfr_source_data ON cfr_content USING GIN(source_data);

-- Array indexes
CREATE INDEX idx_cfr_related_terms ON cfr_content USING GIN(related_terms);

-- Full-text search
CREATE INDEX idx_cfr_content_text_search ON cfr_content USING GIN(to_tsvector('english', content_text));
CREATE INDEX idx_cfr_title_search ON cfr_content USING GIN(to_tsvector('english', title)) WHERE title IS NOT NULL;

-- Detail table indexes
CREATE INDEX idx_training_details_content ON cfr_training_details(content_id);
CREATE INDEX idx_reference_details_content ON cfr_reference_details(content_id);
CREATE INDEX idx_appendix_details_content ON cfr_appendix_details(content_id);

-- ===============================
-- TRIGGERS FOR CFR TABLES
-- ===============================

CREATE TRIGGER tr_cfr_content_updated_at 
    BEFORE UPDATE ON cfr_content 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===============================
-- UTILITY FUNCTIONS FOR CFR CONTENT
-- ===============================

-- Function to get all content for a regulation
CREATE OR REPLACE FUNCTION get_cfr_regulation_content(p_regulation_code VARCHAR(500))
RETURNS TABLE(
    content_id INTEGER,
    content_code VARCHAR(300),
    content_type VARCHAR(100),
    title TEXT,
    content_text TEXT,
    status VARCHAR(100),
    hierarchy_path TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.content_id,
        c.content_code,
        ct.type_name,
        c.title,
        c.content_text,
        c.status,
        c.hierarchy_path
    FROM cfr_content c
    JOIN cfr_content_type ct ON c.content_type_id = ct.content_type_id
    JOIN regulation r ON c.regulation_id = r.regulation_id
    WHERE r.regulation_code = p_regulation_code
    AND c.is_current = TRUE 
    AND c.is_deleted = FALSE
    ORDER BY c.content_code;
END;
$$ LANGUAGE plpgsql;

-- Function to get training requirements for a regulation
CREATE OR REPLACE FUNCTION get_cfr_training_requirements(p_regulation_code VARCHAR(500))
RETURNS TABLE(
    content_code VARCHAR(300),
    title TEXT,
    frequency VARCHAR(200),
    audience TEXT,
    trigger_condition TEXT,
    procedure_steps TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.content_code,
        c.title,
        td.frequency,
        td.audience,
        td.trigger_condition,
        td.procedure_steps
    FROM cfr_content c
    JOIN cfr_content_type ct ON c.content_type_id = ct.content_type_id
    JOIN cfr_training_details td ON c.content_id = td.content_id
    JOIN regulation r ON c.regulation_id = r.regulation_id
    WHERE r.regulation_code = p_regulation_code
    AND ct.type_name = 'training'
    AND c.is_current = TRUE 
    AND c.is_deleted = FALSE
    ORDER BY c.content_code;
END;
$$ LANGUAGE plpgsql;

-- Function to search CFR content by text
CREATE OR REPLACE FUNCTION search_cfr_content(p_search_text TEXT)
RETURNS TABLE(
    content_id INTEGER,
    content_code VARCHAR(300),
    content_type VARCHAR(100),
    title TEXT,
    content_text TEXT,
    rank REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.content_id,
        c.content_code,
        ct.type_name,
        c.title,
        c.content_text,
        ts_rank(to_tsvector('english', c.content_text), plainto_tsquery('english', p_search_text)) as rank
    FROM cfr_content c
    JOIN cfr_content_type ct ON c.content_type_id = ct.content_type_id
    WHERE to_tsvector('english', c.content_text) @@ plainto_tsquery('english', p_search_text)
    AND c.is_current = TRUE 
    AND c.is_deleted = FALSE
    ORDER BY rank DESC, c.content_code;
END;
$$ LANGUAGE plpgsql;

-- ===============================
-- INSERT CONTENT TYPES
-- ===============================

INSERT INTO cfr_content_type (type_name, description, is_rule_based) VALUES
('definition', 'Regulatory definitions and terminology', FALSE),
('training', 'Training requirements and procedures', TRUE),
('procedure', 'Required procedures and processes', TRUE),
('reference', 'External standards and references', FALSE),
('appendix', 'Appendices and guidance documents', FALSE);

-- ===============================
-- MASTER QUERY VIEW
-- ===============================

-- Create a view that combines all CFR content with optional rule linkage
CREATE OR REPLACE VIEW v_cfr_master AS
SELECT 
    c.content_id,
    c.content_code,
    ct.type_name as content_type,
    c.title,
    c.content_text,
    c.summary,
    c.category,
    c.status,
    c.hierarchy_path,
    c.section_number,
    c.subsection,
    c.paragraph,
    
    -- Regulation info
    r.regulation_code,
    r.title as regulation_title,
    r.part,
    r.subpart,
    
    -- Optional rule linkage
    ru.rule_code,
    ru.rule_text,
    ru.severity,
    
    -- Training details (if applicable)
    td.frequency,
    td.audience,
    td.trigger_condition,
    
    -- Reference details (if applicable)
    rd.standard_id,
    rd.organization,
    rd.publication_year,
    
    -- Appendix details (if applicable)
    ad.appendix_type,
    ad.purpose as appendix_purpose,
    
    c.source_location,
    c.cross_references,
    c.related_terms,
    c.created_at,
    c.updated_at
    
FROM cfr_content c
JOIN cfr_content_type ct ON c.content_type_id = ct.content_type_id
JOIN regulation r ON c.regulation_id = r.regulation_id
LEFT JOIN rule ru ON c.rule_id = ru.rule_id
LEFT JOIN cfr_training_details td ON c.content_id = td.content_id
LEFT JOIN cfr_reference_details rd ON c.content_id = rd.content_id
LEFT JOIN cfr_appendix_details ad ON c.content_id = ad.content_id
WHERE c.is_current = TRUE AND c.is_deleted = FALSE;

-- ===============================
-- COMMENTS
-- ===============================

COMMENT ON TABLE cfr_content IS 'Master table for all CFR content types (definitions, training, procedures, references, appendices)';
COMMENT ON TABLE cfr_content_type IS 'Lookup table for different types of CFR content';
COMMENT ON TABLE cfr_training_details IS 'Detailed training information for training-type CFR content';
COMMENT ON TABLE cfr_reference_details IS 'Detailed reference information for external standards';
COMMENT ON TABLE cfr_appendix_details IS 'Detailed information for appendix content';
COMMENT ON VIEW v_cfr_master IS 'Unified view of all CFR content with related details';

-- ===============================
-- SCHEMA VERIFICATION
-- ===============================

DO $$
DECLARE
    new_table_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO new_table_count 
    FROM information_schema.tables 
    WHERE table_schema = 'osha_rules_v2'
    AND table_name LIKE 'cfr_%';
    
    RAISE NOTICE 'Added % new CFR tables to osha_rules_v2 schema', new_table_count;
END $$;


-- Run this in your database to add the missing constraints
SET search_path TO osha_rules_v2;

ALTER TABLE cfr_training_details 
ADD CONSTRAINT uk_cfr_training_details_content_id UNIQUE (content_id);

ALTER TABLE cfr_reference_details 
ADD CONSTRAINT uk_cfr_reference_details_content_id UNIQUE (content_id);

ALTER TABLE cfr_appendix_details 
ADD CONSTRAINT uk_cfr_appendix_details_content_id UNIQUE (content_id);