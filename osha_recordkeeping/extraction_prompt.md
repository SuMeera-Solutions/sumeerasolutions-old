# Comprehensive 29 CFR Part 1904 Extraction Prompt

## Objective
Extract ALL information from the 29 CFR Part 1904 PDF document and structure it according to the predefined JSON architecture. This is a complete, systematic extraction - not a summary.

## Target JSON Structure
Use the comprehensive JSON structure with these main sections:
- `regulation_metadata`
- `company_applicability` 
- `recording_criteria`
- `form_requirements`
- `ongoing_obligations`
- `government_reporting`
- `reference_data`
- `business_change_provisions`
- `variance_provisions`
- `state_plan_provisions`

## Extraction Instructions

### 1. SYSTEMATIC PAGE-BY-PAGE ANALYSIS
- Start from page 1 and proceed sequentially through every page
- Extract information from ALL sections: main text, footnotes, appendices, tables
- Do not skip any content - capture everything that has regulatory meaning

### 2. SUBPART-SPECIFIC EXTRACTION

**Subpart A (Purpose) → `regulation_metadata`**
- Extract purpose statements, legal authority, scope declarations
- Capture editorial notes and effective dates
- Note any disclaimers or clarifications

**Subpart B (Scope) → `company_applicability`**
- Extract ALL exemption criteria (size-based, industry-based)
- Capture implementation details and edge cases
- Extract ALL NAICS codes from appendices with exact industry descriptions
- Document coverage determination procedures

**Subpart C (Recording Criteria) → `recording_criteria` + `form_requirements`**
- Extract complete decision tree logic from flowcharts
- Capture ALL recording criteria with exact conditions
- Extract detailed form instructions and field requirements
- Document timing requirements precisely
- Capture ALL exceptions and special cases
- Extract complete definitions (first aid, medical treatment, etc.)

**Subpart D (Other Requirements) → `ongoing_obligations`**
- Extract retention requirements with exact timeframes
- Capture annual summary process steps in detail
- Document employee access rights and procedures
- Extract establishment-specific recordkeeping rules
- Capture update and correction requirements

**Subpart E (Government Reporting) → `government_reporting`**
- Extract ALL reporting triggers and deadlines
- Capture electronic submission requirements by company size/industry
- Document government access provisions
- Extract BLS survey requirements
- Capture all appendices with industry codes for electronic submission

**Subpart F (Transition) → `business_change_provisions`**
- Extract ownership change requirements
- Document legacy form handling
- Capture transition procedures

**Subpart G (Definitions) → `reference_data`**
- Extract ALL definitions with complete text
- Capture examples and clarifications
- Document cross-references between definitions

### 3. DETAILED EXTRACTION REQUIREMENTS

**For Each Regulation Section:**
```json
{
  "regulation_ref": "exact CFR citation",
  "verbatim_text": "exact regulatory language",
  "plain_english": "simplified explanation",
  "conditions": ["all conditions that must be met"],
  "exceptions": ["all exceptions and exclusions"],
  "timing": "exact timing requirements",
  "cross_references": ["other related sections"]
}
```

**For Decision Logic:**
- Extract complete decision trees with all branches
- Capture conditional logic ("if X then Y, unless Z")
- Document alternative pathways
- Include example scenarios where provided

**For Forms and Procedures:**
- Extract ALL form fields and requirements
- Document completion instructions
- Capture timing and submission requirements
- Include privacy and access provisions

**For Industry Classifications:**
- Extract complete NAICS code lists from ALL appendices
- Include exact industry descriptions
- Document which requirements apply to which industries
- Capture size thresholds (20-249, 250+, 100+, etc.)

### 4. COMPREHENSIVE DATA CAPTURE

**Timing Requirements - Extract ALL:**
- "within X hours/days/months"
- "by [specific date]"
- "immediately"
- "promptly"
- Posting periods and deadlines

