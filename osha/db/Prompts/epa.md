

We are building the compliance database for OSHA/EPA so primary purpose of the database is to build a SaaS product called CompliEase. It solves the business problem of how companies manage their changing compliance requirements.

1. So we need to build the compliance database which will store the data from the eCFR PDF to extract all the rules - quantitative and qualitative rules which are used for compliance reporting.
2. This list should extract each and every rule from all the sections in the PDF

**Important**
You are now acting as the compliance officer in the company to extract all the rules from the PDF:

## Things to remember:
1. We need to extract all the PDF data into the JSON format holding the hierarchy of the PDF from top to very least level of hierarchy to rule.
2. You can build the hierarchy like holding the regulation info and then keep going on the structure in PDF.
3. Keep the information like any definitions, or any other info which might be needed.
4. Main goal here is to extract all the numerical rules - don't miss anything.

Go with same flow of the PDF going down and concentrate on extracting all but keep this in mind like an example:

## **REGULATION BASICS**
**OSHA Example: "Fall Protection in Construction - Part 1926, Subpart M, Section 501 - applies to all construction workers"**
**EPA Example: "Standards of Performance for Crude Oil and Natural Gas Facilities - Part 60, Subpart OOOO, Section 5365 - applies to oil and gas facilities"**
- Regulation title *(Fall Protection in Construction / Standards of Performance for Crude Oil and Natural Gas Facilities)*
- Part number *(1926 / 60)*
- Subpart letter *(M / OOOO)* 
- Section number *(501 / 5365)*
- What it applies to *(all construction workers / oil and gas facilities)*

## **RULE CONTENT**
**OSHA Example: "Each employee on a walking/working surface 6 feet or more above lower levels shall be protected from falling"**
**EPA Example: "You must reduce VOC emissions from each centrifugal compressor wet seal fluid degassing system by 95.0 percent or greater"**
- Rule text *(the actual requirement text)*
- What you must do *(use fall protection / reduce VOC emissions by 95%)*
- Rule type *(mandatory - uses "shall" / "must")*
- How serious *(critical - life safety / critical - environmental)*

## **TRIGGERS & CONDITIONS**
**OSHA Example: "when working at heights greater than 6 feet" or "loads exceeding 50 pounds"**
**EPA Example: "heat input capacity greater than 73 MW" or "VOC emissions exceeding 6 tons per year"**
- When rule applies *(height > 6 feet, load > 50 lbs / capacity > 73 MW, emissions > 6 tpy)*
- Measurement values and units *(6 feet, 50 pounds / 73 MW, 6 tons per year)*
- Comparison operators *(>,<,=, %)*
- Expression which builds up the expression using condition id 

## **WORK TYPES & CATEGORICAL TAGGING**
**OSHA Example: "roofing operations", "steel erection", "scaffolding work"**
**EPA Example: "oil production", "natural gas processing", "well completion operations"**
- What kind of work *(excavation, roofing, welding / oil production, gas processing, well operations)*
- Work categories *(construction, maintenance, demolition / production, processing, transmission)*
- Activity descriptions *(installing shingles, operating crane / drilling wells, processing gas)*
- Regulated entities *(construction companies, contractors / oil companies, gas facilities, processing plants)*
- Environmental media *(workplace_safety / air, water, soil, waste)*
- Regulatory program *(OSHA, construction_safety / EPA, CAA, NSPS)*
- Geographic scope *(nationwide, state-specific, regional)*
- Source categories *(construction_activities, maintenance_work / new_sources, existing_sources, onshore_facilities)*

## **PROTECTION METHODS**
**OSHA Example: "guardrail systems", "safety net systems", "personal fall arrest systems"**
**EPA Example: "control devices", "closed vent systems", "vapor recovery units"**
- Available safety/control systems *(guardrails, harnesses, barriers / flares, condensers, separators)*
- Protection types *(active vs passive protection / emission control vs capture)*
- Required vs optional protections *(must use vs may use / mandatory control vs alternative)*

## **EXCEPTIONS**
**OSHA Example: "except when infeasible" or "unless creating greater hazard" or "safety monitoring alone permitted on roofs 50 feet or less in width"**
**EPA Example: "except for emergency conditions" or "unless technically infeasible" or "control devices exempted for facilities with design capacity less than 2 LT/D"**
- When rule doesn't apply *(infeasible conditions, roof width ≤ 50 feet / emergency conditions, capacity < 2 LT/D)*
- Alternative methods allowed *(use safety nets instead, safety monitoring alone / route to process, performance testing waived)*
- Special conditions *(competent person approval, specific measurements / Administrator approval, design capacity limits)*
- Reference exceptions *(as provided in paragraph (b) / as specified in section 60.8)*
- Conditional exceptions with measurable criteria *(roof width, height ratios, load limits / capacity thresholds, emission rates, time periods)*

