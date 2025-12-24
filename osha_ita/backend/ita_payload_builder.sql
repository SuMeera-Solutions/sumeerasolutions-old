-- ============================================================================
-- OSHA ITA API PAYLOAD GENERATION FUNCTIONS
-- Complete implementation based on API specifications
-- ============================================================================

-- ============================================================================
-- MAPPING FUNCTIONS (Text codes to ITA integer codes)
-- ============================================================================

CREATE OR REPLACE FUNCTION osha_ita_v1.map_outcome_to_ita(outcome_code text)
RETURNS integer LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE outcome_code
    WHEN 'death' THEN 1
    WHEN 'days_away' THEN 2
    WHEN 'job_transfer_restriction' THEN 3
    WHEN 'other_recordable' THEN 4
    ELSE NULL
  END;
$$;

CREATE OR REPLACE FUNCTION osha_ita_v1.map_type_to_ita(type_code text)
RETURNS integer LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE type_code
    WHEN 'injury' THEN 1
    WHEN 'skin_disorder' THEN 2
    WHEN 'respiratory_condition' THEN 3
    WHEN 'poisoning' THEN 4
    WHEN 'hearing_loss' THEN 5
    WHEN 'other_illness' THEN 6
    ELSE NULL
  END;
$$;

CREATE OR REPLACE FUNCTION osha_ita_v1.map_no_injuries_to_ita(has_injuries boolean)
RETURNS integer LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE 
    WHEN has_injuries THEN 1  -- has injuries/illnesses
    ELSE 2  -- no injuries/illnesses
  END;
$$;

-- ============================================================================
-- CASE DATA (Form 300/301) PAYLOAD BUILDER
-- ============================================================================

CREATE OR REPLACE FUNCTION osha_ita_v1.build_case_data_payload(p_incident_id uuid)
RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE
  v_payload jsonb;
  v_incident osha_ita_v1.incidents%ROWTYPE;
  v_est_id text;
  v_est_name text;
BEGIN
  -- Get incident data
  SELECT * INTO v_incident 
  FROM osha_ita_v1.incidents 
  WHERE incident_id = p_incident_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Incident % not found', p_incident_id;
  END IF;
  
  -- Get establishment data
  SELECT establishment_id::text, establishment_name 
  INTO v_est_id, v_est_name
  FROM osha_ita_v1.establishments 
  WHERE establishment_id = v_incident.establishment_id;
  
  -- Build payload according to ITA API spec
  v_payload := jsonb_build_object(
    'establishment', jsonb_build_object(
      'id', v_est_id,
      'establishment_name', v_est_name
    ),
    'case_number', v_incident.case_number,
    'job_title', v_incident.job_title,
    'date_of_incident', to_char(v_incident.date_of_incident, 'MM-DD-YYYY'),
    'incident_location', v_incident.incident_location,
    'incident_description', v_incident.incident_description,
    'incident_outcome', osha_ita_v1.map_outcome_to_ita(v_incident.incident_outcome)::text,
    'type_of_incident', osha_ita_v1.map_type_to_ita(v_incident.type_of_incident)::text,
    'date_of_birth', to_char(v_incident.date_of_birth, 'MM-DD-YYYY'),
    'date_of_hire', to_char(v_incident.date_of_hire, 'MM-DD-YYYY'),
    'treatment_facility_type', v_incident.treatment_facility_type::text,
    'treatment_in_patient', v_incident.treatment_in_patient::text,
    'nar_before_incident', v_incident.nar_before_incident,
    'nar_what_happened', v_incident.nar_what_happened,
    'nar_injury_illness', v_incident.nar_injury_illness,
    'nar_object_substance', v_incident.nar_object_substance
  );
  
  -- Add optional fields only if they have values
  IF v_incident.dafw_num_away IS NOT NULL AND v_incident.dafw_num_away > 0 THEN
    v_payload := v_payload || jsonb_build_object('dafw_num_away', v_incident.dafw_num_away::text);
  END IF;
  
  IF v_incident.djtr_num_tr IS NOT NULL AND v_incident.djtr_num_tr > 0 THEN
    v_payload := v_payload || jsonb_build_object('djtr_num_tr', v_incident.djtr_num_tr::text);
  END IF;
  
  IF v_incident.sex IS NOT NULL THEN
    v_payload := v_payload || jsonb_build_object('sex', v_incident.sex);
  END IF;
  
  IF v_incident.time_started_work IS NOT NULL THEN
    v_payload := v_payload || jsonb_build_object('time_started_work', to_char(v_incident.time_started_work, 'HH24:MI'));
  END IF;
  
  IF v_incident.time_of_incident IS NOT NULL THEN
    v_payload := v_payload || jsonb_build_object('time_of_incident', to_char(v_incident.time_of_incident, 'HH24:MI'));
  END IF;
  
  IF v_incident.time_unknown THEN
    v_payload := v_payload || jsonb_build_object('time_unknown', '1');
  END IF;
  
  IF v_incident.date_of_death IS NOT NULL THEN
    v_payload := v_payload || jsonb_build_object('date_of_death', to_char(v_incident.date_of_death, 'MM-DD-YYYY'));
  END IF;
  
  RETURN v_payload;
