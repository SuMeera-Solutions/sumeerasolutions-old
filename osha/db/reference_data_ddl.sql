-- =====================================================
-- CFR Regulations Database - PostgreSQL DDL
-- Generic Design for Any CFR Title/Part/Subpart
-- =====================================================

-- Create schema for regulations data
CREATE SCHEMA IF NOT EXISTS cfr_regulations;

-- Set search path to include the schema
SET search_path TO cfr_regulations, public;

-- =====================================================
-- CFR Regulations Table (Generic for Any Title)
-- =====================================================

CREATE TABLE cfr_regulations (
    id SERIAL PRIMARY KEY,
    cfr_title VARCHAR(20),                    -- e.g., "29", "40", "49"
    cfr_part VARCHAR(20),                     -- e.g., "1910", "1926"
    cfr_subpart VARCHAR(20),                  -- e.g., "D", "L", "Z"
    part_subpart VARCHAR(100) NOT NULL,       -- e.g., "1910 Subpart D (1910.21-1910.30)"
    section_range VARCHAR(50),                -- e.g., "(1910.21-1910.30)"
    title VARCHAR(200) NOT NULL,              -- Regulation title
    description TEXT NOT NULL,                -- Detailed description
    applicable_industries TEXT,               -- Industries this applies to
    applicable_sectors TEXT,                  -- Specific sectors
    regulation_category VARCHAR(100),         -- Category of regulation
    hazard_types TEXT,                        -- Types of hazards addressed
    keywords TEXT,                           -- Searchable keywords
    ecfr_link VARCHAR(300) NOT NULL,         -- Link to eCFR
    status VARCHAR(20) DEFAULT 'Active',     -- Active, Superseded, Pending
    effective_date DATE,                     -- When regulation became effective
    last_amended_date DATE,                  -- Last amendment date
    agency VARCHAR(50),                      -- Issuing agency (OSHA, EPA, etc.)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- Indexes for Performance
-- =====================================================

CREATE INDEX idx_cfr_title ON cfr_regulations(cfr_title);
CREATE INDEX idx_cfr_part ON cfr_regulations(cfr_part);
CREATE INDEX idx_cfr_subpart ON cfr_regulations(cfr_subpart);
CREATE INDEX idx_part_subpart ON cfr_regulations(part_subpart);
CREATE INDEX idx_title ON cfr_regulations(title);
CREATE INDEX idx_regulation_category ON cfr_regulations(regulation_category);
CREATE INDEX idx_status ON cfr_regulations(status);
CREATE INDEX idx_agency ON cfr_regulations(agency);
CREATE INDEX idx_industries ON cfr_regulations(applicable_industries);

-- =====================================================
-- Full Text Search Indexes
-- =====================================================

CREATE INDEX idx_description_fts ON cfr_regulations USING gin(to_tsvector('english', description));
CREATE INDEX idx_title_fts ON cfr_regulations USING gin(to_tsvector('english', title));
CREATE INDEX idx_keywords_fts ON cfr_regulations USING gin(to_tsvector('english', COALESCE(keywords, '')));

-- =====================================================
-- Composite Indexes for Common Queries
-- =====================================================

CREATE INDEX idx_title_part_subpart ON cfr_regulations(cfr_title, cfr_part, cfr_subpart);
CREATE INDEX idx_agency_title ON cfr_regulations(agency, cfr_title);

-- =====================================================
-- UPDATE TRIGGER for updated_at column
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_cfr_regulations_updated_at 
    BEFORE UPDATE ON cfr_regulations 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- INSERT STATEMENTS - OSHA Title 29 Oil & Gas Data
-- =====================================================

INSERT INTO cfr_regulations (
    cfr_title, cfr_part, cfr_subpart, part_subpart, section_range, title, 
    description, applicable_industries, applicable_sectors, regulation_category, 
    hazard_types, keywords, ecfr_link, agency
) VALUES 

('29', '1910', 'D', '1910 Subpart D (1910.21-1910.30)', '(1910.21-1910.30)', 'Walking-Working Surfaces', 'Standards for ladders, scaffolds, fall protection, and walking-working surfaces to prevent falls.', 'Oil and Gas', 'Upstream, Midstream, Downstream', 'Safety Standards', 'Falls, Ladder Safety, Scaffold Safety', 'walking surfaces, ladders, scaffolds, fall protection', 'https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XVII/part-1910/subpart-D', 'OSHA'),

('29', '1910', 'E', '1910 Subpart E (1910.33-1910.39)', '(1910.33-1910.39)', 'Exit Routes and Emergency Planning', 'Requirements for emergency action plans, fire prevention plans, and exit routes.', 'Oil and Gas', 'Upstream, Midstream, Downstream', 'Emergency Preparedness', 'Fire, Emergency Evacuation', 'exit routes, emergency planning, fire prevention', 'https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XVII/part-1910/subpart-E', 'OSHA'),

('29', '1910', 'F', '1910 Subpart F (1910.66-1910.68)', '(1910.66-1910.68)', 'Powered Platforms, Manlifts, and Vehicle-Mounted Work Platforms', 'Standards for elevated work platforms and manlifts used in maintenance activities.', 'Oil and Gas', 'Upstream, Downstream', 'Equipment Safety', 'Falls, Equipment Failure', 'powered platforms, manlifts, elevated work platforms', 'https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XVII/part-1910/subpart-F', 'OSHA'),

('29', '1910', 'H', '1910 Subpart H (1910.101-1910.126)', '(1910.101-1910.126)', 'Hazardous Materials', 'Covers flammable liquids (1910.106), compressed gases, and hazardous waste operations (HAZWOPER, 1910.120).', 'Oil and Gas', 'Upstream, Midstream, Downstream', 'Hazardous Materials', 'Fire, Explosion, Chemical Exposure', 'hazardous materials, flammable liquids, compressed gases, HAZWOPER', 'https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XVII/part-1910/subpart-H', 'OSHA'),

('29', '1910', 'I', '1910 Subpart I (1910.132-1910.138)', '(1910.132-1910.138)', 'Personal Protective Equipment', 'Requirements for PPE, including flame-resistant clothing, eye protection, and respiratory protection.', 'Oil and Gas', 'Upstream, Midstream, Downstream', 'Personal Protection', 'Chemical Exposure, Burns, Eye Injury', 'PPE, personal protective equipment, flame resistant clothing', 'https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XVII/part-1910/subpart-I', 'OSHA'),

('29', '1910', 'J', '1910 Subpart J (1910.141-1910.147)', '(1910.141-1910.147)', 'General Environmental Controls', 'Includes lockout/tagout (1910.147) for energy control and sanitation standards.', 'Oil and Gas', 'Upstream, Midstream, Downstream', 'Workplace Safety', 'Energy Hazards, Equipment Accidents', 'lockout tagout, LOTO, energy control, sanitation', 'https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XVII/part-1910/subpart-J', 'OSHA'),

('29', '1910', 'L', '1910 Subpart L (1910.156-1910.165)', '(1910.156-1910.165)', 'Fire Protection', 'Standards for fire brigades, portable fire extinguishers, and fire suppression systems.', 'Oil and Gas', 'Upstream, Midstream, Downstream', 'Fire Safety', 'Fire, Explosion', 'fire protection, fire extinguishers, fire suppression', 'https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XVII/part-1910/subpart-L', 'OSHA'),

('29', '1910', 'N', '1910 Subpart N (1910.177-1910.184)', '(1910.177-1910.184)', 'Materials Handling and Storage', 'Covers servicing multi-piece and single-piece rim wheels, cranes, and slings.', 'Oil and Gas', 'Upstream, Midstream, Downstream', 'Equipment Safety', 'Crushing, Struck By Objects', 'materials handling, cranes, slings, rim wheels', 'https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XVII/part-1910/subpart-N', 'OSHA'),

('29', '1910', 'Q', '1910 Subpart Q (1910.241-1910.244)', '(1910.241-1910.244)', 'Welding, Cutting, and Brazing', 'Safety standards for welding and cutting operations, common in maintenance and construction.', 'Oil and Gas', 'Upstream, Midstream, Downstream', 'Hot Work Safety', 'Burns, Fire, Explosion', 'welding, cutting, brazing, hot work', 'https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XVII/part-1910/subpart-Q', 'OSHA'),

('29', '1910', 'S', '1910 Subpart S (1910.301-1910.399)', '(1910.301-1910.399)', 'Electrical', 'Electrical safety standards for wiring, equipment, and hazardous locations.', 'Oil and Gas', 'Upstream, Midstream, Downstream', 'Electrical Safety', 'Electrocution, Fire, Explosion', 'electrical safety, wiring, hazardous locations', 'https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XVII/part-1910/subpart-S', 'OSHA'),

('29', '1910', 'Z', '1910 Subpart Z (1910.1000-1910.1450)', '(1910.1000-1910.1450)', 'Toxic and Hazardous Substances', 'Includes standards for air contaminants (1910.1000), process safety management (1910.119), and benzene (1910.1028).', 'Oil and Gas', 'Upstream, Midstream, Downstream', 'Chemical Safety', 'Chemical Exposure, Process Safety', 'toxic substances, air contaminants, process safety management, PSM, benzene', 'https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XVII/part-1910/subpart-Z', 'OSHA'),

('29', '1926', 'C', '1926 Subpart C (1926.20-1926.35)', '(1926.20-1926.35)', 'General Safety and Health Provisions', 'General safety requirements, including training and inspections for construction activities.', 'Oil and Gas', 'Upstream, Midstream', 'Construction Safety', 'Various Construction Hazards', 'construction safety, training, inspections', 'https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XVII/part-1926/subpart-C', 'OSHA'),

('29', '1926', 'D', '1926 Subpart D (1926.50-1926.66)', '(1926.50-1926.66)', 'Occupational Health and Environmental Controls', 'Covers confined spaces (1926.64), noise, and ventilation.', 'Oil and Gas', 'Upstream, Midstream, Downstream', 'Health and Environment', 'Confined Space, Noise, Air Quality', 'confined spaces, noise, ventilation, occupational health', 'https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XVII/part-1926/subpart-D', 'OSHA'),

('29', '1926', 'E', '1926 Subpart E (1926.95-1926.107)', '(1926.95-1926.107)', 'Personal Protective and Life Saving Equipment', 'PPE requirements for construction, including fall protection and respiratory protection.', 'Oil and Gas', 'Upstream, Midstream', 'Personal Protection', 'Falls, Chemical Exposure', 'PPE, fall protection, respiratory protection, construction', 'https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XVII/part-1926/subpart-E', 'OSHA'),

('29', '1926', 'F', '1926 Subpart F (1926.150-1926.159)', '(1926.150-1926.159)', 'Fire Protection and Prevention', 'Fire safety standards for construction sites.', 'Oil and Gas', 'Upstream, Midstream', 'Fire Safety', 'Fire, Explosion', 'fire protection, fire prevention, construction sites', 'https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XVII/part-1926/subpart-F', 'OSHA'),

('29', '1926', 'K', '1926 Subpart K (1926.400-1926.449)', '(1926.400-1926.449)', 'Electrical', 'Electrical safety for construction activities, including grounding and wiring.', 'Oil and Gas', 'Upstream, Midstream', 'Electrical Safety', 'Electrocution, Fire', 'electrical safety, construction, grounding, wiring', 'https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XVII/part-1926/subpart-K', 'OSHA'),

('29', '1926', 'L', '1926 Subpart L (1926.450-1926.454)', '(1926.450-1926.454)', 'Scaffolds', 'Standards for scaffold design, use, and fall protection in construction.', 'Oil and Gas', 'Upstream, Midstream', 'Construction Safety', 'Falls, Scaffold Collapse', 'scaffolds, fall protection, construction', 'https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XVII/part-1926/subpart-L', 'OSHA'),

('29', '1926', 'M', '1926 Subpart M (1926.500-1926.503)', '(1926.500-1926.503)', 'Fall Protection', 'Requirements for fall protection systems in construction activities.', 'Oil and Gas', 'Upstream, Midstream', 'Fall Protection', 'Falls', 'fall protection, construction, safety systems', 'https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XVII/part-1926/subpart-M', 'OSHA'),

('29', '1915', 'I', '1915 Subpart I (1915.131-1915.140)', '(1915.131-1915.140)', 'Personal Protective Equipment (Shipyard Employment)', 'PPE standards for maritime activities, relevant for offshore oil and gas.', 'Oil and Gas', 'Upstream', 'Personal Protection', 'Maritime Hazards', 'PPE, shipyard, maritime, offshore', 'https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XVII/part-1915/subpart-I', 'OSHA'),

('29', '1904', NULL, '1904', NULL, 'Recording and Reporting Occupational Injuries and Illnesses', 'Requirements for injury and illness recordkeeping and reporting.', 'Oil and Gas', 'Upstream, Midstream, Downstream', 'Recordkeeping', 'Data Collection', 'injury reporting, illness reporting, recordkeeping, OSHA 300', 'https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XVII/part-1904', 'OSHA');

-- =====================================================
-- Sample Queries for Any CFR Title
-- =====================================================

-- Query 1: Get all Title 29 regulations
-- SELECT * FROM cfr_regulations WHERE cfr_title = '29';

-- Query 2: Get all regulations from specific agency
-- SELECT * FROM cfr_regulations WHERE agency = 'OSHA';

-- Query 3: Search across all titles for specific hazard
-- SELECT * FROM cfr_regulations WHERE hazard_types ILIKE '%fire%';

-- Query 4: Get all construction regulations (Part 1926)
-- SELECT * FROM cfr_regulations WHERE cfr_part = '1926';

-- Query 5: Full text search across all regulations
-- SELECT * FROM cfr_regulations WHERE to_tsvector('english', description || ' ' || title) @@ to_tsquery('english', 'electrical & safety');

-- Query 6: Count regulations by CFR title
-- SELECT cfr_title, agency, COUNT(*) as regulation_count
-- FROM cfr_regulations 
-- GROUP BY cfr_title, agency 
-- ORDER BY cfr_title;

-- =====================================================
-- Grant Permissions (Adjust as needed)
-- =====================================================

-- GRANT USAGE ON SCHEMA cfr_regulations TO your_application_user;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA cfr_regulations TO your_application_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA cfr_regulations TO your_application_user;