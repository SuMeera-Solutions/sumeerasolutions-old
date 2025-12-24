-- ============================================================================
-- OSHA ITA Complete Database Schema
-- Database: compliease_sbx
-- Schema: osha_ita_v1
-- ============================================================================

-- Connect to the database
\c compliease_sbx

-- Create required extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create schema
CREATE SCHEMA IF NOT EXISTS osha_ita_v1 AUTHORIZATION postgres;

-- ============================================================================
-- ESTABLISHMENTS
-- ============================================================================
CREATE TABLE osha_ita_v1.establishments (
  establishment_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  establishment_name varchar(100) NOT NULL,
  street_address varchar(255),
  city varchar(100),
  state varchar(2),
  zip varchar(10),
  naics_code varchar(6),
  industry_description varchar(255),
  establishment_type integer,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  is_active boolean NOT NULL DEFAULT true,
  CONSTRAINT uk_establishment_name UNIQUE(establishment_name)
);

CREATE INDEX idx_establishments_active 
  ON osha_ita_v1.establishments(is_active) 
  WHERE is_active;

-- ============================================================================
-- LOOKUP TABLES
-- ============================================================================
CREATE TABLE osha_ita_v1.lu_incident_state (
  code text PRIMARY KEY,
  sort_order int NOT NULL
);

INSERT INTO osha_ita_v1.lu_incident_state(code, sort_order) VALUES
  ('draft', 1),
  ('in_review', 2),
  ('approved', 3),
  ('submitted', 4),
  ('superseded', 5),
  ('void', 99)
ON CONFLICT DO NOTHING;

CREATE TABLE osha_ita_v1.lu_incident_outcome (
  code text PRIMARY KEY,
  sort_order int NOT NULL
);

INSERT INTO osha_ita_v1.lu_incident_outcome(code, sort_order) VALUES
  ('death', 1),
  ('days_away', 2),
  ('job_transfer_restriction', 3),
  ('other_recordable', 4)
ON CONFLICT DO NOTHING;

CREATE TABLE osha_ita_v1.lu_incident_type (
  code text PRIMARY KEY,
  sort_order int NOT NULL
);

INSERT INTO osha_ita_v1.lu_incident_type(code, sort_order) VALUES
  ('injury', 1),
  ('skin_disorder', 2),
  ('respiratory_condition', 3),
  ('poisoning', 4),
  ('hearing_loss', 5),
  ('other_illness', 6)
ON CONFLICT DO NOTHING;

-- State transition control table
CREATE TABLE osha_ita_v1.incident_state_transition (
  from_state text REFERENCES osha_ita_v1.lu_incident_state(code),
  to_state text REFERENCES osha_ita_v1.lu_incident_state(code),
  is_allowed boolean NOT NULL DEFAULT true,
  PRIMARY KEY(from_state, to_state)
);

INSERT INTO osha_ita_v1.incident_state_transition(from_state, to_state) VALUES
  ('draft', 'in_review'),
  ('in_review', 'approved'),
  ('approved', 'submitted'),
  ('in_review', 'draft'),
  ('approved', 'draft'),
  ('submitted', 'superseded'),
  ('draft', 'void'),
  ('in_review', 'void'),
  ('approved', 'void')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- INCIDENTS
-- ============================================================================
CREATE TABLE osha_ita_v1.incidents (
  incident_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  establishment_id uuid NOT NULL REFERENCES osha_ita_v1.establishments(establishment_id),
  case_number text NOT NULL,
  filing_year int NOT NULL,
  current_state text NOT NULL REFERENCES osha_ita_v1.lu_incident_state(code) DEFAULT 'draft',
  version int NOT NULL DEFAULT 1,
  is_privacy_case boolean NOT NULL DEFAULT false,

  date_of_incident date NOT NULL,
  time_of_incident time,
  time_unknown boolean DEFAULT false,
  time_started_work time,

  incident_location varchar(255) NOT NULL,
  incident_description varchar(255) NOT NULL,

  job_title varchar(255) NOT NULL,
  date_of_birth date NOT NULL,
  date_of_hire date NOT NULL,
  sex char(1) CHECK (sex IN ('M', 'F') OR sex IS NULL),

  incident_outcome text NOT NULL REFERENCES osha_ita_v1.lu_incident_outcome(code),
  type_of_incident text NOT NULL REFERENCES osha_ita_v1.lu_incident_type(code),

  dafw_num_away int DEFAULT 0 CHECK (dafw_num_away >= 0 AND dafw_num_away <= 180),
  djtr_num_tr int DEFAULT 0 CHECK (djtr_num_tr >= 0 AND djtr_num_tr <= 180),

  date_of_death date,
  treatment_facility_type int CHECK (treatment_facility_type IN (0, 1)),
  treatment_in_patient int CHECK (treatment_in_patient IN (0, 1)),

  nar_before_incident text NOT NULL,
  nar_what_happened text NOT NULL,
  nar_injury_illness text NOT NULL,
  nar_object_substance text NOT NULL,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  updated_by uuid,

  is_locked boolean NOT NULL DEFAULT false,
  locked_at timestamptz,
  locked_by uuid,

  content_hash varchar(64),

  CONSTRAINT uk_case_unique UNIQUE(establishment_id, filing_year, case_number),
  CONSTRAINT valid_death_date CHECK (
    (incident_outcome = 'death' AND date_of_death IS NOT NULL) OR 
    (incident_outcome <> 'death')
  ),
  CONSTRAINT valid_dafw CHECK (
    (incident_outcome = 'days_away' AND dafw_num_away > 0) OR 
    (incident_outcome <> 'days_away')
  ),
  CONSTRAINT valid_djtr CHECK (
    (incident_outcome IN ('days_away', 'job_transfer_restriction') AND djtr_num_tr >= 0) OR
    (incident_outcome NOT IN ('days_away', 'job_transfer_restriction'))
  )
);

CREATE INDEX idx_incidents_estab_year 
  ON osha_ita_v1.incidents(establishment_id, filing_year);
