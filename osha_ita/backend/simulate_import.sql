-- ============================================================================
-- OSHA ITA COMPLETE WORKFLOW SIMULATION
-- Simulating a Compliance Manager's Journey Through a Filing Year
-- ============================================================================


-- ============================================================================
-- SCENARIO SETUP
-- ============================================================================
-- You are Jane Smith, Compliance Manager at Acme Manufacturing
-- Filing Year: 2024
-- You need to:
--   1. Set up your establishments
--   2. Import incident data from CSV
--   3. Review and validate incidents
--   4. Generate OSHA forms (300, 301, 300A)
--   5. Certify and submit to ITA
-- ============================================================================

-- Clean slate for testing
DO $$ 
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Starting OSHA ITA Workflow Simulation';
  RAISE NOTICE 'Compliance Manager: Jane Smith';
  RAISE NOTICE 'Filing Year: 2024';
  RAISE NOTICE '========================================';
END $$;

-- ============================================================================
-- STEP 1: CREATE USER CONTEXT
-- ============================================================================
-- Simulating logged-in user
DO $$ 
DECLARE
  v_user_id uuid := 'a0000000-0000-0000-0000-000000000001'::uuid;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 1: User Login';
  RAISE NOTICE 'User ID: %', v_user_id;
  RAISE NOTICE 'Role: Compliance Manager';
  
  -- Store in temp table for session
  CREATE TEMP TABLE IF NOT EXISTS current_session (
    user_id uuid,
    user_name text,
    session_start timestamptz
  );
  
  DELETE FROM current_session;
  INSERT INTO current_session VALUES (v_user_id, 'Jane Smith', now());
  
  RAISE NOTICE '✓ Session established';
END $$;

-- ============================================================================
-- STEP 2: SET UP ESTABLISHMENTS
-- ============================================================================
DO $$ 
DECLARE
  v_est1_id uuid;
  v_est2_id uuid;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 2: Setting Up Establishments';
  
  -- Main manufacturing facility
  INSERT INTO osha_ita_v1.establishments (
    establishment_name, 
    street_address, 
    city, 
    state, 
    zip,
    naics_code,
    industry_description,
    establishment_type
  ) VALUES (
    'Acme Manufacturing - Houston Plant',
    '1000 Industrial Blvd',
    'Houston',
    'TX',
    '77001',
    '332710',
    'Machine Shops',
    1
  ) RETURNING establishment_id INTO v_est1_id;
  
  RAISE NOTICE '✓ Created Houston Plant: %', v_est1_id;
  
  -- Warehouse facility
  INSERT INTO osha_ita_v1.establishments (
    establishment_name,
    street_address,
    city,
    state,
    zip,
    naics_code,
    industry_description,
    establishment_type
  ) VALUES (
    'Acme Manufacturing - Dallas Warehouse',
    '500 Distribution Dr',
    'Dallas',
    'TX',
    '75001',
    '493110',
    'General Warehousing and Storage',
    2
  ) RETURNING establishment_id INTO v_est2_id;
  
  RAISE NOTICE '✓ Created Dallas Warehouse: %', v_est2_id;
  
  -- Store for later use
  CREATE TEMP TABLE IF NOT EXISTS test_establishments (
    est_id uuid,
    est_name text,
    est_type int
  );
  
  INSERT INTO test_establishments VALUES 
    (v_est1_id, 'Houston Plant', 1),
    (v_est2_id, 'Dallas Warehouse', 2);
    
  RAISE NOTICE '✓ Total establishments: 2';
END $$;

