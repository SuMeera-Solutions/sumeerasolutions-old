-- ============================================================================
-- OSHA ITA API PAYLOAD GENERATION SIMULATION
-- Tests all payload builders with actual database data
-- ============================================================================

\c compliease_sbx

DO $$ 
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'OSHA ITA PAYLOAD GENERATION SIMULATION';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- STEP 1: VERIFY DATA EXISTS
-- ============================================================================
DO $$ 
DECLARE
  v_est_count int;
  v_incident_count int;
  v_approved_count int;
  v_form300a_count int;
BEGIN
  RAISE NOTICE '>>> STEP 1: Verifying Database Data';
  RAISE NOTICE '';
  
  SELECT COUNT(*) INTO v_est_count FROM osha_ita_v1.establishments;
  SELECT COUNT(*) INTO v_incident_count FROM osha_ita_v1.incidents;
  SELECT COUNT(*) INTO v_approved_count FROM osha_ita_v1.incidents WHERE current_state = 'approved';
  SELECT COUNT(*) INTO v_form300a_count FROM osha_ita_v1.form_300a_summaries WHERE is_current = true;
  
  RAISE NOTICE 'Data Summary:';
  RAISE NOTICE '  Establishments: %', v_est_count;
  RAISE NOTICE '  Total Incidents: %', v_incident_count;
  RAISE NOTICE '  Approved Incidents: %', v_approved_count;
  RAISE NOTICE '  Current Form 300A Summaries: %', v_form300a_count;
  RAISE NOTICE '';
  
  IF v_est_count = 0 THEN
    RAISE NOTICE '⚠ WARNING: No establishments found!';
  END IF;
  
  IF v_approved_count = 0 THEN
    RAISE NOTICE '⚠ WARNING: No approved incidents found!';
  END IF;
END $$;

-- ============================================================================
-- STEP 2: TEST ESTABLISHMENT PAYLOAD BUILDER
-- ============================================================================
DO $$ 
DECLARE
  v_est_id uuid;
  v_est_name text;
  v_payload jsonb;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 2: Testing Establishment Payload Builder';
  RAISE NOTICE '';
  
  -- Get first establishment
  SELECT establishment_id, establishment_name 
  INTO v_est_id, v_est_name
  FROM osha_ita_v1.establishments 
  LIMIT 1;
  
  IF v_est_id IS NULL THEN
    RAISE NOTICE '✗ No establishments found - skipping test';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Building payload for: %', v_est_name;
  RAISE NOTICE '';
  
  -- Build payload
  v_payload := osha_ita_v1.build_establishment_payload(v_est_id);
  
  RAISE NOTICE '========== ESTABLISHMENT PAYLOAD ==========';
  RAISE NOTICE '%', jsonb_pretty(v_payload);
  RAISE NOTICE '===========================================';
  RAISE NOTICE '';
  RAISE NOTICE '✓ Establishment payload generated successfully';
  
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '✗ Error building establishment payload: %', SQLERRM;
END $$;

-- ============================================================================
-- STEP 3: TEST SINGLE CASE DATA PAYLOAD BUILDER
-- ============================================================================
DO $$ 
DECLARE
  v_incident_id uuid;
  v_case_number text;
  v_payload jsonb;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 3: Testing Single Case Data Payload Builder';
  RAISE NOTICE '';
  
  -- Get first approved incident
  SELECT incident_id, case_number 
  INTO v_incident_id, v_case_number
  FROM osha_ita_v1.incidents 
  WHERE current_state = 'approved'
  LIMIT 1;
  
  IF v_incident_id IS NULL THEN
    RAISE NOTICE '✗ No approved incidents found - skipping test';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Building payload for Case: %', v_case_number;
  RAISE NOTICE '';
  
  -- Build payload
  v_payload := osha_ita_v1.build_case_data_payload(v_incident_id);
  
  RAISE NOTICE '========== CASE DATA PAYLOAD ==========';
  RAISE NOTICE '%', jsonb_pretty(v_payload);
  RAISE NOTICE '=======================================';
  RAISE NOTICE '';
  RAISE NOTICE '✓ Case data payload generated successfully';
  
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '✗ Error building case data payload: %', SQLERRM;
END $$;