CREATE INDEX idx_incidents_state 
  ON osha_ita_v1.incidents(current_state);
CREATE INDEX idx_incidents_hash 
  ON osha_ita_v1.incidents(content_hash) 
  WHERE content_hash IS NOT NULL;

-- ============================================================================
-- IMPORT SYSTEM
-- ============================================================================
CREATE TYPE osha_ita_v1.import_source AS ENUM (
  'csv', 'pdf', 'excel', 'api', 'manual'
);

CREATE TYPE osha_ita_v1.import_status AS ENUM (
  'pending', 'validating', 'mapping', 'promoting', 'completed', 'failed'
);

CREATE TYPE osha_ita_v1.row_status AS ENUM (
  'pending', 'valid', 'invalid', 'mapped', 'promoted', 'duplicate', 'skipped'
);

CREATE TABLE osha_ita_v1.import_batches (
  batch_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_type osha_ita_v1.import_source NOT NULL,
  filename varchar(255),
  file_size_bytes bigint,
  file_url text,
  filing_year int NOT NULL,
  status osha_ita_v1.import_status NOT NULL DEFAULT 'pending',
  total_rows int DEFAULT 0,
  valid_rows int DEFAULT 0,
  invalid_rows int DEFAULT 0,
  duplicate_rows int DEFAULT 0,
  promoted_rows int DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid,
  completed_at timestamptz,
  error_summary jsonb,
  idempotency_key varchar(255),
  content_hash varchar(64)
);

CREATE INDEX idx_import_batches_status 
  ON osha_ita_v1.import_batches(status);
CREATE INDEX idx_import_batches_year 
  ON osha_ita_v1.import_batches(filing_year);

CREATE TABLE osha_ita_v1.import_rows (
  row_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id uuid NOT NULL REFERENCES osha_ita_v1.import_batches(batch_id) ON DELETE CASCADE,
  row_number int NOT NULL,
  status osha_ita_v1.row_status NOT NULL DEFAULT 'pending',
  raw_data jsonb NOT NULL,
  mapped_data jsonb,
  validation_errors jsonb DEFAULT '[]'::jsonb,
  validation_warnings jsonb DEFAULT '[]'::jsonb,
  establishment_id uuid REFERENCES osha_ita_v1.establishments(establishment_id),
  incident_id uuid REFERENCES osha_ita_v1.incidents(incident_id),
  content_hash varchar(64),
  duplicate_of_row_id uuid REFERENCES osha_ita_v1.import_rows(row_id),
  created_at timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz,
  CONSTRAINT uk_batch_row UNIQUE(batch_id, row_number)
);

CREATE INDEX idx_import_rows_batch 
  ON osha_ita_v1.import_rows(batch_id);
CREATE INDEX idx_import_rows_status 
  ON osha_ita_v1.import_rows(status);

-- ============================================================================
-- FORM PROJECTIONS
-- ============================================================================
CREATE TABLE osha_ita_v1.form_300_log (
  log_entry_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  establishment_id uuid NOT NULL REFERENCES osha_ita_v1.establishments(establishment_id),
  incident_id uuid NOT NULL REFERENCES osha_ita_v1.incidents(incident_id),
  filing_year int NOT NULL,
  snapshot_data jsonb NOT NULL,
  case_number text NOT NULL,
  employee_name varchar(255),
  job_title varchar(255) NOT NULL,
  date_of_injury date NOT NULL,
  where_event_occurred varchar(255) NOT NULL,
  injury_description varchar(255) NOT NULL,
  death boolean DEFAULT false,
  days_away_from_work boolean DEFAULT false,
  job_transfer_restriction boolean DEFAULT false,
  other_recordable boolean DEFAULT false,
  days_away_count int DEFAULT 0,
  days_restricted_count int DEFAULT 0,
  is_injury boolean DEFAULT false,
  is_skin_disorder boolean DEFAULT false,
  is_respiratory boolean DEFAULT false,
  is_poisoning boolean DEFAULT false,
  is_hearing_loss boolean DEFAULT false,
  is_other_illness boolean DEFAULT false,
  projection_version int NOT NULL DEFAULT 1,
  projected_at timestamptz NOT NULL DEFAULT now(),
  projected_by uuid,
  is_current boolean NOT NULL DEFAULT true,
  superseded_at timestamptz,
  superseded_by_entry_id uuid REFERENCES osha_ita_v1.form_300_log(log_entry_id)
);

CREATE INDEX idx_form300_estab_year 
  ON osha_ita_v1.form_300_log(establishment_id, filing_year) 
  WHERE is_current;

CREATE TABLE osha_ita_v1.form_301_reports (
  report_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id uuid NOT NULL REFERENCES osha_ita_v1.incidents(incident_id),
  snapshot_data jsonb NOT NULL,
  establishment_name varchar(100) NOT NULL,
  year_of_filing int NOT NULL,
  case_number varchar(100) NOT NULL,
  job_title varchar(255) NOT NULL,
  date_of_incident date NOT NULL,
  incident_location varchar(255) NOT NULL,
  incident_description varchar(255) NOT NULL,
  incident_outcome text NOT NULL REFERENCES osha_ita_v1.lu_incident_outcome(code),
  dafw_num_away int,
  djtr_num_tr int,
  type_of_incident text NOT NULL REFERENCES osha_ita_v1.lu_incident_type(code),
  date_of_birth date NOT NULL,
  date_of_hire date NOT NULL,
  sex char(1),
  treatment_facility_type int NOT NULL,
  treatment_in_patient int NOT NULL,
  time_started_work time,
  time_of_incident time,
  time_unknown boolean,
  nar_before_incident text NOT NULL,
  nar_what_happened text NOT NULL,
  nar_injury_illness text NOT NULL,
  nar_object_substance text NOT NULL,
  date_of_death date,
  projection_version int NOT NULL DEFAULT 1,
  projected_at timestamptz NOT NULL DEFAULT now(),
  projected_by uuid,
  is_current boolean NOT NULL DEFAULT true,
  superseded_at timestamptz,
  superseded_by_report_id uuid REFERENCES osha_ita_v1.form_301_reports(report_id)
);