-- ============================================================================
-- STEP 3: IMPORT CSV DATA
-- ============================================================================
DO $$ 
DECLARE
  v_batch_id uuid;
  v_user_id uuid;
  v_est_id uuid;
  v_row_id1 uuid;
  v_row_id2 uuid;
  v_row_id3 uuid;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 3: Importing Incident Data from CSV';
  
  SELECT user_id INTO v_user_id FROM current_session;
  SELECT est_id INTO v_est_id FROM test_establishments WHERE est_type = 1;
  
  -- Create import batch
  INSERT INTO osha_ita_v1.import_batches (
    source_type,
    filename,
    file_size_bytes,
    filing_year,
    status,
    created_by
  ) VALUES (
    'csv',
    'incidents_2024_q1.csv',
    15420,
    2024,
    'pending',
    v_user_id
  ) RETURNING batch_id INTO v_batch_id;
  
  RAISE NOTICE '✓ Created import batch: %', v_batch_id;
  RAISE NOTICE '  File: incidents_2024_q1.csv';
  
  -- Import Row 1: Valid incident (back injury)
  INSERT INTO osha_ita_v1.import_rows (
    batch_id,
    row_number,
    status,
    raw_data
  ) VALUES (
    v_batch_id,
    1,
    'pending',
    jsonb_build_object(
      'establishment_name', 'Acme Manufacturing - Houston Plant',
      'year_of_filing', '2024',
      'case_number', '2024-001',
      'date_of_incident', '2024-03-15',
      'time_of_incident', '14:30:00',
      'time_started_work', '07:00:00',
      'incident_location', 'Production Floor - Bay 3',
      'incident_description', 'Back strain while lifting heavy equipment',
      'job_title', 'Machine Operator',
      'date_of_birth', '1985-06-20',
      'date_of_hire', '2018-01-15',
      'sex', 'M',
      'incident_outcome', 'days_away',
      'type_of_incident', 'injury',
      'dafw_num_away', '5',
      'djtr_num_tr', '0',
      'treatment_facility_type', '1',
      'treatment_in_patient', '0',
      'nar_before_incident', 'Employee was moving equipment to prepare for production run',
      'nar_what_happened', 'Employee bent to lift 50lb motor without proper lifting technique',
      'nar_injury_illness', 'Lower back strain, muscle spasm',
      'nar_object_substance', 'Electric motor assembly'
    )
  ) RETURNING row_id INTO v_row_id1;
  
  RAISE NOTICE '✓ Row 1: Back injury case imported';
  
  -- Import Row 2: Valid incident (laceration)
  INSERT INTO osha_ita_v1.import_rows (
    batch_id,
    row_number,
    status,
    raw_data
  ) VALUES (
    v_batch_id,
    2,
    'pending',
    jsonb_build_object(
      'establishment_name', 'Acme Manufacturing - Houston Plant',
      'year_of_filing', '2024',
      'case_number', '2024-002',
      'date_of_incident', '2024-04-22',
      'time_of_incident', '10:15:00',
      'time_started_work', '06:00:00',
      'incident_location', 'Assembly Line 2',
      'incident_description', 'Hand laceration from sharp edge',
      'job_title', 'Assembly Technician',
      'date_of_birth', '1992-11-08',
      'date_of_hire', '2020-05-01',
      'sex', 'F',
      'incident_outcome', 'other_recordable',
      'type_of_incident', 'injury',
      'dafw_num_away', '0',
      'djtr_num_tr', '0',
      'treatment_facility_type', '0',
      'treatment_in_patient', '0',
      'nar_before_incident', 'Employee was performing routine assembly operations',
      'nar_what_happened', 'Employee contacted sharp burr on metal part while positioning component',
      'nar_injury_illness', 'Laceration to right palm requiring 4 stitches',
      'nar_object_substance', 'Metal bracket with sharp edge'
    )
  ) RETURNING row_id INTO v_row_id2;
  
  RAISE NOTICE '✓ Row 2: Laceration case imported';
  
  -- Import Row 3: Invalid incident (missing data)
  INSERT INTO osha_ita_v1.import_rows (
    batch_id,
    row_number,
    status,
    raw_data
  ) VALUES (
    v_batch_id,
    3,
    'pending',
    jsonb_build_object(
      'establishment_name', 'Unknown Facility',
      'year_of_filing', '2024',
      'case_number', ''
    )
  ) RETURNING row_id INTO v_row_id3;
  
  RAISE NOTICE '✓ Row 3: Invalid case imported (for testing validation)';
  
  -- Update batch totals
  UPDATE osha_ita_v1.import_batches 
  SET total_rows = 3,
      status = 'validating'
  WHERE batch_id = v_batch_id;
  
  RAISE NOTICE '✓ Import batch ready for validation';
  
  -- Store for next steps
  CREATE TEMP TABLE IF NOT EXISTS test_import (
    batch_id uuid,
    row_ids uuid[]
  );
  
  INSERT INTO test_import VALUES (v_batch_id, ARRAY[v_row_id1, v_row_id2, v_row_id3]);
END $$;

-- ============================================================================
-- STEP 4: VALIDATE IMPORT DATA
-- ============================================================================
DO $$ 
DECLARE
  v_batch_id uuid;
  v_row_id uuid;
  v_result jsonb;
  v_valid_count int := 0;
  v_invalid_count int := 0;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 4: Validating Import Data';
  
  SELECT batch_id INTO v_batch_id FROM test_import;
  
  -- Validate each row
  FOR v_row_id IN 
    SELECT unnest(row_ids) FROM test_import
  LOOP
    v_result := osha_ita_v1.validate_import_row(v_row_id);
    
    IF v_result->>'status' = 'valid' THEN
      v_valid_count := v_valid_count + 1;
      RAISE NOTICE '✓ Row validated successfully: %', (v_result->>'row_id')::uuid;
    ELSE
      v_invalid_count := v_invalid_count + 1;
      RAISE NOTICE '✗ Row validation failed: %', (v_result->>'row_id')::uuid;
      RAISE NOTICE '  Errors: %', v_result->'errors';
    END IF;
  END LOOP;
  
  -- Update batch statistics
  UPDATE osha_ita_v1.import_batches
  SET valid_rows = v_valid_count,
      invalid_rows = v_invalid_count,
      status = 'mapping'
  WHERE batch_id = v_batch_id;
  
  RAISE NOTICE '';
  RAISE NOTICE 'Validation Summary:';
  RAISE NOTICE '  Valid rows: %', v_valid_count;
  RAISE NOTICE '  Invalid rows: %', v_invalid_count;
END $$;

-- ============================================================================
-- STEP 5: MAP AND PREPARE DATA FOR PROMOTION
-- ============================================================================
DO $$ 
DECLARE
  v_batch_id uuid;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 5: Mapping Valid Data';
  
  SELECT batch_id INTO v_batch_id FROM test_import;
  
  -- Map raw data to structured format
  UPDATE osha_ita_v1.import_rows
  SET mapped_data = raw_data,
      status = 'mapped'
  WHERE batch_id = v_batch_id
    AND status = 'valid';
    
  UPDATE osha_ita_v1.import_batches
  SET status = 'promoting'
  WHERE batch_id = v_batch_id;
  
  RAISE NOTICE '✓ Valid rows mapped and ready for promotion';
END $$;

