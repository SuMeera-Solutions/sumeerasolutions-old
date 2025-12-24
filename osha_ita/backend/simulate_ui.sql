-- ============================================================================
-- OSHA ITA MANUAL ENTRY WORKFLOW SIMULATION
-- Simulating a Compliance Manager's Journey - UI-Based Entry
-- ============================================================================

\c compliease_sbx

-- ============================================================================
-- SCENARIO SETUP
-- ============================================================================
-- You are Jane Smith, Compliance Manager at Acme Manufacturing
-- Filing Year: 2024
-- Workflow:
--   1. Login and view dashboard
--   2. Set up establishments
--   3. Manually enter incidents through UI forms
--   4. Review and approve incidents
--   5. Generate OSHA forms (300, 301, 300A)
--   6. Add employment data and certify
--   7. Submit to ITA
-- ============================================================================

DO $$ 
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'OSHA ITA Manual Entry Simulation';
  RAISE NOTICE 'Compliance Manager: Jane Smith';
  RAISE NOTICE 'Filing Year: 2024';
  RAISE NOTICE 'Entry Method: Manual UI Forms';
  RAISE NOTICE '========================================';
END $$;

-- ============================================================================
-- STEP 1: USER LOGIN & SESSION
-- ============================================================================
DO $$ 
DECLARE
  v_user_id uuid := 'a0000000-0000-0000-0000-000000000001'::uuid;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 1: User Login';
  RAISE NOTICE 'User: Jane Smith (Compliance Manager)';
  RAISE NOTICE 'User ID: %', v_user_id;
  
  CREATE TEMP TABLE IF NOT EXISTS current_session (
    user_id uuid,
    user_name text,
    user_role text,
    session_start timestamptz
  );
  
  DELETE FROM current_session;
  INSERT INTO current_session VALUES 
    (v_user_id, 'Jane Smith', 'Compliance Manager', now());
  
  RAISE NOTICE '✓ Session established at %', now();
END $$;

-- ============================================================================
-- STEP 2: DASHBOARD - VIEW CURRENT STATUS
-- ============================================================================
DO $$ 
DECLARE
  v_total_establishments int;
  v_total_incidents int;
  v_pending_review int;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 2: Dashboard Overview';
  
  SELECT COUNT(*) INTO v_total_establishments
  FROM osha_ita_v1.establishments WHERE is_active = true;
  
  SELECT COUNT(*) INTO v_total_incidents
  FROM osha_ita_v1.incidents WHERE filing_year = 2024;
  
  SELECT COUNT(*) INTO v_pending_review
  FROM osha_ita_v1.incidents 
  WHERE filing_year = 2024 AND current_state = 'in_review';
  
  RAISE NOTICE '----------------------------------------';
  RAISE NOTICE 'Current Status:';
  RAISE NOTICE '  Establishments: %', v_total_establishments;
  RAISE NOTICE '  2024 Incidents: %', v_total_incidents;
  RAISE NOTICE '  Pending Review: %', v_pending_review;
  RAISE NOTICE '----------------------------------------';
END $$;

-- ============================================================================
-- STEP 3: SETUP ESTABLISHMENTS
-- ============================================================================
DO $$ 
DECLARE
  v_est1_id uuid;
  v_est2_id uuid;
  v_user_id uuid;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 3: Setting Up Establishments';
  RAISE NOTICE 'Action: Navigate to Settings > Establishments > Add New';
  RAISE NOTICE '';
  
  SELECT user_id INTO v_user_id FROM current_session;
  
  -- Establishment 1: Houston Plant
  RAISE NOTICE 'Creating Establishment #1...';
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
  
  RAISE NOTICE '  ✓ Houston Plant created';
  RAISE NOTICE '    ID: %', v_est1_id;
  RAISE NOTICE '    NAICS: 332710 - Machine Shops';
  
  -- Establishment 2: Dallas Warehouse
  RAISE NOTICE '';
  RAISE NOTICE 'Creating Establishment #2...';
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
  
  RAISE NOTICE '  ✓ Dallas Warehouse created';
  RAISE NOTICE '    ID: %', v_est2_id;
  RAISE NOTICE '    NAICS: 493110 - Warehousing';
  
  -- Store for later use
  CREATE TEMP TABLE IF NOT EXISTS test_establishments (
    est_id uuid,
    est_name text,
    est_type int
  );
  
  INSERT INTO test_establishments VALUES 
    (v_est1_id, 'Houston Plant', 1),
    (v_est2_id, 'Dallas Warehouse', 2);
    
  RAISE NOTICE '';
  RAISE NOTICE '✓ Total establishments: 2';
END $$;