END $$;

-- ============================================================================
-- FORM 300A PAYLOAD BUILDER
-- ============================================================================

CREATE OR REPLACE FUNCTION osha_ita_v1.build_form_300a_payload(
  p_establishment_id uuid,
  p_filing_year int
)
RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE
  v_payload jsonb;
  v_summary osha_ita_v1.form_300a_summaries%ROWTYPE;
  v_est_id text;
  v_est_name text;
BEGIN
  -- Get the current Form 300A summary
  SELECT * INTO v_summary
  FROM osha_ita_v1.form_300a_summaries
  WHERE establishment_id = p_establishment_id
    AND filing_year = p_filing_year
    AND is_current = true;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Form 300A not found for establishment % year %', p_establishment_id, p_filing_year;
  END IF;
  
  -- Get establishment data
  SELECT establishment_id::text, establishment_name 
  INTO v_est_id, v_est_name
  FROM osha_ita_v1.establishments 
  WHERE establishment_id = p_establishment_id;
  
  -- Build payload according to ITA API spec
  v_payload := jsonb_build_object(
    'establishment', jsonb_build_object(
      'id', v_est_id,
      'establishment_name', v_est_name
    ),
    'annual_average_employees', v_summary.annual_average_employees::text,
    'total_hours_worked', v_summary.total_hours_worked::text,
    'no_injuries_illnesses', osha_ita_v1.map_no_injuries_to_ita(v_summary.no_injuries_illnesses)::text,
    'total_deaths', v_summary.total_deaths::text,
    'total_dafw_cases', v_summary.total_dafw_cases::text,
    'total_djtr_cases', v_summary.total_djtr_cases::text,
    'total_other_cases', v_summary.total_other_cases::text,
    'total_dafw_days', v_summary.total_dafw_days::text,
    'total_djtr_days', v_summary.total_djtr_days::text,
    'total_injuries', v_summary.total_injuries::text,
    'total_skin_disorders', v_summary.total_skin_disorders::text,
    'total_respiratory_conditions', v_summary.total_respiratory_conditions::text,
    'total_poisonings', v_summary.total_poisonings::text,
    'total_hearing_loss', v_summary.total_hearing_loss::text,
    'total_other_illnesses', v_summary.total_other_illnesses::text
  );
  
  RETURN v_payload;
END $$;

-- ============================================================================
-- COMPLETE SUBMISSION PAYLOAD BUILDER
-- Per the "Complete Submission" endpoint spec
-- ============================================================================