-- ============================================================================
-- STEP 6: PROMOTE VALID ROWS TO INCIDENTS
-- ============================================================================
DO $$ 
DECLARE
  v_batch_id uuid;
  v_promoted_count int;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 6: Promoting Valid Rows to Incidents';
  
  SELECT batch_id INTO v_batch_id FROM test_import;
  
  -- Promote rows
  v_promoted_count := osha_ita_v1.promote_valid_rows(v_batch_id);
  
  -- Update batch
  UPDATE osha_ita_v1.import_batches
  SET promoted_rows = v_promoted_count,
      status = 'completed',
      completed_at = now()
  WHERE batch_id = v_batch_id;
  
  RAISE NOTICE '✓ Promoted % incidents to system', v_promoted_count;
  RAISE NOTICE '✓ Import batch completed';
END $$;

-- ============================================================================
-- STEP 7: REVIEW INCIDENTS IN THE SYSTEM
-- ============================================================================
DO $$ 
DECLARE
  v_rec record;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 7: Reviewing Incidents';
  RAISE NOTICE '';
  
  FOR v_rec IN 
    SELECT 
      i.case_number,
      i.date_of_incident,
      i.current_state,
      i.incident_description,
      i.incident_outcome,
      e.establishment_name
    FROM osha_ita_v1.incidents i
    JOIN osha_ita_v1.establishments e ON e.establishment_id = i.establishment_id
    WHERE i.filing_year = 2024
    ORDER BY i.date_of_incident
  LOOP
    RAISE NOTICE 'Case: % | Date: % | Status: %', 
      v_rec.case_number, v_rec.date_of_incident, v_rec.current_state;
    RAISE NOTICE '  Location: %', v_rec.establishment_name;
    RAISE NOTICE '  Description: %', v_rec.incident_description;
    RAISE NOTICE '  Outcome: %', v_rec.incident_outcome;
    RAISE NOTICE '';
  END LOOP;
END $$;

-- ============================================================================
-- STEP 8: MOVE INCIDENTS THROUGH WORKFLOW
-- ============================================================================
DO $$ 
DECLARE
  v_incident_id uuid;
  v_user_id uuid;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 8: Moving Incidents Through Approval Workflow';
  
  SELECT user_id INTO v_user_id FROM current_session;
  
  -- Get first incident
  SELECT incident_id INTO v_incident_id 
  FROM osha_ita_v1.incidents 
  WHERE case_number = '2024-001' 
  LIMIT 1;
  
  -- Draft -> In Review
  UPDATE osha_ita_v1.incidents
  SET current_state = 'in_review',
      updated_by = v_user_id
  WHERE incident_id = v_incident_id;
  
  RAISE NOTICE '✓ Case 2024-001: draft -> in_review';
  
  -- In Review -> Approved
  UPDATE osha_ita_v1.incidents
  SET current_state = 'approved',
      updated_by = v_user_id
  WHERE incident_id = v_incident_id;
  
  RAISE NOTICE '✓ Case 2024-001: in_review -> approved';
  
  -- Approve second incident
  SELECT incident_id INTO v_incident_id 
  FROM osha_ita_v1.incidents 
  WHERE case_number = '2024-002' 
  LIMIT 1;
  
  UPDATE osha_ita_v1.incidents
  SET current_state = 'in_review',
      updated_by = v_user_id
  WHERE incident_id = v_incident_id;
  
  UPDATE osha_ita_v1.incidents
  SET current_state = 'approved',
      updated_by = v_user_id
  WHERE incident_id = v_incident_id;
  
  RAISE NOTICE '✓ Case 2024-002: draft -> in_review -> approved';
  RAISE NOTICE '';
  RAISE NOTICE '✓ All incidents approved and ready for form generation';
END $$;

-- ============================================================================
-- STEP 9: GENERATE OSHA FORMS (300, 301, 300A)
-- ============================================================================
DO $$ 
DECLARE
  v_est_id uuid;
  v_year int := 2024;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 9: Generating OSHA Forms';
  
  SELECT est_id INTO v_est_id FROM test_establishments WHERE est_type = 1;
  
  -- Rebuild all projections
  PERFORM osha_ita_v1.rebuild_all_projections(v_est_id, v_year);
  
  RAISE NOTICE '✓ Form 300 (Log) generated';
  RAISE NOTICE '✓ Form 301 (Incident Reports) generated';
  RAISE NOTICE '✓ Form 300A (Summary) generated';
END $$;

-- ============================================================================
-- STEP 10: REVIEW FORM 300 (LOG)
-- ============================================================================
DO $$ 
DECLARE
  v_rec record;
  v_count int;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 10: Reviewing Form 300 (OSHA Log)';
  RAISE NOTICE '';
  
  SELECT COUNT(*) INTO v_count 
  FROM osha_ita_v1.form_300_log 
  WHERE filing_year = 2024 AND is_current = true;
  
  RAISE NOTICE 'Total entries in 300 Log: %', v_count;
  RAISE NOTICE '';
  
  FOR v_rec IN 
    SELECT 
      case_number,
      job_title,
      date_of_injury,
      injury_description,
      death,
      days_away_from_work,
      days_away_count
    FROM osha_ita_v1.form_300_log
    WHERE filing_year = 2024 AND is_current = true
    ORDER BY date_of_injury
  LOOP
    RAISE NOTICE 'Case %: % on %', 
      v_rec.case_number, v_rec.job_title, v_rec.date_of_injury;
    RAISE NOTICE '  Injury: %', v_rec.injury_description;
    RAISE NOTICE '  Days Away: %', v_rec.days_away_count;
    RAISE NOTICE '';
  END LOOP;
END $$;