-- ============================================================================
-- STEP 4: TEST BATCH CASE DATA PAYLOAD BUILDER
-- ============================================================================
DO $$ 
DECLARE
  v_est_id uuid;
  v_est_name text;
  v_year int := 2024;
  v_payload jsonb;
  v_case_count int;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 4: Testing Batch Case Data Payload Builder';
  RAISE NOTICE '';
  
  -- Get establishment with approved incidents
  SELECT DISTINCT i.establishment_id, e.establishment_name
  INTO v_est_id, v_est_name
  FROM osha_ita_v1.incidents i
  JOIN osha_ita_v1.establishments e ON e.establishment_id = i.establishment_id
  WHERE i.current_state = 'approved' AND i.filing_year = v_year
  LIMIT 1;
  
  IF v_est_id IS NULL THEN
    RAISE NOTICE '✗ No approved incidents for year % found - skipping test', v_year;
    RETURN;
  END IF;
  
  -- Count cases
  SELECT COUNT(*) INTO v_case_count
  FROM osha_ita_v1.incidents
  WHERE establishment_id = v_est_id 
    AND filing_year = v_year 
    AND current_state = 'approved';
  
  RAISE NOTICE 'Building batch payload for: %', v_est_name;
  RAISE NOTICE 'Year: % | Cases: %', v_year, v_case_count;
  RAISE NOTICE '';
  
  -- Build payload
  v_payload := osha_ita_v1.build_batch_case_data_payload(v_est_id, v_year);
  
  RAISE NOTICE '========== BATCH CASE DATA PAYLOAD ==========';
  RAISE NOTICE 'Array contains % cases', jsonb_array_length(v_payload);
  RAISE NOTICE '%', jsonb_pretty(v_payload);
  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE '✓ Batch case data payload generated successfully';
  
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '✗ Error building batch payload: %', SQLERRM;
END $$;

-- ============================================================================
-- STEP 5: TEST FORM 300A PAYLOAD BUILDER
-- ============================================================================
DO $$ 
DECLARE
  v_est_id uuid;
  v_est_name text;
  v_year int;
  v_payload jsonb;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 5: Testing Form 300A Payload Builder';
  RAISE NOTICE '';
  
  -- Get establishment with a current 300A summary
  SELECT s.establishment_id, e.establishment_name, s.filing_year
  INTO v_est_id, v_est_name, v_year
  FROM osha_ita_v1.form_300a_summaries s
  JOIN osha_ita_v1.establishments e ON e.establishment_id = s.establishment_id
  WHERE s.is_current = true
  LIMIT 1;
  
  IF v_est_id IS NULL THEN
    RAISE NOTICE '✗ No Form 300A summaries found - skipping test';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Building Form 300A payload for: %', v_est_name;
  RAISE NOTICE 'Year: %', v_year;
  RAISE NOTICE '';
  
  -- Build payload
  v_payload := osha_ita_v1.build_form_300a_payload(v_est_id, v_year);
  
  RAISE NOTICE '========== FORM 300A PAYLOAD ==========';
  RAISE NOTICE '%', jsonb_pretty(v_payload);
  RAISE NOTICE '======================================';
  RAISE NOTICE '';
  RAISE NOTICE '✓ Form 300A payload generated successfully';
  
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '✗ Error building Form 300A payload: %', SQLERRM;
END $$;

-- ============================================================================
-- STEP 6: TEST COMPLETE SUBMISSION PAYLOAD
-- ============================================================================
DO $$ 
DECLARE
  v_est_id uuid;
  v_est_name text;
  v_year int := 2024;
  v_payload jsonb;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 6: Testing Complete Submission Payload';
  RAISE NOTICE '';
  
  -- Get establishment
  SELECT establishment_id, establishment_name 
  INTO v_est_id, v_est_name
  FROM osha_ita_v1.establishments 
  LIMIT 1;
  
  IF v_est_id IS NULL THEN
    RAISE NOTICE '✗ No establishments found - skipping test';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Building submission payload for: %', v_est_name;
  RAISE NOTICE 'Year: %', v_year;
  RAISE NOTICE '';
  
  -- Build payload without change reason
  v_payload := osha_ita_v1.build_complete_submission_payload(v_est_id, v_year);
  
  RAISE NOTICE '========== SUBMISSION PAYLOAD (Initial) ==========';
  RAISE NOTICE '%', jsonb_pretty(v_payload);
  RAISE NOTICE '=================================================';
  RAISE NOTICE '';
  
  -- Build payload with change reason
  v_payload := osha_ita_v1.build_complete_submission_payload(
    v_est_id, 
    v_year, 
    'Correcting data per OSHA inspector feedback'
  );
  
  RAISE NOTICE '========== SUBMISSION PAYLOAD (Resubmission) ==========';
  RAISE NOTICE '%', jsonb_pretty(v_payload);
  RAISE NOTICE '======================================================';
  RAISE NOTICE '';
  RAISE NOTICE '✓ Submission payloads generated successfully';
  
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '✗ Error building submission payload: %', SQLERRM;
END $$;