-- ============================================================================
-- STEP 4: MANUAL INCIDENT ENTRY #1 - BACK INJURY
-- ============================================================================
DO $$ 
DECLARE
  v_user_id uuid;
  v_est_id uuid;
  v_incident_id uuid;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 4: Creating Incident #1 (Back Injury)';
  RAISE NOTICE 'Action: Navigate to Incidents > Add New Incident';
  RAISE NOTICE '';
  
  SELECT user_id INTO v_user_id FROM current_session;
  SELECT est_id INTO v_est_id FROM test_establishments WHERE est_type = 1;
  
  RAISE NOTICE 'UI Form - Step 1: Basic Information';
  RAISE NOTICE '  Establishment: Acme Manufacturing - Houston Plant';
  RAISE NOTICE '  Case Number: 2024-001';
  RAISE NOTICE '  Filing Year: 2024';
  RAISE NOTICE '  Date of Incident: 2024-03-15';
  RAISE NOTICE '  Time: 14:30';
  RAISE NOTICE '';
  
  RAISE NOTICE 'UI Form - Step 2: Employee Information';
  RAISE NOTICE '  Job Title: Machine Operator';
  RAISE NOTICE '  Date of Birth: 1985-06-20';
  RAISE NOTICE '  Date of Hire: 2018-01-15';
  RAISE NOTICE '  Sex: Male';
  RAISE NOTICE '  Privacy Case: No';
  RAISE NOTICE '';
  
  RAISE NOTICE 'UI Form - Step 3: Incident Details';
  RAISE NOTICE '  Location: Production Floor - Bay 3';
  RAISE NOTICE '  Description: Back strain while lifting heavy equipment';
  RAISE NOTICE '  Outcome: Days Away from Work';
  RAISE NOTICE '  Type: Injury';
  RAISE NOTICE '  Days Away: 5';
  RAISE NOTICE '  Days Restricted: 0';
  RAISE NOTICE '';
  
  RAISE NOTICE 'UI Form - Step 4: Treatment Information';
  RAISE NOTICE '  Treatment Location: Emergency Room';
  RAISE NOTICE '  Inpatient Stay: No';
  RAISE NOTICE '';
  
  RAISE NOTICE 'UI Form - Step 5: Narrative';
  
  -- Insert the incident
  INSERT INTO osha_ita_v1.incidents (
    establishment_id,
    case_number,
    filing_year,
    current_state,
    is_privacy_case,
    date_of_incident,
    time_of_incident,
    time_started_work,
    incident_location,
    incident_description,
    job_title,
    date_of_birth,
    date_of_hire,
    sex,
    incident_outcome,
    type_of_incident,
    dafw_num_away,
    djtr_num_tr,
    treatment_facility_type,
    treatment_in_patient,
    nar_before_incident,
    nar_what_happened,
    nar_injury_illness,
    nar_object_substance,
    created_by,
    updated_by
  ) VALUES (
    v_est_id,
    '2024-001',
    2024,
    'draft',
    false,
    '2024-03-15'::date,
    '14:30:00'::time,
    '07:00:00'::time,
    'Production Floor - Bay 3',
    'Back strain while lifting heavy equipment',
    'Machine Operator',
    '1985-06-20'::date,
    '2018-01-15'::date,
    'M',
    'days_away',
    'injury',
    5,
    0,
    1, -- ER
    0, -- Not inpatient
    'Employee was moving equipment to prepare for production run',
    'Employee bent to lift 50lb motor without proper lifting technique',
    'Lower back strain, muscle spasm',
    'Electric motor assembly',
    v_user_id,
    v_user_id
  ) RETURNING incident_id INTO v_incident_id;
  
  RAISE NOTICE '';
  RAISE NOTICE '✓ Incident 2024-001 created successfully';
  RAISE NOTICE '  ID: %', v_incident_id;
  RAISE NOTICE '  Status: Draft';
  RAISE NOTICE '  Action: Click "Save Draft"';
END $$;

-- ============================================================================
-- STEP 5: MANUAL INCIDENT ENTRY #2 - LACERATION
-- ============================================================================
DO $$ 
DECLARE
  v_user_id uuid;
  v_est_id uuid;
  v_incident_id uuid;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 5: Creating Incident #2 (Hand Laceration)';
  RAISE NOTICE 'Action: Navigate to Incidents > Add New Incident';
  RAISE NOTICE '';
  
  SELECT user_id INTO v_user_id FROM current_session;
  SELECT est_id INTO v_est_id FROM test_establishments WHERE est_type = 1;
  
  RAISE NOTICE 'UI Form Data Entry:';
  RAISE NOTICE '  Case Number: 2024-002';
  RAISE NOTICE '  Date: 2024-04-22, Time: 10:15';
  RAISE NOTICE '  Employee: Assembly Technician (Female)';
  RAISE NOTICE '  Location: Assembly Line 2';
  RAISE NOTICE '  Injury: Hand laceration from sharp edge';
  RAISE NOTICE '  Outcome: Other Recordable';
  RAISE NOTICE '';
  
  INSERT INTO osha_ita_v1.incidents (
    establishment_id,
    case_number,
    filing_year,
    current_state,
    is_privacy_case,
    date_of_incident,
    time_of_incident,
    time_started_work,
    incident_location,
    incident_description,
    job_title,
    date_of_birth,
    date_of_hire,
    sex,
    incident_outcome,
    type_of_incident,
    dafw_num_away,
    djtr_num_tr,
    treatment_facility_type,
    treatment_in_patient,
    nar_before_incident,
    nar_what_happened,
    nar_injury_illness,
    nar_object_substance,
    created_by,
    updated_by
  ) VALUES (
    v_est_id,
    '2024-002',
    2024,
    'draft',
    false,
    '2024-04-22'::date,
    '10:15:00'::time,
    '06:00:00'::time,
    'Assembly Line 2',
    'Hand laceration from sharp edge',
    'Assembly Technician',
    '1992-11-08'::date,
    '2020-05-01'::date,
    'F',
    'other_recordable',
    'injury',
    0,
    0,
    0, -- On-site first aid
    0,
    'Employee was performing routine assembly operations',
    'Employee contacted sharp burr on metal part while positioning component',
    'Laceration to right palm requiring 4 stitches',
    'Metal bracket with sharp edge',
    v_user_id,
    v_user_id
  ) RETURNING incident_id INTO v_incident_id;
  
  RAISE NOTICE '✓ Incident 2024-002 created successfully';
  RAISE NOTICE '  ID: %', v_incident_id;
  RAISE NOTICE '  Status: Draft';
END $$;