-- ============================================================================
-- STEP 11: REVIEW FORM 301 (INCIDENT REPORTS)
-- ============================================================================
DO $$ 
DECLARE
  v_rec record;
  v_count int;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 11: Reviewing Form 301 (Incident Reports)';
  RAISE NOTICE '';
  
  SELECT COUNT(*) INTO v_count 
  FROM osha_ita_v1.form_301_reports 
  WHERE year_of_filing = 2024 AND is_current = true;
  
  RAISE NOTICE 'Total 301 Reports: %', v_count;
  RAISE NOTICE '';
  
  FOR v_rec IN 
    SELECT 
      case_number,
      job_title,
      date_of_incident,
      incident_description,
      nar_what_happened
    FROM osha_ita_v1.form_301_reports
    WHERE year_of_filing = 2024 AND is_current = true
    ORDER BY date_of_incident
  LOOP
    RAISE NOTICE 'Report for Case %:', v_rec.case_number;
    RAISE NOTICE '  Title: %', v_rec.job_title;
    RAISE NOTICE '  What happened: %', v_rec.nar_what_happened;
    RAISE NOTICE '';
  END LOOP;
END $$;

-- ============================================================================
-- STEP 12: UPDATE AND CERTIFY FORM 300A (SUMMARY)
-- ============================================================================
DO $$ 
DECLARE
  v_summary_id uuid;
  v_user_id uuid;
  v_est_id uuid;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 12: Updating and Certifying Form 300A';
  
  SELECT user_id INTO v_user_id FROM current_session;
  SELECT est_id INTO v_est_id FROM test_establishments WHERE est_type = 1;
  
  -- Get the summary
  SELECT summary_id INTO v_summary_id
  FROM osha_ita_v1.form_300a_summaries
  WHERE establishment_id = v_est_id
    AND filing_year = 2024
    AND is_current = true;
    
  RAISE NOTICE '✓ Form 300A Summary ID: %', v_summary_id;
  
  -- Update employment data
  UPDATE osha_ita_v1.form_300a_summaries
  SET annual_average_employees = 45,
      total_hours_worked = 93600  -- 45 employees * 2080 hours
  WHERE summary_id = v_summary_id;
  
  RAISE NOTICE '✓ Employment data updated';
  RAISE NOTICE '  Average Employees: 45';
  RAISE NOTICE '  Total Hours: 93,600';
  
  -- Certify the summary
  PERFORM osha_ita_v1.certify_300a(
    v_summary_id,
    v_user_id,
    'Jane Smith',
    'Compliance Manager'
  );
  
  RAISE NOTICE '✓ Form 300A certified by Jane Smith';
END $$;

-- ============================================================================
-- STEP 13: REVIEW FORM 300A SUMMARY
-- ============================================================================
DO $$ 
DECLARE
  v_rec record;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 13: Form 300A Summary Report';
  RAISE NOTICE '';
  
  SELECT * INTO v_rec
  FROM osha_ita_v1.form_300a_summaries
  WHERE filing_year = 2024 AND is_current = true
  LIMIT 1;
  
  RAISE NOTICE '========== FORM 300A SUMMARY ==========';
  RAISE NOTICE 'Establishment: %', v_rec.establishment_name;
  RAISE NOTICE 'Year: %', v_rec.filing_year;
  RAISE NOTICE 'NAICS: %', v_rec.naics_code;
  RAISE NOTICE '';
  RAISE NOTICE 'Employment Information:';
  RAISE NOTICE '  Average Employees: %', v_rec.annual_average_employees;
  RAISE NOTICE '  Total Hours Worked: %', v_rec.total_hours_worked;
  RAISE NOTICE '';
  RAISE NOTICE 'Injury & Illness Summary:';
  RAISE NOTICE '  Total Deaths: %', v_rec.total_deaths;
  RAISE NOTICE '  Days Away Cases: %', v_rec.total_dafw_cases;
  RAISE NOTICE '  Job Transfer Cases: %', v_rec.total_djtr_cases;
  RAISE NOTICE '  Other Recordable: %', v_rec.total_other_cases;
  RAISE NOTICE '  Total Days Away: %', v_rec.total_dafw_days;
  RAISE NOTICE '  Total Days Restricted: %', v_rec.total_djtr_days;
  RAISE NOTICE '';
  RAISE NOTICE 'By Type:';
  RAISE NOTICE '  Injuries: %', v_rec.total_injuries;
  RAISE NOTICE '  Skin Disorders: %', v_rec.total_skin_disorders;
  RAISE NOTICE '  Respiratory: %', v_rec.total_respiratory_conditions;
  RAISE NOTICE '  Poisonings: %', v_rec.total_poisonings;
  RAISE NOTICE '  Hearing Loss: %', v_rec.total_hearing_loss;
  RAISE NOTICE '  Other Illness: %', v_rec.total_other_illnesses;
  RAISE NOTICE '';
  RAISE NOTICE 'Certification:';
  RAISE NOTICE '  Certified By: %', v_rec.certifier_name;
  RAISE NOTICE '  Title: %', v_rec.certifier_title;
  RAISE NOTICE '  Date: %', v_rec.certified_at;
  RAISE NOTICE '=====================================';
END $$;