CREATE INDEX idx_form301_incident 
  ON osha_ita_v1.form_301_reports(incident_id) 
  WHERE is_current;

CREATE TABLE osha_ita_v1.form_300a_summaries (
  summary_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  establishment_id uuid NOT NULL REFERENCES osha_ita_v1.establishments(establishment_id),
  filing_year int NOT NULL,
  establishment_name varchar(100) NOT NULL,
  company_name varchar(255),
  ein varchar(9),
  street_address varchar(255),
  city varchar(100),
  state varchar(2),
  zip varchar(10),
  naics_code varchar(6),
  industry_description varchar(255),
  establishment_type integer,
  annual_average_employees int NOT NULL,
  total_hours_worked bigint NOT NULL,
  no_injuries_illnesses boolean DEFAULT false,
  total_deaths int DEFAULT 0,
  total_dafw_cases int DEFAULT 0,
  total_djtr_cases int DEFAULT 0,
  total_other_cases int DEFAULT 0,
  total_dafw_days int DEFAULT 0,
  total_djtr_days int DEFAULT 0,
  total_injuries int DEFAULT 0,
  total_skin_disorders int DEFAULT 0,
  total_respiratory_conditions int DEFAULT 0,
  total_poisonings int DEFAULT 0,
  total_hearing_loss int DEFAULT 0,
  total_other_illnesses int DEFAULT 0,
  certified_by uuid,
  certified_at timestamptz,
  certifier_name varchar(255),
  certifier_title varchar(255),
  projection_version int NOT NULL DEFAULT 1,
  projected_at timestamptz NOT NULL DEFAULT now(),
  projected_by uuid,
  is_current boolean NOT NULL DEFAULT true,
  superseded_at timestamptz,
  superseded_by_summary_id uuid REFERENCES osha_ita_v1.form_300a_summaries(summary_id),
  CONSTRAINT uk_estab_year UNIQUE(establishment_id, filing_year, projection_version)
);

CREATE INDEX idx_form300a_estab_year 
  ON osha_ita_v1.form_300a_summaries(establishment_id, filing_year) 
  WHERE is_current;

-- ============================================================================
-- PERIOD LOCKS
-- ============================================================================
CREATE TABLE osha_ita_v1.period_locks (
  lock_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  establishment_id uuid NOT NULL REFERENCES osha_ita_v1.establishments(establishment_id),
  filing_year int NOT NULL,
  is_locked boolean NOT NULL DEFAULT true,
  locked_at timestamptz NOT NULL DEFAULT now(),
  locked_by uuid NOT NULL,
  lock_reason text,
  unlocked_at timestamptz,
  unlocked_by uuid,
  unlock_reason text,
  lock_snapshot jsonb,
  CONSTRAINT uk_period_lock UNIQUE(establishment_id, filing_year)
);

-- ============================================================================
-- SUBMISSIONS
-- ============================================================================
CREATE TYPE osha_ita_v1.submission_status AS ENUM (
  'pending', 'in_progress', 'succeeded', 'failed', 'superseded'
);

CREATE TABLE osha_ita_v1.ita_submissions (
  submission_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  establishment_id uuid NOT NULL REFERENCES osha_ita_v1.establishments(establishment_id),
  filing_year int NOT NULL,
  submission_type varchar(20) NOT NULL CHECK (submission_type IN ('form_300a', 'form_300_301')),
  status osha_ita_v1.submission_status NOT NULL DEFAULT 'pending',
  payload jsonb NOT NULL,
  payload_hash varchar(64),
  request_sent_at timestamptz,
  response_received_at timestamptz,
  http_status_code int,
  response_body jsonb,
  ita_submission_id varchar(255),
  ita_confirmation_number varchar(255),
  submission_version int NOT NULL DEFAULT 1,
  supersedes_submission_id uuid REFERENCES osha_ita_v1.ita_submissions(submission_id),
  superseded_by_submission_id uuid REFERENCES osha_ita_v1.ita_submissions(submission_id),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  error_message text,
  retry_count int DEFAULT 0,
  idempotency_key varchar(255) UNIQUE
);

CREATE INDEX idx_ita_submissions_estab_year 
  ON osha_ita_v1.ita_submissions(establishment_id, filing_year);
CREATE INDEX idx_ita_submissions_status 
  ON osha_ita_v1.ita_submissions(status);

-- ============================================================================
-- ATTACHMENTS
-- ============================================================================
CREATE TABLE osha_ita_v1.attachments (
  attachment_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type varchar(50) NOT NULL,
  entity_id uuid NOT NULL,
  filename varchar(255) NOT NULL,
  file_size_bytes bigint NOT NULL,
  mime_type varchar(100),
  storage_url text NOT NULL,
  storage_key varchar(500) NOT NULL,
  is_public boolean NOT NULL DEFAULT false,
  signed_url_expires_at timestamptz,
  uploaded_at timestamptz NOT NULL DEFAULT now(),
  uploaded_by uuid NOT NULL,
  checksum varchar(64)
);

CREATE INDEX idx_attachments_entity 
  ON osha_ita_v1.attachments(entity_type, entity_id);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Incident content hash computation
CREATE OR REPLACE FUNCTION osha_ita_v1.compute_incident_hash(
  p_est uuid, 
  p_year int, 
  p_case text, 
  p_date date, 
  p_desc text, 
  p_what text
) RETURNS varchar(64) 
LANGUAGE sql IMMUTABLE AS $$
  SELECT encode(digest(
    lower(trim(p_est::text)) || '|' ||
    lower(trim(p_year::text)) || '|' ||
    lower(trim(p_case)) || '|' ||
    p_date::text || '|' ||
    lower(trim(p_desc)) || '|' ||
    lower(trim(coalesce(p_what, '')))
  , 'sha256'), 'hex');