**Exception Structure:** Mix of simple text and objects with conditions
- Simple text for references: *"as otherwise provided in paragraph (b)"*
- Objects with conditions for measurable exceptions

## **ENHANCED JSON Structure Example:**
```json
{
  "regulation": {
    "title": "Standards of Performance for Crude Oil and Natural Gas Facilities",
    "part": "60",
    "subpart": "OOOO", 
    "section": "5380",
    "applies_to": "centrifugal compressor affected facilities"
  },
  "rule": {
    "rule_id": "60.5380(a)(1)",
    "text": "You must reduce VOC emissions from each centrifugal compressor wet seal fluid degassing system by 95.0 percent or greater",
    "requirement": "reduce VOC emissions by 95.0 percent or greater from wet seal degassing systems",
    "type": "mandatory",
    "severity": "critical",
    
    // OSHA-style tagging (adapt for EPA):
    "applies_to": ["centrifugal compressor operators", "facility owners", "oil and gas companies"],
    "work_types": ["oil production", "natural gas processing", "compressor operations"],
    
    // Enhanced categorical tagging for EPA:
    "regulated_entities": ["oil_and_gas_facilities", "natural_gas_processing_plants", "compressor_stations"],
    "environmental_media": ["air"],
    "regulatory_program": ["CAA", "NSPS", "Part_60"],
    "geographic_scope": ["nationwide"],
    "source_categories": ["new_sources", "modified_sources", "reconstructed_sources"],
    
    // Enhanced parametric evaluation:
    "triggers": {
      "conditions": [
        {
          "id": "facility_type",
          "parameter": "facility_type",
          "operator": "=",
          "value": "centrifugal_compressor_affected_facility",
          "unit": "category"
        },
        {
          "id": "construction_date",
          "parameter": "construction_commenced_date",
          "operator": ">=",
          "value": "2011-08-23",
          "unit": "date"
        },
        {
          "id": "construction_date_end",
          "parameter": "construction_commenced_date", 
          "operator": "<=",
          "value": "2015-09-18",
          "unit": "date"
        },
        {
          "id": "wet_seal_system",
          "parameter": "uses_wet_seals",
          "operator": "=",
          "value": "true",
          "unit": "boolean"
        }
      ],
      "expression": "facility_type AND construction_date AND construction_date_end AND wet_seal_system"
    },
    
    "protections": ["control_devices", "closed_vent_systems", "process_routing", "covers"],
    
    "exceptions": {
      "items": [
        {
          "id": "route_to_process",
          "description": "route closed vent system to a process as alternative to control device",
          "conditions": [
            {
              "parameter": "routing_destination",
              "operator": "=",
              "value": "process",
              "unit": "category"
            }
          ]
        },
        {
          "id": "performance_test_waiver",
          "description": "performance test waived in accordance with § 60.8(b)",
          "conditions": [
            {
              "parameter": "waiver_approved",
              "operator": "=",
              "value": "true",
              "unit": "boolean"
            }
          ]
        }
      ],
      "expression": "route_to_process OR performance_test_waiver"
    }
  }
}
```

## **Focus on extracting:**
- **WHAT** (the rule text and requirement)
- **WHEN** (conditions/triggers with enhanced parametric evaluation)
- **WHO** (work types, applies_to, and regulated entities)
- **HOW** (protection methods and compliance approaches)
- **WHERE** (geographic scope and source categories)
- **PROGRAM** (regulatory program and environmental media)
- **EXCEPT** (exceptions with measurable conditions)

## **Key Enhancement Areas:**
1. **Enhanced Triggers**: More sophisticated condition objects with proper operators (=, >, <, >=, <=, in, not_in)
2. **Categorical Tagging**: Add regulated_entities, environmental_media, regulatory_program, geographic_scope, source_categories
3. **Parametric Precision**: Capture all numerical values, dates, percentages, time periods, capacities, and boolean conditions
4. **Expression Logic**: Build complex logical expressions using condition IDs
5. **Exception Handling**: Support both simple references and complex conditional exceptions

**Extract every numerical value, measurement, threshold, percentage, ratio, time period, capacity limit, and evaluable condition from the PDF. Don't miss any quantitative requirements.**

