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

INSERT INTO COMPANIES (companyName, industryId, sectorId, regionId, zipCode, created_by, updated_by)
SELECT cd."company_name" AS companyName, 
       i.industryId, 
       s.sectorId, 
       r.regionId, 
       cd."zip_code" AS zipCode, 
       'nreddy' AS created_by, 
       'nreddy' AS updated_by
FROM stg_company_data cd
JOIN INDUSTRIES i ON cd."industry" = i.industryName
JOIN SECTORS s ON cd."sector" = s.sectorName AND s.industryId = i.industryId
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


CREATE VIEW company_compliance_hierarchy AS
SELECT 
    c.countryName AS country,
    r.regionName AS region,
    i.industryName AS industry,
    s.sectorName AS sector,
    cmp.companyName AS company,
    rb.regBodyName AS regulatory_body,
    reg.regulationName AS regulation,
    cr.ruleNumber AS rule_number,
    cr.ruleTitle AS rule_title,
    cr.ruleDescription AS rule_description,
    c.countryId AS country_id,
    r.regionId AS region_id,
    i.industryId AS industry_id,
    s.sectorId AS sector_id,
    cmp.companyId AS company_id,
    rb.regBodyId AS regulatory_body_id,
    reg.regulationId AS regulation_id,
    cr.ruleId AS rule_id,
    cr.created_by AS rule_created_by,
    cr.updated_by AS rule_updated_by,
    cmp.zipCode AS company_zip_code,
    cmp.created_by AS company_created_by,
    cmp.updated_by AS company_updated_by
FROM COMPANIES cmp
JOIN REGION r ON cmp.regionId = r.regionId
JOIN COUNTRY c ON r.countryId = c.countryId
JOIN SECTORS s ON cmp.sectorId = s.sectorId
JOIN INDUSTRIES i ON s.industryId = i.industryId
LEFT JOIN COMPLIANCE_RULES cr ON cmp.companyId = cr.companyId
JOIN REGULATIONS reg ON cr.regulationId = reg.regulationId
JOIN REGULATORY_BODIES rb ON reg.regBodyId = rb.regBodyId