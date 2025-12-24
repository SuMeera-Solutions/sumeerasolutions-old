We are building the compliance database for osha so primary purpose of the  database is to build a saas product called compliease. it solves the business problem of how companies manage their changing compliance requirements.
1.So we need to build teh compliance database which will store teh data from the ecfr pdf to extract all teh rules qunatiative and qualitative ules which are used for compliance reporting.
2. this list should extract each and  every rule from all the sections in the pdf
** Important **
You are now acting as the comnpliance officer in teh company to extract all  the rules from teh pdf:
Things to remember:
1. We need to extract all the pdf data into the json format holding teh hierarchy of the pdf from top to very least level of hercahy tio rule.
2. You can build teh hierarchy liek holding teh reguulatin info and then keep going on the sytrycture in pdf .
3. keep teh information liek any deinatins , or any other info which might be nneeded ,
4. Main goal heer is to extract al teh numerical rules dont miss anyting .

Go with same flow of teh pdf going down and conecenatrte on extracting ll but keep this isn mind liekj an example ;
Perfect! Here are the core data points with **examples** for each:
## **REGULATION BASICS**
**Example: "Fall Protection in Construction - Part 1926, Subpart M, Section 501 - applies to all construction workers"**
- Regulation title *(Fall Protection in Construction)*
- Part number *(1926)*
- Subpart letter *(M)* 
- Section number *(501)*
- What it applies to *(all construction workers)*
## **RULE CONTENT**
**Example: "Each employee on a walking/working surface 6 feet or more above lower levels shall be protected from falling"**
- Rule text *(the actual requirement text)*
- What you must do *(use fall protection)*
- Rule type *(mandatory - uses "shall")*
- How serious *(critical - life safety)*
## **TRIGGERS & CONDITIONS**
**Example: "when working at heights greater than 6 feet" or "loads exceeding 50 pounds"**
- When rule applies *(height > 6 feet, load > 50 lbs)*
- Measurement values and units *(6 feet, 50 pounds)*
- Comparison operators *(>,<,=, %)*
-  Exzpression which builds up teh expression  using condition id 
## **WORK TYPES**
**Example: "roofing operations", "steel erection", "scaffolding work"**
- What kind of work *(excavation, roofing, welding)*
- Work categories *(construction, maintenance, demolition)*
- Activity descriptions *(installing shingles, operating crane)*
## **PROTECTION METHODS**
**Example: "guardrail systems", "safety net systems", "personal fall arrest systems"**
- Available safety systems *(guardrails, harnesses, barriers)*
- Protection types *(active vs passive protection)*
- Required vs optional protections *(must use vs may use)*
EXCEPTIONS
Example: "except when infeasible" or "unless creating greater hazard" or "safety monitoring alone permitted on roofs 50 feet or less in width"
 
When rule doesn't apply (infeasible conditions, roof width ≤ 50 feet)
Alternative methods allowed (use safety nets instead, safety monitoring alone)
Special conditions (competent person approval, specific measurements)
Reference exceptions (as provided in paragraph (b))
Conditional exceptions with measurable criteria (roof width, height ratios, load limits)
 
Exception Structure: Mix of simple text and objects with conditions
 
Simple text for references: "as otherwise provided in paragraph (b)"
Objects with conditions for measurable exceptions:
 
json{
  "description": "safety monitoring alone permitted on roofs 50 feet or less in width",
  "conditions": [
    {"parameter": "roof width", "value": "50", "unit": "feet", "operator": "<="}
  ]
}
 
Extract any numerical values, measurements, or evaluable conditions from exception text
When multiple exceptions exist, capture each separately in the array
If exceptions have logical relationships (AND/OR), note the relationship
## **JSON Structure Example:**
```json
{
  "regulation": {
    "title": "Fall Protection in Construction",
    "part": "1926",
    "subpart": "M", 
    "section": "501",
    "applies_to": "construction workers"
  },
  "rule": {
    "text": "Each employee on walking/working surface 6 feet or more above lower levels shall be protected",
    "requirement": "use fall protection",
    "type": "mandatory",
    "severity": "critical"
  },
  "triggers": [
    "triggers": {
    "conditions": [
      {"id": "height_unprotected", "condition": "height of unprotected sides/edges", "value": "6", "unit": "feet", "operator": ">="},
      {"id": "roof_width_monitoring", "condition": "roof width for safety monitoring alone", "value": "50", "unit": "feet", "operator": "<="},
      {"id": "low_slope_work", "condition": "low-slope roof work", "value": "true", "unit": "boolean", "operator": "="}
    ],
    "expression": "height_unprotected AND (roof_width_monitoring OR low_slope_work)"
  }
  ],
  "work_types": ["roofing", "steel erection", "scaffolding"],
  "protections": ["guardrail systems", "safety nets", "personal fall arrest"],
  "exceptions": {
   "items": [
     {"id": "paragraph_b", "description": "as otherwise provided in paragraph (b)", "conditions": []},
     {"id": "safety_monitoring", "description": "safety monitoring alone permitted on roofs 50 feet or less in width", "conditions": [{"parameter": "roof width", "value": "50", "unit": "feet", "operator": "<="}]},
     {"id": "fall_arrest", "description": "when using personal fall arrest systems", "conditions": [{"parameter": "fall_arrest_system", "value": "true", "operator": "="}]}
   ],
   "expression": "paragraph_b OR (safety_monitoring AND fall_arrest)"
}
}
```
Focus on extracting:
WHAT (the rule)
WHEN (conditions/triggers)
WHO (work types)
HOW (protection methods)
EXCEPT (exceptions)