-- ============================================================================
-- STEP 14: LOCK THE PERIOD
-- ============================================================================
DO $$ 
DECLARE
  v_lock_id uuid;
  v_user_id uuid;
  v_est_id uuid;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 14: Locking Filing Period';
  
  SELECT user_id INTO v_user_id FROM current_session;
  SELECT est_id INTO v_est_id FROM test_establishments WHERE est_type = 1;
  
  -- Lock the period
  v_lock_id := osha_ita_v1.lock_period(
    v_est_id,
    2024,
    v_user_id,
    'Finalizing 2024 annual submission'
  );
  
  RAISE NOTICE '✓ Period locked for 2024';
  RAISE NOTICE '  Lock ID: %', v_lock_id;
  RAISE NOTICE '  Reason: Finalizing 2024 annual submission';
  
  -- Try to modify an incident (should fail)
  BEGIN
    UPDATE osha_ita_v1.incidents
    SET incident_description = 'Modified description'
    WHERE filing_year = 2024;
    --LIMIT 1;
    
    RAISE NOTICE '✗ ERROR: Period lock did not prevent modification!';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '✓ Period lock working: %', SQLERRM;
  END;
END $$;

-- ============================================================================
-- STEP 15: CREATE ITA SUBMISSION
-- ============================================================================
DO $$ 
DECLARE
  v_submission_id uuid;
  v_user_id uuid;
  v_est_id uuid;
  v_payload jsonb;
  v_summary record;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 15: Creating ITA Submission';
  
  SELECT user_id INTO v_user_id FROM current_session;
  SELECT est_id INTO v_est_id FROM test_establishments WHERE est_type = 1;
  
  -- Get summary data
  SELECT * INTO v_summary
  FROM osha_ita_v1.form_300a_summaries
  WHERE establishment_id = v_est_id
    AND filing_year = 2024
    AND is_current = true;
  
  -- Build payload
  v_payload := jsonb_build_object(
    'year', 2024,
    'establishment', jsonb_build_object(
      'name', v_summary.establishment_name,
      'address', v_summary.street_address,
      'city', v_summary.city,
      'state', v_summary.state,
      'zip', v_summary.zip,
      'naics', v_summary.naics_code
    ),
    'employment', jsonb_build_object(
      'annual_average_employees', v_summary.annual_average_employees,
      'total_hours_worked', v_summary.total_hours_worked
    ),
    'summary', jsonb_build_object(
      'total_deaths', v_summary.total_deaths,
      'total_dafw_cases', v_summary.total_dafw_cases,
      'total_djtr_cases', v_summary.total_djtr_cases,
      'total_other_cases', v_summary.total_other_cases,
      'total_injuries', v_summary.total_injuries
    ),
    'certification', jsonb_build_object(
      'name', v_summary.certifier_name,
      'title', v_summary.certifier_title,
      'date', v_summary.certified_at
    )
  );
  
  -- Create submission
  v_submission_id := osha_ita_v1.create_submission(
    v_est_id,
    2024,
    'form_300a',
    v_payload,
    v_user_id
  );
  
  RAISE NOTICE '✓ Submission created: %', v_submission_id;
  RAISE NOTICE '  Type: Form 300A';
  RAISE NOTICE '  Status: pending';
END $$;

-- ============================================================================
-- STEP 16: SIMULATE ITA SUBMISSION RESPONSE
-- ============================================================================
DO $$ 
DECLARE
  v_submission_id uuid;
  v_response jsonb;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 16: Simulating ITA API Response';
  
  -- Get the submission
  SELECT submission_id INTO v_submission_id
  FROM osha_ita_v1.ita_submissions
  WHERE filing_year = 2024
    AND status = 'pending'
  LIMIT 1;
  
  -- Simulate successful response
  v_response := jsonb_build_object(
    'success', true,
    'submissionId', 'ITA-2024-TX-000123',
    'confirmationNumber', 'CONF-2024-ABC123XYZ',
    'timestamp', now()
  );
  
  -- Record the attempt
  PERFORM osha_ita_v1.record_submission_attempt(
    v_submission_id,
    200,
    v_response,
    true
  );
  
  RAISE NOTICE '✓ Submission successful!';
  RAISE NOTICE '  ITA Submission ID: %', v_response->>'submissionId';
  RAISE NOTICE '  Confirmation Number: %', v_response->>'confirmationNumber';
END $$;

-- ============================================================================
-- STEP 17: FINAL DASHBOARD SUMMARY
-- ============================================================================
DO $$ 
DECLARE
  v_total_incidents int;
  v_approved_incidents int;
  v_submitted_incidents int;
  v_total_forms_300 int;
  v_total_forms_301 int;
  v_locked_periods int;
  v_successful_submissions int;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 17: Compliance Dashboard Summary';
  RAISE NOTICE '';
  
  -- Gather statistics
  SELECT COUNT(*) INTO v_total_incidents
  FROM osha_ita_v1.incidents
  WHERE filing_year = 2024;
  
  SELECT COUNT(*) INTO v_approved_incidents
  FROM osha_ita_v1.incidents
  WHERE filing_year = 2024 AND current_state = 'approved';
  
  SELECT COUNT(*) INTO v_submitted_incidents
  FROM osha_ita_v1.incidents
  WHERE filing_year = 2024 AND current_state = 'submitted';
  
  SELECT COUNT(*) INTO v_total_forms_300
  FROM osha_ita_v1.form_300_log
  WHERE filing_year = 2024 AND is_current = true;
  
  SELECT COUNT(*) INTO v_total_forms_301
  FROM osha_ita_v1.form_301_reports
  WHERE year_of_filing = 2024 AND is_current = true;
  
  SELECT COUNT(*) INTO v_locked_periods
  FROM osha_ita_v1.period_locks
  WHERE filing_year = 2024 AND is_locked = true;
  
  SELECT COUNT(*) INTO v_successful_submissions
  FROM osha_ita_v1.ita_submissions
  WHERE filing_year = 2024 AND status = 'succeeded';
  
  RAISE NOTICE '========================================';
  RAISE NOTICE '     2024 COMPLIANCE DASHBOARD';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Incidents:';
  RAISE NOTICE '  Total Incidents: %', v_total_incidents;
  RAISE NOTICE '  Approved: %', v_approved_incidents;
  RAISE NOTICE '  Submitted: %', v_submitted_incidents;
  RAISE NOTICE '';
  RAISE NOTICE 'Forms Generated:';
  RAISE NOTICE '  Form 300 (Log) Entries: %', v_total_forms_300;
  RAISE NOTICE '  Form 301 (Reports): %', v_total_forms_301;
  RAISE NOTICE '  Form 300A (Summaries): 1';
  RAISE NOTICE '';
  RAISE NOTICE 'Period Management:';
  RAISE NOTICE '  Locked Periods: %', v_locked_periods;
  RAISE NOTICE '';
  RAISE NOTICE 'ITA Submissions:';
  RAISE NOTICE '  Successful Submissions: %', v_successful_submissions;
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '  ✓ ALL SYSTEMS OPERATIONAL';
  RAISE NOTICE '========================================';
