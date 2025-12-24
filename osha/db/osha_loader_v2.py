#!/usr/bin/env python3
"""
OSHA JSON to PostgreSQL Data Loader - Updated for New Schema
Loads OSHA regulations from JSON into the osha_rules_v2 schema
Handles new JSON structure with triggers/conditions/exceptions
"""

import json
import psycopg2
import psycopg2.extras
from datetime import datetime
import logging
from typing import Dict, List, Any, Optional
import sys
import hashlib

# Database configuration
DB_CONFIG = {
    'host': 'rds-dev-compliease-pg.cm9ok286yrdx.us-east-1.rds.amazonaws.com',
    'username': 'postgres',
    'password': '0XNfzbSGvzzvWc40Ra7U',
    'database': 'compliease_sbx',
    'schema': 'osha_rules_v1'
}

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class OSHADataLoader:
    """Loads OSHA JSON data into PostgreSQL database with new schema"""
    
    def __init__(self, db_config: dict):
        self.db_config = db_config
        self.conn = None
        self.cursor = None
        
    def connect(self):
        """Establish database connection"""
        try:
            self.conn = psycopg2.connect(
                host=self.db_config['host'],
                user=self.db_config['username'],
                password=self.db_config['password'],
                database=self.db_config['database']
            )
            self.cursor = self.conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
            
            # Set search path to our schema
            self.cursor.execute(f"SET search_path TO {self.db_config['schema']}")
            self.conn.commit()
            
            logger.info(f"Connected to database: {self.db_config['database']}")
            logger.info(f"Using schema: {self.db_config['schema']}")
            
        except Exception as e:
            logger.error(f"Database connection failed: {e}")
            raise
    
    def disconnect(self):
        """Close database connection"""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        logger.info("Database connection closed")
    
    def convert_to_array(self, value: Any) -> List[str]:
        """Convert various formats to PostgreSQL array format"""
        if isinstance(value, list):
            return [str(item).strip() for item in value if item and str(item).strip()]
        elif isinstance(value, str) and value.strip():
            return [value.strip()]
        else:
            return []
    
    def generate_regulation_code(self, regulation: dict) -> str:
        """Generate standardized regulation code"""
        title_num = 29  # Always 29 for OSHA
        part = regulation.get('part', '')
        subpart = regulation.get('subpart', '')
        return f"{title_num}-CFR-{part}-Subpart-{subpart}"
    
    def generate_rule_hash(self, rule_data: dict) -> str:
        """Generate SHA256 hash for rule change detection"""
        rule_str = json.dumps(rule_data, sort_keys=True)
        return hashlib.sha256(rule_str.encode()).hexdigest()
    
    def load_regulation(self, json_data: dict) -> int:
        """
        Load regulation data into regulation table
        Returns: regulation_id (primary key)
        """
        regulation_data = json_data.get('regulation', {})
        
        # Generate regulation code
        reg_code = self.generate_regulation_code(regulation_data)
        
        # Prepare regulation record
        regulation_record = {
            'regulation_code': reg_code,
            'title_number': 29,  # Always 29 for OSHA
            'title': regulation_data.get('title'),
            'part': regulation_data.get('part'),
            'subpart': regulation_data.get('subpart'),
            'section_title': regulation_data.get('title'),  # Use title as section_title
            'authority': regulation_data.get('authority'),
            'effective_date': regulation_data.get('effective_date'),
            'last_updated': regulation_data.get('last_updated'),
            'applies_to': regulation_data.get('applies_to'),
            'excludes': self.convert_to_array(regulation_data.get('excludes', [])),
            'source_data': json.dumps(regulation_data),
            'created_by': 'osha_loader_v2',
            'updated_by': 'osha_loader_v2'
        }
        
        # Insert regulation
        insert_sql = """
        INSERT INTO regulation (
            regulation_code, title_number, title, part, subpart, section_title,
            authority, effective_date, last_updated, applies_to, excludes,
            source_data, created_by, updated_by
        ) VALUES (
            %(regulation_code)s, %(title_number)s, %(title)s, %(part)s, %(subpart)s, %(section_title)s,
            %(authority)s, %(effective_date)s, %(last_updated)s, %(applies_to)s, %(excludes)s,
            %(source_data)s, %(created_by)s, %(updated_by)s
        ) 
        ON CONFLICT (regulation_code) 
        DO UPDATE SET
            title = EXCLUDED.title,
            authority = EXCLUDED.authority,
            last_updated = EXCLUDED.last_updated,
            applies_to = EXCLUDED.applies_to,
            excludes = EXCLUDED.excludes,
            source_data = EXCLUDED.source_data,
            updated_by = EXCLUDED.updated_by,
            updated_at = CURRENT_TIMESTAMP
        RETURNING regulation_id
        """
        
        try:
            self.cursor.execute(insert_sql, regulation_record)
            regulation_id = self.cursor.fetchone()['regulation_id']
            self.conn.commit()
            
            logger.info(f"Loaded regulation: {reg_code} (ID: {regulation_id})")
            return regulation_id
            
        except Exception as e:
            self.conn.rollback()
            logger.error(f"Failed to load regulation {reg_code}: {e}")
            raise
    
    def load_rules(self, json_data: dict, regulation_id: int) -> Dict[str, int]:
        """
        Load rules from sections->subsections->rules into rule table
        Returns: Dictionary mapping rule_code to rule_id (primary key)
        """
        rule_mapping = {}
        sections = json_data.get('sections', [])
        
        for section in sections:
            section_number = section.get('section_number')
            section_title = section.get('title')
            
            subsections = section.get('subsections', [])
            for subsection in subsections:
                subsection_number = subsection.get('subsection')
                subsection_title = subsection.get('title')
                
                rules = subsection.get('rules', [])
                for rule_json in rules:
                    rule_id = self._load_single_rule(
                        rule_json, regulation_id,
                        section_number, section_title,
                        subsection_number, subsection_title
                    )
                    
                    if rule_id:
                        rule_mapping[rule_json['rule_id']] = rule_id
        
        # Load appendices as rules if they exist
        appendices = json_data.get('appendices', [])
        for appendix in appendices:
            key_rule = appendix.get('key_rule')
            if key_rule:
                rule_id = self._load_single_rule(
                    key_rule, regulation_id,
                    'Appendix', appendix.get('title', 'Appendix'),
                    appendix.get('appendix_id', 'A'), appendix.get('title', 'Appendix')
                )
                
                if rule_id:
                    rule_mapping[key_rule['rule_id']] = rule_id
        
        logger.info(f"Loaded {len(rule_mapping)} rules")
        return rule_mapping
    
    def _load_single_rule(self, rule_json: dict, regulation_id: int,
                         section_number: str, section_title: str,
                         subsection_number: str, subsection_title: str) -> Optional[int]:
        """Load a single rule into the rule table"""
        
        # Extract trigger and exception expressions
        triggers = rule_json.get('triggers', {})
        trigger_expression = triggers.get('expression', '') if triggers else ''
        
        exceptions = rule_json.get('exceptions', {})
        exception_expression = exceptions.get('expression', '') if exceptions else ''
        
        # Convert personnel_required field
        personnel_required = rule_json.get('personnel_required')
        
        rule_record = {
            'rule_code': rule_json.get('rule_id'),
            'regulation_id': regulation_id,
            'rule_text': rule_json.get('text'),
            'rule_type': rule_json.get('type'),
            'compliance_requirement': rule_json.get('requirement'),
            'severity': rule_json.get('severity'),
            'section_number': section_number,
            'section_title': section_title,
            'subsection': subsection_number,
            'subsection_title': subsection_title,
            'applies_to': self.convert_to_array(rule_json.get('applies_to')),
            'work_types': self.convert_to_array(rule_json.get('work_types')),
            'protections': self.convert_to_array(rule_json.get('protections')),
            'personnel_required': personnel_required,
            'trigger_expression': trigger_expression if trigger_expression else None,
            'exception_expression': exception_expression if exception_expression else None,
            'rule_hash': self.generate_rule_hash(rule_json),
            'source_data': json.dumps(rule_json),
            'created_by': 'osha_loader_v2',
            'updated_by': 'osha_loader_v2'
        }
        
        insert_sql = """
        INSERT INTO rule (
            rule_code, regulation_id, rule_text, rule_type, compliance_requirement, severity,
            section_number, section_title, subsection, subsection_title,
            applies_to, work_types, protections, personnel_required,
            trigger_expression, exception_expression, rule_hash,
            source_data, created_by, updated_by
        ) VALUES (
            %(rule_code)s, %(regulation_id)s, %(rule_text)s, %(rule_type)s, %(compliance_requirement)s, %(severity)s,
            %(section_number)s, %(section_title)s, %(subsection)s, %(subsection_title)s,
            %(applies_to)s, %(work_types)s, %(protections)s, %(personnel_required)s,
            %(trigger_expression)s, %(exception_expression)s, %(rule_hash)s,
            %(source_data)s, %(created_by)s, %(updated_by)s
        ) 
        RETURNING rule_id
        """
        
        try:
            self.cursor.execute(insert_sql, rule_record)
            rule_id = self.cursor.fetchone()['rule_id']
            self.conn.commit()
            
            logger.info(f"Loaded rule: {rule_json.get('rule_id')} (ID: {rule_id})")
            return rule_id
            
        except Exception as e:
            self.conn.rollback()
            logger.error(f"Failed to load rule {rule_json.get('rule_id')}: {e}")
            return None
    
    def load_conditions(self, json_data: dict, rule_mapping: Dict[str, int]):
        """Load conditions from rule triggers and exceptions into condition table"""
        sections = json_data.get('sections', [])
        conditions_loaded = 0
        
        for section in sections:
            subsections = section.get('subsections', [])
            for subsection in subsections:
                rules = subsection.get('rules', [])
                for rule_json in rules:
                    rule_code = rule_json.get('rule_id')
                    rule_id = rule_mapping.get(rule_code)
                    
                    if not rule_id:
                        continue
                    
                    # Load trigger conditions
                    triggers = rule_json.get('triggers', {})
                    trigger_conditions = triggers.get('conditions', [])
                    for condition_data in trigger_conditions:
                        if self._create_condition(rule_id, condition_data, 'trigger'):
                            conditions_loaded += 1
                    
                    # Load exception conditions
                    exceptions = rule_json.get('exceptions', {})
                    exception_items = exceptions.get('items', [])
                    for exception_item in exception_items:
                        # Create condition for exception logic if it has conditions
                        if exception_item.get('conditions'):
                            for condition_data in exception_item['conditions']:
                                if self._create_condition(rule_id, condition_data, 'exception'):
                                    conditions_loaded += 1
                        
                        # Create description-only condition for the exception
                        description_condition = {
                            'id': exception_item.get('id'),
                            'description': exception_item.get('description')
                        }
                        if self._create_condition(rule_id, description_condition, 'description_only'):
                            conditions_loaded += 1
        
        # Load conditions from appendices
        appendices = json_data.get('appendices', [])
        for appendix in appendices:
            key_rule = appendix.get('key_rule')
            if key_rule:
                rule_code = key_rule.get('rule_id')
                rule_id = rule_mapping.get(rule_code)
                
                if rule_id:
                    # Load trigger conditions from appendix
                    triggers = key_rule.get('triggers', {})
                    trigger_conditions = triggers.get('conditions', [])
                    for condition_data in trigger_conditions:
                        if self._create_condition(rule_id, condition_data, 'trigger'):
                            conditions_loaded += 1
        
        logger.info(f"Loaded {conditions_loaded} conditions")
    
    def _create_condition(self, rule_id: int, condition_data: dict, condition_type: str) -> bool:
        """Create a single condition"""
        
        # Handle different condition data structures
        if condition_type == 'description_only':
            condition_record = {
                'rule_id': rule_id,
                'condition_key': condition_data.get('id', 'unknown'),
                'parameter': None,
                'operator': None,
                'value': None,
                'unit': None,
                'description': condition_data.get('description', ''),
                'data_type': None,
                'condition_type': condition_type,
                'condition_details': json.dumps(condition_data),
                'created_by': 'osha_loader_v2',
                'updated_by': 'osha_loader_v2'
            }
        else:
            # Regular trigger/exception condition with logic
            condition_record = {
                'rule_id': rule_id,
                'condition_key': condition_data.get('id', 'unknown'),
                'parameter': condition_data.get('condition'),
                'operator': condition_data.get('operator'),
                'value': str(condition_data.get('value', '')),
                'unit': condition_data.get('unit'),
                'description': condition_data.get('condition', ''),
                'data_type': self._infer_data_type(condition_data.get('value')),
                'condition_type': condition_type,
                'condition_details': json.dumps(condition_data),
                'created_by': 'osha_loader_v2',
                'updated_by': 'osha_loader_v2'
            }
        
        insert_sql = """
        INSERT INTO condition (
            rule_id, condition_key, parameter, operator, value, unit,
            description, data_type, condition_type, condition_details,
            created_by, updated_by
        ) VALUES (
            %(rule_id)s, %(condition_key)s, %(parameter)s, %(operator)s, %(value)s, %(unit)s,
            %(description)s, %(data_type)s, %(condition_type)s, %(condition_details)s,
            %(created_by)s, %(updated_by)s
        )
        """
        
        try:
            self.cursor.execute(insert_sql, condition_record)
            self.conn.commit()
            return True
            
        except Exception as e:
            self.conn.rollback()
            logger.error(f"Failed to create condition {condition_data.get('id')}: {e}")
            return False
    
    def _infer_data_type(self, value: Any) -> str:
        """Infer data type from value"""
        if value is None:
            return 'string'
        
        value_str = str(value).lower()
        
        if value_str in ['true', 'false']:
            return 'boolean'
        
        try:
            float(value_str)
            return 'numeric'
        except ValueError:
            pass
        
        return 'string'
    
    def load_definitions(self, json_data: dict, regulation_id: int):
        """Load definitions from sections where rule_type is 'informational'"""
        definitions_loaded = 0
        sections = json_data.get('sections', [])
        
        for section in sections:
            if section.get('title') == 'Definitions':  # Definition sections
                subsections = section.get('subsections', [])
                for subsection in subsections:
                    rules = subsection.get('rules', [])
                    for rule_json in rules:
                        # Extract term from rule_id (e.g., "1926.500(b)-hole" -> "hole")
                        rule_id = rule_json.get('rule_id', '')
                        if '-' in rule_id:
                            term = rule_id.split('-')[-1]
                        else:
                            term = rule_json.get('requirement', 'unknown_term')
                        
                        definition_text = rule_json.get('text', '')
                        context = section.get('section_number', '')
                        
                        if self._create_definition(regulation_id, term, definition_text, context):
                            definitions_loaded += 1
        
        logger.info(f"Loaded {definitions_loaded} definitions")
    
    def _create_definition(self, regulation_id: int, term: str, definition_text: str, context: str) -> bool:
        """Create a single definition"""
        definition_record = {
            'regulation_id': regulation_id,
            'term': term,
            'definition_text': definition_text,
            'context_section': context,
            'created_by': 'osha_loader_v2',
            'updated_by': 'osha_loader_v2'
        }
        
        insert_sql = """
        INSERT INTO definition (
            regulation_id, term, definition_text, context_section, created_by, updated_by
        ) VALUES (
            %(regulation_id)s, %(term)s, %(definition_text)s, %(context_section)s, %(created_by)s, %(updated_by)s
        )
        """
        
        try:
            self.cursor.execute(insert_sql, definition_record)
            self.conn.commit()
            return True
            
        except Exception as e:
            self.conn.rollback()
            logger.error(f"Failed to create definition for term '{term}': {e}")
            return False
    
    def load_appendices(self, json_data: dict, regulation_id: int):
        """Load appendices into appendix table"""
        appendices_loaded = 0
        appendices = json_data.get('appendices', [])
        
        for appendix in appendices:
            appendix_record = {
                'regulation_id': regulation_id,
                'title': appendix.get('title'),
                'content_text': appendix.get('purpose'),
                'appendix_type': 'guidance',
                'created_by': 'osha_loader_v2',
                'updated_by': 'osha_loader_v2'
            }
            
            insert_sql = """
            INSERT INTO appendix (
                regulation_id, title, content_text, appendix_type, created_by, updated_by
            ) VALUES (
                %(regulation_id)s, %(title)s, %(content_text)s, %(appendix_type)s, %(created_by)s, %(updated_by)s
            )
            """
            
            try:
                self.cursor.execute(insert_sql, appendix_record)
                self.conn.commit()
                appendices_loaded += 1
                
            except Exception as e:
                self.conn.rollback()
                logger.error(f"Failed to create appendix '{appendix.get('title')}': {e}")
        
        logger.info(f"Loaded {appendices_loaded} appendices")
    
    def validate_json_structure(self, json_data: dict) -> bool:
        """Validate JSON structure before loading"""
        required_fields = ['regulation', 'sections']
        
        for field in required_fields:
            if field not in json_data:
                logger.error(f"Missing required field: {field}")
                return False
        
        regulation = json_data['regulation']
        reg_required = ['part', 'subpart', 'title']
        for field in reg_required:
            if field not in regulation:
                logger.error(f"Missing required regulation field: {field}")
                return False
        
        logger.info("JSON structure validation passed")
        return True
    
    def cleanup_previous_data(self, regulation_id: int):
        """Clean up existing data for this regulation before loading new data"""
        try:
            # Delete in reverse foreign key order
            self.cursor.execute("DELETE FROM condition WHERE rule_id IN (SELECT rule_id FROM rule WHERE regulation_id = %s)", (regulation_id,))
            self.cursor.execute("DELETE FROM training_requirement WHERE rule_id IN (SELECT rule_id FROM rule WHERE regulation_id = %s)", (regulation_id,))
            self.cursor.execute("DELETE FROM rule_version_tag_map WHERE rule_id IN (SELECT rule_id FROM rule WHERE regulation_id = %s)", (regulation_id,))
            self.cursor.execute("DELETE FROM rule WHERE regulation_id = %s", (regulation_id,))
            self.cursor.execute("DELETE FROM definition WHERE regulation_id = %s", (regulation_id,))
            self.cursor.execute("DELETE FROM appendix WHERE regulation_id = %s", (regulation_id,))
            
            self.conn.commit()
            logger.info("Cleaned up previous data for regulation")
            
        except Exception as e:
            self.conn.rollback()
            logger.error(f"Failed to cleanup previous data: {e}")
            raise
    
    def generate_summary_report(self, regulation_id: int):
        """Generate a summary report of loaded data"""
        try:
            # Count loaded records
            self.cursor.execute("""
                SELECT 
                    COUNT(DISTINCT r.rule_id) as rules_count,
                    COUNT(DISTINCT c.condition_id) as conditions_count,
                    COUNT(DISTINCT d.definition_id) as definitions_count,
                    COUNT(DISTINCT a.appendix_id) as appendices_count
                FROM regulation reg
                LEFT JOIN rule r ON reg.regulation_id = r.regulation_id
                LEFT JOIN condition c ON r.rule_id = c.rule_id
                LEFT JOIN definition d ON reg.regulation_id = d.regulation_id
                LEFT JOIN appendix a ON reg.regulation_id = a.regulation_id
                WHERE reg.regulation_id = %s
            """, (regulation_id,))
            
            summary = self.cursor.fetchone()
            
            logger.info("=== LOAD SUMMARY ===")
            logger.info(f"Rules loaded: {summary['rules_count']}")
            logger.info(f"Conditions loaded: {summary['conditions_count']}")
            logger.info(f"Definitions loaded: {summary['definitions_count']}")
            logger.info(f"Appendices loaded: {summary['appendices_count']}")
            logger.info("===================")
            
        except Exception as e:
            logger.error(f"Failed to generate summary report: {e}")
    
    def load_complete_dataset(self, json_file_path: str, clean_existing: bool = True):
        """
        Main orchestration method to load complete OSHA dataset
        """
        logger.info(f"Starting OSHA data load from: {json_file_path}")
        
        try:
            # Load and validate JSON
            with open(json_file_path, 'r', encoding='utf-8') as f:
                json_data = json.load(f)
            
            if not self.validate_json_structure(json_data):
                raise ValueError("Invalid JSON structure")
            
            # Connect to database
            self.connect()
            
            # Load regulation first to get regulation_id
            logger.info("Phase 1: Loading regulation...")
            regulation_id = self.load_regulation(json_data)
            
            # Clean existing data if requested
            if clean_existing:
                logger.info("Phase 1.5: Cleaning existing data...")
                self.cleanup_previous_data(regulation_id)
            
            # Load data in proper order (respecting foreign key constraints)
            logger.info("Phase 2: Loading rules...")
            rule_mapping = self.load_rules(json_data, regulation_id)
            
            logger.info("Phase 3: Loading conditions...")
            self.load_conditions(json_data, rule_mapping)
            
            logger.info("Phase 4: Loading definitions...")
            self.load_definitions(json_data, regulation_id)
            
            logger.info("Phase 5: Loading appendices...")
            self.load_appendices(json_data, regulation_id)
            
            # Generate summary report
            self.generate_summary_report(regulation_id)
            
            logger.info("✅ OSHA data load completed successfully!")
            
        except Exception as e:
            logger.error(f"❌ Data load failed: {e}")
            raise
        finally:
            self.disconnect()

def main():
    """Main entry point"""
    if len(sys.argv) < 2:
        print("Usage: python osha_loader_v2.py <json_file_path> [--keep-existing]")
        print("Example: python osha_loader_v2.py SubpartM_Updated.json")
        print("Options:")
        print("  --keep-existing    Don't clean existing data before loading")
        sys.exit(1)
    
    json_file_path = sys.argv[1]
    clean_existing = '--keep-existing' not in sys.argv
    
    try:
        loader = OSHADataLoader(DB_CONFIG)
        loader.load_complete_dataset(json_file_path, clean_existing)
        print("✅ Data loading completed successfully!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()