CREATE OR REPLACE FUNCTION osha_ita_v1.build_complete_submission_payload(
  p_establishment_id uuid,
  p_filing_year int,
  p_change_reason text DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE
  v_payload jsonb;
BEGIN
  v_payload := jsonb_build_object(
    'establishment_id', p_establishment_id::text,
    'year_filing_for', p_filing_year::text
  );
  
  IF p_change_reason IS NOT NULL THEN
    v_payload := v_payload || jsonb_build_object('change_reason', p_change_reason);
  END IF;
  
  RETURN v_payload;
END $$;

-- ============================================================================
-- BATCH CASE DATA PAYLOAD BUILDER
-- For submitting multiple cases at once
-- ============================================================================

CREATE OR REPLACE FUNCTION osha_ita_v1.build_batch_case_data_payload(
  p_establishment_id uuid,
  p_filing_year int
)
RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE
  v_cases jsonb := '[]'::jsonb;
  v_incident_id uuid;
BEGIN
  -- Get all approved incidents for this establishment/year
  FOR v_incident_id IN
    SELECT incident_id 
    FROM osha_ita_v1.incidents
    WHERE establishment_id = p_establishment_id
      AND filing_year = p_filing_year
      AND current_state = 'approved'
    ORDER BY case_number
  LOOP
    v_cases := v_cases || osha_ita_v1.build_case_data_payload(v_incident_id);
  END LOOP;
  
  RETURN v_cases;
END $$;

-- ============================================================================
-- ESTABLISHMENT PAYLOAD BUILDER
-- For creating/editing establishments via API
-- ============================================================================

CREATE OR REPLACE FUNCTION osha_ita_v1.build_establishment_payload(p_establishment_id uuid)
RETURNS jsonb LANGUAGE plpgsql AS $$
DECLARE
  v_payload jsonb;
  v_est osha_ita_v1.establishments%ROWTYPE;
  v_size_code text;
BEGIN
  SELECT * INTO v_est
  FROM osha_ita_v1.establishments
  WHERE establishment_id = p_establishment_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Establishment % not found', p_establishment_id;
  END IF;
  
  -- Determine size code based on establishment_type or add a size field to your schema
  -- For now, defaulting to '2' (20-99 employees) - you may need to add this field
  v_size_code := '2';
  
  v_payload := jsonb_build_object(
    'establishment_name', v_est.establishment_name,
    'company', jsonb_build_object(
      'company_name', COALESCE(v_est.establishment_name, 'Company Name') -- Add company_name field if needed
    ),
    'address', jsonb_build_object(
      'street', v_est.street_address,
      'city', v_est.city,
      'state', v_est.state,
      'zip', v_est.zip
    ),
    'naics', jsonb_build_object(
      'naics_code', v_est.naics_code,
      'industry_description', v_est.industry_description
    ),
    'size', v_size_code
  );
  
  -- Add optional fields
  IF v_est.establishment_type IS NOT NULL THEN
    v_payload := v_payload || jsonb_build_object('establishment_type', v_est.establishment_type::text);
  END IF;
  
  RETURN v_payload;
END $$;

-- ============================================================================
-- VALIDATION FUNCTION
-- Validates that an incident is ready for ITA submission
-- ============================================================================

CREATE OR REPLACE FUNCTION osha_ita_v1.validate_incident_for_ita(p_incident_id uuid)
RETURNS TABLE(is_valid boolean, errors jsonb) LANGUAGE plpgsql AS $$
DECLARE
  v_incident osha_ita_v1.incidents%ROWTYPE;
  v_errors jsonb := '[]'::jsonb;
BEGIN
  SELECT * INTO v_incident FROM osha_ita_v1.incidents WHERE incident_id = p_incident_id;
  
  IF NOT FOUND THEN
    RETURN QUERY SELECT false, jsonb_build_array(jsonb_build_object('error', 'Incident not found'));
    RETURN;
  END IF;
  
  -- Check required fields
  IF v_incident.case_number IS NULL THEN
    v_errors := v_errors || jsonb_build_object('field', 'case_number', 'message', 'Required');
  END IF;
  
  IF v_incident.job_title IS NULL THEN
    v_errors := v_errors || jsonb_build_object('field', 'job_title', 'message', 'Required');
  END IF;
  
  IF v_incident.date_of_incident IS NULL THEN
    v_errors := v_errors || jsonb_build_object('field', 'date_of_incident', 'message', 'Required');
  END IF;
  
  -- Validate outcome-specific fields
  IF v_incident.incident_outcome = 'death' AND v_incident.date_of_death IS NULL THEN
    v_errors := v_errors || jsonb_build_object('field', 'date_of_death', 'message', 'Required for death outcomes');
  END IF;
  
  IF v_incident.incident_outcome = 'days_away' AND (v_incident.dafw_num_away IS NULL OR v_incident.dafw_num_away = 0) THEN
    v_errors := v_errors || jsonb_build_object('field', 'dafw_num_away', 'message', 'Must be > 0 for days away outcome');
  END IF;
  
  -- Check state
  IF v_incident.current_state != 'approved' THEN
    v_errors := v_errors || jsonb_build_object('field', 'current_state', 'message', 'Incident must be approved before submission');
  END IF;
  
  RETURN QUERY SELECT (jsonb_array_length(v_errors) = 0), v_errors;
END $$;

-- ============================================================================
-- GET ALL INCIDENTS READY FOR SUBMISSION
-- ============================================================================

CREATE OR REPLACE FUNCTION osha_ita_v1.get_incidents_ready_for_ita(
  p_establishment_id uuid,
  p_filing_year int
)
RETURNS TABLE(
  incident_id uuid,
  case_number text,
  is_valid boolean,
  validation_errors jsonb
) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT 
    i.incident_id,
    i.case_number,
    v.is_valid,
    v.errors
  FROM osha_ita_v1.incidents i
  CROSS JOIN LATERAL osha_ita_v1.validate_incident_for_ita(i.incident_id) v
  WHERE i.establishment_id = p_establishment_id
    AND i.filing_year = p_filing_year
    AND i.current_state = 'approved'
  ORDER BY i.case_number;
END $$;




-- Get Form 300A payload
SELECT osha_ita_v1.build_form_300a_payload(establishment_id, 2024);

-- Get single case data payload
SELECT osha_ita_v1.build_case_data_payload(incident_id);

-- Get all cases for submission
SELECT osha_ita_v1.build_batch_case_data_payload(establishment_id, 2024);

-- Validate before submission
SELECT * FROM osha_ita_v1.get_incidents_ready_for_ita(establishment_id, 2024);

-- Complete submission payload
SELECT osha_ita_v1.build_complete_submission_payload(establishment_id, 2024, 'Correcting data per OSHA feedback');