-- =====================================================
-- FIXED STORED PROCEDURE - Simplified Working Version
-- =====================================================

DROP FUNCTION IF EXISTS generate_complete_compliance_report(character varying,character varying,character varying,character varying,character varying);

CREATE OR REPLACE FUNCTION generate_complete_compliance_report(
    p_country VARCHAR DEFAULT NULL,
    p_region VARCHAR DEFAULT NULL,
    p_sector VARCHAR DEFAULT NULL,
    p_industry VARCHAR DEFAULT NULL,
    p_company_name VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    result_type VARCHAR,
    total_regulations BIGINT,
    regulatory_bodies_count BIGINT,
    federal_count BIGINT,
    state_count BIGINT,
    international_count BIGINT,
    automation_potential INTEGER,
    industries_covered BIGINT,
    company_name VARCHAR,
    country_name VARCHAR,
    sector_name VARCHAR,
    industry_name VARCHAR,
    regulatory_body_name_detail VARCHAR,
    regulatory_level_detail VARCHAR,
    regulation_name VARCHAR,
    regulation_description VARCHAR,
    compliance_status VARCHAR,
    regulation_code VARCHAR,
    regulation_type VARCHAR,
    industry_regulation_count BIGINT,
    report_generated_at TIMESTAMP,
    report_date_display VARCHAR,
    match_priority INTEGER
) 
AS $$
DECLARE
    total_regs BIGINT;
    total_bodies BIGINT;
    federal_cnt BIGINT;
    state_cnt BIGINT;
    intl_cnt BIGINT;
    industries_cnt BIGINT;