**Numerical Thresholds - Extract ALL:**
- Employee count thresholds (10, 20, 100, 250)
- Hearing loss thresholds (25 dB, 10 dB)
- Time limits (180 days, 30 days, 8 hours, 24 hours)
- Form retention periods (5 years)

**Lists and Enumerations - Extract COMPLETE:**
- All NAICS industry codes
- Complete first aid procedures list
- All privacy concern case types
- All form field requirements
- All authorized signatory types

**Conditional Logic - Extract FULLY:**
- "Must... unless..."
- "May... if..."
- "Required when..."
- "Except for..."
- Multi-step decision processes

### 5. CROSS-REFERENCE MAPPING
For every extracted item, document:
- Source regulation section
- Related/dependent sections
- Definitions that apply
- Forms that are affected
- Procedures that reference it

### 6. QUALITY REQUIREMENTS

**Completeness Checks:**
- Every page reviewed
- Every section addressed
- Every appendix processed
- Every footnote captured
- Every table/list extracted

**Accuracy Requirements:**
- Exact regulatory citations
- Verbatim text for key requirements
- Precise numerical values
- Complete conditional logic
- All exceptions documented

**Structure Compliance:**
- All data fits the predefined JSON schema
- Proper categorization by section
- Consistent field usage
- Complete cross-referencing

## Output Format
Generate a complete JSON document following the comprehensive structure, containing ALL regulatory information from the PDF. Each section should be fully populated with extracted data, not summaries or highlights.

## Validation Criteria
The extraction is complete when:
1. Every page of the PDF has been analyzed
2. Every regulatory requirement has been captured
3. All NAICS codes from appendices are included
4. All timing requirements are documented
5. All cross-references are mapped
6. The JSON structure is fully populated
7. No regulatory text is omitted or summarized away

This is a comprehensive regulatory data extraction, not a selective summary. Capture everything that has compliance implications.

## Example JSON Output Structure

Here's an example of how the extracted data should be structured for one specific regulation:

```json
{
  "regulation_metadata": {
    "regulation_id": "29_CFR_1904",
    "title": "Recording and Reporting Occupational Injuries and Illnesses",
    "authority": "OSHA",
    "effective_date": "2025-09-24",
    "last_updated": "2025-09-24",
    "source_url": "https://www.ecfr.gov/current/title-29/subtitle-B/chapter-XVII/part-1904",
    "parsing_version": "v1.0",
    "parsing_date": "2025-09-25",
    "content_hash": "sha256:extracted_from_actual_pdf_content",
    "legal_basis": ["29 U.S.C. 657", "29 U.S.C. 658", "29 U.S.C. 660", "29 U.S.C. 666", "29 U.S.C. 669", "29 U.S.C. 673"]
  },

  "company_applicability": {
    "size_exemptions": [
      {
        "exemption_id": "small_employer_exemption",
        "regulation_ref": "29CFR-1904.1",
        "condition": "10_or_fewer_employees_at_all_times_during_last_calendar_year",
        "scope": "entire_company",
        "result": "partial_exemption_from_recordkeeping",
        "exceptions": [
          {
            "exception_type": "fatality_reporting", 
            "requirement": "must_report_work_related_fatalities",
            "regulation_ref": "29CFR-1904.39"
          },
          {
            "exception_type": "serious_injury_reporting",
            "requirement": "must_report_hospitalizations_amputations_eye_loss", 
            "regulation_ref": "29CFR-1904.39"
          },
          {
            "exception_type": "osha_bls_written_request",
            "requirement": "must_keep_records_if_written_request_received",
            "regulation_ref": "29CFR-1904.41, 29CFR-1904.42"
          }
        ],
        "implementation_details": {
          "size_determination": "peak_employment_during_last_calendar_year",
          "counting_rule": "no_more_than_10_employees_at_any_time",
          "employee_types_counted": "all_employees_including_part_time_seasonal_temporary"
        },
        "verbatim_text": "If your company had 10 or fewer employees at all times during the last calendar year, you do not need to keep OSHA injury and illness records unless OSHA or the Bureau of Labor Statistics informs you in writing that you must keep records under § 1904.41 or § 1904.42."
      }
    ],
    "industry_exemptions": [
      {
        "exemption_id": "retail_automotive_parts_stores",
        "regulation_ref": "29CFR-1904.2",
        "naics_code": "4412",
        "industry_description": "Other Motor Vehicle Dealers",
        "scope": "individual_business_establishments",
        "result": "partial_exemption_from_recordkeeping",
        "exceptions": [
          "fatality_reporting_required",
          "hospitalization_amputation_eye_loss_reporting_required",
          "written_government_request_overrides_exemption"
        ],
        "verbatim_text": "If your business establishment is classified in a specific industry group listed in appendix A to this subpart, you do not need to keep OSHA injury and illness records unless the government asks you to keep the records under § 1904.41 or § 1904.42."
      }
    ]
  },

  "recording_criteria": {
    "recordability_decision_tree": {
      "regulation_ref": "29CFR-1904.4(b)(2)",
      "decision_path": [
        {
          "step": 1,
          "question": "Did the employee experience an injury or illness?",
          "regulation_ref": "29CFR-1904.4(a)",
          "yes_path": "step_2",
          "no_path": "not_recordable",
          "notes": "Basic threshold - must be actual injury or illness"
        },
        {
          "step": 2, 
          "question": "Is the injury or illness work-related?",
          "regulation_ref": "29CFR-1904.5",
          "yes_path": "step_3",
          "no_path": "not_recordable",
          "determination_method": "use_work_relatedness_rules"
        },
        {
          "step": 3,
          "question": "Is the injury or illness a new case?", 
          "regulation_ref": "29CFR-1904.6",
          "yes_path": "step_4",
          "no_path": "update_previously_recorded_entry_if_necessary",
          "determination_method": "use_new_case_criteria"
        },
        {
          "step": 4,
          "question": "Does the injury or illness meet the general recording criteria or the application to specific cases?",
          "regulation_ref": "29CFR-1904.7",
          "yes_path": "record_the_injury_or_illness",
          "no_path": "do_not_record_the_injury_or_illness",
          "criteria_references": ["29CFR-1904.7", "29CFR-1904.8", "29CFR-1904.9", "29CFR-1904.10", "29CFR-1904.11", "29CFR-1904.12"]
        }
      ]
    },
    "general_recording_criteria": [
      {
        "criterion": "death",
        "regulation_ref": "29CFR-1904.7(b)(2)", 
        "condition": "injury_or_illness_results_in_death",
        "form_action": {
          "form": "OSHA_300_Log",
          "action": "enter_check_mark_in_death_column"
        },
        "additional_requirements": [
          {
            "requirement": "report_to_osha",
            "timing": "within_8_hours",
            "regulation_ref": "29CFR-1904.39"
          }
        ],
        "verbatim_text": "You must record an injury or illness that results in death by entering a check mark on the OSHA 300 Log in the space for cases resulting in death. You must also report any work-related fatality to OSHA within eight (8) hours, as required by § 1904.39."
      }
    ]
  },

  "form_requirements": {
    "required_forms": [
      {
        "form_id": "OSHA_300",
        "form_name": "Log of Work-Related Injuries and Illnesses", 
        "regulation_ref": "29CFR-1904.29(a)",
        "purpose": "ongoing_log_of_recordable_cases",
        "completion_timing": {
          "deadline": "within_7_calendar_days",
          "trigger": "receiving_information_that_recordable_injury_illness_occurred",
          "regulation_ref": "29CFR-1904.29(b)(3)"
        },
        "required_information": [
          "business_information_at_top_of_log",
          "one_or_two_line_description_for_each_recordable_case"
        ],
        "privacy_protections": {
          "privacy_concern_cases": [
            "injury_illness_to_intimate_body_part_reproductive_system",
            "injury_illness_from_sexual_assault", 
            "mental_illnesses",
            "hiv_hepatitis_tuberculosis",
            "needlestick_cuts_contaminated_sharps",
            "employee_voluntary_request_name_not_entered"
          ],
          "privacy_case_handling": "enter_privacy_case_instead_of_employee_name",
          "confidential_list_requirement": "keep_separate_confidential_list_case_numbers_employee_names"
        },
        "verbatim_text": "You must use OSHA 300, 300-A, and 301 forms, or equivalent forms, for recordable injuries and illnesses."
      }
    ]
  },

  "government_reporting": {
    "immediate_reporting": [
      {
        "trigger": "employee_fatality",
        "regulation_ref": "29CFR-1904.39(a)(1)",
        "deadline": "within_8_hours_after_death",
        "recipient": "OSHA", 
        "reporting_methods": [
          "telephone_or_in_person_to_nearest_OSHA_area_office",
          "telephone_to_1-800-321-OSHA",
          "electronic_submission_via_osha_website"
        ],
        "required_information": [
          "establishment_name",
          "location_of_work_related_incident", 
          "time_of_work_related_incident",
          "type_of_reportable_event",
          "number_of_employees_who_suffered_fatality",
          "names_of_employees_who_suffered_fatality",
          "contact_person_and_phone_number",
          "brief_description_of_work_related_incident"
        ],
        "exceptions": [
          {
            "exception_type": "motor_vehicle_public_street",
            "condition": "motor_vehicle_accident_on_public_street_highway_not_construction_zone",
            "result": "no_reporting_required_but_must_record_if_keeping_records"
          },
          {
            "exception_type": "commercial_transportation",
            "condition": "occurred_on_commercial_public_transportation_system",
            "result": "no_reporting_required_but_must_record_if_keeping_records"
          }
        ],
        "verbatim_text": "Within eight (8) hours after the death of any employee as a result of a work-related incident, you must report the fatality to the Occupational Safety and Health Administration (OSHA), U.S. Department of Labor."
      }
    ]
  },

  "reference_data": {
    "definitions": {
      "first_aid": {
        "regulation_ref": "29CFR-1904.7(b)(5)(ii)",
        "definition_type": "complete_list_of_treatments",
        "items": [
          {
            "treatment": "non_prescription_medication",
            "details": "using_nonprescription_medication_at_nonprescription_strength",
            "exception": "recommendation_by_physician_to_use_nonprescription_medication_at_prescription_strength_is_medical_treatment"
          },
          {
            "treatment": "tetanus_immunizations",
            "details": "administering_tetanus_immunizations_only",
            "exception": "other_immunizations_such_as_hepatitis_b_rabies_considered_medical_treatment"
          },
          {
            "treatment": "wound_care",
            "details": "cleaning_flushing_soaking_wounds_on_surface_of_skin"
          },
          {
            "treatment": "bandages",
            "details": "using_wound_coverings_bandages_gauze_pads_butterfly_bandages_steri_strips",
            "exception": "other_wound_closing_devices_sutures_staples_considered_medical_treatment"
          }
        ],
        "completeness_note": "this_is_complete_list_of_all_treatments_considered_first_aid",
        "verbatim_text": "For the purposes of part 1904, \"first aid\" means the following: [complete list provided]"
      }
    },
    "naics_codes": {
      "appendix_a_partial_exemption": [
        {
          "naics_code": "4412",
          "industry": "Other Motor Vehicle Dealers"
        },
        {
          "naics_code": "4431", 
          "industry": "Electronics and Appliance Stores"
        }
      ]
    }
  }
}
```

This example shows the level of detail and structure expected for EVERY regulation extracted from the PDF. Each entry should include:
- Exact regulation references
- Verbatim regulatory text for key requirements
- Complete conditions and exceptions
- Precise timing and numerical requirements
- Cross-references to related sections
- Implementation details and edge cases