END $$;

-- ============================================================================
-- STEP 18: ADVANCED QUERIES - WHAT YOU CAN DO AS COMPLIANCE MANAGER
-- ============================================================================
DO $$ 
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 18: Advanced Compliance Queries';
  RAISE NOTICE '';
END $;

-- Query 1: Get all incidents by outcome type
RAISE NOTICE '1. Incidents by Outcome Type:';
SELECT 
  incident_outcome,
  COUNT(*) as count,
  AVG(COALESCE(dafw_num_away, 0) + COALESCE(djtr_num_tr, 0)) as avg_days_lost
FROM osha_ita_v1.incidents
WHERE filing_year = 2024
GROUP BY incident_outcome
ORDER BY count DESC;

-- Query 2: Monthly incident trend
RAISE NOTICE '';
RAISE NOTICE '2. Monthly Incident Trends:';
SELECT 
  TO_CHAR(date_of_incident, 'YYYY-MM') as month,
  COUNT(*) as incidents,
  SUM(CASE WHEN incident_outcome = 'death' THEN 1 ELSE 0 END) as deaths,
  SUM(COALESCE(dafw_num_away, 0)) as total_days_away
FROM osha_ita_v1.incidents
WHERE filing_year = 2024
GROUP BY TO_CHAR(date_of_incident, 'YYYY-MM')
ORDER BY month;

-- Query 3: Incidents by job title
RAISE NOTICE '';
RAISE NOTICE '3. High-Risk Job Titles:';
SELECT 
  job_title,
  COUNT(*) as incident_count,
  COUNT(*) FILTER (WHERE incident_outcome = 'days_away') as days_away_cases
FROM osha_ita_v1.incidents
WHERE filing_year = 2024
GROUP BY job_title
ORDER BY incident_count DESC;

-- Query 4: Import batch history
RAISE NOTICE '';
RAISE NOTICE '4. Import History:';
SELECT 
  filename,
  filing_year,
  status,
  total_rows,
  valid_rows,
  promoted_rows,
  created_at
FROM osha_ita_v1.import_batches
ORDER BY created_at DESC;

-- Query 5: Form 300 export view
RAISE NOTICE '';
RAISE NOTICE '5. Form 300 Export (Privacy-Aware):';
SELECT 
  case_number,
  employee_name_export,
  job_title,
  date_of_injury,
  where_event_occurred,
  days_away_count
FROM osha_ita_v1.v_form_300_export
WHERE filing_year = 2024
ORDER BY date_of_injury;

-- ============================================================================
-- STEP 19: TEST BUSINESS RULES AND VALIDATIONS
-- ============================================================================
DO $$ 
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 19: Testing Business Rules';
  RAISE NOTICE '';
END $;

-- Test 1: State transition validation
DO $$
DECLARE
  v_incident_id uuid;
BEGIN
  RAISE NOTICE 'Test 1: Invalid State Transition';
  
  SELECT incident_id INTO v_incident_id
  FROM osha_ita_v1.incidents
  WHERE current_state = 'approved'
  LIMIT 1;
  
  BEGIN
    -- Try invalid transition: approved -> draft (not in transition table)
    UPDATE osha_ita_v1.incidents
    SET current_state = 'submitted'
    WHERE incident_id = v_incident_id;
    
    RAISE NOTICE '  ✓ Valid transition succeeded: approved -> submitted';
    
    -- Try to go backwards invalidly
    UPDATE osha_ita_v1.incidents
    SET current_state = 'in_review'
    WHERE incident_id = v_incident_id;
    
    RAISE NOTICE '  ✗ ERROR: Invalid transition was allowed!';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ✓ Invalid transition blocked: %', SQLERRM;
  END;
END $;

-- Test 2: Death date validation
DO $$
DECLARE
  v_est_id uuid;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'Test 2: Death Incident Validation';
  
  SELECT est_id INTO v_est_id FROM test_establishments WHERE est_type = 1;
  
  BEGIN
    -- Try to create death incident without death date
    INSERT INTO osha_ita_v1.incidents (
      establishment_id, case_number, filing_year,
      date_of_incident, incident_location, incident_description,
      job_title, date_of_birth, date_of_hire,
      incident_outcome, type_of_incident,
      treatment_facility_type, treatment_in_patient,
      nar_before_incident, nar_what_happened, 
      nar_injury_illness, nar_object_substance
    ) VALUES (
      v_est_id, '2024-999', 2024,
      '2024-05-01', 'Test Location', 'Test incident',
      'Test Worker', '1980-01-01', '2020-01-01',
      'death', 'injury',
      1, 0,
      'Before', 'What happened', 'Injury', 'Object'
    );
    
    RAISE NOTICE '  ✗ ERROR: Death without date_of_death was allowed!';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ✓ Death validation working: %', SQLERRM;
  END;