BEGIN
    -- First, get summary statistics with simple matching
    SELECT 
        COUNT(*),
        COUNT(DISTINCT cmv.regulatory_body_name),
        COUNT(CASE WHEN cmv.regulatory_level = 'Federal' THEN 1 END),
        COUNT(CASE WHEN cmv.regulatory_level = 'State' THEN 1 END),
        COUNT(CASE WHEN cmv.regulatory_level = 'International' THEN 1 END),
        COUNT(DISTINCT cmv.industry_name)
    INTO total_regs, total_bodies, federal_cnt, state_cnt, intl_cnt, industries_cnt
    FROM companies_data.companies_master_view cmv
    WHERE cmv.regulatory_body_name IS NOT NULL
      -- Simple matching conditions
      AND (p_country IS NULL OR cmv.country_name ILIKE '%' || p_country || '%')
      AND (p_region IS NULL OR cmv.region_name ILIKE '%' || p_region || '%')
      AND (p_sector IS NULL OR cmv.sector_name ILIKE '%' || p_sector || '%')
      AND (p_industry IS NULL OR cmv.industry_name ILIKE '%' || p_industry || '%')
      AND (p_company_name IS NULL OR cmv.company_name ILIKE '%' || p_company_name || '%');

    -- Return 1: Summary Statistics
    RETURN QUERY
    SELECT 
        'SUMMARY'::VARCHAR as result_type,
        total_regs as total_regulations,
        total_bodies as regulatory_bodies_count,
        federal_cnt as federal_count,
        state_cnt as state_count,
        intl_cnt as international_count,
        85 as automation_potential,
        industries_cnt as industries_covered,
        
        NULL::VARCHAR as company_name,
        NULL::VARCHAR as country_name,
        NULL::VARCHAR as sector_name,
        NULL::VARCHAR as industry_name,
        NULL::VARCHAR as regulatory_body_name_detail,
        NULL::VARCHAR as regulatory_level_detail,
        NULL::VARCHAR as regulation_name,
        NULL::VARCHAR as regulation_description,
        NULL::VARCHAR as compliance_status,
        NULL::VARCHAR as regulation_code,
        NULL::VARCHAR as regulation_type,
        NULL::BIGINT as industry_regulation_count,
        
        CURRENT_TIMESTAMP::TIMESTAMP as report_generated_at,
        TO_CHAR(CURRENT_TIMESTAMP, 'Month DD, YYYY')::VARCHAR as report_date_display,
        1 as match_priority;

    -- Return 2: Detailed Regulations
    RETURN QUERY
    SELECT 
        'REGULATION'::VARCHAR as result_type,
        total_regs as total_regulations,
        total_bodies as regulatory_bodies_count,
        federal_cnt as federal_count,
        state_cnt as state_count,
        intl_cnt as international_count,
        85 as automation_potential,
        industries_cnt as industries_covered,
        
        cmv.company_name::VARCHAR,
        cmv.country_name::VARCHAR,
        cmv.sector_name::VARCHAR,
        cmv.industry_name::VARCHAR,
        cmv.regulatory_body_name::VARCHAR,
        cmv.regulatory_level::VARCHAR,
        cmv.regulation_name::VARCHAR,
        cmv.regulation_description::VARCHAR,
        cmv.compliance_status::VARCHAR,
        cmv.regulation_code::VARCHAR,
        cmv.regulation_type::VARCHAR,
        COUNT(*) OVER (PARTITION BY cmv.industry_name)::BIGINT as industry_regulation_count,
        
        CURRENT_TIMESTAMP::TIMESTAMP as report_generated_at,
        TO_CHAR(CURRENT_TIMESTAMP, 'Month DD, YYYY')::VARCHAR as report_date_display,
        CASE 
            WHEN p_company_name IS NULL THEN 1
            WHEN cmv.company_name ILIKE p_company_name THEN 1  -- Exact match
            WHEN cmv.company_name ILIKE '%' || p_company_name || '%' THEN 2  -- Contains
            ELSE 3
        END as match_priority

    FROM companies_data.companies_master_view cmv
    WHERE cmv.regulatory_body_name IS NOT NULL
      AND (p_country IS NULL OR cmv.country_name ILIKE '%' || p_country || '%')
      AND (p_region IS NULL OR cmv.region_name ILIKE '%' || p_region || '%')
      AND (p_sector IS NULL OR cmv.sector_name ILIKE '%' || p_sector || '%')
      AND (p_industry IS NULL OR cmv.industry_name ILIKE '%' || p_industry || '%')
      AND (p_company_name IS NULL OR cmv.company_name ILIKE '%' || p_company_name || '%');

    -- Return 3: Industry Breakdown
    RETURN QUERY
    SELECT 
        'INDUSTRY'::VARCHAR as result_type,
        total_regs as total_regulations,
        total_bodies as regulatory_bodies_count,
        federal_cnt as federal_count,
        state_cnt as state_count,
        intl_cnt as international_count,
        85 as automation_potential,
        industries_cnt as industries_covered,
        
        NULL::VARCHAR as company_name,
        NULL::VARCHAR as country_name,
        NULL::VARCHAR as sector_name,
        cmv.industry_name::VARCHAR,
        NULL::VARCHAR as regulatory_body_name_detail,
        NULL::VARCHAR as regulatory_level_detail,
        NULL::VARCHAR as regulation_name,
        NULL::VARCHAR as regulation_description,
        NULL::VARCHAR as compliance_status,
        NULL::VARCHAR as regulation_code,
        NULL::VARCHAR as regulation_type,
        COUNT(*)::BIGINT as industry_regulation_count,
        
        CURRENT_TIMESTAMP::TIMESTAMP as report_generated_at,
        TO_CHAR(CURRENT_TIMESTAMP, 'Month DD, YYYY')::VARCHAR as report_date_display,
        1 as match_priority

    FROM companies_data.companies_master_view cmv
    WHERE cmv.regulatory_body_name IS NOT NULL
      AND (p_country IS NULL OR cmv.country_name ILIKE '%' || p_country || '%')
      AND (p_region IS NULL OR cmv.region_name ILIKE '%' || p_region || '%')
      AND (p_sector IS NULL OR cmv.sector_name ILIKE '%' || p_sector || '%')
      AND (p_industry IS NULL OR cmv.industry_name ILIKE '%' || p_industry || '%')
      AND (p_company_name IS NULL OR cmv.company_name ILIKE '%' || p_company_name || '%')
    GROUP BY cmv.industry_name
    ORDER BY COUNT(*) DESC;

END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TEST THE FIXED PROCEDURE
-- =====================================================

-- Test with no filters (should return data)
SELECT result_type, total_regulations, company_name, industry_name 
FROM generate_complete_compliance_report(NULL, NULL, NULL, NULL, NULL) 
LIMIT 10;

-- Test with company filter
SELECT * 
FROM generate_complete_compliance_report(NULL, NULL, NULL, NULL, 'exxon') 
LIMIT 10;


SELECT * 
FROM generate_complete_compliance_report(NULL, NULL, NULL, NULL, 'Enterprise') ;



-- =====================================================
-- UPDATED STORED PROCEDURE WITH SHORT NAME
-- =====================================================

DROP FUNCTION IF EXISTS generate_complete_compliance_report(character varying,character varying,character varying,character varying,character varying);

