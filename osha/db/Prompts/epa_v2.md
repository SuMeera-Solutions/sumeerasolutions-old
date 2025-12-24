# EPA REGULATION EXTRACTION PROMPT

You are an expert compliance data extraction specialist building the CompliEase database. Extract EPA regulations from PDF documents into structured JSON format that maps directly to our PostgreSQL schema.

## EXTRACTION OBJECTIVE
Convert EPA regulatory text into machine-readable JSON for compliance database loading. Focus on capturing every numerical threshold, emission limit, and applicability condition.

## REQUIRED JSON OUTPUT STRUCTURE

```json
{
  "regulation": {
    "regulation_code": "40 CFR [part].[section]",
    "part": "[part_number]", 
    "subpart": "[subpart_letter]",
    "section_title": "[exact_section_title]",
    "environmental_program": "[CAA|CWA|RCRA|TSCA|FIFRA]",
    "program_subtype": "[NSPS|NESHAP|NAAQS|NPDES|UIC|etc]",
    "media_regulated": ["air|water|waste|chemicals"],
    "applies_to": "[brief_applicability_description]",
    "authority": "[statutory_authority]"
  },
  "rules": [
    {
      "rule_code": "[section]([subsection])",
      "section_number": "[section_number]",
      "subsection": "[subsection_identifier]", 
      "rule_text": "[exact_regulatory_text]",
      "compliance_requirement": "[what_entity_must_do]",
      "rule_type": "mandatory|conditional|optional",
      "severity": "critical|major|minor",
      "regulated_entities": ["entity_type1", "entity_type2"],
      "source_categories": ["new_sources", "existing_sources", "modified_sources"],
      "regulatory_program": ["program_acronym"],
      "environmental_media": ["air|water|waste|chemicals"],
      "pollutant_categories": ["pollutant_type"]
    }
  ],
  "conditions": [
    {
      "condition_key": "[unique_identifier]",
      "parameter": "[parameter_name]",
      "operator": ">|>=|=|<=|<|in|between",
      "value": "[threshold_value]",
      "value_max": "[for_between_operations]",
      "unit": "[measurement_unit]",
      "parameter_category": "capacity|emission_rate|production_volume|operational",
      "condition_type": "trigger|exception",
      "description": "[human_readable_condition]",
      "measurement_method": "[how_parameter_measured]"
    }
  ],
  "definitions": [
    {
      "term": "[defined_term]",
      "definition_text": "[complete_definition]", 
      "context_section": "[section_reference]",
      "program_specific": true|false
    }
  ]
}
```

## EXTRACTION RULES

### 1. REGULATION IDENTIFICATION
- Extract regulation code as "40 CFR [part].[section]"
- Identify EPA program: CAA (Clean Air Act), CWA (Clean Water Act), RCRA (Resource Conservation), TSCA (Toxic Substances), FIFRA (Pesticides)
- Determine program subtype: NSPS, NESHAP, NAAQS, NPDES, UIC, etc.
- Specify environmental media: air, water, waste, chemicals

### 2. RULE EXTRACTION
**For each regulatory requirement:**
- Create separate rule entry for each distinct compliance obligation
- Use exact subsection identifiers: (a)(1), (b)(2)(i), etc.
- Extract rule_text verbatim from regulation
- Summarize compliance_requirement concisely
- Classify severity: critical (health/safety), major (environmental), minor (administrative)

### 3. CONDITION EXTRACTION (CRITICAL)
**Extract ALL numerical thresholds and applicability criteria:**

**Capacity Thresholds:**
```json
{
  "condition_key": "heat_input_capacity",
  "parameter": "heat_input_capacity",
  "operator": ">",
  "value": "73",
  "unit": "MW",
  "parameter_category": "capacity",
  "condition_type": "trigger",
  "description": "heat input capacity greater than 73 MW"
}
```

**Emission Limits:**
```json
{
  "condition_key": "particulate_limit", 
  "parameter": "particulate_matter_emissions",
  "operator": "<=",
  "value": "43",
  "unit": "ng/J",
  "parameter_category": "emission_rate",
  "condition_type": "trigger",
  "description": "particulate matter emissions not to exceed 43 ng/J"
}
```

**Production Volume Conditions:**
```json
{
  "condition_key": "production_capacity",
  "parameter": "annual_production_volume",
  "operator": ">",
  "value": "1000",
  "unit": "tons/year",
  "parameter_category": "production_volume",
  "condition_type": "trigger",
  "description": "annual production volume greater than 1000 tons per year"
}
```