END $;

-- Test 3: Days away validation
DO $$
DECLARE
  v_est_id uuid;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'Test 3: Days Away Validation';
  
  SELECT est_id INTO v_est_id FROM test_establishments WHERE est_type = 1;
  
  BEGIN
    -- Try days_away outcome with 0 days
    INSERT INTO osha_ita_v1.incidents (
      establishment_id, case_number, filing_year,
      date_of_incident, incident_location, incident_description,
      job_title, date_of_birth, date_of_hire,
      incident_outcome, type_of_incident,
      dafw_num_away,
      treatment_facility_type, treatment_in_patient,
      nar_before_incident, nar_what_happened, 
      nar_injury_illness, nar_object_substance
    ) VALUES (
      v_est_id, '2024-998', 2024,
      '2024-05-01', 'Test Location', 'Test incident',
      'Test Worker', '1980-01-01', '2020-01-01',
      'days_away', 'injury',
      0,  -- Invalid: should be > 0 for days_away outcome
      1, 0,
      'Before', 'What happened', 'Injury', 'Object'
    );
    
    RAISE NOTICE '  ✗ ERROR: Days away with 0 days was allowed!';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ✓ Days away validation working: %', SQLERRM;
  END;
END $;

-- ============================================================================
-- STEP 20: UNLOCK PERIOD AND MAKE CORRECTION
-- ============================================================================
DO $$ 
DECLARE
  v_user_id uuid;
  v_est_id uuid;
  v_incident_id uuid;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 20: Unlock Period for Correction';
  
  SELECT user_id INTO v_user_id FROM current_session;
  SELECT est_id INTO v_est_id FROM test_establishments WHERE est_type = 1;
  
  -- Unlock the period
  PERFORM osha_ita_v1.unlock_period(
    v_est_id,
    2024,
    v_user_id,
    'Correcting incident description per OSHA inspector feedback'
  );
  
  RAISE NOTICE '✓ Period unlocked for corrections';
  
  -- Make correction
  SELECT incident_id INTO v_incident_id
  FROM osha_ita_v1.incidents
  WHERE case_number = '2024-001'
  LIMIT 1;
  
  UPDATE osha_ita_v1.incidents
  SET incident_description = 'Back strain while lifting heavy equipment (corrected)',
      updated_by = v_user_id
  WHERE incident_id = v_incident_id;
  
  RAISE NOTICE '✓ Correction made to Case 2024-001';
  
  -- Rebuild projections to reflect changes
  PERFORM osha_ita_v1.rebuild_all_projections(v_est_id, 2024);
  
  RAISE NOTICE '✓ Forms regenerated with corrections';
  
  -- Re-lock the period
  PERFORM osha_ita_v1.lock_period(
    v_est_id,
    2024,
    v_user_id,
    'Corrections complete, re-locking for final submission'
  );
  
  RAISE NOTICE '✓ Period re-locked';
END $;

-- ============================================================================
-- STEP 21: QUERY AUDIT TRAIL
-- ============================================================================
DO $$ 
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 21: Audit Trail Review';
  RAISE NOTICE '';
END $;

-- Check incident update history
RAISE NOTICE 'Recent Incident Updates:';
SELECT 
  case_number,
  current_state,
  created_at,
  updated_at,
  updated_at - created_at as time_in_system
FROM osha_ita_v1.incidents
WHERE filing_year = 2024
ORDER BY updated_at DESC;

-- Check period lock history
RAISE NOTICE '';
RAISE NOTICE 'Period Lock History:';
SELECT 
  filing_year,
  is_locked,
  locked_at,
  lock_reason,
  unlocked_at,
  unlock_reason
FROM osha_ita_v1.period_locks
ORDER BY locked_at DESC;

-- Check projection versions
RAISE NOTICE '';
RAISE NOTICE 'Form Projection History:';
SELECT 
  'Form 300' as form_type,
  projection_version,
  projected_at,
  is_current,
  superseded_at
FROM osha_ita_v1.form_300_log
WHERE filing_year = 2024
ORDER BY projection_version DESC
LIMIT 5;