$$;

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION osha_ita_v1.touch_updated_at()
RETURNS trigger 
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP IN ('INSERT', 'UPDATE') AND NEW IS DISTINCT FROM OLD THEN
    NEW.updated_at := now();
  END IF;
  RETURN NEW;
END $$;

-- ============================================================================
-- TRIGGER FUNCTIONS
-- ============================================================================

-- Set incident hash on insert/update
CREATE OR REPLACE FUNCTION osha_ita_v1.set_incident_hash() 
RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.content_hash := osha_ita_v1.compute_incident_hash(
    NEW.establishment_id, 
    NEW.filing_year, 
    NEW.case_number, 
    NEW.date_of_incident,
    NEW.incident_description, 
    NEW.nar_what_happened
  );
  RETURN NEW;
END $$;

-- Guard state transitions
CREATE OR REPLACE FUNCTION osha_ita_v1.guard_state_transition() 
RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE 
  ok bool;
BEGIN
  IF TG_OP = 'INSERT' OR NEW.current_state = OLD.current_state THEN
    RETURN NEW;
  END IF;

  SELECT is_allowed INTO ok
  FROM osha_ita_v1.incident_state_transition
  WHERE from_state = OLD.current_state 
    AND to_state = NEW.current_state;

  IF NOT coalesce(ok, false) THEN
    RAISE EXCEPTION 'Invalid state transition % -> %', OLD.current_state, NEW.current_state;
  END IF;

  RETURN NEW;
END $$;

-- Guard period locks
CREATE OR REPLACE FUNCTION osha_ita_v1.guard_period_lock() 
RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE 
  is_locked bool;
BEGIN
  SELECT pl.is_locked INTO is_locked
  FROM osha_ita_v1.period_locks pl
  WHERE pl.establishment_id = NEW.establishment_id
    AND pl.filing_year = NEW.filing_year
    AND pl.is_locked = true;
    
  IF is_locked THEN
    RAISE EXCEPTION 'Locked period for establishment %, year %', 
      NEW.establishment_id, NEW.filing_year;
  END IF;
  
  RETURN NEW;
END $$;

-- ============================================================================
-- CREATE TRIGGERS
-- ============================================================================

-- Incident hash trigger
CREATE TRIGGER trg_incident_hash
  BEFORE INSERT OR UPDATE ON osha_ita_v1.incidents
  FOR EACH ROW 
  EXECUTE FUNCTION osha_ita_v1.set_incident_hash();

-- State transition guard
CREATE TRIGGER trg_state_guard
  BEFORE UPDATE OF current_state ON osha_ita_v1.incidents
  FOR EACH ROW 
  EXECUTE FUNCTION osha_ita_v1.guard_state_transition();

-- Period lock guard
CREATE TRIGGER trg_lock_incidents
  BEFORE INSERT OR UPDATE ON osha_ita_v1.incidents
  FOR EACH ROW 
  EXECUTE FUNCTION osha_ita_v1.guard_period_lock();

-- Updated_at triggers
CREATE TRIGGER trg_touch_establishments
  BEFORE UPDATE ON osha_ita_v1.establishments
  FOR EACH ROW 
  EXECUTE FUNCTION osha_ita_v1.touch_updated_at();

CREATE TRIGGER trg_touch_incidents
  BEFORE UPDATE ON osha_ita_v1.incidents
  FOR EACH ROW 
  EXECUTE FUNCTION osha_ita_v1.touch_updated_at();

-- ============================================================================
-- IMPORT VALIDATION FUNCTION
-- ============================================================================
CREATE OR REPLACE FUNCTION osha_ita_v1.validate_import_row(p_row_id uuid)
RETURNS jsonb 
LANGUAGE plpgsql AS $$
DECLARE 
  v_row osha_ita_v1.import_rows%ROWTYPE;
  v_errors jsonb := '[]'::jsonb;
  v_warnings jsonb := '[]'::jsonb;
  v_est uuid;
BEGIN
  SELECT * INTO v_row 
  FROM osha_ita_v1.import_rows 
  WHERE row_id = p_row_id;

  -- Validate establishment name
  IF v_row.raw_data->>'establishment_name' IS NULL THEN
    v_errors := v_errors || jsonb_build_array(
      jsonb_build_object('field', 'establishment_name', 'message', 'Required')
    );
  END IF;

  -- Validate filing year
  IF v_row.raw_data->>'year_of_filing' IS NULL OR 
     (v_row.raw_data->>'year_of_filing') !~ '^\d{4}$' THEN
    v_errors := v_errors || jsonb_build_array(
      jsonb_build_object('field', 'year_of_filing', 'message', '4-digit year required')
    );
  END IF;

  -- Validate case number
  IF v_row.raw_data->>'case_number' IS NULL THEN
    v_errors := v_errors || jsonb_build_array(
      jsonb_build_object('field', 'case_number', 'message', 'Required')
    );
  END IF;

  -- Look up establishment
  SELECT establishment_id INTO v_est
  FROM osha_ita_v1.establishments
  WHERE establishment_name = v_row.raw_data->>'establishment_name'
    AND is_active = true;

  IF v_est IS NULL THEN
    v_errors := v_errors || jsonb_build_array(
      jsonb_build_object('field', 'establishment_name', 'message', 'Unknown establishment')
    );
  END IF;

  -- Update row with validation results
  UPDATE osha_ita_v1.import_rows
  SET validation_errors = v_errors,
      validation_warnings = v_warnings,
      establishment_id = v_est,
      status = CASE 
        WHEN jsonb_array_length(v_errors) = 0 THEN 'valid'::osha_ita_v1.row_status
        ELSE 'invalid'::osha_ita_v1.row_status 
      END,
      processed_at = now()
  WHERE row_id = p_row_id;

  RETURN jsonb_build_object(
    'row_id', p_row_id,
    'status', CASE WHEN jsonb_array_length(v_errors) = 0 THEN 'valid' ELSE 'invalid' END,
    'errors', v_errors,
    'warnings', v_warnings
  );