-- ============================================================================
-- STEP 7: VALIDATE INCIDENTS FOR ITA SUBMISSION
-- ============================================================================
DO $$ 
DECLARE
  v_est_id uuid;
  v_year int := 2024;
  v_rec record;
  v_valid_count int := 0;
  v_invalid_count int := 0;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 7: Validating Incidents for ITA Submission';
  RAISE NOTICE '';
  
  -- Get establishment
  SELECT DISTINCT establishment_id
  INTO v_est_id
  FROM osha_ita_v1.incidents
  WHERE filing_year = v_year
  LIMIT 1;
  
  IF v_est_id IS NULL THEN
    RAISE NOTICE '✗ No incidents for year % found - skipping test', v_year;
    RETURN;
  END IF;
  
  RAISE NOTICE 'Validating incidents for year %', v_year;
  RAISE NOTICE '';
  
  FOR v_rec IN 
    SELECT * FROM osha_ita_v1.get_incidents_ready_for_ita(v_est_id, v_year)
  LOOP
    IF v_rec.is_valid THEN
      v_valid_count := v_valid_count + 1;
      RAISE NOTICE '✓ Case %: VALID', v_rec.case_number;
    ELSE
      v_invalid_count := v_invalid_count + 1;
      RAISE NOTICE '✗ Case %: INVALID', v_rec.case_number;
      RAISE NOTICE '  Errors: %', v_rec.validation_errors;
    END IF;
  END LOOP;
  
  RAISE NOTICE '';
  RAISE NOTICE 'Validation Summary:';
  RAISE NOTICE '  Valid: %', v_valid_count;
  RAISE NOTICE '  Invalid: %', v_invalid_count;
  RAISE NOTICE '';
  
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '✗ Error during validation: %', SQLERRM;
END $$;

