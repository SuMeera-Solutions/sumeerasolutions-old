-- DDL for creating all tables in the schema

-- Table: INDUSTRIES
CREATE TABLE INDUSTRIES (
    industryId SERIAL PRIMARY KEY,
    industryName VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100)
);

-- Table: SECTORS
CREATE TABLE SECTORS (
    sectorId SERIAL PRIMARY KEY,
    sectorName VARCHAR(100) NOT NULL,
    industryId INT REFERENCES INDUSTRIES(industryId),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100)
);

-- Table: COUNTRY
CREATE TABLE COUNTRY (
    countryId SERIAL PRIMARY KEY,
    countryName VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100)
);

-- Table: REGION
CREATE TABLE REGION (
    regionId SERIAL PRIMARY KEY,
    regionName VARCHAR(100) NOT NULL,
    countryId INT REFERENCES COUNTRY(countryId),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100)
);

-- Table: COMPANIES
CREATE TABLE COMPANIES (
    companyId SERIAL PRIMARY KEY,
    companyName VARCHAR(100) NOT NULL,
    sectorId INT REFERENCES SECTORS(sectorId),
    industryId INT REFERENCES INDUSTRIES(industryId),
    regionId INT REFERENCES REGION(regionId),
    zipCode VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100)
);

-- Table: REGULATORY_BODIES
CREATE TABLE REGULATORY_BODIES (
    regBodyId SERIAL PRIMARY KEY,
    regBodyName VARCHAR(100) NOT NULL,
    regBodyDescription VARCHAR(255),
    website VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100)
);

-- Table: REGULATIONS
CREATE TABLE REGULATIONS (
    regulationId SERIAL PRIMARY KEY,
    regBodyId INT REFERENCES REGULATORY_BODIES(regBodyId),
    regulationName VARCHAR(255) NOT NULL,
    regulationDescription TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100)
);

-- Table: COMPLIANCE_RULES
CREATE TABLE COMPLIANCE_RULES (
    ruleId SERIAL PRIMARY KEY,
    regulationId INT REFERENCES REGULATIONS(regulationId),
    regBodyId INT REFERENCES REGULATORY_BODIES(regBodyId),
    sectorId INT REFERENCES SECTORS(sectorId),
    companyId INT REFERENCES COMPANIES(companyId),
    ruleNumber VARCHAR(50),
    ruleTitle VARCHAR(255),
    ruleDescription TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100)
);

-- Table: COMPLIANCE_STATUS
CREATE TABLE COMPLIANCE_STATUS (
    complianceStatusId SERIAL PRIMARY KEY,
    companyId INT REFERENCES COMPANIES(companyId),
    ruleId INT REFERENCES COMPLIANCE_RULES(ruleId),
    complianceStatus VARCHAR(50),
    lastCheckedDate TIMESTAMP,
    comments TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100)
);

-- Table: VIOLATIONS
CREATE TABLE VIOLATIONS (
    violationId SERIAL PRIMARY KEY,
    companyId INT REFERENCES COMPANIES(companyId),
    ruleId INT REFERENCES COMPLIANCE_RULES(ruleId),
    violationDate TIMESTAMP,
    correctiveAction TEXT,
    penalty DECIMAL(15, 2),
    resolved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    updated_by VARCHAR(100)
);

-- Audit Tables

-- Table: INDUSTRIES_AUDIT
CREATE TABLE INDUSTRIES_AUDIT (
    auditId SERIAL PRIMARY KEY,
    industryId INT,
    industryName VARCHAR(100),
    operation VARCHAR(10), -- INSERT, UPDATE, DELETE
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(100)
);

-- Table: SECTORS_AUDIT
CREATE TABLE SECTORS_AUDIT (
    auditId SERIAL PRIMARY KEY,
    sectorId INT,
    sectorName VARCHAR(100),
    industryId INT,
    operation VARCHAR(10), -- INSERT, UPDATE, DELETE
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(100)
);

-- Table: COUNTRY_AUDIT
CREATE TABLE COUNTRY_AUDIT (
    auditId SERIAL PRIMARY KEY,
    countryId INT,
    countryName VARCHAR(100),
    operation VARCHAR(10), -- INSERT, UPDATE, DELETE
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(100)
);