END $$;

-- ============================================================================
-- FORM PROJECTION FUNCTIONS
-- ============================================================================

-- Rebuild Form 301
CREATE OR REPLACE FUNCTION osha_ita_v1.rebuild_form_301(
  p_establishment_id uuid, 
  p_year int
)
RETURNS void 
LANGUAGE plpgsql AS $$
BEGIN
  -- Supersede current reports
  UPDATE osha_ita_v1.form_301_reports
  SET is_current = false, 
      superseded_at = now()
  WHERE report_id IN (
    SELECT report_id 
    FROM osha_ita_v1.form_301_reports r
    JOIN osha_ita_v1.incidents i ON i.incident_id = r.incident_id
    WHERE i.establishment_id = p_establishment_id
      AND i.filing_year = p_year
      AND r.is_current = true
  );

  -- Insert fresh snapshots from approved incidents
  INSERT INTO osha_ita_v1.form_301_reports(
    incident_id, snapshot_data,
    establishment_name, year_of_filing, case_number, job_title,
    date_of_incident, incident_location, incident_description,
    incident_outcome, dafw_num_away, djtr_num_tr, type_of_incident,
    date_of_birth, date_of_hire, sex, 
    treatment_facility_type, treatment_in_patient,
    time_started_work, time_of_incident, time_unknown,
    nar_before_incident, nar_what_happened, nar_injury_illness, nar_object_substance,
    date_of_death, projected_by
  )
  SELECT
    i.incident_id,
    to_jsonb(i.*) - 'content_hash' - 'created_by' - 'updated_by' AS snapshot_data,
    e.establishment_name, i.filing_year, i.case_number, i.job_title,
    i.date_of_incident, i.incident_location, i.incident_description,
    i.incident_outcome, i.dafw_num_away, i.djtr_num_tr, i.type_of_incident,
    i.date_of_birth, i.date_of_hire, i.sex, 
    i.treatment_facility_type, i.treatment_in_patient,
    i.time_started_work, i.time_of_incident, i.time_unknown,
    i.nar_before_incident, i.nar_what_happened, i.nar_injury_illness, i.nar_object_substance,
    i.date_of_death, NULL::uuid
  FROM osha_ita_v1.incidents i
  JOIN osha_ita_v1.establishments e ON e.establishment_id = i.establishment_id
  WHERE i.establishment_id = p_establishment_id
    AND i.filing_year = p_year
    AND i.current_state = 'approved';
END $$;
--issue
-- Rebuild Form 300
CREATE OR REPLACE FUNCTION osha_ita_v1.rebuild_form_300(
  p_establishment_id uuid, 
  p_year int
)
RETURNS void 
LANGUAGE plpgsql AS $$
BEGIN
  -- Supersede current entries
  UPDATE osha_ita_v1.form_300_log
  SET is_current = false, 
      superseded_at = now()
  WHERE is_current = true
    AND establishment_id = p_establishment_id
    AND filing_year = p_year;

  -- Insert new entries
  INSERT INTO osha_ita_v1.form_300_log(
    establishment_id, incident_id, filing_year, snapshot_data,
    case_number, employee_name, job_title, date_of_injury, where_event_occurred,
    injury_description, death, days_away_from_work, job_transfer_restriction, other_recordable,
    days_away_count, days_restricted_count,
    is_injury, is_skin_disorder, is_respiratory, is_poisoning, is_hearing_loss, is_other_illness
  )
  SELECT
    i.establishment_id, i.incident_id, i.filing_year,
    to_jsonb(i.*) - 'content_hash' - 'created_by' - 'updated_by',
    i.case_number,
    CASE WHEN i.is_privacy_case THEN 'Privacy Case' ELSE NULL END AS employee_name,
    i.job_title,
    i.date_of_incident AS date_of_injury,
    i.incident_location AS where_event_occurred,
    i.incident_description AS injury_description,
    (i.incident_outcome = 'death') AS death,
    (i.incident_outcome = 'days_away') AS days_away_from_work,
    (i.incident_outcome = 'job_transfer_restriction') AS job_transfer_restriction,
    (i.incident_outcome = 'other_recordable') AS other_recordable,
    COALESCE(i.dafw_num_away, 0) AS days_away_count,
    COALESCE(i.djtr_num_tr, 0) AS days_restricted_count,
    (i.type_of_incident = 'injury'),
    (i.type_of_incident = 'skin_disorder'),
    (i.type_of_incident = 'respiratory_condition'),
    (i.type_of_incident = 'poisoning'),
    (i.type_of_incident = 'hearing_loss'),
    (i.type_of_incident = 'other_illness')
  FROM osha_ita_v1.incidents i
  WHERE i.establishment_id = p_establishment_id
    AND i.filing_year = p_year
    AND i.current_state = 'approved'
    AND i.incident_outcome IN ('death', 'days_away', 'job_transfer_restriction', 'other_recordable');
END $$;

-- Rebuild Form 300A
CREATE OR REPLACE FUNCTION osha_ita_v1.rebuild_form_300a(
  p_establishment_id uuid, 
  p_year int
)
RETURNS void 
LANGUAGE plpgsql AS $$
DECLARE
  v_est osha_ita_v1.establishments%ROWTYPE;
  v_summary_id uuid;