-- ============================================================================
-- STEP 8: SIMULATE COMPLETE ITA SUBMISSION WORKFLOW
-- ============================================================================
DO $$ 
DECLARE
  v_est_id uuid;
  v_est_name text;
  v_year int := 2024;
  v_form300a_payload jsonb;
  v_cases_payload jsonb;
  v_submission_payload jsonb;
  v_case_count int;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 8: Complete ITA Submission Workflow Simulation';
  RAISE NOTICE '';
  
  -- Get establishment with complete data
  SELECT DISTINCT i.establishment_id, e.establishment_name
  INTO v_est_id, v_est_name
  FROM osha_ita_v1.incidents i
  JOIN osha_ita_v1.establishments e ON e.establishment_id = i.establishment_id
  JOIN osha_ita_v1.form_300a_summaries s ON s.establishment_id = i.establishment_id 
    AND s.filing_year = i.filing_year AND s.is_current = true
  WHERE i.current_state = 'approved' AND i.filing_year = v_year
  LIMIT 1;
  
  IF v_est_id IS NULL THEN
    RAISE NOTICE '✗ No complete data found for year % - skipping simulation', v_year;
    RETURN;
  END IF;
  
  SELECT COUNT(*) INTO v_case_count
  FROM osha_ita_v1.incidents
  WHERE establishment_id = v_est_id 
    AND filing_year = v_year 
    AND current_state = 'approved';
  
  RAISE NOTICE '========================================';
  RAISE NOTICE 'SIMULATING COMPLETE ITA SUBMISSION';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Establishment: %', v_est_name;
  RAISE NOTICE 'Filing Year: %', v_year;
  RAISE NOTICE 'Approved Cases: %', v_case_count;
  RAISE NOTICE '';
  RAISE NOTICE '----------------------------------------';
  
  -- Step 1: POST Form 300A Data
  RAISE NOTICE '';
  RAISE NOTICE 'STEP 1: POST /oshaApi/v1/forms/form300A';
  RAISE NOTICE '';
  v_form300a_payload := osha_ita_v1.build_form_300a_payload(v_est_id, v_year);
  RAISE NOTICE 'Request Body:';
  RAISE NOTICE '%', jsonb_pretty(v_form300a_payload);
  RAISE NOTICE '';
  RAISE NOTICE '✓ Form 300A would be submitted';
  
  -- Step 2: POST Case Data (if there are cases)
  IF v_case_count > 0 THEN
    RAISE NOTICE '';
    RAISE NOTICE '----------------------------------------';
    RAISE NOTICE 'STEP 2: POST /oshaApi/v1/forms/caseData';
    RAISE NOTICE '';
    v_cases_payload := osha_ita_v1.build_batch_case_data_payload(v_est_id, v_year);
    RAISE NOTICE 'Request Body (% cases):',  jsonb_array_length(v_cases_payload);
    RAISE NOTICE '%', jsonb_pretty(v_cases_payload);
    RAISE NOTICE '';
    RAISE NOTICE '✓ % case data records would be submitted', v_case_count;
  ELSE
    RAISE NOTICE '';
    RAISE NOTICE 'STEP 2: No case data to submit (no injuries/illnesses)';
  END IF;
  
  -- Step 3: POST Complete Submission
  RAISE NOTICE '';
  RAISE NOTICE '----------------------------------------';
  RAISE NOTICE 'STEP 3: POST /oshaApi/v1/submissions';
  RAISE NOTICE '';
  v_submission_payload := osha_ita_v1.build_complete_submission_payload(v_est_id, v_year);
  RAISE NOTICE 'Request Body:';
  RAISE NOTICE '%', jsonb_pretty(v_submission_payload);
  RAISE NOTICE '';
  RAISE NOTICE '✓ Submission would be completed';
  
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'SIMULATION COMPLETE';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Summary:';
  RAISE NOTICE '  ✓ Form 300A payload generated';
  IF v_case_count > 0 THEN
    RAISE NOTICE '  ✓ % case data payloads generated', v_case_count;
  ELSE
    RAISE NOTICE '  ✓ No case data (establishment had no recordable incidents)';
  END IF;
  RAISE NOTICE '  ✓ Complete submission payload generated';
  RAISE NOTICE '';
  RAISE NOTICE 'All payloads are ready for ITA API submission!';
  RAISE NOTICE '';
  
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE '✗ Error during workflow simulation: %', SQLERRM;
END $$;

-- ============================================================================
-- STEP 9: EXPORT SAMPLE PAYLOADS TO INSPECT
-- ============================================================================
DO $$ 
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 9: Sample Payloads for API Testing';
  RAISE NOTICE '';
  RAISE NOTICE 'The following queries can be used to extract payloads for API testing:';
  RAISE NOTICE '';
END $$;

-- Form 300A payload query
\echo '-- Get Form 300A payload:'
\echo 'SELECT jsonb_pretty(osha_ita_v1.build_form_300a_payload(establishment_id, filing_year))'
\echo 'FROM osha_ita_v1.form_300a_summaries'
\echo 'WHERE is_current = true LIMIT 1;'
\echo ''

-- Case data payload query  
\echo '-- Get single case data payload:'
\echo 'SELECT jsonb_pretty(osha_ita_v1.build_case_data_payload(incident_id))'
\echo 'FROM osha_ita_v1.incidents'
\echo 'WHERE current_state = '\''approved'\'' LIMIT 1;'
\echo ''

-- Batch case data payload query
\echo '-- Get batch case data payload:'
\echo 'SELECT jsonb_pretty(osha_ita_v1.build_batch_case_data_payload(establishment_id, 2024))'
\echo 'FROM osha_ita_v1.establishments LIMIT 1;'
\echo ''

-- Complete submission payload query
\echo '-- Get complete submission payload:'
\echo 'SELECT jsonb_pretty(osha_ita_v1.build_complete_submission_payload(establishment_id, 2024))'
\echo 'FROM osha_ita_v1.establishments LIMIT 1;'
\echo ''

-- ============================================================================
-- FINAL SUMMARY
-- ============================================================================
DO $$ 
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '  PAYLOAD SIMULATION COMPLETE';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE 'All payload generation functions tested!';
  RAISE NOTICE '';
  RAISE NOTICE 'Next Steps:';
  RAISE NOTICE '  1. Review the generated payloads above';
  RAISE NOTICE '  2. Use the sample queries to extract payloads';
  RAISE NOTICE '  3. Test the payloads with OSHA ITA API';
  RAISE NOTICE '  4. Update your ita_submissions table with responses';
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
END $$;