CREATE OR REPLACE FUNCTION generate_complete_compliance_report(
    p_country VARCHAR DEFAULT NULL,
    p_region VARCHAR DEFAULT NULL,
    p_sector VARCHAR DEFAULT NULL,
    p_industry VARCHAR DEFAULT NULL,
    p_company_name VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    result_type VARCHAR,
    total_regulations BIGINT,
    regulatory_bodies_count BIGINT,
    federal_count BIGINT,
    state_count BIGINT,
    international_count BIGINT,
    automation_potential INTEGER,
    industries_covered BIGINT,
    company_name VARCHAR,
    country_name VARCHAR,
    sector_name VARCHAR,
    industry_name VARCHAR,
    regulatory_body_name_detail VARCHAR,
    regulatory_body_short_name VARCHAR,  -- <- ADDED SHORT NAME
    regulatory_level_detail VARCHAR,
    regulation_name VARCHAR,
    regulation_description VARCHAR,
    compliance_status VARCHAR,
    regulation_code VARCHAR,
    regulation_type VARCHAR,
    industry_regulation_count BIGINT,
    report_generated_at TIMESTAMP,
    report_date_display VARCHAR,
    match_priority INTEGER
) 
AS $$
DECLARE
    total_regs BIGINT;
    total_bodies BIGINT;
    federal_cnt BIGINT;
    state_cnt BIGINT;
    intl_cnt BIGINT;
    industries_cnt BIGINT;