BEGIN
  -- Get establishment details
  SELECT * INTO v_est
  FROM osha_ita_v1.establishments
  WHERE establishment_id = p_establishment_id;

  -- Supersede current summary
  UPDATE osha_ita_v1.form_300a_summaries
  SET is_current = false,
      superseded_at = now()
  WHERE establishment_id = p_establishment_id
    AND filing_year = p_year
    AND is_current = true;

  -- Insert new summary with aggregated data
  INSERT INTO osha_ita_v1.form_300a_summaries(
    establishment_id, filing_year,
    establishment_name, street_address, city, state, zip,
    naics_code, industry_description, establishment_type,
    annual_average_employees, total_hours_worked,
    no_injuries_illnesses,
    total_deaths, total_dafw_cases, total_djtr_cases, total_other_cases,
    total_dafw_days, total_djtr_days,
    total_injuries, total_skin_disorders, total_respiratory_conditions,
    total_poisonings, total_hearing_loss, total_other_illnesses
  )
  SELECT
    p_establishment_id,
    p_year,
    v_est.establishment_name,
    v_est.street_address,
    v_est.city,
    v_est.state,
    v_est.zip,
    v_est.naics_code,
    v_est.industry_description,
    v_est.establishment_type,
    0 AS annual_average_employees,
    0 AS total_hours_worked,
    (COUNT(*) = 0) AS no_injuries_illnesses,
    COUNT(*) FILTER (WHERE incident_outcome = 'death'),
    COUNT(*) FILTER (WHERE incident_outcome = 'days_away'),
    COUNT(*) FILTER (WHERE incident_outcome = 'job_transfer_restriction'),
    COUNT(*) FILTER (WHERE incident_outcome = 'other_recordable'),
    COALESCE(SUM(dafw_num_away) FILTER (WHERE incident_outcome = 'days_away'), 0),
    COALESCE(SUM(djtr_num_tr) FILTER (WHERE incident_outcome IN ('days_away', 'job_transfer_restriction')), 0),
    COUNT(*) FILTER (WHERE type_of_incident = 'injury'),
    COUNT(*) FILTER (WHERE type_of_incident = 'skin_disorder'),
    COUNT(*) FILTER (WHERE type_of_incident = 'respiratory_condition'),
    COUNT(*) FILTER (WHERE type_of_incident = 'poisoning'),
    COUNT(*) FILTER (WHERE type_of_incident = 'hearing_loss'),
    COUNT(*) FILTER (WHERE type_of_incident = 'other_illness')
  FROM osha_ita_v1.incidents
  WHERE establishment_id = p_establishment_id
    AND filing_year = p_year
    AND current_state = 'approved'
    AND incident_outcome IN ('death', 'days_away', 'job_transfer_restriction', 'other_recordable');
END $$;

-- Rebuild all projections
CREATE OR REPLACE FUNCTION osha_ita_v1.rebuild_all_projections(
  p_establishment_id uuid, 
  p_year int
)
RETURNS void 
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM osha_ita_v1.rebuild_form_301(p_establishment_id, p_year);
  PERFORM osha_ita_v1.rebuild_form_300(p_establishment_id, p_year);
  PERFORM osha_ita_v1.rebuild_form_300a(p_establishment_id, p_year);
END $$;

-- ============================================================================
-- PERIOD LOCK FUNCTIONS
-- ============================================================================

-- Lock a period
CREATE OR REPLACE FUNCTION osha_ita_v1.lock_period(
  p_establishment_id uuid, 
  p_year int, 
  p_user uuid, 
  p_reason text
)
RETURNS uuid 
LANGUAGE plpgsql AS $$
DECLARE 
  v_id uuid;
BEGIN
  INSERT INTO osha_ita_v1.period_locks(
    establishment_id, filing_year, is_locked, locked_by, lock_reason
  )
  VALUES (
    p_establishment_id, p_year, true, p_user, p_reason
  )
  ON CONFLICT (establishment_id, filing_year) DO UPDATE
    SET is_locked = true, 
        locked_at = now(), 
        locked_by = p_user, 
        lock_reason = p_reason, 
        unlocked_at = NULL, 
        unlocked_by = NULL, 
        unlock_reason = NULL
  RETURNING lock_id INTO v_id;
  
  RETURN v_id;
END $$;

-- Unlock a period
CREATE OR REPLACE FUNCTION osha_ita_v1.unlock_period(
  p_establishment_id uuid, 
  p_year int, 
  p_user uuid, 
  p_reason text
)
RETURNS void 
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE osha_ita_v1.period_locks
  SET is_locked = false, 
      unlocked_at = now(), 
      unlocked_by = p_user, 
      unlock_reason = p_reason
  WHERE establishment_id = p_establishment_id 
    AND filing_year = p_year;
END $$;

-- ============================================================================
-- IMPORT PROMOTION FUNCTION
-- ============================================================================

-- Promote valid rows to incidents
CREATE OR REPLACE FUNCTION osha_ita_v1.promote_valid_rows(p_batch_id uuid)
RETURNS int 
LANGUAGE plpgsql AS $$
DECLARE 
  v_row osha_ita_v1.import_rows%ROWTYPE;
  v_count int := 0;
  v_incident_id uuid;