-- Table: REGION_AUDIT
CREATE TABLE REGION_AUDIT (
    auditId SERIAL PRIMARY KEY,
    regionId INT,
    regionName VARCHAR(100),
    countryId INT,
    operation VARCHAR(10), -- INSERT, UPDATE, DELETE
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(100)
);

-- Table: COMPANIES_AUDIT
CREATE TABLE COMPANIES_AUDIT (
    auditId SERIAL PRIMARY KEY,
    companyId INT,
    companyName VARCHAR(100),
    sectorId INT,
    industryId INT,
    regionId INT,
    zipCode VARCHAR(20),
    operation VARCHAR(10), -- INSERT, UPDATE, DELETE
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(100)
);

-- Table: REGULATORY_BODIES_AUDIT
CREATE TABLE REGULATORY_BODIES_AUDIT (
    auditId SERIAL PRIMARY KEY,
    regBodyId INT,
    regBodyName VARCHAR(100),
    regBodyDescription VARCHAR(255),
    website VARCHAR(255),
    operation VARCHAR(10), -- INSERT, UPDATE, DELETE
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(100)
);

-- Table: REGULATIONS_AUDIT
CREATE TABLE REGULATIONS_AUDIT (
    auditId SERIAL PRIMARY KEY,
    regulationId INT,
    regBodyId INT,
    regulationName VARCHAR(255),
    regulationDescription TEXT,
    operation VARCHAR(10), -- INSERT, UPDATE, DELETE
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(100)
);

-- Table: COMPLIANCE_RULES_AUDIT
CREATE TABLE COMPLIANCE_RULES_AUDIT (
    auditId SERIAL PRIMARY KEY,
    ruleId INT,
    regulationId INT,
    regBodyId INT,
    sectorId INT,
    companyId INT,
    ruleNumber VARCHAR(50),
    ruleTitle VARCHAR(255),
    ruleDescription TEXT,
    operation VARCHAR(10), -- INSERT, UPDATE, DELETE
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(100)
);

-- Insert statements

-- Insert statements

INSERT INTO INDUSTRIES (industryName, created_by, updated_by)
SELECT DISTINCT industry AS industryName, 'nreddy' AS created_by, 'nreddy' AS updated_by
FROM stg_company_data
WHERE industry IS NOT NULL;

INSERT INTO SECTORS (sectorName, industryId, created_by, updated_by)
SELECT DISTINCT cd.sector AS sectorName, i.industryId, 'nreddy' AS created_by, 'nreddy' AS updated_by
FROM stg_company_data cd
JOIN INDUSTRIES i ON cd.industry = i.industryName
WHERE cd.sector IS NOT NULL;

INSERT INTO COUNTRY (countryName, created_by, updated_by)
SELECT DISTINCT country AS countryName, 'nreddy' AS created_by, 'nreddy' AS updated_by
FROM stg_company_data
WHERE country IS NOT NULL;

INSERT INTO REGION (regionName, countryId, created_by, updated_by)
SELECT DISTINCT cd.region AS regionName, c.countryId, 'nreddy' AS created_by, 'nreddy' AS updated_by
FROM stg_company_data cd
JOIN COUNTRY c ON cd.country = c.countryName
WHERE cd.region IS NOT NULL;

INSERT INTO COMPANIES (companyName, sectorId, industryId, regionId, zipCode, created_by, updated_by)
SELECT cd."company_name" AS companyName,
       s.sectorId,
       s.industryId,
       r.regionId,
       cd."zip_code" AS zipCode,
       'nreddy' AS created_by,
       'nreddy' AS updated_by
FROM stg_company_data cd
JOIN SECTORS s ON cd."sector" = s.sectorName
JOIN INDUSTRIES i ON s.industryId = i.industryId
JOIN REGION r ON cd."region" = r.regionName
WHERE cd."company_name" IS NOT NULL;

INSERT INTO REGULATORY_BODIES (regBodyName, regBodyDescription, website, created_by, updated_by)
SELECT DISTINCT sc.compliance_type AS regBodyName, NULL AS regBodyDescription, NULL AS website, 'nreddy', 'nreddy'
FROM stg_compliance_data sc
WHERE sc.compliance_type IS NOT NULL;

INSERT INTO REGULATIONS (regBodyId, regulationName, regulationDescription, created_by, updated_by)
SELECT DISTINCT rb.regBodyId, sc.compliance_details AS regulationName, NULL AS regulationDescription, 'nreddy', 'nreddy'
FROM stg_compliance_data sc
JOIN REGULATORY_BODIES rb ON sc.compliance_type = rb.regBodyName
WHERE sc.compliance_details IS NOT NULL;