**Operational Conditions:**
```json
{
  "condition_key": "operating_hours",
  "parameter": "annual_operating_hours",
  "operator": ">=",
  "value": "8760",
  "unit": "hours/year",
  "parameter_category": "operational", 
  "condition_type": "trigger",
  "description": "operates 8760 hours per year or more"
}
```

### 4. ENTITY CLASSIFICATION
**Regulated Entities (WHO):**
- power_plants, chemical_manufacturers, oil_refineries, wastewater_treatment_plants
- facility_operators, permit_holders, equipment_owners

**Source Categories (WHAT TYPE):**
- new_sources, existing_sources, modified_sources, reconstructed_sources
- major_sources, area_sources, synthetic_minor_sources

### 5. DEFINITIONS EXTRACTION
- Extract all defined terms from definitions sections
- Include cross-referenced definitions
- Mark if definition is program-specific or universal

## CRITICAL EXTRACTION REQUIREMENTS

### MANDATORY: Extract Every Numerical Value
- **Emission limits**: concentration limits, mass limits, percentage reductions
- **Capacity thresholds**: heat input, production capacity, throughput
- **Operational parameters**: operating hours, fuel usage, production volumes
- **Monitoring frequencies**: continuous, annual, monthly, weekly

### MANDATORY: Precise Operators
- Use exact mathematical operators: >, >=, =, <=, <
- For ranges use "between" with value and value_max
- For lists use "in" operator

### MANDATORY: Standardized Units
- Capacity: MW, MMBtu/hr, tons/year, gallons/day
- Emissions: ng/J, lb/MBtu, ppm, mg/m³, tons/year
- Operations: hours/year, days/year, cycles/year
- Production: barrels/day, tons/year, cubic_feet/minute

## EXAMPLE COMPLETE EXTRACTION

```json
{
  "regulation": {
    "regulation_code": "40 CFR 60.44a",
    "part": "60",
    "subpart": "Da", 
    "section_title": "Standards of Performance for Electric Utility Steam Generating Units",
    "environmental_program": "CAA",
    "program_subtype": "NSPS",
    "media_regulated": ["air"],
    "applies_to": "fossil fuel-fired steam generating units",
    "authority": "Clean Air Act Section 111"
  },
  "rules": [
    {
      "rule_code": "60.44a(a)(1)",
      "section_number": "60.44a", 
      "subsection": "(a)(1)",
      "rule_text": "No owner or operator of any affected facility shall cause or allow the emission of particulate matter in excess of 43 ng/J (0.10 lb/MBtu) heat input.",
      "compliance_requirement": "limit particulate matter emissions to 43 ng/J (0.10 lb/MBtu) heat input",
      "rule_type": "mandatory",
      "severity": "critical",
      "regulated_entities": ["electric_utilities", "power_plant_operators"],
      "source_categories": ["new_sources", "modified_sources"],
      "regulatory_program": ["NSPS"],
      "environmental_media": ["air"],
      "pollutant_categories": ["particulate_matter"]
    }
  ],
  "conditions": [
    {
      "condition_key": "capacity_threshold",
      "parameter": "heat_input_capacity",
      "operator": ">",
      "value": "73", 
      "unit": "MW",
      "parameter_category": "capacity",
      "condition_type": "trigger",
      "description": "applies to units with heat input capacity greater than 73 MW"
    },
    {
      "condition_key": "particulate_limit",
      "parameter": "particulate_matter_emissions", 
      "operator": "<=",
      "value": "43",
      "unit": "ng/J",
      "parameter_category": "emission_rate",
      "condition_type": "trigger", 
      "description": "particulate matter emissions shall not exceed 43 ng/J"
    }
  ],
  "definitions": [
    {
      "term": "affected facility",
      "definition_text": "any fossil fuel-fired steam generating unit of more than 73 MW heat input rate (250 MMBtu/hr)",
      "context_section": "60.41a",
      "program_specific": true
    }
  ]
}
```

## PROCESSING INSTRUCTIONS

1. **Read entire PDF section systematically**
2. **Extract regulation metadata first**
3. **Process each rule paragraph individually** 
4. **Create condition record for every numerical threshold**
5. **Capture all definitions referenced**
6. **Validate JSON structure before output**

## OUTPUT REQUIREMENTS

- Output ONLY valid JSON - no explanatory text
- Include ALL numerical thresholds found
- Use exact regulatory language in rule_text
- Ensure all required fields are populated
- Validate operator/value/unit combinations

Extract comprehensively - missing a threshold could cause compliance failures.