BEGIN
  FOR v_row IN
    SELECT * 
    FROM osha_ita_v1.import_rows
    WHERE batch_id = p_batch_id 
      AND status = 'valid'::osha_ita_v1.row_status
  LOOP
    -- Generate content hash if missing
    IF v_row.content_hash IS NULL THEN
      UPDATE osha_ita_v1.import_rows
      SET content_hash = encode(
        digest(coalesce(v_row.mapped_data::text, v_row.raw_data::text), 'sha256'), 
        'hex'
      )
      WHERE row_id = v_row.row_id;
      
      SELECT * INTO v_row 
      FROM osha_ita_v1.import_rows 
      WHERE row_id = v_row.row_id;
    END IF;

    -- Check for duplicate
    SELECT i.incident_id INTO v_incident_id
    FROM osha_ita_v1.incidents i
    WHERE i.content_hash = v_row.content_hash
    LIMIT 1;

    IF v_incident_id IS NULL THEN
      -- Create new incident
      INSERT INTO osha_ita_v1.incidents(
        establishment_id, case_number, filing_year, current_state, is_privacy_case,
        date_of_incident, time_of_incident, time_unknown, time_started_work,
        incident_location, incident_description,
        job_title, date_of_birth, date_of_hire, sex,
        incident_outcome, type_of_incident,
        dafw_num_away, djtr_num_tr, date_of_death,
        treatment_facility_type, treatment_in_patient,
        nar_before_incident, nar_what_happened, nar_injury_illness, nar_object_substance
      )
      VALUES (
        v_row.establishment_id,
        v_row.mapped_data->>'case_number',
        (v_row.mapped_data->>'filing_year')::int,
        'draft',
        COALESCE((v_row.mapped_data->>'is_privacy_case')::boolean, false),
        (v_row.mapped_data->>'date_of_incident')::date,
        (v_row.mapped_data->>'time_of_incident')::time,
        COALESCE((v_row.mapped_data->>'time_unknown')::boolean, false),
        (v_row.mapped_data->>'time_started_work')::time,
        v_row.mapped_data->>'incident_location',
        v_row.mapped_data->>'incident_description',
        v_row.mapped_data->>'job_title',
        (v_row.mapped_data->>'date_of_birth')::date,
        (v_row.mapped_data->>'date_of_hire')::date,
        NULLIF(v_row.mapped_data->>'sex', '')::char(1),
        v_row.mapped_data->>'incident_outcome',
        v_row.mapped_data->>'type_of_incident',
        NULLIF(v_row.mapped_data->>'dafw_num_away', '')::int,
        NULLIF(v_row.mapped_data->>'djtr_num_tr', '')::int,
        NULLIF(v_row.mapped_data->>'date_of_death', '')::date,
        NULLIF(v_row.mapped_data->>'treatment_facility_type', '')::int,
        NULLIF(v_row.mapped_data->>'treatment_in_patient', '')::int,
        v_row.mapped_data->>'nar_before_incident',
        v_row.mapped_data->>'nar_what_happened',
        v_row.mapped_data->>'nar_injury_illness',
        v_row.mapped_data->>'nar_object_substance'
      )
      RETURNING incident_id INTO v_incident_id;
    END IF;

    -- Update import row
    UPDATE osha_ita_v1.import_rows
    SET status = 'promoted'::osha_ita_v1.row_status,
        incident_id = v_incident_id,
        processed_at = now()
    WHERE row_id = v_row.row_id;

    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END $$;

-- ============================================================================
-- SUBMISSION FUNCTIONS
-- ============================================================================

-- Create a submission
CREATE OR REPLACE FUNCTION osha_ita_v1.create_submission(
  p_est uuid, 
  p_year int, 
  p_type text, 
  p_payload jsonb, 
  p_actor uuid
)
RETURNS uuid 
LANGUAGE plpgsql AS $$
DECLARE 
  v_id uuid := gen_random_uuid();
BEGIN
  INSERT INTO osha_ita_v1.ita_submissions(
    submission_id, establishment_id, filing_year, submission_type,
    status, payload, payload_hash, created_by
  )
  VALUES (
    v_id, p_est, p_year, p_type,
    'pending', p_payload,
    encode(digest(p_payload::text, 'sha256'), 'hex'),
    p_actor
  );
  
  RETURN v_id;
END $$;

-- Record submission attempt
CREATE OR REPLACE FUNCTION osha_ita_v1.record_submission_attempt(
  p_submission_id uuid,
  p_http_status int,
  p_response jsonb,
  p_success boolean
) 
RETURNS void 
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE osha_ita_v1.ita_submissions
  SET status = CASE WHEN p_success THEN 'succeeded'::osha_ita_v1.submission_status 
                    ELSE 'failed'::osha_ita_v1.submission_status END,
      http_status_code = p_http_status,
      response_body = p_response,
      request_sent_at = COALESCE(request_sent_at, now()),
      response_received_at = now(),
      ita_submission_id = COALESCE(p_response->>'submissionId', ita_submission_id),
      ita_confirmation_number = COALESCE(p_response->>'confirmationNumber', ita_confirmation_number)
  WHERE submission_id = p_submission_id;
END $$;

-- ============================================================================
-- CERTIFICATION FUNCTION
-- ============================================================================

-- Certify Form 300A
CREATE OR REPLACE FUNCTION osha_ita_v1.certify_300a(
  p_summary_id uuid, 
  p_certifier uuid, 
  p_name text, 
  p_title text
) 
RETURNS void 
LANGUAGE plpgsql AS $$
DECLARE 
  v_summary osha_ita_v1.form_300a_summaries%ROWTYPE;
BEGIN
  SELECT * INTO v_summary
  FROM osha_ita_v1.form_300a_summaries
  WHERE summary_id = p_summary_id 
    AND is_current = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Summary % not found or not current', p_summary_id;
  END IF;

  IF v_summary.annual_average_employees <= 0 OR v_summary.total_hours_worked <= 0 THEN
    RAISE EXCEPTION 'Cannot certify: annual_average_employees and total_hours_worked must be greater than zero';
  END IF;

  UPDATE osha_ita_v1.form_300a_summaries
  SET certified_by = p_certifier,
      certifier_name = p_name,
      certifier_title = p_title,
      certified_at = now()
  WHERE summary_id = p_summary_id;
END $$;

-- ============================================================================
-- USEFUL VIEWS
-- ============================================================================

-- Form 300 export view (handles privacy cases)
CREATE OR REPLACE VIEW osha_ita_v1.v_form_300_export AS
SELECT
  l.*,
  CASE 
    WHEN i.is_privacy_case THEN 'Privacy Case' 
    ELSE l.employee_name 
  END AS employee_name_export
FROM osha_ita_v1.form_300_log l
JOIN osha_ita_v1.incidents i ON i.incident_id = l.incident_id
WHERE l.is_current = true;

-- Current incidents summary view
CREATE OR REPLACE VIEW osha_ita_v1.v_current_incidents AS
SELECT
  i.*,
  e.establishment_name,
  e.city,
  e.state,
  ls.code AS state_description,
  lo.code AS outcome_description,
  lt.code AS type_description