INSERT INTO COMPLIANCE_RULES (
    regulationId,
    regBodyId,
    sectorId,
    companyId,
    ruleNumber,
    ruleTitle,
    ruleDescription,
    created_by,
    updated_by
)
SELECT DISTINCT 
    r.regulationId,
    rb.regBodyId,
    s.sectorId,
    cmp.companyId,
    'Rule-' || r.regulationId AS ruleNumber,
    r.regulationName AS ruleTitle,
    r.regulationDescription AS ruleDescription,
    'nreddy',
    'nreddy'
FROM stg_compliance_data sc
JOIN REGULATIONS r ON sc.compliance_details = r.regulationName
JOIN REGULATORY_BODIES rb ON sc.compliance_type = rb.regBodyName
JOIN COMPANIES cmp ON sc.company = cmp.companyName
JOIN SECTORS s ON cmp.sectorId = s.sectorId
WHERE sc.compliance_details IS NOT NULL;

INSERT INTO COMPLIANCE_STATUS (
    companyId,
    ruleId,
    complianceStatus,
    lastCheckedDate,
    comments,
    created_by,
    updated_by
)
SELECT DISTINCT 
    cmp.companyId,
    cr.ruleId,
    'Pending' AS complianceStatus,
    CURRENT_TIMESTAMP AS lastCheckedDate,
    'Initial compliance status' AS comments,
    'nreddy',
    'nreddy'
FROM stg_compliance_data sc
JOIN COMPANIES cmp ON sc.company = cmp.companyName
JOIN COMPLIANCE_RULES cr ON cr.companyId = cmp.companyId
WHERE sc.compliance_details IS NOT NULL;

INSERT INTO VIOLATIONS (
    companyId,
    ruleId,
    violationDate,
    correctiveAction,
    penalty,
    resolved,
    created_by,
    updated_by
)
SELECT DISTINCT 
    cmp.companyId,
    cr.ruleId,
    CURRENT_TIMESTAMP AS violationDate,
    'Corrective action required' AS correctiveAction,
    1000.00 AS penalty,
    FALSE AS resolved,
    'nreddy',
    'nreddy'
FROM stg_compliance_data sc
JOIN COMPANIES cmp ON sc.company = cmp.companyName
JOIN COMPLIANCE_RULES cr ON cr.companyId = cmp.companyId
WHERE sc.compliance_details IS NOT NULL;

-- View to retrieve all company details including compliance rules (if available)

CREATE OR REPLACE VIEW company_compliance_levels AS
SELECT 
    level_1.countryName AS country_name_level_1,
    level_2.regionName AS region_name_level_2,
    level_3.sectorName AS sector_name_level_3,
    level_4.industryName AS industry_name_level_4,
    level_5.companyName AS company_name_level_5,
    level_6.regBodyName AS regulatory_body_name_level_6,
    level_7.regulationName AS regulation_name_level_7,
    level_8.ruleNumber AS rule_number_level_8,
    level_8.ruleTitle AS rule_title_level_8,
    level_8.ruleDescription AS rule_description_level_8,
    cs.complianceStatus AS compliance_status,
    cs.lastCheckedDate AS last_checked_date,
    cs.comments AS compliance_comments,
    v.violationDate AS violation_date,
    v.correctiveAction AS corrective_action,
    v.penalty,
    v.resolved AS violation_resolved
FROM COMPANIES level_5
LEFT JOIN COMPLIANCE_STATUS cs ON level_5.companyId = cs.companyId
LEFT JOIN VIOLATIONS v ON level_5.companyId = v.companyId
LEFT JOIN REGION level_2 ON level_5.regionId = level_2.regionId
LEFT JOIN COUNTRY level_1 ON level_2.countryId = level_1.countryId
LEFT JOIN SECTORS level_3 ON level_5.sectorId = level_3.sectorId
LEFT JOIN INDUSTRIES level_4 ON level_3.industryId = level_4.industryId
LEFT JOIN COMPLIANCE_RULES level_8 ON level_5.companyId = level_8.companyId
LEFT JOIN REGULATIONS level_7 ON level_8.regulationId = level_7.regulationId
LEFT JOIN REGULATORY_BODIES level_6 ON level_7.regBodyId = level_6.regBodyId;