BEGIN
    -- First, get summary statistics with simple matching
    SELECT 
        COUNT(*),
        COUNT(DISTINCT cmv.regulatory_body_name),
        COUNT(CASE WHEN cmv.regulatory_level = 'Federal' THEN 1 END),
        COUNT(CASE WHEN cmv.regulatory_level = 'State' THEN 1 END),
        COUNT(CASE WHEN cmv.regulatory_level = 'International' THEN 1 END),
        COUNT(DISTINCT cmv.industry_name)
    INTO total_regs, total_bodies, federal_cnt, state_cnt, intl_cnt, industries_cnt
    FROM companies_data.companies_master_view cmv
    WHERE cmv.regulatory_body_name IS NOT NULL
      -- Simple matching conditions
      AND (p_country IS NULL OR cmv.country_name ILIKE '%' || p_country || '%')
      AND (p_region IS NULL OR cmv.region_name ILIKE '%' || p_region || '%')
      AND (p_sector IS NULL OR cmv.sector_name ILIKE '%' || p_sector || '%')
      AND (p_industry IS NULL OR cmv.industry_name ILIKE '%' || p_industry || '%')
      AND (p_company_name IS NULL OR cmv.company_name ILIKE '%' || p_company_name || '%');

    -- Return 1: Summary Statistics
    RETURN QUERY
    SELECT 
        'SUMMARY'::VARCHAR as result_type,
        total_regs as total_regulations,
        total_bodies as regulatory_bodies_count,
        federal_cnt as federal_count,
        state_cnt as state_count,
        intl_cnt as international_count,
        85 as automation_potential,
        industries_cnt as industries_covered,
        
        NULL::VARCHAR as company_name,
        NULL::VARCHAR as country_name,
        NULL::VARCHAR as sector_name,
        NULL::VARCHAR as industry_name,
        NULL::VARCHAR as regulatory_body_name_detail,
        NULL::VARCHAR as regulatory_body_short_name,  -- <- ADDED SHORT NAME
        NULL::VARCHAR as regulatory_level_detail,
        NULL::VARCHAR as regulation_name,
        NULL::VARCHAR as regulation_description,
        NULL::VARCHAR as compliance_status,
        NULL::VARCHAR as regulation_code,
        NULL::VARCHAR as regulation_type,
        NULL::BIGINT as industry_regulation_count,
        
        CURRENT_TIMESTAMP::TIMESTAMP as report_generated_at,
        TO_CHAR(CURRENT_TIMESTAMP, 'Month DD, YYYY')::VARCHAR as report_date_display,
        1 as match_priority;

    -- Return 2: Detailed Regulations
    RETURN QUERY
    SELECT 
        'REGULATION'::VARCHAR as result_type,
        total_regs as total_regulations,
        total_bodies as regulatory_bodies_count,
        federal_cnt as federal_count,
        state_cnt as state_count,
        intl_cnt as international_count,
        85 as automation_potential,
        industries_cnt as industries_covered,
        
        cmv.company_name::VARCHAR,
        cmv.country_name::VARCHAR,
        cmv.sector_name::VARCHAR,
        cmv.industry_name::VARCHAR,
        cmv.regulatory_body_name::VARCHAR,
        cmv.regulatory_body_short_name::VARCHAR,  -- <- ADDED SHORT NAME FROM VIEW
        cmv.regulatory_level::VARCHAR,
        cmv.regulation_name::VARCHAR,
        cmv.regulation_description::VARCHAR,
        cmv.compliance_status::VARCHAR,
        cmv.regulation_code::VARCHAR,
        cmv.regulation_type::VARCHAR,
        COUNT(*) OVER (PARTITION BY cmv.industry_name)::BIGINT as industry_regulation_count,
        
        CURRENT_TIMESTAMP::TIMESTAMP as report_generated_at,
        TO_CHAR(CURRENT_TIMESTAMP, 'Month DD, YYYY')::VARCHAR as report_date_display,
        CASE 
            WHEN p_company_name IS NULL THEN 1
            WHEN cmv.company_name ILIKE p_company_name THEN 1  -- Exact match
            WHEN cmv.company_name ILIKE '%' || p_company_name || '%' THEN 2  -- Contains
            ELSE 3
        END as match_priority

    FROM companies_data.companies_master_view cmv
    WHERE cmv.regulatory_body_name IS NOT NULL
      AND (p_country IS NULL OR cmv.country_name ILIKE '%' || p_country || '%')
      AND (p_region IS NULL OR cmv.region_name ILIKE '%' || p_region || '%')
      AND (p_sector IS NULL OR cmv.sector_name ILIKE '%' || p_sector || '%')
      AND (p_industry IS NULL OR cmv.industry_name ILIKE '%' || p_industry || '%')
      AND (p_company_name IS NULL OR cmv.company_name ILIKE '%' || p_company_name || '%');

    -- Return 3: Industry Breakdown
    RETURN QUERY
    SELECT 
        'INDUSTRY'::VARCHAR as result_type,
        total_regs as total_regulations,
        total_bodies as regulatory_bodies_count,
        federal_cnt as federal_count,
        state_cnt as state_count,
        intl_cnt as international_count,
        85 as automation_potential,
        industries_cnt as industries_covered,
        
        NULL::VARCHAR as company_name,
        NULL::VARCHAR as country_name,
        NULL::VARCHAR as sector_name,
        cmv.industry_name::VARCHAR,
        NULL::VARCHAR as regulatory_body_name_detail,
        NULL::VARCHAR as regulatory_body_short_name,  -- <- ADDED SHORT NAME
        NULL::VARCHAR as regulatory_level_detail,
        NULL::VARCHAR as regulation_name,
        NULL::VARCHAR as regulation_description,
        NULL::VARCHAR as compliance_status,
        NULL::VARCHAR as regulation_code,
        NULL::VARCHAR as regulation_type,
        COUNT(*)::BIGINT as industry_regulation_count,
        
        CURRENT_TIMESTAMP::TIMESTAMP as report_generated_at,
        TO_CHAR(CURRENT_TIMESTAMP, 'Month DD, YYYY')::VARCHAR as report_date_display,
        1 as match_priority

    FROM companies_data.companies_master_view cmv
    WHERE cmv.regulatory_body_name IS NOT NULL
      AND (p_country IS NULL OR cmv.country_name ILIKE '%' || p_country || '%')
      AND (p_region IS NULL OR cmv.region_name ILIKE '%' || p_region || '%')
      AND (p_sector IS NULL OR cmv.sector_name ILIKE '%' || p_sector || '%')
      AND (p_industry IS NULL OR cmv.industry_name ILIKE '%' || p_industry || '%')
      AND (p_company_name IS NULL OR cmv.company_name ILIKE '%' || p_company_name || '%')
    GROUP BY cmv.industry_name
    ORDER BY COUNT(*) DESC;

END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TEST THE UPDATED PROCEDURE WITH SHORT NAME
-- =====================================================

-- Test with no filters (should return data with short names)
SELECT result_type, regulatory_body_name_detail, regulatory_body_short_name, company_name
FROM generate_complete_compliance_report(NULL, NULL, NULL, NULL, NULL) 
WHERE result_type = 'REGULATION'
LIMIT 10;

-- Test with company filter
SELECT result_type, regulatory_body_name_detail, regulatory_body_short_name, company_name
FROM generate_complete_compliance_report(NULL, NULL, NULL, NULL, 'exxon') 
WHERE result_type = 'REGULATION'
LIMIT 10;