FROM osha_ita_v1.incidents i
JOIN osha_ita_v1.establishments e ON e.establishment_id = i.establishment_id
JOIN osha_ita_v1.lu_incident_state ls ON ls.code = i.current_state
JOIN osha_ita_v1.lu_incident_outcome lo ON lo.code = i.incident_outcome
JOIN osha_ita_v1.lu_incident_type lt ON lt.code = i.type_of_incident
WHERE e.is_active = true;

-- Import batch summary view
CREATE OR REPLACE VIEW osha_ita_v1.v_import_batch_summary AS
SELECT
  b.*,
  COUNT(r.row_id) AS actual_row_count,
  COUNT(r.row_id) FILTER (WHERE r.status = 'valid') AS actual_valid_count,
  COUNT(r.row_id) FILTER (WHERE r.status = 'invalid') AS actual_invalid_count,
  COUNT(r.row_id) FILTER (WHERE r.status = 'promoted') AS actual_promoted_count,
  COUNT(r.row_id) FILTER (WHERE r.status = 'duplicate') AS actual_duplicate_count
FROM osha_ita_v1.import_batches b
LEFT JOIN osha_ita_v1.import_rows r ON r.batch_id = b.batch_id
GROUP BY b.batch_id;

-- ============================================================================
-- GRANT PERMISSIONS (adjust as needed for your roles)
-- ============================================================================

-- Grant usage on schema
GRANT USAGE ON SCHEMA osha_ita_v1 TO postgres;

-- Grant all on tables
GRANT ALL ON ALL TABLES IN SCHEMA osha_ita_v1 TO postgres;

-- Grant all on sequences
GRANT ALL ON ALL SEQUENCES IN SCHEMA osha_ita_v1 TO postgres;

-- Grant execute on functions
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA osha_ita_v1 TO postgres;

-- ============================================================================
-- SAMPLE DATA (optional - for testing)
-- ============================================================================

-- Insert sample establishment
INSERT INTO osha_ita_v1.establishments (
  establishment_name, street_address, city, state, zip, 
  naics_code, industry_description
) VALUES (
  'Sample Manufacturing Plant',
  '123 Industrial Way',
  'Houston',
  'TX',
  '77001',
  '333111',
  'Farm Machinery and Equipment Manufacturing'
) ON CONFLICT (establishment_name) DO NOTHING;

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'OSHA ITA Schema Installation Complete!';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Database: compliease_sbx';
  RAISE NOTICE 'Schema: osha_ita_v1';
  RAISE NOTICE '';
  RAISE NOTICE 'Created:';
  RAISE NOTICE '  - 14 Tables';
  RAISE NOTICE '  - 4 Enums';
  RAISE NOTICE '  - 3 Views';
  RAISE NOTICE '  - 15 Functions';
  RAISE NOTICE '  - 5 Triggers';
  RAISE NOTICE '';
  RAISE NOTICE 'Ready for use!';
  RAISE NOTICE '========================================';
END $$;



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







------

---Ita response submissions

--rbac and comapny isolatin


CREATE TABLE osha_ita_v1.companies (
  company_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name text UNIQUE NOT NULL,
  ein text, -- optional: corporate EIN
  created_at timestamptz DEFAULT now()
);

ALTER TABLE osha_ita_v1.establishments
  ADD COLUMN company_id uuid REFERENCES osha_ita_v1.companies(company_id),
  ADD COLUMN ein text; -- establishment EIN if different

-- Optional: per-establishment RBAC
CREATE TABLE osha_ita_v1.user_accounts (
  user_id uuid PRIMARY KEY,
  email text UNIQUE NOT NULL,
  full_name text
);

CREATE TABLE osha_ita_v1.user_establishment_roles (
  user_id uuid REFERENCES osha_ita_v1.user_accounts(user_id),
  establishment_id uuid REFERENCES osha_ita_v1.establishments(establishment_id),
  role text CHECK (role IN ('viewer','editor','approver','admin')),
  PRIMARY KEY (user_id, establishment_id)
);


-- lookups/filtering
CREATE INDEX idx_establishments_company ON osha_ita_v1.establishments(company_id);
CREATE INDEX idx_user_roles_user ON osha_ita_v1.user_establishment_roles(user_id);
CREATE INDEX idx_user_roles_estab ON osha_ita_v1.user_establishment_roles(establishment_id);

-- (optional) normalize emails & keep unique by lowercase
ALTER TABLE osha_ita_v1.user_accounts ADD COLUMN email_norm text GENERATED ALWAYS AS (lower(email)) STORED;
CREATE UNIQUE INDEX uq_user_accounts_email_norm ON osha_ita_v1.user_accounts(email_norm);

-- (optional) keep establishment names unique *within* a company (instead of globally)
-- run only if you want duplicate names across different companies:
DROP INDEX IF EXISTS osha_ita_v1.uk_establishment_name;
CREATE UNIQUE INDEX uq_estab_company_name
  ON osha_ita_v1.establishments(company_id, establishment_name)
  WHERE establishment_name IS NOT NULL AND company_id IS NOT NULL;


-- example backfill
INSERT INTO osha_ita_v1.companies (company_id, company_name)
SELECT gen_random_uuid(), 'Default Company'
WHERE NOT EXISTS (SELECT 1 FROM osha_ita_v1.companies);

UPDATE osha_ita_v1.establishments e
SET company_id = (SELECT company_id FROM osha_ita_v1.companies LIMIT 1)
WHERE company_id IS NULL;

-- now you *could* enforce not null:
-- ALTER TABLE osha_ita_v1.establishments ALTER COLUMN company_id SET NOT NULL;


-- all incidents a user can see
SELECT i.*
FROM osha_ita_v1.incidents i
JOIN osha_ita_v1.user_establishment_roles r
  ON r.establishment_id = i.establishment_id
WHERE r.user_id = $1;

-- establishments a user can act on
SELECT e.*, r.role
FROM osha_ita_v1.establishments e
JOIN osha_ita_v1.user_establishment_roles r
  ON r.establishment_id = e.establishment_id
WHERE r.user_id = $1;