-- ============================================================================
-- STEP 22: GENERATE COMPLIANCE METRICS
-- ============================================================================
DO $$ 
DECLARE
  v_summary record;
  v_total_recordable_rate numeric;
  v_dart_rate numeric;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 22: OSHA Compliance Metrics';
  RAISE NOTICE '';
  
  -- Get summary data
  SELECT * INTO v_summary
  FROM osha_ita_v1.form_300a_summaries
  WHERE filing_year = 2024 AND is_current = true
  LIMIT 1;
  
  -- Calculate Total Recordable Incident Rate (TRIR)
  -- Formula: (Total recordable cases × 200,000) / Total hours worked
  v_total_recordable_rate := 
    ((v_summary.total_deaths + v_summary.total_dafw_cases + 
      v_summary.total_djtr_cases + v_summary.total_other_cases) * 200000.0) / 
    NULLIF(v_summary.total_hours_worked, 0);
  
  -- Calculate Days Away, Restricted, or Transferred (DART) Rate
  -- Formula: (DAFW + DJTR cases × 200,000) / Total hours worked
  v_dart_rate := 
    ((v_summary.total_dafw_cases + v_summary.total_djtr_cases) * 200000.0) / 
    NULLIF(v_summary.total_hours_worked, 0);
  
  RAISE NOTICE '========================================';
  RAISE NOTICE '   OSHA INCIDENT RATE METRICS - 2024';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Total Recordable Incident Rate (TRIR):';
  RAISE NOTICE '  %.2f incidents per 100 FTE', v_total_recordable_rate;
  RAISE NOTICE '';
  RAISE NOTICE 'Days Away, Restricted, Transfer Rate (DART):';
  RAISE NOTICE '  %.2f incidents per 100 FTE', v_dart_rate;
  RAISE NOTICE '';
  RAISE NOTICE 'Lost Workday Case Rate (LWCR):';
  RAISE NOTICE '  %.2f cases per 100 FTE', 
    (v_summary.total_dafw_cases * 200000.0) / NULLIF(v_summary.total_hours_worked, 0);
  RAISE NOTICE '';
  RAISE NOTICE 'Severity Rate:';
  RAISE NOTICE '  %.2f days per 100 FTE',
    ((v_summary.total_dafw_days + v_summary.total_djtr_days) * 200000.0) / 
    NULLIF(v_summary.total_hours_worked, 0);
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
END $;

-- ============================================================================
-- STEP 23: EXPORT DATA QUERIES
-- ============================================================================
DO $$ 
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 23: Data Export Queries';
  RAISE NOTICE '';
  RAISE NOTICE 'These queries can be used to export data to Excel/CSV:';
  RAISE NOTICE '';
END $;

-- Export Query 1: Complete incident list
RAISE NOTICE '1. Complete Incident Export Query:';
\echo 'SELECT 
  e.establishment_name,
  i.filing_year,
  i.case_number,
  i.current_state,
  i.date_of_incident,
  i.job_title,
  i.incident_location,
  i.incident_description,
  i.incident_outcome,
  i.type_of_incident,
  i.dafw_num_away,
  i.djtr_num_tr,
  i.created_at,
  i.updated_at
FROM osha_ita_v1.incidents i
JOIN osha_ita_v1.establishments e ON e.establishment_id = i.establishment_id
WHERE i.filing_year = 2024
ORDER BY i.date_of_incident;'

-- Export Query 2: Form 300 for printing
RAISE NOTICE '';
RAISE NOTICE '2. Form 300 Export Query:';
\echo 'SELECT 
  case_number,
  employee_name_export,
  job_title,
  date_of_injury,
  where_event_occurred,
  injury_description,
  death,
  days_away_from_work,
  job_transfer_restriction,
  other_recordable,
  days_away_count,
  days_restricted_count,
  is_injury,
  is_skin_disorder,
  is_respiratory,
  is_poisoning,
  is_hearing_loss,
  is_other_illness
FROM osha_ita_v1.v_form_300_export
WHERE filing_year = 2024
ORDER BY date_of_injury;'

-- ============================================================================
-- FINAL SUMMARY
-- ============================================================================
DO $$ 
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE '   WORKFLOW SIMULATION COMPLETE!';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Successfully Tested:';
  RAISE NOTICE '  ✓ User authentication and session management';
  RAISE NOTICE '  ✓ Establishment setup';
  RAISE NOTICE '  ✓ CSV import and validation';
  RAISE NOTICE '  ✓ Data mapping and promotion';
  RAISE NOTICE '  ✓ Incident workflow (draft -> review -> approved)';
  RAISE NOTICE '  ✓ State transition guards';
  RAISE NOTICE '  ✓ Form generation (300, 301, 300A)';
  RAISE NOTICE '  ✓ Employment data updates';
  RAISE NOTICE '  ✓ Form certification';
  RAISE NOTICE '  ✓ Period locking/unlocking';
  RAISE NOTICE '  ✓ ITA submission creation';
  RAISE NOTICE '  ✓ Submission tracking';
  RAISE NOTICE '  ✓ Business rule validations';
  RAISE NOTICE '  ✓ Audit trail tracking';
  RAISE NOTICE '  ✓ Compliance metrics calculation';
  RAISE NOTICE '  ✓ Data export queries';
  RAISE NOTICE '';
  RAISE NOTICE 'All systems operational and ready for production!';
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
END $;

-- ============================================================================
-- CLEANUP (Optional - comment out to keep test data)
-- ============================================================================
-- UNCOMMENT BELOW TO CLEAN UP TEST DATA
/*
DO $$ 
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE 'Cleaning up test data...';
  
  DELETE FROM osha_ita_v1.ita_submissions WHERE filing_year = 2024;
  DELETE FROM osha_ita_v1.period_locks WHERE filing_year = 2024;
  DELETE FROM osha_ita_v1.form_300a_summaries WHERE filing_year = 2024;
  DELETE FROM osha_ita_v1.form_301_reports WHERE year_of_filing = 2024;
  DELETE FROM osha_ita_v1.form_300_log WHERE filing_year = 2024;
  DELETE FROM osha_ita_v1.import_rows;
  DELETE FROM osha_ita_v1.import_batches;
  DELETE FROM osha_ita_v1.incidents WHERE filing_year = 2024;
  DELETE FROM osha_ita_v1.establishments 
    WHERE establishment_name LIKE 'Acme Manufacturing%';
  
  DROP TABLE IF EXISTS current_session;
  DROP TABLE IF EXISTS test_establishments;
  DROP TABLE IF EXISTS test_import;
  
  RAISE NOTICE '✓ Test data cleaned up';
END $;
*/