-- ============================================================================
-- STEP 6: MANUAL INCIDENT ENTRY #3 - CHEMICAL EXPOSURE (PRIVACY CASE)
-- ============================================================================
DO $$ 
DECLARE
  v_user_id uuid;
  v_est_id uuid;
  v_incident_id uuid;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 6: Creating Incident #3 (Chemical Exposure - Privacy Case)';
  RAISE NOTICE '';
  
  SELECT user_id INTO v_user_id FROM current_session;
  SELECT est_id INTO v_est_id FROM test_establishments WHERE est_type = 1;
  
  RAISE NOTICE 'UI Form Data Entry:';
  RAISE NOTICE '  Case Number: 2024-003';
  RAISE NOTICE '  Date: 2024-06-10';
  RAISE NOTICE '  Privacy Case: YES (checked)';
  RAISE NOTICE '  Outcome: Job Transfer/Restriction';
  RAISE NOTICE '  Type: Respiratory Condition';
  RAISE NOTICE '';
  
  INSERT INTO osha_ita_v1.incidents (
    establishment_id,
    case_number,
    filing_year,
    current_state,
    is_privacy_case,
    date_of_incident,
    time_of_incident,
    time_started_work,
    incident_location,
    incident_description,
    job_title,
    date_of_birth,
    date_of_hire,
    sex,
    incident_outcome,
    type_of_incident,
    dafw_num_away,
    djtr_num_tr,
    treatment_facility_type,
    treatment_in_patient,
    nar_before_incident,
    nar_what_happened,
    nar_injury_illness,
    nar_object_substance,
    created_by,
    updated_by
  ) VALUES (
    v_est_id,
    '2024-003',
    2024,
    'draft',
    true, -- Privacy case
    '2024-06-10'::date,
    '11:20:00'::time,
    '07:00:00'::time,
    'Chemical Storage Area',
    'Respiratory irritation from chemical fumes',
    'Maintenance Technician',
    '1988-03-12'::date,
    '2019-08-01'::date,
    'M',
    'job_transfer_restriction',
    'respiratory_condition',
    0,
    10, -- 10 days restricted
    1,
    0,
    'Employee was performing routine maintenance in chemical storage area',
    'Ventilation system malfunctioned, employee exposed to cleaning solution fumes',
    'Respiratory irritation, coughing, temporary breathing difficulty',
    'Industrial cleaning solution vapors',
    v_user_id,
    v_user_id
  ) RETURNING incident_id INTO v_incident_id;
  
  RAISE NOTICE '✓ Incident 2024-003 created successfully';
  RAISE NOTICE '  ID: %', v_incident_id;
  RAISE NOTICE '  Status: Draft';
  RAISE NOTICE '  NOTE: Privacy Case - Employee name will be hidden on Form 300';
END $$;

-- ============================================================================
-- STEP 7: REVIEW DRAFT INCIDENTS
-- ============================================================================
DO $$ 
DECLARE
  v_rec record;
  v_count int;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 7: Reviewing Draft Incidents';
  RAISE NOTICE 'Action: Navigate to Incidents > Draft';
  RAISE NOTICE '';
  
  SELECT COUNT(*) INTO v_count
  FROM osha_ita_v1.incidents
  WHERE filing_year = 2024 AND current_state = 'draft';
  
  RAISE NOTICE 'Draft Incidents (%): ', v_count;
  RAISE NOTICE '----------------------------------------';
  
  FOR v_rec IN 
    SELECT 
      case_number,
      date_of_incident,
      job_title,
      incident_description,
      incident_outcome,
      is_privacy_case,
      created_at
    FROM osha_ita_v1.incidents
    WHERE filing_year = 2024 AND current_state = 'draft'
    ORDER BY case_number
  LOOP
    RAISE NOTICE '';
    RAISE NOTICE 'Case: %', v_rec.case_number;
    RAISE NOTICE '  Date: %', v_rec.date_of_incident;
    RAISE NOTICE '  Job: %', v_rec.job_title;
    RAISE NOTICE '  Description: %', v_rec.incident_description;
    RAISE NOTICE '  Outcome: %', v_rec.incident_outcome;
    RAISE NOTICE '  Privacy: %', CASE WHEN v_rec.is_privacy_case THEN 'Yes' ELSE 'No' END;
    RAISE NOTICE '  Created: %', v_rec.created_at;
  END LOOP;
  
  RAISE NOTICE '';
  RAISE NOTICE '----------------------------------------';
END $$;

