-- ===================================================================
-- COMPLETE DDL SCRIPT FOR COMPANIES DATA MODEL (PostgreSQL Compatible)
-- ===================================================================

-- Create schema if needed
CREATE SCHEMA IF NOT EXISTS companies_data;
SET search_path TO companies_data;

-- ===================================================================
-- 1. INDUSTRIES TABLE
-- ===================================================================
CREATE TABLE industries (
    industry_id INTEGER PRIMARY KEY,
    industry_name VARCHAR(255) NOT NULL UNIQUE,
    industry_description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_industries_name ON industries(industry_name);

-- ===================================================================
-- 2. SECTORS TABLE  
-- ===================================================================
CREATE TABLE sectors (
    sector_id INTEGER PRIMARY KEY,
    sector_name VARCHAR(255) NOT NULL UNIQUE,
    sector_description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sectors_name ON sectors(sector_name);

-- ===================================================================
-- 3. REGIONS TABLE
-- ===================================================================
CREATE TABLE regions (
    region_id INTEGER PRIMARY KEY,
    region_name VARCHAR(100) NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    region_code VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_region_country UNIQUE (region_name, country_name)
);

CREATE INDEX idx_regions_name ON regions(region_name);
CREATE INDEX idx_regions_country ON regions(country_name);

-- ===================================================================
-- 4. REGULATORY BODIES TABLE
-- ===================================================================
CREATE TYPE regulatory_level_enum AS ENUM ('Federal', 'State', 'Local', 'International');

CREATE TABLE regulatory_bodies (
    regulatory_body_id SERIAL PRIMARY KEY,
    regulatory_body_name VARCHAR(255) NOT NULL UNIQUE,
    regulatory_level regulatory_level_enum NOT NULL,
    description TEXT,
    website_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_regulatory_bodies_name ON regulatory_bodies(regulatory_body_name);
CREATE INDEX idx_regulatory_bodies_level ON regulatory_bodies(regulatory_level);

-- ===================================================================
-- 5. REGULATIONS TABLE
-- ===================================================================
CREATE TYPE regulation_status_enum AS ENUM ('Active', 'Inactive', 'Proposed', 'Under Review');

CREATE TABLE regulations (
    regulation_id SERIAL PRIMARY KEY,
    regulation_name VARCHAR(500) NOT NULL,
    regulation_code VARCHAR(100),
    regulatory_body_id INTEGER NOT NULL,
    regulation_type VARCHAR(100),
    effective_date DATE,
    status regulation_status_enum DEFAULT 'Active',
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_regulations_regulatory_body 
        FOREIGN KEY (regulatory_body_id) 
        REFERENCES regulatory_bodies(regulatory_body_id)
);

CREATE INDEX idx_regulations_name ON regulations(regulation_name);
CREATE INDEX idx_regulations_code ON regulations(regulation_code);
CREATE INDEX idx_regulations_body ON regulations(regulatory_body_id);
CREATE INDEX idx_regulations_status ON regulations(status);

-- ===================================================================
-- 6. COMPANIES TABLE
-- ===================================================================
CREATE TABLE companies (
    company_id INTEGER PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    zipcode VARCHAR(20),
    industry_id INTEGER,
    sector_id INTEGER,
    region_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_companies_industry 
        FOREIGN KEY (industry_id) 
        REFERENCES industries(industry_id),
    CONSTRAINT fk_companies_sector 
        FOREIGN KEY (sector_id) 
        REFERENCES sectors(sector_id),
    CONSTRAINT fk_companies_region 
        FOREIGN KEY (region_id) 
        REFERENCES regions(region_id)
);

CREATE INDEX idx_companies_name ON companies(company_name);
CREATE INDEX idx_companies_industry ON companies(industry_id);
CREATE INDEX idx_companies_sector ON companies(sector_id);
CREATE INDEX idx_companies_region ON companies(region_id);

-- ===================================================================
-- 7. COMPANY REGULATIONS MAPPING TABLE
-- ===================================================================
CREATE TYPE compliance_status_enum AS ENUM ('Compliant', 'Non-Compliant', 'Under Review', 'Not Applicable');

CREATE TABLE company_regulations (
    mapping_id SERIAL PRIMARY KEY,
    company_id INTEGER NOT NULL,
    regulation_id INTEGER NOT NULL,
    compliance_status compliance_status_enum DEFAULT 'Under Review',
    last_audit_date DATE,
    next_audit_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_company_regulations_company 
        FOREIGN KEY (company_id) 
        REFERENCES companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_company_regulations_regulation 
        FOREIGN KEY (regulation_id) 
        REFERENCES regulations(regulation_id) ON DELETE CASCADE,
    CONSTRAINT unique_company_regulation UNIQUE (company_id, regulation_id)
);

CREATE INDEX idx_company_regulations_company ON company_regulations(company_id);
CREATE INDEX idx_company_regulations_regulation ON company_regulations(regulation_id);
CREATE INDEX idx_company_regulations_status ON company_regulations(compliance_status);

-- ===================================================================
-- 8. NAICS CODES TABLE (Optional)
-- ===================================================================
CREATE TABLE naics_codes (
    naics_code VARCHAR(10) PRIMARY KEY,
    industry_description VARCHAR(500) NOT NULL,
    osha_recordkeeping_exempt BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_naics_exempt ON naics_codes(osha_recordkeeping_exempt);

-- ===================================================================
-- 9. TRIGGERS FOR AUTOMATIC UPDATED_AT TIMESTAMPS
-- ===================================================================

-- Function to update the updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to tables with updated_at columns
CREATE TRIGGER update_regulations_updated_at 
    BEFORE UPDATE ON regulations 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_companies_updated_at 
    BEFORE UPDATE ON companies 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_company_regulations_updated_at 
    BEFORE UPDATE ON company_regulations 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ===================================================================
-- 10. USEFUL VIEWS FOR COMMON QUERIES
-- ===================================================================

-- View: Companies with full details
CREATE VIEW companies_full_details AS
SELECT 
    c.company_id,
    c.company_name,
    c.zipcode,
    i.industry_name,
    s.sector_name,
    r.region_name,
    r.country_name,
    c.created_at,
    c.updated_at
FROM companies c
LEFT JOIN industries i ON c.industry_id = i.industry_id
LEFT JOIN sectors s ON c.sector_id = s.sector_id
LEFT JOIN regions r ON c.region_id = r.region_id;

-- View: Company regulations summary
CREATE VIEW company_regulations_summary AS
SELECT 
    c.company_id,
    c.company_name,
    COUNT(cr.regulation_id) as total_regulations,
    COUNT(CASE WHEN cr.compliance_status = 'Compliant' THEN 1 END) as compliant_count,
    COUNT(CASE WHEN cr.compliance_status = 'Non-Compliant' THEN 1 END) as non_compliant_count,
    COUNT(CASE WHEN cr.compliance_status = 'Under Review' THEN 1 END) as under_review_count
FROM companies c
LEFT JOIN company_regulations cr ON c.company_id = cr.company_id
GROUP BY c.company_id, c.company_name;

-- View: Regulations with regulatory body details
CREATE VIEW regulations_full_details AS
SELECT 
    r.regulation_id,
    r.regulation_name,
    r.regulation_code,
    r.regulation_type,
    r.effective_date,
    r.status,
    rb.regulatory_body_name,
    rb.regulatory_level,
    r.created_at,
    r.updated_at
FROM regulations r
JOIN regulatory_bodies rb ON r.regulatory_body_id = rb.regulatory_body_id;

-- ===================================================================
-- 11. GRANT PERMISSIONS (Adjust as needed for your users)
-- ===================================================================

-- Grant usage on schema
GRANT USAGE ON SCHEMA companies_data TO PUBLIC;

-- Grant permissions on tables
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA companies_data TO PUBLIC;

-- Grant permissions on sequences (for SERIAL columns)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA companies_data TO PUBLIC;

-- ===================================================================
-- 12. COMMENTS FOR DOCUMENTATION
-- ===================================================================

COMMENT ON SCHEMA companies_data IS 'Schema for storing company information and regulatory compliance data';

COMMENT ON TABLE companies IS 'Core company information with references to industry, sector, and region';
COMMENT ON TABLE industries IS 'Industry classifications lookup table';
COMMENT ON TABLE sectors IS 'Business sector classifications lookup table';
COMMENT ON TABLE regions IS 'Geographic regions/states lookup table';
COMMENT ON TABLE regulatory_bodies IS 'Regulatory organizations and agencies';
COMMENT ON TABLE regulations IS 'Specific regulations and compliance requirements';
COMMENT ON TABLE company_regulations IS 'Many-to-many mapping between companies and regulations';
COMMENT ON TABLE naics_codes IS 'NAICS codes with OSHA exemption information';

-- ===================================================================
-- 13. VERIFICATION SCRIPT
-- ===================================================================

-- Check that all tables were created successfully
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables 
WHERE schemaname = 'companies_data'
ORDER BY tablename;

-- Check that all indexes were created
SELECT 
    schemaname,
    tablename,
    indexname
FROM pg_indexes 
WHERE schemaname = 'companies_data'
ORDER BY tablename, indexname;

-- Check that all foreign key constraints exist
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_schema = 'companies_data'
ORDER BY tc.table_name;

-- ===================================================================
-- SCRIPT COMPLETE
-- ===================================================================
-- 
-- This script creates a complete, production-ready database schema for
-- storing company information and regulatory compliance data.
--
-- Key Features:
-- ✅ PostgreSQL compatible syntax
-- ✅ Proper data types and constraints
-- ✅ Comprehensive indexing strategy
-- ✅ Automatic timestamp updates via triggers
-- ✅ Useful views for common queries
-- ✅ Complete foreign key relationships
-- ✅ Documentation via comments
-- ✅ Verification queries
-- 
-- Ready to load your spreadsheet data!
-- ===================================================================



-- ===================================================================
-- MASTER VIEW WITH ALL ATTRIBUTES - CORRECTED VERSION
-- Single comprehensive view joining all tables for easy querying
-- ===================================================================

SET search_path TO companies_data;

-- ===================================================================
-- MASTER VIEW WITH ALL ATTRIBUTES - CORRECTED VERSION
-- Single comprehensive view joining all tables for easy querying
-- ===================================================================

CREATE OR REPLACE VIEW companies_master_view AS
SELECT 
    -- Company Information
    c.company_id,
    c.company_name,
    c.zipcode,
    c.created_at as company_created_at,
    c.updated_at as company_updated_at,
    
    -- Industry Information
    i.industry_id,
    i.industry_name,
    i.industry_description,
    
    -- Sector Information
    s.sector_id,
    s.sector_name,
    s.sector_description,
    
    -- Region Information
    r.region_id,
    r.region_name,
    r.country_name,
    r.region_code,
    
    -- Regulatory Body Information
    rb.regulatory_body_id,
    rb.regulatory_body_name,
    rb.regulatory_level,
    rb.description as regulatory_body_description,
    rb.website_url as regulatory_body_website,
    rb.created_at as regulatory_body_created_at,
    
    -- Regulation Information
    reg.regulation_id,
    reg.regulation_name,
    reg.regulation_code,
    reg.regulation_type,
    reg.effective_date as regulation_effective_date,
    reg.status as regulation_status,
    reg.description as regulation_description,
    reg.created_at as regulation_created_at,
    reg.updated_at as regulation_updated_at,
    
    -- Company-Regulation Mapping Information
    cr.mapping_id,
    cr.compliance_status,
    cr.last_audit_date,
    cr.next_audit_date,
    cr.notes as compliance_notes,
    cr.created_at as mapping_created_at,
    cr.updated_at as mapping_updated_at,
    
    -- Geographic Information (Full)
    CONCAT(r.region_name, ', ', r.country_name) as full_location,
    
    -- Regulatory Information (Full)
    CONCAT(rb.regulatory_body_name, ' (', rb.regulatory_level, ')') as full_regulatory_info

FROM companies c
    LEFT JOIN industries i ON c.industry_id = i.industry_id
    LEFT JOIN sectors s ON c.sector_id = s.sector_id
    LEFT JOIN regions r ON c.region_id = r.region_id
    LEFT JOIN company_regulations cr ON c.company_id = cr.company_id
    LEFT JOIN regulations reg ON cr.regulation_id = reg.regulation_id
    LEFT JOIN regulatory_bodies rb ON reg.regulatory_body_id = rb.regulatory_body_id;

-- Add comments for documentation
COMMENT ON VIEW companies_master_view IS 'Master view containing all attributes from companies, industries, sectors, regions, regulatory bodies, regulations, and company-regulation mappings. Use this view for comprehensive queries across the entire companies database.';





-- =====================================================
-- CLEAN INSERT SCRIPT FOR REGULATORY BODIES
-- =====================================================

-- First, create the table if it doesn't exist
CREATE TABLE IF NOT EXISTS regulatory_bodies_short_name (
    id SERIAL PRIMARY KEY,
    regulatory_body_name VARCHAR(500) NOT NULL,
    short_name VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Clear existing data (optional)
-- TRUNCATE TABLE regulatory_bodies RESTART IDENTITY;

-- Insert all regulatory bodies (cleaned and validated)
INSERT INTO regulatory_bodies_short_name (regulatory_body_name, short_name) VALUES
('MASE / Regions / Prefects', 'MRP'),
('Oklahoma Corporation Commission - Oil & Gas Conservation Division', 'OCC'),
('New Mexico Public Regulation Commission', 'PRC'),
('Pennsylvania Public Utility Commission (PUC)', 'PUC'),
('Impact Assessment Agency of Canada', 'IAAC'),
('Texas Commission on Environmental Quality (TCEQ)', 'TCEQ'),
('Food and Drug Administration (FDA)', 'FDA'),
('Environment and Climate Change Canada (ECCC) - Environmental Emergencies', 'ECCC'),
('Texas Secretary of State', 'TSS'),
('Ministry of the Environment and Energy Security (MASE)', 'MASE'),
('European Commission', 'EC'),
('Petroleum Safety Authority Norway', 'PSAN'),
('Bureau of Ocean Energy Management (BOEM)', 'BOEM'),
('U.S. DOT - PHMSA', 'PHMSA'),
('Alaska Department of Environmental Conservation (ADEC)', 'ADEC'),
('Board of Governors of the Federal Reserve System', 'FRB'),
('U.S. Maritime Administration (MARAD)', 'MARAD'),
('ALNAFT (National Agency for the Development of Hydrocarbon Resources)', 'ALNAFT'),
('Ministerio de Ambiente y Desarrollo Sostenible Colombia', 'MDAY'),
('Oregon Public Utility Commission', 'OPUC'),
('Three Affiliated Tribes', 'TAT'),
('Various Port Authorities', 'LOCAL'),
('Global Reporting Initiative (GRI)', 'GRI'),
('Delaware Secretary of State', 'DSS'),
('Office of Foreign Assets Control (OFAC, U.S. Treasury)', 'OFAC'),
('Pennsylvania Department of Environmental Protection (DEP) - Air', 'PADEP'),
('New York State Department of Financial Services (NYDFS)', 'NYDFS'),
('Ontario Ministry of Labour', 'OML'),
('Wisconsin Department of Natural Resources', 'WDNR'),
('New Mexico Environment Department', 'NMED'),
('Task Force on Climate-related Financial Disclosures (TCFD)', 'TCFD'),
('Municipal Authorities', 'LOCAL'),
('WV DEP - Office of Oil & Gas', 'WVDEP'),
('ISPRA / Regional ARPA agencies', 'IRAA'),
('West Virginia Oil and Gas Conservation Commission', 'WVOGCC'),
('Ontario - Industrial Emissions Carbon Pricing', 'OIECP'),
('Securities and Exchange Commission (SEC)', 'SEC'),
('Federal Motor Carrier Safety Administration (FMCSA)', 'FMCSA'),
('Communications Security Establishment (CSE)', 'CSE'),
('U.S. EPA - Oil Pollution Prevention', 'EPA'),
('KazMunayGas (Kazakhstan)', 'KMG'),
('Local Municipalities', 'LOCAL'),
('OSHA - Hazard Communication (GHS)', 'OSHA'),
('Employment and Social Development Canada', 'ESDC'),
('Ministry for Investments and Development (Kazakhstan)', 'MIDK'),
('North Dakota Industrial Commission - Oil & Gas Division (DMR)', 'NDIC'),
('Repsol S.A.', 'REPSOL'),
('Ministry of Energy (Kazakhstan)', 'MEK'),
('California Energy Commission (CEC)', 'CEC'),
('Canada Competition Bureau', 'CCB'),
('Canadian Energy Regulator (CER)', 'CER'),
('Louisiana Workforce Commission', 'LWC'),
('U.S. EPA - Fuels & Fuel Additives', 'EPA'),
('Pennsylvania Department of Environmental Protection (DEP)', 'PADEP'),
('Financial Crimes Enforcement Network (FinCEN) - Bank Secrecy Act (BSA)', 'FINCEN'),
('Colorado Public Utilities Commission', 'CPUC'),
('EMVCo', 'EMVCO'),
('Ministerio de Energia y Recursos Naturales No Renovables Ecuador', 'MERNRE'),
('Alberta Energy Regulator (AER)', 'AER'),
('Federal Motor Carrier Safety Administration (FMCSA) - DOT', 'FMCSA'),
('Transport Canada', 'TC'),
('U.S. Coast Guard', 'USCG'),
('OSHA - Process Safety Management (PSM)', 'OSHA'),
('BC Utilities Commission (BCUC)', 'BCUC'),
('Ministry of Mineral Resources and Energy (Mozambique)', 'MMRE'),
('Ministry of Energy (Norway)', 'MEN'),
('Department of Justice (DOJ)', 'DOJ'),
('South Dakota Public Utilities Commission', 'SDPUC'),
('Oklahoma Tax Commission', 'OTC'),
('U.S. Department of Justice (DOJ)', 'DOJ'),
('State Attorneys General', 'SAG'),
('PHMSA (DOT)', 'PHMSA'),
('B3 - Brasil Bolsa Balcao', 'B3'),
('North Dakota Public Service Commission (PSC) - Pipeline Safety', 'NDPSC'),
('Honolulu County, Hawaii', 'LOCAL'),
('ECCC - Fuels Regulations', 'ECCC'),
('North Dakota Industrial Commission (NDIC)', 'NDIC'),
('U.S. DOT/PHMSA - Pipeline Safety (Liquids)', 'PHMSA'),
('Oklahoma Corporation Commission', 'OCC'),
('South Carolina Department of Environmental Services (SCDES)', 'SCDES'),
('Illinois Environmental Protection Agency (IEPA)', 'IEPA'),
('Competition Bureau Canada', 'CBC'),
('Federal Reserve Board (FRB)', 'FRB'),
('Ontario Ministry of Environment, Conservation and Parks', 'MECP'),
('National Futures Association (NFA)', 'NFA'),
('Consumer Financial Protection Bureau (CFPB)', 'CFPB'),
('U.S. Coast Guard - 33 CFR Part 156 (Transfer Ops)', 'USCG'),
('Commodity Futures Trading Commission (CFTC)', 'CFTC'),
('Department of Homeland Security (DHS)', 'DHS'),
('Massachusetts State Fire Marshal', 'MSFM'),
('Idaho Public Utilities Commission (Idaho Commission)', 'IPUC'),
('BP p.l.c.', 'BP'),
('U.S. Environmental Protection Agency (EPA) - Oil Pollution Prevention', 'EPA'),
('Alberta Environment and Protected Areas (AEPA)', 'AEPA'),
('New York State Public Service Commission (PSC)', 'NYPSC'),
('Provincial Regulatory Authorities (Various)', 'LOCAL'),
('National Oceanic and Atmospheric Administration (NOAA)', 'NOAA'),
('Alberta Labour and Immigration', 'ALI'),
('Colorado Department of Public Health & Environment (CDPHE) - Air Pollution Control Division / Air Quality Control Commission', 'CDPHE'),
('Delaware River Basin Commission', 'DRBC'),
('Federal Energy Regulatory Commission (FERC)', 'FERC'),
('Various Provincial Governments', 'LOCAL'),
('Options Clearing Corporation (OCC)', 'OCC'),
('Colorado Oil & Gas Conservation Commission (COGCC)', 'COGCC'),
('KAZENERGY Association (Kazakhstan)', 'KAZENERGY'),
('U.S. EPA - Fuels Program (Streamlining)', 'EPA'),
('EU Agency for the Cooperation of Energy Regulators (ACER)', 'ACER'),
('Chicago Board Options Exchange (CBOE)', 'CBOE'),
('Lloyds Register (LR)', 'LR'),
('U.S. EPA - Underground Storage Tanks', 'EPA'),
('U.S. EPA - EPCRA (TRI)', 'EPA'),
('Ontario Ministry of Natural Resources and Forestry', 'OMNRF'),
('Wyoming Department of Environmental Quality', 'WDEQ'),
('Department of Labor (DOL)', 'DOL'),
('Ministry of Energy and Mines (Algeria)', 'MEMA'),
('International Labour Organization (ILO)', 'ILO'),
('Comision Nacional de Valores Venezuela', 'CNV'),
('International Association of Oil & Gas Producers (IOGP)', 'IOGP'),
('Department of the Interior (DOI) - Bureau of Land Management (BLM)', 'BLM'),
('Public Utilities Commission of Ohio (Ohio Commission)', 'PUCO'),
('Pakistan Petroleum Limited', 'PPL'),
('Bureau of Safety and Environmental Enforcement (BSEE) - DOI', 'BSEE'),
('Ministry of Energy (UAE)', 'MEUAE'),
('Paris Memorandum of Understanding (Paris MoU)', 'PARISMOU'),
('Arkansas Department of Energy & Environment - Division of Environmental Quality (DEQ)', 'ADEQ'),
('Innovation, Science and Economic Development Canada', 'ISED'),
('Ohio Public Utilities Commission (PUCO)', 'PUCO'),
('Ohio Environmental Protection Agency (Ohio EPA)', 'OEPA'),
('Ghana National Petroleum Corporation', 'GNPC'),
('Washington Utilities and Transportation Commission', 'WUTC'),
('State Securities Regulators (50 States, DC, Puerto Rico)', 'SSR'),
('Kansas Department of Health and Environment (KDHE)', 'KDHE'),
('U.S. Coast Guard (DHS)', 'USCG'),
('Agencia Nacional do Petroleo Gas Natural e Biocombustiveis (ANP)', 'ANP'),
('Pertamina (Indonesia)', 'PERTAMINA'),
('Canada Revenue Agency', 'CRA'),
('Florida Department of Revenue', 'FDR'),
('North Dakota Department of Environmental Quality', 'NDDEQ'),
('National Energy Board (NEB) [now CER]', 'NEB'),
('U.S. EPA - CERCLA', 'EPA'),
('Ohio Department of Natural Resources (ODNR)', 'ODNR'),
('Louisiana Department of Environmental Quality (LDEQ)', 'LDEQ'),
('BC Energy Regulator (BCER)', 'BCER'),
('Texas Railroad Commission (TRRC)', 'RRC'),
('International Finance Corporation (IFC)', 'IFC'),
('Council on Environmental Quality (CEQ) / Federal Agencies', 'CEQ'),
('Monetary Authority of Singapore (MAS)', 'MAS'),
('Ministry of National Economy (Kazakhstan)', 'MNEK'),
('Pipeline and Hazardous Materials Safety Administration (PHMSA)-Part Of DOT', 'PHMSA'),
('U.S. Environmental Protection Agency (EPA)', 'EPA'),
('Tokyo Memorandum of Understanding (Tokyo MoU)', 'TOKYOMOU'),
('County Governments', 'LOCAL'),
('Department of Energy', 'DOE'),
('Various County and Municipal Authorities', 'LOCAL'),
('U.S. Environmental Protection Agency (EPA) - RMP', 'EPA'),
('Occupational Safety & Health Administration (OSHA)', 'OSHA'),
('Perenco (Congo)', 'PERENCO'),
('U.S. Department of the Treasury - Financial Crimes Enforcement Network (FinCEN)', 'FINCEN'),
('Ohio Department of Natural Resources (ODNR) - Division of Oil & Gas Resources', 'ODNR'),
('Conselho Nacional de Politica Energetica (CNPE)', 'CNPE'),
('Autoriteit Financiele Markten Netherlands (AFM)', 'AFM'),
('United States Coast Guard (USCG) Port State Control', 'USCG'),
('CONSOB - Commissione Nazionale per le Societa e la Borsa', 'CONSOB'),
('New Mexico Energy, Minerals & Natural Resources Department - Oil Conservation Division (OCD)', 'OCD'),
('Ohio Department of Commerce', 'ODC'),
('Alberta Treasury Board and Finance', 'ATBF'),
('Natural Resources Canada (NRCan)', 'NRCAN'),
('Commission Nacional de Hidrocarburos (Mexico)', 'CNH'),
('Fisheries and Oceans Canada (DFO)', 'DFO'),
('Controladoria-Geral da Uniao (CGU)', 'CGU'),
('Office of the Comptroller of the Currency (OCC)', 'OCC'),
('Organismo Supervisor de la Inversion en Energia y Mineria Peru (OSINERGMIN)', 'OSINERGMIN'),
('Secretaria de Medio Ambiente y Recursos Naturales (SEMARNAT)', 'SEMARNAT'),
('Massachusetts Department of Revenue', 'MDR'),
('Sharjah National Oil Corporation (SNOC)', 'SNOC'),
('Provincial Privacy Commissioners', 'PPC'),
('TSX & IIROC (Investor regulation bodies)', 'TSX'),
('NASDAQ Stock Market', 'NASDAQ'),
('Alaska Department of Natural Resources (DNR)', 'ADNR'),
('U.S. Environmental Protection Agency (EPA) - NPDES', 'EPA'),
('ANPG (National Agency for Oil, Gas and Biofuels - Angola)', 'ANPG'),
('Contra Costa County, California', 'LOCAL'),
('New Mexico Oil Conservation Division', 'OCD'),
('Secretaria de Ambiente y Desarrollo Sustentable Argentina', 'SADS'),
('SKK Migas (Indonesia)', 'SKKMIGAS'),
('UK Health and Safety Executive (HSE)', 'HSE'),
('Mississippi Department of Revenue', 'MDR'),
('Florida Office of Financial Regulation', 'FOFR'),
('Ministry of Economy and Finance (Italy)', 'MEF'),
('Public Safety Canada', 'PSC'),
('California Division of Oil, Gas, and Geothermal Resources (DOGGR)', 'CALGEM'),
('Depository Trust & Clearing Corporation (DTCC)', 'DTCC'),
('U.S. Fish & Wildlife Service (USFWS)', 'USFWS'),
('Agencia Nacional de Energia Electrica (ANEEL)', 'ANEEL'),
('Department of Transportation (DOT)', 'DOT'),
('Federal Motor Carrier Safety Administration (FMCSA)-Part Of DOT', 'FMCSA'),
('Ministerio de Hidrocarburos y Energias Bolivia', 'MHE'),
('Louisiana Department of Environmental Quality', 'LDEQ'),
('Pennsylvania Department of Labor & Industry', 'PADLI'),
('Italian Legislature / Courts', 'ILC'),
('U.S. Department of Commerce - Bureau of Industry and Security (BIS)', 'BIS'),
('U.S. Department of the Treasury - OFAC', 'OFAC'),
('Office of the Privacy Commissioner of Canada', 'OPC'),
('European Commission / EFRAG', 'EC'),
('Canada Business Corporations Act', 'CBCA'),
('Global Affairs Canada', 'GAC'),
('Autoridad Nacional de Licencias Ambientales Colombia (ANLA)', 'ANLA'),
('Ontario MECP - Air', 'MECP'),
('Alberta Energy Regulator (AER) - Measurement', 'AER'),
('U.S. Dept. of the Interior - Bureau of Land Management (BLM)', 'BLM'),
('Wisconsin Public Service Commission', 'WPSC'),
('Ministry of Environment and Energy Security (Italy)', 'MEES'),
('US Army Corps of Engineers', 'USACE'),
('Libya National Oil Corporation (NOC)', 'NOC'),
('Canada Energy Regulator (CER)', 'CER'),
('Technical Standards & Safety Authority (TSSA) - Ontario', 'TSSA'),
('Financial Crimes Enforcement Network (FinCEN)', 'FINCEN'),
('Government of Northwest Territories', 'GNWT'),
('Ohio Environmental Protection Agency (OEPA)', 'OEPA'),
('Nigerian National Petroleum Corporation', 'NNPC'),
('Local Fire Departments', 'LOCAL'),
('ECCC - Pollutant Reporting', 'ECCC'),
('Alberta Emergency Management Agency', 'AEMA'),
('U.S. Department of the Treasury - Office of Foreign Assets Control (OFAC)', 'OFAC'),
('Ministerio da Fazenda', 'MF'),
('National Agency for Mineral Resources (Brazil)', 'ANM'),
('U.S. EPA - EPCRA', 'EPA'),
('Comision Federal de Competencia Economica (COFECE)', 'COFECE'),
('Ministerio do Trabalho e Emprego', 'MTE'),
('Enbridge Gas - Regulatory Info', 'ENBRIDGE'),
('U.S. Army Corps of Engineers (USACE)', 'USACE'),
('Equinor ASA', 'EQUINOR'),
('NACHA (National Automated Clearing House Association)', 'NACHA'),
('International Organization for Standardization (ISO)', 'ISO'),
('European Chemicals Agency (ECHA) / European Commission', 'ECHA'),
('Office of Foreign Assets Control (OFAC), U.S. Treasury', 'OFAC'),
('Transport Canada - Marine Security', 'TC'),
('U.S. EPA - NPDES Stormwater', 'EPA'),
('New Mexico Oil Conservation Division (OCD)', 'OCD'),
('OSHA - HAZWOPER', 'OSHA'),
('Nevada Financial Institutions Division (NFID)', 'NFID'),
('International Association of Classification Societies (IACS)', 'IACS'),
('U.S. Environmental Protection Agency (EPA) - Oil Discharge', 'EPA'),
('Petrobras (Brazil)', 'PETROBRAS'),
('European Commission (DG ENER)', 'EC'),
('PHMSA (DOT) - Hazardous Materials Regulations', 'PHMSA'),
('Department of Energy (DOE)', 'DOE'),
('North Carolina Utilities Commission (North Carolina Commission)', 'NCUC'),
('Idaho Public Utilities Commission', 'IPUC'),
('French Energy Regulatory Commission (CRE)', 'CRE'),
('U.S. Coast Guard (USCG)', 'USCG'),
('Technical Standards & Safety Authority (TSSA) - Liquid Fuels', 'TSSA'),
('SENER (Mexico)', 'SENER'),
('Delaware Division of Corporations', 'DDC'),
('National Offshore Petroleum Titles Administrator (NOPTA)', 'NOPTA'),
('Federal Reserve System (FRS)', 'FRS'),
('Society of International Gas Tanker and Terminal Operators (SIGTTO)', 'SIGTTO'),
('Technical Standards & Safety Authority (TSSA) - Pipelines', 'TSSA'),
('Wyoming Department of Environmental Quality (WDEQ)', 'WDEQ'),
('World Bank Group', 'WBG'),
('Alberta Securities Commission (ASC)', 'ASC'),
('OROGO - Licences/Authorizations', 'OROGO'),
('Office of Foreign Assets Control (OFAC)', 'OFAC'),
('Democratic Republic of Congo Ministry of Hydrocarbons', 'DRCMH'),
('British Columbia Oil and Gas Commission (BCOGC)', 'BCOGC'),
('Kentucky Energy and Environment Cabinet (EEC)', 'KEEC'),
('Environment and Climate Change Canada (CEPA, 1999)', 'ECCC'),
('Ontario - Refinery SO2 Controls (MECP)', 'MECP'),
('Louisiana Department of Energy & Natural Resources - Office of Conservation', 'LDNR'),
('Texas Department of Savings and Mortgage Lending (TDSML)', 'TDSML'),
('NOAA - National Marine Fisheries Service', 'NMFS'),
('The United Kingdom Mutual Steamship Assurance Association Limited', 'UKMS'),
('United States Coast Guard (USCG)', 'USCG'),
('Financial Accounting Standards Board (FASB)', 'FASB'),
('Alberta Energy Regulator (AER) - Applications', 'AER'),
('B3 S.A. - Brasil Bolsa Balcao', 'B3'),
('Pipeline and Hazardous Materials Safety Administration (PHMSA)', 'PHMSA'),
('Conselho Administrativo de Defesa Economica (CADE)', 'CADE'),
('Saskatchewan Ministry of Environment', 'SME'),
('Various State Port Authorities', 'LOCAL'),
('Ontario Energy Board (OEB)', 'OEB'),
('Equinor (Norway)', 'EQUINOR'),
('FRA (DOT) - Rail Safety', 'FRA'),
('Saskatchewan Ministry of Energy and Resources', 'SMER'),
('Comissao de Valores Mobiliarios (CVM)', 'CVM'),
('Mississippi State Oil and Gas Board (MSOGB)', 'MSOGB'),
('Technical Standards & Safety Authority (TSSA) - Fuel Oil', 'TSSA'),
('Port of Houston Authority', 'PHA'),
('Crown-Indigenous Relations and Northern Affairs Canada', 'CIRNAC'),
('Internal Revenue Service (IRS)', 'IRS'),
('National Environmental Policy Act (NEPA)', 'NEPA'),
('Alaska Oil and Gas Conservation Commission (AOGCC)', 'AOGCC'),
('Oklahoma Corporation Commission - Oil & Gas Conservation', 'OCC'),
('Transportation Security Administration (TSA)', 'TSA'),
('Regie de l''energie du Quebec', 'REQ'),
('Environment and Climate Change Canada', 'ECCC'),
('California Air Resources Board (CARB)', 'CARB'),
('Egyptian Natural Gas Holding Company (EGAS)', 'EGAS'),
('Maritime Administration (MARAD)', 'MARAD'),
('Various State Attorneys General', 'SAG'),
('National Marine Fisheries Service (NMFS)', 'NMFS'),
('New York State Department of Environmental Conservation (DEC) - Air', 'NYSDEC'),
('Alberta - Emissions Pricing (TIER)', 'TIER'),
('PHMSA (DOT) - LNG Safety (as applicable)', 'PHMSA'),
('Secretaria de Energia Argentina', 'SEA'),
('Local Planning and Zoning Boards', 'LOCAL'),
('Nigeria Department of Petroleum Resources', 'DPR'),
('Municipal Fire Departments', 'LOCAL'),
('Financial Conduct Authority (FCA) UK', 'FCA'),
('Transport Canada - TDG', 'TC'),
('Colorado Department of Public Health and Environment (CDPHE)', 'CDPHE'),
('Bureau of Alcohol, Tobacco, Firearms and Explosives (ATF)', 'ATF'),
('U.S. Environmental Protection Agency (EPA) - GHG Reporting', 'EPA'),
('Ontario Ministry of the Environment', 'MECP'),
('Tennessee Department of Financial Institutions', 'TDFI'),
('Colorado Energy & Carbon Management Commission (ECMC)', 'ECMC'),
('Agencia Nacional de Hidrocarburos Colombia (ANH)', 'ANH'),
('Comision Nacional de Valores (CNV) Argentina', 'CNV'),
('Comissao Nacional de Energia Nuclear (CNEN)', 'CNEN'),
('Canada Energy Regulator (CER) - Standards', 'CER'),
('Sonatrach (Algeria)', 'SONATRACH'),
('ARERA - Energy, Networks and Environment Authority', 'ARERA'),
('Canadian Securities Administrators', 'CSA'),
('German Federal Network Agency (BNetzA)', 'BNETZA'),
('Texas Railroad Commission (RRC)', 'RRC'),
('Public Company Accounting Oversight Board (PCAOB)', 'PCAOB'),
('Department of Interior (DOI)', 'DOI'),
('Ministry of Oil and Gas (Libya)', 'MOGL'),
('U.S. Occupational Safety and Health Administration (OSHA)', 'OSHA'),
('City of Richmond, California', 'LOCAL'),
('ExxonMobil Corporation', 'EXXON'),
('U.S. Army Corps of Engineers', 'USACE'),
('U.S. DOT/PHMSA - Tank Cars', 'PHMSA'),
('Susquehanna River Basin Commission', 'SRBC'),
('U.S. DOT/PHMSA - Packaging Qualification', 'PHMSA'),
('Cyprus Ministry of Energy, Commerce and Industry', 'CMECI'),
('Wyoming Oil and Gas Conservation Commission (WOGCC)', 'WOGCC'),
('West Virginia Division of Natural Resources', 'WVDNR'),
('West Virginia Public Service Commission', 'WVPSC'),
('OSHA - Occupational Safety & Health Administration', 'OSHA'),
('Ministerio de Energia y Minas (Venezuela)', 'MEM'),
('Mississippi State Oil and Gas Board', 'MSOGB'),
('Comision de Valores Ecuador', 'CVE'),
('Toronto Stock Exchange (TSX)', 'TSX'),
('Public Utilities Commission of Ohio (PUCO)', 'PUCO'),
('CSA Group / Security Standard (referenced by provinces)', 'CSA'),
('National Credit Union Administration (NCUA)', 'NCUA'),
('New Mexico Oil Conservation Division (EMNRD)', 'OCD'),
('Various State Environmental Agencies', 'LOCAL'),
('Ministry of Oil (Iraq)', 'MOI'),
('New York Stock Exchange (NYSE)', 'NYSE'),
('Illinois Environmental Protection Agency', 'IEPA'),
('West Virginia Department of Environmental Protection', 'WVDEP'),
('PHMSA (DOT) - Pipeline Safety', 'PHMSA'),
('Energy, Minerals & Natural Resources Dept. - Oil Conservation Division (OCD)', 'OCD'),
('ESMA / European Commission', 'ESMA'),
('Mississippi Department of Environmental Quality', 'MDEQ'),
('U.S. EPA + DOJ settlements', 'EPA'),
('Ontario Ministry of Labour, Immigration, Training and Skills Development', 'OMLIT'),
('Local Building Departments', 'LOCAL'),
('Canada Energy Regulator', 'CER'),
('U.S. Environmental Protection Agency (EPA) - Air', 'EPA'),
('Ministry of Ecology, Geology and Natural Resources (Kazakhstan)', 'MEGNR'),
('Environment and Climate Change Canada (ECCC)', 'ECCC'),
('National Offshore Petroleum Safety and Environmental Management Authority (NOPSEMA)', 'NOPSEMA'),
('Local Health Authorities', 'LOCAL'),
('Ministry of Energy (Indonesia)', 'MEI'),
('Texas Railroad Commission', 'RRC'),
('U.S. DOT / PHMSA', 'PHMSA'),
('Office of the Regulator of Oil and Gas Operations (OROGO) - NWT', 'OROGO'),
('Arizona Corporation Commission', 'ACC'),
('Pipeline and Hazardous Materials Safety Administration (PHMSA) - Part of DOT', 'PHMSA'),
('Alberta Securities Commission', 'ASC'),
('Transportation Security Administration (TSA) - Pipeline Security', 'TSA'),
('Australian Department of Industry, Science and Resources', 'ADISR'),
('Ministere de l''Environnement du Quebec', 'MEQ'),
('Oil and Gas Development Company Limited (Pakistan)', 'OGDCL'),
('State Banking Departments - Money Transmitter', 'LOCAL'),
('Ontario Energy Board', 'OEB'),
('Ministere de l''Environnement, de la Lutte contre les changements climatiques, de la Faune et des Parcs (MELCCFP)', 'MELCCFP'),
('Canadian Securities Administrators (CSA)', 'CSA'),
('Environmental Protection Agency (EPA)', 'EPA'),
('Colorado Department of Revenue', 'CDR'),
('Bureau of Land Management (BLM)', 'BLM'),
('Alberta Environment and Protected Areas', 'AEPA'),
('U.S. Coast Guard - MTSA Security', 'USCG'),
('California Department of Financial Protection and Innovation', 'CDFPI'),
('Agencia Nacional de Transportes Terrestres (ANTT)', 'ANTT'),
('British Columbia Securities Commission', 'BCSC'),
('West Virginia Department of Commerce', 'WVDC'),
('Agencia Nacional de Hidrocarburos Bolivia (ANH)', 'ANH'),
('Municipal Building Departments', 'LOCAL'),
('City of Pasadena, Texas', 'LOCAL'),
('Financial Industry Regulatory Authority (FINRA)', 'FINRA'),
('Ministerio de Energia y Minas Peru', 'MINEM'),
('European Commission (DG MOVE)', 'EC'),
('State Travel Agent Licensing Authorities', 'LOCAL'),
('Texas Comptroller of Public Accounts', 'TCPA'),
('Department of State (DOS)', 'DOS'),
('Council on Environmental Quality (CEQ)', 'CEQ'),
('Parliament of Canada', 'POC'),
('Federal Financial Institutions Examination Council (FFIEC)', 'FFIEC'),
('Alberta Utilities Commission', 'AUC'),
('Transport Canada - Navigable Waters', 'TC'),
('Alberta Utilities Commission (AUC)', 'AUC'),
('North Dakota Department of Environmental Quality (NDDEQ)', 'NDDEQ'),
('Kansas Corporation Commission (KCC) - Pipeline Safety', 'KCC'),
('New Mexico Public Regulation Commission - Pipeline Safety Bureau', 'NMPRC'),
('Local County and Municipal Authorities', 'LOCAL'),
('Oklahoma Corporation Commission (OCC)', 'OCC'),
('Colorado Air Quality Control Commission', 'CAQCC'),
('Illinois Commerce Commission', 'ICC'),
('California Geologic Energy Management Division (CalGEM)', 'CALGEM'),
('Florida Department of Environmental Protection (DEP) - Oil & Gas Program', 'FDEP'),
('North Dakota Industrial Commission', 'NDIC'),
('Transport Canada - Navigation Protection Program', 'TC'),
('European Union - European Maritime Safety Agency (EMSA)', 'EMSA'),
('State of New Jersey Department of the Treasury', 'NJDT'),
('Mastercard Incorporated (Self-Regulatory)', 'MASTERCARD'),
('Pennsylvania Department of Environmental Protection', 'PADEP'),
('U.S. Commodity Futures Trading Commission (CFTC)', 'CFTC'),
('U.S. Dept. of the Interior - Bureau of Indian Affairs (BIA)', 'BIA'),
('Ontario Securities Commission (OSC)', 'OSC'),
('Alberta Energy', 'AE'),
('American Bureau of Shipping (ABS)', 'ABS'),
('Georgia Environmental Protection Division (EPD)', 'GEPD'),
('New Mexico Environment Department (NMED)', 'NMED'),
('California Health & Safety Code', 'CHSC'),
('Woodside Energy (Australia)', 'WOODSIDE'),
('Ministerio de Minas e Energia', 'MME'),
('Ohio Environmental Protection Agency', 'OEPA'),
('UK Department for Energy Security and Net Zero', 'DESNZ'),
('Bureau of Land Management (BLM) - U.S. DOI', 'BLM'),
('Louisiana Department of Natural Resources', 'LDNR'),
('Securities Investor Protection Corporation (SIPC)', 'SIPC'),
('Financial Stability Oversight Council (FSOC)', 'FSOC'),
('Petroleum Commission (Ghana)', 'PC'),
('Connecticut Department of Energy and Environmental Protection (DEEP)', 'CTDEEP'),
('Local Fire Departments and Fire Marshals', 'LOCAL'),
('Sonangol (Angola)', 'SONANGOL'),
('Borsa Italiana S.p.A.', 'BORSA'),
('Colorado Department of Public Health & Environment (CDPHE) - Water Quality Control Division', 'CDPHE'),
('Wyoming Public Service Commission', 'WPSC'),
('Ontario Securities Commission', 'OSC'),
('ConocoPhillips', 'CONOCOPHILLIPS'),
('U.S. Environmental Protection Agency (EPA) - National Contingency Plan', 'EPA'),
('Internal Revenue Service (IRS)', 'IRS'),
('Cybersecurity and Infrastructure Security Agency (CISA)', 'CISA'),
('Department of Labor', 'DOL'),
('Railroad Commission of Texas (RRC)', 'RRC'),
('Impact Assessment Agency of Canada (IAAC)', 'IAAC'),
('Ministry of Petroleum and Natural Gas (India)', 'MPNG'),
('United States Environmental Protection Agency (EPA)', 'EPA'),
('Colorado Dept. of Public Health & Environment (CDPHE) - Air Quality Control Commission', 'CDPHE'),
('British Columbia Utilities Commission (BCUC)', 'BCUC'),
('Municipal Securities Rulemaking Board (MSRB)', 'MSRB'),
('New York State Department of Environmental Conservation (DEC) - LNG', 'NYSDEC'),
('National Marine Fisheries Service (NOAA/NMFS)', 'NMFS'),
('FINRA (Self-Regulatory Organization)', 'FINRA'),
('Florida Department of Business and Professional Regulation (DBPR)', 'FDBPR'),
('Fisheries and Oceans Canada', 'DFO'),
('European Renewable Energy Regulatory Authorities', 'LOCAL'),
('Bureau of Ocean Energy Management (BOEM) - DOI', 'BOEM'),
('QazaqGaz (Kazakhstan)', 'QAZAQGAS'),
('Ministerio do Trabalho e Emprego (MTE) - Normas Regulamentadoras', 'MTE'),
('Agencia Nacional do Petroleo, Gas Natural e Biocombustiveis (ANP)', 'ANP'),
('First Nations Energy Authorities', 'LOCAL'),
('U.S. Fish and Wildlife Service (USFWS)', 'USFWS'),
('Canada-Newfoundland and Labrador Offshore Petroleum Board (C-NLOPB)', 'CNLOPB'),
('U.S. EPA - Risk Management Program (RMP)', 'EPA'),
('Egypt Ministry of Petroleum and Mineral Resources', 'EMPMR'),
('ARH (Hydrocarbon Regulation Authority - Algeria)', 'ARH'),
('European Securities and Markets Authority (ESMA)', 'ESMA'),
('International Maritime Organization (IMO)', 'IMO'),
('West Virginia Department of Environmental Protection (WVDEP)', 'WVDEP'),
('Salt Lake County, Utah', 'LOCAL'),
('Harris County, Texas', 'LOCAL'),
('Canada Revenue Agency (CRA)', 'CRA'),
('Williston Basin Local Authorities', 'LOCAL'),
('Alberta Occupational Health and Safety', 'AOHS'),
('U.S. Department of Transportation (DOT) / PHMSA', 'PHMSA'),
('New Mexico Public Regulation Commission (PRC) - Pipeline Safety Bureau', 'NMPRC'),
('IBAMA / CONAMA (Meio Ambiente)', 'IBAMA'),
('European Chemicals Agency (ECHA)', 'ECHA'),
('Occupational Safety and Health Administration (OSHA)', 'OSHA'),
('New York State Dept. of Environmental Conservation (NYSDEC)', 'NYSDEC'),
('Minnesota Public Utilities Commission', 'MPUC'),
('Alberta Environment & Protected Areas (AEPA)', 'AEPA'),
('Egyptian General Petroleum Corporation (EGPC)', 'EGPC'),
('Oil and Natural Gas Corporation (ONGC - India)', 'ONGC'),
('Autoridad de Fiscalizacion y Control Social de Empresas Bolivia', 'AEFCSE'),
('Municipal Planning Departments', 'LOCAL'),
('Alberta Energy Regulator (AER) - Flaring/Venting', 'AER'),
('Transportation Security Administration (TSA) - Department of Homeland Security', 'TSA'),
('State Agency for Management and Use of Hydrocarbon Resources (Turkmenistan)', 'SAMHR'),
('Federal Reserve Board', 'FRB'),
('Health Canada', 'HC'),
('Kansas Corporation Commission', 'KCC'),
('Canada-Newfoundland and Labrador Offshore Petroleum Board (C-NLOPB)', 'CNLOPB'),
('Louisiana Public Service Commission', 'LPSC'),
('Massachusetts Department of Environmental Protection (MassDEP)', 'MASSDEP'),
('Instituto Brasileiro do Meio Ambiente e dos Recursos Naturais Renovaveis (IBAMA)', 'IBAMA'),
('Republic of the Marshall Islands Maritime Administrator', 'RMI'),
('Department of Homeland Security (TSA/CISA)', 'DHS'),
('Bureau of Safety and Environmental Enforcement (BSEE)', 'BSEE'),
('UK Environment Agency', 'UKEA'),
('International Energy Agency (IEA)', 'IEA'),
('New Mexico Oil Conservation Commission', 'NMOCC'),
('PDVSA (Venezuela)', 'PDVSA'),
('National Petroleum Institute (Mozambique)', 'INP'),
('Federal Banking Agencies (FRB, OCC, FDIC, NCUA)', 'FBA'),
('Ministerio del Poder Popular de Petroleo Venezuela', 'MPPETROL'),
('ECCC - Greenhouse Gas Reporting', 'ECCC'),
('Montana Public Service Commission', 'MPSC'),
('Cassa Depositi e Prestiti', 'CDP'),
('Financial Crimes Enforcement Network (FinCEN, U.S. Treasury)', 'FINCEN'),
('Agencia Nacional de Transportes Aquaviarios (ANTAQ)', 'ANTAQ'),
('U.S. Fish & Wildlife Service (USFWS) / NOAA NMFS (Joint)', 'USFWS'),
('Colorado Oil and Gas Conservation Commission (COGCC)', 'COGCC'),
('Michigan Public Service Commission', 'MIPSC'),
('Louisiana Department of Natural Resources - Office of Conservation (Pipeline Safety)', 'LDNR'),
('U.S. DOT/PHMSA - Rail', 'PHMSA'),
('Cal/OSHA', 'CALOSHA'),
('GAIL India', 'GAIL'),
('San Francisco Bay Regional Water Quality Control Board', 'SFBRWQCB'),
('Federal Deposit Insurance Corporation (FDIC)', 'FDIC'),
('Equal Employment Opportunity Commission (EEOC)', 'EEOC'),
('California Public Utilities Commission', 'CPUC'),
('Texas State Securities Board', 'TSSB'),
('Santos (Australia)', 'SANTOS'),
('New York Public Service Commission (PSC)', 'NYPSC'),
('New York State Department of Financial Services', 'NYDFS'),
('Ontario Ministry of the Environment, Conservation and Parks (MECP)', 'MECP'),
('Office of Natural Resources Revenue (ONRR)', 'ONRR'),
('Office of Financial Research (OFR)', 'OFR'),
('Banco Central do Brasil', 'BCB'),
('Department for Energy Security and Net Zero (UK)', 'DESNZ'),
('Texas Department of Transportation (TxDOT)', 'TXDOT'),
('Nebraska Public Service Commission', 'NPSC'),
('Florida Department of Environmental Protection', 'FDEP'),
('ANAC - National Anti-Corruption Authority', 'ANAC'),
('Federal Trade Commission (FTC)', 'FTC'),
('TotalEnergies SE', 'TOTALENERGIES'),
('Pennsylvania Department of Environmental Protection (PADEP)', 'PADEP'),
('Borsa Italiana (Euronext Milan)', 'BORSA'),
('United Nations Framework Convention on Climate Change (UNFCCC)', 'UNFCCC'),
('Pipeline and Hazardous Materials Safety Administration (PHMSA) - DOT', 'PHMSA'),
('U.S. Environmental Protection Agency (EPA) - EPCRA', 'EPA'),
('Louisiana Department of Revenue', 'LDR'),
('Illinois Department of Financial and Professional Regulation', 'IDFPR'),
('WV DEP - Division of Air Quality', 'WVDEP'),
('Abu Dhabi National Oil Company (ADNOC)', 'ADNOC'),
('Comision Nacional de Energia (CNE)', 'CNE'),
('Board of Governors of the Federal Reserve System (FRB)', 'FRB'),
('Commissione Nazionale per le Societa e la Borsa (CONSOB)', 'CONSOB'),
('U.S. Congress (Statute)', 'CONGRESS'),
('New York State Department of Environmental Conservation (DEC)', 'NYSDEC'),
('Agencia de Seguridad, Energia y Ambiente (ASEA)', 'ASEA'),
('European Union (EU)', 'EU'),
('PEMEX (Mexico)', 'PEMEX'),
('Local Health Departments', 'LOCAL'),
('North American Electric Reliability Corporation (NERC)', 'NERC'),
('Iraq National Oil Company', 'INOC'),
('Regulatory Body', 'RB'),
('PCI Security Standards Council', 'PCI'),
('Wyoming Oil and Gas Conservation Commission', 'WOGCC'),
('Petroleos de Venezuela S.A. (PDVSA)', 'PDVSA'),
('Pipeline and Hazardous Materials Safety Administration (PHMSA) - U.S. DOT', 'PHMSA'),
('Colorado Air Quality Control Commission (AQCC)', 'CAQCC'),
('Bureau of Industry and Security (BIS)', 'BIS'),
('U.S. Coast Guard - 33 CFR Part 154 (Facilities Transferring Oil/HM in Bulk)', 'USCG'),
('Enbridge (Tariff Notices) - FERC jurisdiction', 'ENBRIDGE'),
('Ontario MECP - Environmental Approvals', 'MECP'),
('U.S. Army Corps of Engineers / EPA', 'USACE'),
('Oil and Gas Authority (UK)', 'OGA'),
('Energy Regulatory Commission (CRE) / successor National Energy Commission (CNE)', 'CNE'),
('Occupational Safety and Health Administration (OSHA)-Part Of DOL', 'OSHA'),
('Massachusetts Office of Energy and Environmental Affairs (EEA)', 'MAEEA'),
('Texas General Land Office (GLO)', 'GLO'),
('Ministry of Labour & Social Policies', 'MLSP'),
('National Petroleum and Minerals Authority (Timor-Leste)', 'NPMA'),
('Utah Public Service Commission (Utah Commission)', 'UPSC'),
('European Commission (DG ENV)', 'EC'),
('Delaware Department of Finance', 'DDF'),
('Ministry of Petroleum and Energy (Timor-Leste)', 'MPE'),
('Wyoming Public Service Commission (Wyoming Commission)', 'WPSC'),
('Louisiana Department of Natural Resources - Office of Conservation', 'LDNR'),
('Canadian Nuclear Safety Commission (CNSC)', 'CNSC'),
('City of El Segundo, California', 'LOCAL'),
('Oklahoma Department of Environmental Quality (ODEQ)', 'ODEQ'),
('U.S. Securities and Exchange Commission (SEC)', 'SEC'),
('U.S. Customs and Border Protection (CBP)', 'CBP'),
('North Dakota Public Service Commission', 'NDPSC'),
('Federal Trade Commission (FTC) / Commodity Futures Trading Commission (CFTC)', 'FTC'),
('Department of Interior Bureau of Land Management (BLM)', 'BLM'),
('OROGO - Drilling & Production', 'OROGO'),
('Canada Energy Regulator (CER) - Damage Prevention', 'CER'),
('European Central Bank (ECB)', 'ECB'),
('Massachusetts Department of Public Utilities (DPU)', 'MADPU'),
('UK Maritime and Coastguard Agency', 'MCA'),
('Federal Emergency Management Agency (FEMA)', 'FEMA'),
('MIREMPET (Ministry of Mineral Resources, Petroleum and Gas - Angola)', 'MIREMPET'),
('British Columbia Oil and Gas Commission', 'BCOGC'),
('Environment and Climate Change Canada - Storage Tanks (federal jurisdiction)', 'ECCC'),
('Independent Electricity System Operator (IESO)', 'IESO'),
('Committee for Environmental Protection under the Government (Turkmenistan)', 'CEPG'),
('Republic of Marshall Islands Maritime Administrator', 'RMI'),
('Pennsylvania Department of Environmental Protection (DEP) - Oil & Gas', 'PADEP'),
('Texas Department of Banking', 'TDB'),
('Comision Nacional del Agua (CONAGUA)', 'CONAGUA'),
('U.S. DOT/PHMSA - HMR (General)', 'PHMSA'),
('Port of Beaumont', 'POB'),
('Det Norske Veritas (DNV)', 'DNV'),
('Oklahoma Corporation Commission - Pipeline Safety', 'OCC'),
('Quebec Regie de l''energie', 'RDL'),
('Oklahoma Department of Environmental Quality', 'ODEQ'),
('Autoridade Nacional de Seguranca Nuclear (ANSN)', 'ANSN'),
('U.S. Environmental Protection Agency (EPA) - EPCRA/CERCLA', 'EPA'),
('UK Financial Conduct Authority (FCA)', 'FCA'),
('Secretaria de Energia (SENER)', 'SENER'),
('Indigenous Services Canada', 'ISC'),
('U.S. Coast Guard (USCG) - Department of Homeland Security', 'USCG'),
('ENH (Empresa Nacional de Hidrocarbonetos - Mozambique)', 'ENH'),
('Natural Resources Canada', 'NRCAN'),
('New Mexico Taxation and Revenue Department', 'NMTRD'),
('Florida Department of Agriculture and Consumer Services (FDACS)', 'FDACS'),
('European Network of Transmission System Operators for Gas (ENTSOG)', 'ENTSOG'),
('Utah Department of Financial Institutions', 'UDFI'),
('European Commission (DG CLIMA)', 'EC'),
('Oklahoma Corporation Commission (OCC) - Pipeline Safety', 'OCC');

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_regulatory_bodies_short_name_name ON regulatory_bodies(regulatory_body_name);
CREATE INDEX IF NOT EXISTS idx_regulatory_bodies_short_name ON regulatory_bodies(short_name);

-- Update the updated_at timestamp automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_regulatory_bodies_updated_at 
    BEFORE UPDATE ON regulatory_bodies 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Verify the insert
SELECT COUNT(*) as total_regulatory_bodies FROM regulatory_bodies;

-- Show sample data
SELECT id, regulatory_body_name, short_name 
FROM regulatory_bodies 
ORDER BY regulatory_body_name 
LIMIT 10;





SET search_path TO companies_data;

-- ===================================================================
-- FIXED VIEW: JOIN WITH regulatory_bodies_short_name TABLE
-- Join on regulatory_body_name to get the short_name
-- ===================================================================

CREATE OR REPLACE VIEW  companies_master_view AS
SELECT 
    -- Company Information
    c.company_id,
    c.company_name,
    c.zipcode,
    c.created_at as company_created_at,
    c.updated_at as company_updated_at,
    
    -- Industry Information
    i.industry_id,
    i.industry_name,
    i.industry_description,
    
    -- Sector Information
    s.sector_id,
    s.sector_name,
    s.sector_description,
    
    -- Region Information
    r.region_id,
    r.region_name,
    r.country_name,
    r.region_code,
    
    -- Regulatory Body Information (WITH SHORT_NAME FROM SEPARATE TABLE)
    rb.regulatory_body_id,
    rb.regulatory_body_name,
    COALESCE(rbsn.short_name, 'UNK') as regulatory_body_short_name,  -- <- JOIN TO GET SHORT NAME
    rb.regulatory_level,
    rb.description as regulatory_body_description,
    rb.website_url as regulatory_body_website,
    rb.created_at as regulatory_body_created_at,
    
    -- Regulation Information
    reg.regulation_id,
    reg.regulation_name,
    reg.regulation_code,
    reg.regulation_type,
    reg.effective_date as regulation_effective_date,
    reg.status as regulation_status,
    reg.description as regulation_description,
    reg.created_at as regulation_created_at,
    reg.updated_at as regulation_updated_at,
    
    -- Company-Regulation Mapping Information
    cr.mapping_id,
    cr.compliance_status,
    cr.last_audit_date,
    cr.next_audit_date,
    cr.notes as compliance_notes,
    cr.created_at as mapping_created_at,
    cr.updated_at as mapping_updated_at,
    
    -- Geographic Information (Full)
    CONCAT(r.region_name, ', ', r.country_name) as full_location,
    
    -- Regulatory Information (Full)
    CONCAT(rb.regulatory_body_name, ' (', rb.regulatory_level, ')') as full_regulatory_info

FROM companies c
    LEFT JOIN industries i ON c.industry_id = i.industry_id
    LEFT JOIN sectors s ON c.sector_id = s.sector_id
    LEFT JOIN regions r ON c.region_id = r.region_id
    LEFT JOIN company_regulations cr ON c.company_id = cr.company_id
    LEFT JOIN regulations reg ON cr.regulation_id = reg.regulation_id
    LEFT JOIN regulatory_bodies rb ON reg.regulatory_body_id = rb.regulatory_body_id
    -- JOIN WITH THE SHORT NAME TABLE
    LEFT JOIN regulatory_bodies_short_name rbsn ON rb.regulatory_body_name = rbsn.regulatory_body_name;

-- Add comments for documentation
COMMENT ON VIEW companies_master_view IS 'Master view containing all attributes from companies, industries, sectors, regions, regulatory bodies, regulations, and company-regulation mappings. Now includes regulatory_body_short_name field.';

-- Test the view
-- SELECT company_name, regulatory_body_name, regulatory_body_short_name
-- FROM companies_master_view 
-- WHERE regulatory_body_short_name IS NOT NULL
-- LIMIT 10;