-- ============================================================================
-- STEP 8: SUBMIT FOR REVIEW (Incident #1)
-- ============================================================================
DO $$ 
DECLARE
  v_user_id uuid;
  v_incident_id uuid;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 8: Submit Incident for Review';
  RAISE NOTICE 'Action: Open Case 2024-001 > Click "Submit for Review"';
  RAISE NOTICE '';
  
  SELECT user_id INTO v_user_id FROM current_session;
  
  SELECT incident_id INTO v_incident_id
  FROM osha_ita_v1.incidents
  WHERE case_number = '2024-001';
  
  -- Change state from draft to in_review
  UPDATE osha_ita_v1.incidents
  SET current_state = 'in_review',
      updated_by = v_user_id
  WHERE incident_id = v_incident_id;
  
  RAISE NOTICE '✓ Case 2024-001: draft → in_review';
  RAISE NOTICE '  Notification sent to Safety Manager';
  RAISE NOTICE '  Status: Pending Review';
END $$;

-- ============================================================================
-- STEP 9: REVIEW AND APPROVE (Safety Manager Role)
-- ============================================================================
DO $$ 
DECLARE
  v_reviewer_id uuid := 'b0000000-0000-0000-0000-000000000002'::uuid;
  v_incident_id uuid;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 9: Review Process (Safety Manager)';
  RAISE NOTICE 'User: Mike Johnson (Safety Manager)';
  RAISE NOTICE 'Action: Navigate to Incidents > Pending Review';
  RAISE NOTICE '';
  
  SELECT incident_id INTO v_incident_id
  FROM osha_ita_v1.incidents
  WHERE case_number = '2024-001';
  
  RAISE NOTICE 'Reviewing Case 2024-001...';
  RAISE NOTICE '  ✓ Verified incident details';
  RAISE NOTICE '  ✓ Confirmed days away calculation';
  RAISE NOTICE '  ✓ Reviewed narratives';
  RAISE NOTICE '  ✓ Checked treatment documentation';
  RAISE NOTICE '';
  RAISE NOTICE 'Action: Click "Approve"';
  
  -- Approve the incident
  UPDATE osha_ita_v1.incidents
  SET current_state = 'approved',
      updated_by = v_reviewer_id
  WHERE incident_id = v_incident_id;
  
  RAISE NOTICE '';
  RAISE NOTICE '✓ Case 2024-001: in_review → approved';
  RAISE NOTICE '  Approved by: Mike Johnson';
  RAISE NOTICE '  Ready for OSHA reporting';
END $$;

-- ============================================================================
-- STEP 10: BULK APPROVE REMAINING INCIDENTS
-- ============================================================================
DO $$ 
DECLARE
  v_user_id uuid;
  v_incident_id uuid;
  v_case_num text;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 10: Approving Remaining Incidents';
  RAISE NOTICE 'User: Jane Smith (Compliance Manager)';
  RAISE NOTICE '';
  
  SELECT user_id INTO v_user_id FROM current_session;
  
  -- Submit remaining drafts for review
  FOR v_incident_id, v_case_num IN
    SELECT incident_id, case_number
    FROM osha_ita_v1.incidents
    WHERE filing_year = 2024 AND current_state = 'draft'
  LOOP
    UPDATE osha_ita_v1.incidents
    SET current_state = 'in_review',
        updated_by = v_user_id
    WHERE incident_id = v_incident_id;
    
    RAISE NOTICE '  % → in_review', v_case_num;
  END LOOP;
  
  -- Approve all
  FOR v_incident_id, v_case_num IN
    SELECT incident_id, case_number
    FROM osha_ita_v1.incidents
    WHERE filing_year = 2024 AND current_state = 'in_review'
  LOOP
    UPDATE osha_ita_v1.incidents
    SET current_state = 'approved',
        updated_by = v_user_id
    WHERE incident_id = v_incident_id;
    
    RAISE NOTICE '  % → approved', v_case_num;
  END LOOP;
  
  RAISE NOTICE '';
  RAISE NOTICE '✓ All incidents approved';
END $$;

-- ============================================================================
-- STEP 11: GENERATE OSHA FORMS
-- ============================================================================
DO $$ 
DECLARE
  v_est_id uuid;
  v_year int := 2024;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 11: Generating OSHA Forms';
  RAISE NOTICE 'Action: Navigate to Reports > Generate Forms';
  RAISE NOTICE '';
  
  SELECT est_id INTO v_est_id FROM test_establishments WHERE est_type = 1;
  
  RAISE NOTICE 'Generating forms for Houston Plant, Year 2024...';
  RAISE NOTICE '';
  
  -- Rebuild all projections
  PERFORM osha_ita_v1.rebuild_all_projections(v_est_id, v_year);
  
  RAISE NOTICE '✓ Form 300 (OSHA Log) - Generated';
  RAISE NOTICE '✓ Form 301 (Incident Reports) - Generated';
  RAISE NOTICE '✓ Form 300A (Annual Summary) - Generated';
  RAISE NOTICE '';
  RAISE NOTICE 'Forms ready for review';
END $$;

-- ============================================================================
-- STEP 12: REVIEW FORM 300 (OSHA LOG)
-- ============================================================================
DO $$ 
DECLARE
  v_rec record;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 12: Review Form 300 (OSHA Log)';
  RAISE NOTICE 'Action: Navigate to Reports > Form 300';
  RAISE NOTICE '';
  RAISE NOTICE '========== FORM 300 - OSHA LOG ==========';
  RAISE NOTICE 'Establishment: Acme Manufacturing - Houston Plant';
  RAISE NOTICE 'Year: 2024';
  RAISE NOTICE '';
  
  FOR v_rec IN 
    SELECT 
      case_number,
      employee_name_export AS employee,
      job_title,
      date_of_injury,
      where_event_occurred,
      injury_description,
      death,
      days_away_from_work AS dafw,
      job_transfer_restriction AS djtr,
      other_recordable AS other,
      days_away_count,
      days_restricted_count
    FROM osha_ita_v1.v_form_300_export
    WHERE filing_year = 2024
    ORDER BY case_number
  LOOP
    RAISE NOTICE 'Case: % | Employee: %', v_rec.case_number, v_rec.employee;
    RAISE NOTICE '  Job: %', v_rec.job_title;
    RAISE NOTICE '  Date: % | Location: %', v_rec.date_of_injury, v_rec.where_event_occurred;
    RAISE NOTICE '  Description: %', v_rec.injury_description;
    RAISE NOTICE '  Death: % | DAFW: % | DJTR: % | Other: %', 
      v_rec.death, v_rec.dafw, v_rec.djtr, v_rec.other;
    RAISE NOTICE '  Days Away: % | Days Restricted: %',
      v_rec.days_away_count, v_rec.days_restricted_count;
    RAISE NOTICE '';
  END LOOP;
  
  RAISE NOTICE '=========================================';
END $$;

-- ============================================================================
-- STEP 13: ADD EMPLOYMENT DATA TO FORM 300A
-- ============================================================================
DO $$ 
DECLARE
  v_summary_id uuid;
  v_user_id uuid;
  v_est_id uuid;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 13: Update Form 300A Employment Data';
  RAISE NOTICE 'Action: Navigate to Reports > Form 300A > Edit Employment Info';
  RAISE NOTICE '';
  
  SELECT user_id INTO v_user_id FROM current_session;
  SELECT est_id INTO v_est_id FROM test_establishments WHERE est_type = 1;
  
  SELECT summary_id INTO v_summary_id
  FROM osha_ita_v1.form_300a_summaries
  WHERE establishment_id = v_est_id
    AND filing_year = 2024
    AND is_current = true;
  
  RAISE NOTICE 'UI Form: Employment Information';
  RAISE NOTICE '  Annual Average Employees: 45';
  RAISE NOTICE '  Total Hours Worked: 93,600';
  RAISE NOTICE '  (45 employees × 2,080 hours/year)';
  RAISE NOTICE '';
  RAISE NOTICE 'Action: Click "Save"';
  
  UPDATE osha_ita_v1.form_300a_summaries
  SET annual_average_employees = 45,
      total_hours_worked = 93600
  WHERE summary_id = v_summary_id;
  
  RAISE NOTICE '';
  RAISE NOTICE '✓ Employment data updated';
END $$;

-- ============================================================================
-- STEP 14: REVIEW FORM 300A SUMMARY
-- ============================================================================
DO $$ 
DECLARE
  v_rec record;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 14: Review Form 300A Summary';
  RAISE NOTICE 'Action: Navigate to Reports > Form 300A';
  RAISE NOTICE '';
  
  SELECT * INTO v_rec
  FROM osha_ita_v1.form_300a_summaries
  WHERE filing_year = 2024 AND is_current = true;
  
  RAISE NOTICE '========== FORM 300A - ANNUAL SUMMARY ==========';
  RAISE NOTICE '';
  RAISE NOTICE 'Establishment Information:';
  RAISE NOTICE '  Name: %', v_rec.establishment_name;
  RAISE NOTICE '  Address: %', v_rec.street_address;
  RAISE NOTICE '  City, State ZIP: %, % %', v_rec.city, v_rec.state, v_rec.zip;
  RAISE NOTICE '  NAICS: % - %', v_rec.naics_code, v_rec.industry_description;
  RAISE NOTICE '';
  RAISE NOTICE 'Employment:';
  RAISE NOTICE '  Annual Average Employees: %', v_rec.annual_average_employees;
  RAISE NOTICE '  Total Hours Worked: %', v_rec.total_hours_worked;
  RAISE NOTICE '';
  RAISE NOTICE 'Number of Cases:';
  RAISE NOTICE '  Total Deaths: %', v_rec.total_deaths;
  RAISE NOTICE '  Total DAFW Cases: %', v_rec.total_dafw_cases;
  RAISE NOTICE '  Total DJTR Cases: %', v_rec.total_djtr_cases;
  RAISE NOTICE '  Total Other Recordable: %', v_rec.total_other_cases;
  RAISE NOTICE '';
  RAISE NOTICE 'Number of Days:';
  RAISE NOTICE '  Total Days Away: %', v_rec.total_dafw_days;
  RAISE NOTICE '  Total Days Restricted: %', v_rec.total_djtr_days;
  RAISE NOTICE '';
  RAISE NOTICE 'Injury & Illness Types:';
  RAISE NOTICE '  Injuries: %', v_rec.total_injuries;
  RAISE NOTICE '  Skin Disorders: %', v_rec.total_skin_disorders;
  RAISE NOTICE '  Respiratory Conditions: %', v_rec.total_respiratory_conditions;
  RAISE NOTICE '  Poisonings: %', v_rec.total_poisonings;
  RAISE NOTICE '  Hearing Loss: %', v_rec.total_hearing_loss;
  RAISE NOTICE '  Other Illnesses: %', v_rec.total_other_illnesses;
  RAISE NOTICE '';
  RAISE NOTICE '===============================================';
END $$;

-- ============================================================================
-- STEP 15: CERTIFY FORM 300A
-- ============================================================================
DO $$ 
DECLARE
  v_summary_id uuid;
  v_user_id uuid;
  v_est_id uuid;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 15: Certify Form 300A';
  RAISE NOTICE 'Action: Navigate to Reports > Form 300A > Certify';
  RAISE NOTICE '';
  
  SELECT user_id INTO v_user_id FROM current_session;
  SELECT est_id INTO v_est_id FROM test_establishments WHERE est_type = 1;
  
  SELECT summary_id INTO v_summary_id
  FROM osha_ita_v1.form_300a_summaries
  WHERE establishment_id = v_est_id
    AND filing_year = 2024
    AND is_current = true;
  
  RAISE NOTICE 'UI Form: Certification';
  RAISE NOTICE '  Company Executive: Jane Smith';
  RAISE NOTICE '  Title: Compliance Manager';
  RAISE NOTICE '  Date: %', current_date;
  RAISE NOTICE '';
  RAISE NOTICE 'Certification Statement:';
  RAISE NOTICE '  "I certify that I have examined this document and that to the';
  RAISE NOTICE '   best of my knowledge the entries are true and complete."';
  RAISE NOTICE '';
  RAISE NOTICE 'Action: Click "Certify"';
  
  -- Certify the summary
  PERFORM osha_ita_v1.certify_300a(
    v_summary_id,
    v_user_id,
    'Jane Smith',
    'Compliance Manager'
  );
  
  RAISE NOTICE '';
  RAISE NOTICE '✓ Form 300A certified';
  RAISE NOTICE '  Certified by: Jane Smith';
  RAISE NOTICE '  Title: Compliance Manager';
  RAISE NOTICE '  Date: %', now();
END $$;

-- ============================================================================
-- STEP 16: CALCULATE OSHA METRICS
-- ============================================================================
DO $$ 
DECLARE
  v_summary record;
  v_trir numeric;
  v_dart numeric;
  v_lwcr numeric;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 16: OSHA Incident Rate Calculations';
  RAISE NOTICE 'Action: Navigate to Dashboard > Safety Metrics';
  RAISE NOTICE '';
  
  SELECT * INTO v_summary
  FROM osha_ita_v1.form_300a_summaries
  WHERE filing_year = 2024 AND is_current = true;
  
  -- Calculate TRIR
  v_trir := ((v_summary.total_deaths + v_summary.total_dafw_cases + 
              v_summary.total_djtr_cases + v_summary.total_other_cases) * 200000.0) / 
            NULLIF(v_summary.total_hours_worked, 0);
  
  -- Calculate DART
  v_dart := ((v_summary.total_dafw_cases + v_summary.total_djtr_cases) * 200000.0) / 
            NULLIF(v_summary.total_hours_worked, 0);
  
  -- Calculate LWCR
  v_lwcr := (v_summary.total_dafw_cases * 200000.0) / 
            NULLIF(v_summary.total_hours_worked, 0);
  
  RAISE NOTICE '========== SAFETY METRICS DASHBOARD ==========';
  RAISE NOTICE '';
  RAISE NOTICE 'Total Recordable Incident Rate (TRIR):';
  RAISE NOTICE '  Rate: %.2f per 100 FTE', v_trir;
  RAISE NOTICE '  Formula: (Total Cases × 200,000) / Total Hours';
  RAISE NOTICE '  Calculation: (% × 200,000) / %', 
    (v_summary.total_deaths + v_summary.total_dafw_cases + 
     v_summary.total_djtr_cases + v_summary.total_other_cases),
    v_summary.total_hours_worked;
  RAISE NOTICE '';
  RAISE NOTICE 'DART Rate (Days Away/Restricted/Transfer):';
  RAISE NOTICE '  Rate: %.2f per 100 FTE', v_dart;
  RAISE NOTICE '  Cases: % (DAFW: %, DJTR: %)', 
    (v_summary.total_dafw_cases + v_summary.total_djtr_cases),
    v_summary.total_dafw_cases,
    v_summary.total_djtr_cases;
  RAISE NOTICE '';
  RAISE NOTICE 'Lost Workday Case Rate (LWCR):';
  RAISE NOTICE '  Rate: %.2f per 100 FTE', v_lwcr;
  RAISE NOTICE '  Cases: %', v_summary.total_dafw_cases;
  RAISE NOTICE '';
  RAISE NOTICE 'Severity Rate:';
  RAISE NOTICE '  %.2f days per 100 FTE',
    ((v_summary.total_dafw_days + v_summary.total_djtr_days) * 200000.0) / 
    NULLIF(v_summary.total_hours_worked, 0);
  RAISE NOTICE '  Total Days Lost: % (Away: %, Restricted: %)',
    (v_summary.total_dafw_days + v_summary.total_djtr_days),
    v_summary.total_dafw_days,
    v_summary.total_djtr_days;
  RAISE NOTICE '';
  RAISE NOTICE '=============================================';
END $$;

-- ============================================================================
-- STEP 17: LOCK THE FILING PERIOD
-- ============================================================================
DO $$ 
DECLARE
  v_lock_id uuid;
  v_user_id uuid;
  v_est_id uuid;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 17: Lock Filing Period';
  RAISE NOTICE 'Action: Navigate to Settings > Period Management > Lock Period';
  RAISE NOTICE '';
  
  SELECT user_id INTO v_user_id FROM current_session;
  SELECT est_id INTO v_est_id FROM test_establishments WHERE est_type = 1;
  
  RAISE NOTICE 'UI Form: Lock Period';
  RAISE NOTICE '  Establishment: Acme Manufacturing - Houston Plant';
  RAISE NOTICE '  Year: 2024';
  RAISE NOTICE '  Reason: Finalizing annual OSHA submission';
  RAISE NOTICE '';
  RAISE NOTICE 'Warning: Once locked, incidents cannot be edited';
  RAISE NOTICE '         without unlocking the period.';
  RAISE NOTICE '';
  RAISE NOTICE 'Action: Click "Lock Period"';
  
  v_lock_id := osha_ita_v1.lock_period(
    v_est_id,
    2024,
    v_user_id,
    'Finalizing annual OSHA submission'
  );
  
  RAISE NOTICE '';
  RAISE NOTICE '✓ Period locked successfully';
  RAISE NOTICE '  Lock ID: %', v_lock_id;
  RAISE NOTICE '  Locked by: Jane Smith';
  RAISE NOTICE '  Locked at: %', now();
  
  -- Test the lock
  RAISE NOTICE '';
  RAISE NOTICE 'Testing period lock...';
  BEGIN
    UPDATE osha_ita_v1.incidents
    SET incident_description = 'Modified description'
    WHERE filing_year = 2024;
    --LIMIT 1;
    
    RAISE NOTICE '  ✗ ERROR: Lock did not prevent modification!';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '  ✓ Lock working correctly: %', SQLERRM;
  END;
END $$;

-- ============================================================================
-- STEP 18: CREATE ITA SUBMISSION
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
  RAISE NOTICE '>>> STEP 18: Create ITA Submission';
  RAISE NOTICE 'Action: Navigate to Submissions > New Submission';
  RAISE NOTICE '';
  
  SELECT user_id INTO v_user_id FROM current_session;
  SELECT est_id INTO v_est_id FROM test_establishments WHERE est_type = 1;
  
  -- Get summary data
  SELECT * INTO v_summary
  FROM osha_ita_v1.form_300a_summaries
  WHERE establishment_id = v_est_id
    AND filing_year = 2024
    AND is_current = true;
  
  RAISE NOTICE 'UI Form: ITA Submission Details';
  RAISE NOTICE '  Submission Type: Form 300A (Annual Summary)';
  RAISE NOTICE '  Year: 2024';
  RAISE NOTICE '  Establishment: %', v_summary.establishment_name;
  RAISE NOTICE '';
  
  -- Build payload
  v_payload := jsonb_build_object(
    'year', 2024,
    'establishment', jsonb_build_object(
      'name', v_summary.establishment_name,
      'address', v_summary.street_address,
      'city', v_summary.city,
      'state', v_summary.state,
      'zip', v_summary.zip,
      'naics', v_summary.naics_code,
      'industry_description', v_summary.industry_description
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
      'total_dafw_days', v_summary.total_dafw_days,
      'total_djtr_days', v_summary.total_djtr_days,
      'total_injuries', v_summary.total_injuries,
      'total_skin_disorders', v_summary.total_skin_disorders,
      'total_respiratory_conditions', v_summary.total_respiratory_conditions,
      'total_poisonings', v_summary.total_poisonings,
      'total_hearing_loss', v_summary.total_hearing_loss,
      'total_other_illnesses', v_summary.total_other_illnesses
    ),
    'certification', jsonb_build_object(
      'name', v_summary.certifier_name,
      'title', v_summary.certifier_title,
      'date', v_summary.certified_at
    )
  );
  
  RAISE NOTICE 'Generating submission payload...';
  RAISE NOTICE '';
  RAISE NOTICE 'Action: Click "Create Submission"';
  
  -- Create submission
  v_submission_id := osha_ita_v1.create_submission(
    v_est_id,
    2024,
    'form_300a',
    v_payload,
    v_user_id
  );
  
  RAISE NOTICE '';
  RAISE NOTICE '✓ Submission created successfully';
  RAISE NOTICE '  Submission ID: %', v_submission_id;
  RAISE NOTICE '  Type: Form 300A';
  RAISE NOTICE '  Status: Pending';
  RAISE NOTICE '  Ready to submit to OSHA ITA';
END $$;

-- ============================================================================
-- STEP 19: SUBMIT TO ITA (SIMULATE API CALL)
-- ============================================================================
DO $$ 
DECLARE
  v_submission_id uuid;
  v_response jsonb;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 19: Submit to OSHA ITA';
  RAISE NOTICE 'Action: Navigate to Submissions > View > Submit';
  RAISE NOTICE '';
  
  SELECT submission_id INTO v_submission_id
  FROM osha_ita_v1.ita_submissions
  WHERE filing_year = 2024 AND status = 'pending'
  LIMIT 1;
  
  RAISE NOTICE 'Submitting to OSHA ITA API...';
  RAISE NOTICE '  Endpoint: https://api.osha.gov/ita/v1/submissions';
  RAISE NOTICE '  Method: POST';
  RAISE NOTICE '  Authentication: Bearer token';
  RAISE NOTICE '';
  RAISE NOTICE 'Waiting for response...';
  
  -- Simulate successful API response
  v_response := jsonb_build_object(
    'success', true,
    'submissionId', 'ITA-2024-TX-' || lpad(floor(random() * 999999)::text, 6, '0'),
    'confirmationNumber', 'CONF-2024-' || upper(substring(md5(random()::text) from 1 for 10)),
    'timestamp', now(),
    'message', 'Submission received and accepted',
    'status', 'processed'
  );
  
  -- Record the attempt
  PERFORM osha_ita_v1.record_submission_attempt(
    v_submission_id,
    200,
    v_response,
    true
  );
  
  RAISE NOTICE '';
  RAISE NOTICE '✓ Submission successful!';
  RAISE NOTICE '  HTTP Status: 200 OK';
  RAISE NOTICE '  ITA Submission ID: %', v_response->>'submissionId';
  RAISE NOTICE '  Confirmation Number: %', v_response->>'confirmationNumber';
  RAISE NOTICE '  Message: %', v_response->>'message';
  RAISE NOTICE '';
  RAISE NOTICE 'Email confirmation sent to: jane.smith@acme.com';
END $$;

-- ============================================================================
-- STEP 20: VIEW SUBMISSION HISTORY
-- ============================================================================
DO $$ 
DECLARE
  v_rec record;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 20: View Submission History';
  RAISE NOTICE 'Action: Navigate to Submissions > History';
  RAISE NOTICE '';
  RAISE NOTICE '========== SUBMISSION HISTORY ==========';
  
  FOR v_rec IN
    SELECT 
      s.submission_type,
      s.filing_year,
      s.status,
      s.ita_confirmation_number,
      s.created_at,
      s.response_received_at,
      e.establishment_name
    FROM osha_ita_v1.ita_submissions s
    JOIN osha_ita_v1.establishments e ON e.establishment_id = s.establishment_id
    ORDER BY s.created_at DESC
  LOOP
    RAISE NOTICE '';
    RAISE NOTICE 'Submission: % - Year %', v_rec.submission_type, v_rec.filing_year;
    RAISE NOTICE '  Establishment: %', v_rec.establishment_name;
    RAISE NOTICE '  Status: %', v_rec.status;
    RAISE NOTICE '  Confirmation: %', v_rec.ita_confirmation_number;
    RAISE NOTICE '  Submitted: %', v_rec.created_at;
    RAISE NOTICE '  Response: %', v_rec.response_received_at;
  END LOOP;
  
  RAISE NOTICE '';
  RAISE NOTICE '======================================';
END $$;

-- ============================================================================
-- STEP 21: INCIDENT TREND ANALYSIS
-- ============================================================================
DO $$ 
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 21: Incident Trend Analysis';
  RAISE NOTICE 'Action: Navigate to Analytics > Trends';
  RAISE NOTICE '';
END $$;

-- Monthly trends
RAISE NOTICE '========== MONTHLY INCIDENT TRENDS ==========';
RAISE NOTICE '';
SELECT 
  TO_CHAR(date_of_incident, 'Month YYYY') as month,
  COUNT(*) as total_incidents,
  COUNT(*) FILTER (WHERE incident_outcome = 'days_away') as days_away_cases,
  SUM(COALESCE(dafw_num_away, 0)) as total_days_away
FROM osha_ita_v1.incidents
WHERE filing_year = 2024
GROUP BY TO_CHAR(date_of_incident, 'YYYY-MM'), TO_CHAR(date_of_incident, 'Month YYYY')
ORDER BY TO_CHAR(date_of_incident, 'YYYY-MM');

RAISE NOTICE '';
RAISE NOTICE '========== INCIDENTS BY JOB TITLE ==========';
RAISE NOTICE '';
SELECT 
  job_title,
  COUNT(*) as incident_count,
  COUNT(*) FILTER (WHERE incident_outcome = 'days_away') as days_away_cases,
  AVG(COALESCE(dafw_num_away, 0) + COALESCE(djtr_num_tr, 0)) as avg_days_lost
FROM osha_ita_v1.incidents
WHERE filing_year = 2024
GROUP BY job_title
ORDER BY incident_count DESC;

RAISE NOTICE '';
RAISE NOTICE '========== INCIDENTS BY OUTCOME ==========';
RAISE NOTICE '';
SELECT 
  incident_outcome,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM osha_ita_v1.incidents
WHERE filing_year = 2024
GROUP BY incident_outcome
ORDER BY count DESC;

-- ============================================================================
-- STEP 22: NEED TO MAKE A CORRECTION
-- ============================================================================
DO $$ 
DECLARE
  v_user_id uuid;
  v_est_id uuid;
  v_incident_id uuid;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 22: Making a Correction (Unlock Required)';
  RAISE NOTICE 'Scenario: OSHA inspector requests clarification on Case 2024-001';
  RAISE NOTICE '';
  
  SELECT user_id INTO v_user_id FROM current_session;
  SELECT est_id INTO v_est_id FROM test_establishments WHERE est_type = 1;
  
  RAISE NOTICE 'Action: Navigate to Settings > Period Management';
  RAISE NOTICE 'Action: Click "Unlock Period"';
  RAISE NOTICE '';
  RAISE NOTICE 'UI Prompt: Enter unlock reason';
  RAISE NOTICE '  Reason: "Updating incident description per OSHA inspector request"';
  RAISE NOTICE '';
  
  -- Unlock the period
  PERFORM osha_ita_v1.unlock_period(
    v_est_id,
    2024,
    v_user_id,
    'Updating incident description per OSHA inspector request'
  );
  
  RAISE NOTICE '✓ Period unlocked';
  RAISE NOTICE '';
  RAISE NOTICE 'Action: Navigate to Incidents > Case 2024-001 > Edit';
  
  -- Make the correction
  SELECT incident_id INTO v_incident_id
  FROM osha_ita_v1.incidents
  WHERE case_number = '2024-001';
  
  UPDATE osha_ita_v1.incidents
  SET incident_description = 'Back strain while lifting heavy equipment without assistance',
      nar_injury_illness = 'Lower back strain, muscle spasm - evaluated by orthopedic specialist',
      updated_by = v_user_id
  WHERE incident_id = v_incident_id;
  
  RAISE NOTICE '✓ Updated incident description';
  RAISE NOTICE '✓ Updated injury narrative';
  RAISE NOTICE '';
  RAISE NOTICE 'Action: Click "Save Changes"';
  
  -- Regenerate forms
  RAISE NOTICE '';
  RAISE NOTICE 'Regenerating OSHA forms with corrections...';
  PERFORM osha_ita_v1.rebuild_all_projections(v_est_id, 2024);
  
  RAISE NOTICE '✓ Forms regenerated';
  RAISE NOTICE '';
  RAISE NOTICE 'Action: Re-lock the period';
  
  -- Re-lock
  PERFORM osha_ita_v1.lock_period(
    v_est_id,
    2024,
    v_user_id,
    'Corrections complete, re-locking for compliance'
  );
  
  RAISE NOTICE '✓ Period re-locked';
END $$;

-- ============================================================================
-- STEP 23: AUDIT TRAIL REVIEW
-- ============================================================================
DO $$ 
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> STEP 23: Audit Trail Review';
  RAISE NOTICE 'Action: Navigate to System > Audit Log';
  RAISE NOTICE '';
END $$;

RAISE NOTICE '========== INCIDENT UPDATE HISTORY ==========';
RAISE NOTICE '';
SELECT 
  case_number,
  current_state,
  created_at,
  updated_at,
  EXTRACT(EPOCH FROM (updated_at - created_at))/3600 as hours_in_system
FROM osha_ita_v1.incidents
WHERE filing_year = 2024
ORDER BY updated_at DESC;

RAISE NOTICE '';
RAISE NOTICE '========== PERIOD LOCK HISTORY ==========';
RAISE NOTICE '';
SELECT 
  filing_year,
  is_locked,
  locked_at,
  lock_reason,
  unlocked_at,
  unlock_reason
FROM osha_ita_v1.period_locks
ORDER BY locked_at DESC;

-- ============================================================================
-- FINAL DASHBOARD
-- ============================================================================
DO $$ 
DECLARE
  v_total_incidents int;
  v_approved_incidents int;
  v_draft_incidents int;
  v_total_forms_300 int;
  v_total_forms_301 int;
  v_certifications int;
  v_successful_submissions int;
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '>>> FINAL COMPLIANCE DASHBOARD';
  RAISE NOTICE '';
  
  SELECT COUNT(*) INTO v_total_incidents
  FROM osha_ita_v1.incidents WHERE filing_year = 2024;
  
  SELECT COUNT(*) INTO v_approved_incidents
  FROM osha_ita_v1.incidents 
  WHERE filing_year = 2024 AND current_state = 'approved';
  
  SELECT COUNT(*) INTO v_draft_incidents
  FROM osha_ita_v1.incidents 
  WHERE filing_year = 2024 AND current_state = 'draft';
  
  SELECT COUNT(*) INTO v_total_forms_300
  FROM osha_ita_v1.form_300_log 
  WHERE filing_year = 2024 AND is_current = true;
  
  SELECT COUNT(*) INTO v_total_forms_301
  FROM osha_ita_v1.form_301_reports 
  WHERE year_of_filing = 2024 AND is_current = true;
  
  SELECT COUNT(*) INTO v_certifications
  FROM osha_ita_v1.form_300a_summaries 
  WHERE filing_year = 2024 AND certified_at IS NOT NULL;
  
  SELECT COUNT(*) INTO v_successful_submissions
  FROM osha_ita_v1.ita_submissions 
  WHERE filing_year = 2024 AND status = 'succeeded';
  
  RAISE NOTICE '================================================';
  RAISE NOTICE '        2024 COMPLIANCE DASHBOARD';
  RAISE NOTICE '================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Incidents:';
  RAISE NOTICE '  Total: %', v_total_incidents;
  RAISE NOTICE '  Approved: %', v_approved_incidents;
  RAISE NOTICE '  Draft: %', v_draft_incidents;
  RAISE NOTICE '';
  RAISE NOTICE 'OSHA Forms:';
  RAISE NOTICE '  Form 300 Entries: %', v_total_forms_300;
  RAISE NOTICE '  Form 301 Reports: %', v_total_forms_301;
  RAISE NOTICE '  Form 300A Certified: %', v_certifications;
  RAISE NOTICE '';
  RAISE NOTICE 'ITA Submissions:';
  RAISE NOTICE '  Successful: %', v_successful_submissions;
  RAISE NOTICE '';
  RAISE NOTICE 'Compliance Status: ✓ COMPLIANT';
  RAISE NOTICE '';
  RAISE NOTICE '================================================';
END $$;

-- ============================================================================
-- WORKFLOW COMPLETION SUMMARY
-- ============================================================================
DO $$ 
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '';
  RAISE NOTICE '================================================';
  RAISE NOTICE '    WORKFLOW SIMULATION COMPLETE!';
  RAISE NOTICE '================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Successfully Simulated:';
  RAISE NOTICE '  ✓ User login and dashboard access';
  RAISE NOTICE '  ✓ Establishment creation';
  RAISE NOTICE '  ✓ Manual incident entry (3 incidents)';
  RAISE NOTICE '  ✓ Draft incident review';
  RAISE NOTICE '  ✓ Submit for review workflow';
  RAISE NOTICE '  ✓ Approval process';
  RAISE NOTICE '  ✓ OSHA form generation (300, 301, 300A)';
  RAISE NOTICE '  ✓ Employment data entry';
  RAISE NOTICE '  ✓ Form 300A certification';
  RAISE NOTICE '  ✓ Safety metrics calculation';
  RAISE NOTICE '  ✓ Period locking';
  RAISE NOTICE '  ✓ ITA submission creation';
  RAISE NOTICE '  ✓ API submission to OSHA';
  RAISE NOTICE '  ✓ Submission confirmation';
  RAISE NOTICE '  ✓ Trend analysis';
  RAISE NOTICE '  ✓ Unlock and correction workflow';
  RAISE NOTICE '  ✓ Audit trail tracking';
  RAISE NOTICE '';
  RAISE NOTICE 'All systems operational!';
  RAISE NOTICE 'Database ready for production use.';
  RAISE NOTICE '';
  RAISE NOTICE '================================================';
END $$;