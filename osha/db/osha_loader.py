#!/usr/bin/env python3
"""
OSHA JSON to PostgreSQL Data Loader
Loads OSHA regulations from JSON into the osha_rules schema
"""

import json
import psycopg2
import psycopg2.extras
from datetime import datetime
import logging
from typing import Dict, List, Any, Optional
import sys

# Database configuration
DB_CONFIG = {
    'host': 'rds-dev-compliease-pg.cm9ok286yrdx.us-east-1.rds.amazonaws.com',
    'username': 'postgres',
    'password': '0XNfzbSGvzzvWc40Ra7U',
    'database': 'compliease_sbx',
    'schema': 'osha_rules'
}

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class OSHADataLoader:
    """Loads OSHA JSON data into PostgreSQL database"""
    
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
            return [str(item) for item in value if item]  # Filter out empty/None items
        elif isinstance(value, str) and value.strip():
            return [value.strip()]
        else:
            return []
    
    def generate_regulation_code(self, regulation: dict) -> str:
        """Generate standardized regulation code"""
        title_num = regulation.get('title_number', 29)
        part = regulation.get('part', '')
        subpart = regulation.get('subpart', '')
        return f"{title_num}-CFR-{part}-Subpart-{subpart}"
    
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
            'title_number': regulation_data.get('title_number', 29),
            'title': regulation_data.get('title'),
            'part': regulation_data.get('part'),
            'subpart': regulation_data.get('subpart'),
            'section_title': regulation_data.get('section_title'),
            'authority': regulation_data.get('authority'),
            'effective_date': regulation_data.get('effective_date'),
            'last_updated': regulation_data.get('last_updated'),
            'applies_to': regulation_data.get('applies_to'),
            'excludes': self.convert_to_array(regulation_data.get('excludes', [])),
            'source_data': json.dumps(regulation_data),
            'created_by': 'osha_loader',
            'updated_by': 'osha_loader'
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
        ) RETURNING regulation_id
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
        Returns: Dictionary mapping rule_id to rule_version_id
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
                    rule_version_id = self._load_single_rule(
                        rule_json, regulation_id,
                        section_number, section_title,
                        subsection_number, subsection_title
                    )
                    
                    if rule_version_id:
                        rule_mapping[rule_json['rule_id']] = rule_version_id
        
        logger.info(f"Loaded {len(rule_mapping)} rules")
        return rule_mapping
    
    def _load_single_rule(self, rule_json: dict, regulation_id: int,
                         section_number: str, section_title: str,
                         subsection_number: str, subsection_title: str) -> Optional[int]:
        """Load a single rule into the rule table"""
        
        # Handle different JSON field names
        applies_to_field = rule_json.get('applies_to')
        if isinstance(applies_to_field, str):
            applies_to_array = [applies_to_field]
        elif isinstance(applies_to_field, list):
            applies_to_array = applies_to_field
        else:
            applies_to_array = []
        
        # Handle work_types vs work_types
        work_types_array = self.convert_to_array(rule_json.get('work_types'))
        
        # Handle protections - ensure it's an array
        protections_array = self.convert_to_array(rule_json.get('protections'))
        
        # Handle exceptions - ensure it's an array  
        exceptions_array = self.convert_to_array(rule_json.get('exceptions'))
        
        rule_record = {
            'rule_id': rule_json.get('rule_id'),
            'regulation_id': regulation_id,
            'rule_text': rule_json.get('text'),
            'rule_type': rule_json.get('type'),
            'compliance_requirement': rule_json.get('requirement'),
            'severity': rule_json.get('severity'),
            'section_number': section_number,
            'section_title': section_title,
            'subsection': subsection_number,
            'subsection_title': subsection_title,
            'applies_to': applies_to_array,
            'work_types': work_types_array,
            'protections': protections_array,
            'exceptions': exceptions_array,
            'source_data': json.dumps(rule_json),
            'created_by': 'osha_loader',
            'updated_by': 'osha_loader'
        }
        
        insert_sql = """
        INSERT INTO rule (
            rule_id, regulation_id, rule_text, rule_type, compliance_requirement, severity,
            section_number, section_title, subsection, subsection_title,
            applies_to, work_types, protections, exceptions,
            source_data, created_by, updated_by
        ) VALUES (
            %(rule_id)s, %(regulation_id)s, %(rule_text)s, %(rule_type)s, %(compliance_requirement)s, %(severity)s,
            %(section_number)s, %(section_title)s, %(subsection)s, %(subsection_title)s,
            %(applies_to)s, %(work_types)s, %(protections)s, %(exceptions)s,
            %(source_data)s, %(created_by)s, %(updated_by)s
        ) RETURNING rule_version_id
        """
        
        try:
            self.cursor.execute(insert_sql, rule_record)
            rule_version_id = self.cursor.fetchone()['rule_version_id']
            self.conn.commit()
            
            logger.info(f"Loaded rule: {rule_json.get('rule_id')} (Version ID: {rule_version_id})")
            return rule_version_id
            
        except Exception as e:
            self.conn.rollback()
            logger.error(f"Failed to load rule {rule_json.get('rule_id')}: {e}")
            return None
    
    def load_conditions(self, json_data: dict, rule_mapping: Dict[str, int]):
        """Load conditions from rule triggers into condition_group and condition tables"""
        sections = json_data.get('sections', [])
        condition_groups_loaded = 0
        conditions_loaded = 0
        
        for section in sections:
            subsections = section.get('subsections', [])
            for subsection in subsections:
                rules = subsection.get('rules', [])
                for rule_json in rules:
                    rule_id = rule_json.get('rule_id')
                    rule_version_id = rule_mapping.get(rule_id)
                    
                    if not rule_version_id:
                        continue
                    
                    triggers = rule_json.get('triggers', [])
                    if triggers:
                        # Create condition group
                        condition_group_id = self._create_condition_group(
                            rule_version_id, rule_id, len(triggers)
                        )
                        
                        if condition_group_id:
                            condition_groups_loaded += 1
                            
                            # Create individual conditions
                            for i, trigger in enumerate(triggers):
                                if self._create_condition(condition_group_id, rule_version_id, trigger, i + 1):
                                    conditions_loaded += 1
        
        logger.info(f"Loaded {condition_groups_loaded} condition groups and {conditions_loaded} conditions")
    
    def _create_condition_group(self, rule_version_id: int, rule_id: str, trigger_count: int) -> Optional[int]:
        """Create a condition group for a rule"""
        group_record = {
            'rule_version_id': rule_version_id,
            'logic_operator': 'AND',  # Default - could be enhanced to parse from JSON
            'group_sequence': 1,
            'description': f'Conditions for rule {rule_id} ({trigger_count} conditions)',
            'created_by': 'osha_loader',
            'updated_by': 'osha_loader'
        }
        
        insert_sql = """
        INSERT INTO condition_group (
            rule_version_id, logic_operator, group_sequence, description, created_by, updated_by
        ) VALUES (
            %(rule_version_id)s, %(logic_operator)s, %(group_sequence)s, %(description)s, %(created_by)s, %(updated_by)s
        ) RETURNING condition_group_id
        """
        
        try:
            self.cursor.execute(insert_sql, group_record)
            condition_group_id = self.cursor.fetchone()['condition_group_id']
            self.conn.commit()
            return condition_group_id
            
        except Exception as e:
            self.conn.rollback()
            logger.error(f"Failed to create condition group for rule {rule_id}: {e}")
            return None
    
    def _create_condition(self, condition_group_id: int, rule_version_id: int, 
                         trigger: dict, sequence: int) -> bool:
        """Create a single condition"""
        condition_record = {
            'rule_version_id': rule_version_id,
            'condition_group_id': condition_group_id,
            'parameter': trigger.get('condition'),
            'operator': trigger.get('operator'),
            'value': str(trigger.get('value')),
            'unit': trigger.get('unit'),
            'sequence_order': sequence,
            'expression_json': json.dumps(trigger),
            'created_by': 'osha_loader',
            'updated_by': 'osha_loader'
        }
        
        insert_sql = """
        INSERT INTO condition (
            rule_version_id, condition_group_id, parameter, operator, value, unit,
            sequence_order, expression_json, created_by, updated_by
        ) VALUES (
            %(rule_version_id)s, %(condition_group_id)s, %(parameter)s, %(operator)s, %(value)s, %(unit)s,
            %(sequence_order)s, %(expression_json)s, %(created_by)s, %(updated_by)s
        )
        """
        
        try:
            self.cursor.execute(insert_sql, condition_record)
            self.conn.commit()
            return True
            
        except Exception as e:
            self.conn.rollback()
            logger.error(f"Failed to create condition: {e}")
            return False
    
    def load_definitions(self, json_data: dict, regulation_id: int):
        """Load definitions from regulation key_definitions or definitions object"""
        definitions_loaded = 0
        
        # Check for definitions in regulation level (Fall Protection format)
        regulation = json_data.get('regulation', {})
        key_definitions = regulation.get('key_definitions', {})
        
        for term, definition_text in key_definitions.items():
            if self._create_definition(regulation_id, term, definition_text, 'regulation'):
                definitions_loaded += 1
        
        # Check for top-level definitions object (Fall Protection format)
        definitions_obj = json_data.get('definitions', {})
        for term, definition_text in definitions_obj.items():
            if self._create_definition(regulation_id, term, definition_text, 'top_level'):
                definitions_loaded += 1
        
        # Check for definitions in rule level (Scaffolds format)
        sections = json_data.get('sections', [])
        for section in sections:
            subsections = section.get('subsections', [])
            for subsection in subsections:
                rules = subsection.get('rules', [])
                for rule_json in rules:
                    rule_definitions = rule_json.get('key_definitions', {})
                    for term, definition_text in rule_definitions.items():
                        context = f"{section.get('section_number')}.{subsection.get('subsection')}"
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
            'created_by': 'osha_loader',
            'updated_by': 'osha_loader'
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
        
        # Validate sections structure
        sections = json_data.get('sections', [])
        if not sections:
            logger.warning("No sections found in JSON data")
            return True  # Allow empty sections, might be a definitions-only file
        
        # Check section structure
        for i, section in enumerate(sections):
            if 'section_number' not in section:
                logger.error(f"Section {i} missing 'section_number'")
                return False
            if 'subsections' not in section:
                logger.error(f"Section {section.get('section_number')} missing 'subsections'")
                return False
        
        logger.info("JSON structure validation passed")
        return True
    
    def load_complete_dataset(self, json_file_path: str):
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
            
            # Load data in proper order (respecting foreign key constraints)
            logger.info("Phase 1: Loading regulation...")
            regulation_id = self.load_regulation(json_data)
            
            logger.info("Phase 2: Loading rules...")
            rule_mapping = self.load_rules(json_data, regulation_id)
            
            logger.info("Phase 3: Loading conditions...")
            self.load_conditions(json_data, rule_mapping)
            
            logger.info("Phase 4: Loading definitions...")
            self.load_definitions(json_data, regulation_id)
            
            logger.info("✅ OSHA data load completed successfully!")
            logger.info(f"Summary: 1 regulation, {len(rule_mapping)} rules loaded")
            
        except Exception as e:
            logger.error(f"❌ Data load failed: {e}")
            raise
        finally:
            self.disconnect()

def main():
    """Main entry point"""
    if len(sys.argv) != 2:
        print("Usage: python osha_loader.py <json_file_path>")
        print("Example: python osha_loader.py osha_scaffolds_1926L.json")
        sys.exit(1)
    
    json_file_path = sys.argv[1]
    
    try:
        loader = OSHADataLoader(DB_CONFIG)
        loader.load_complete_dataset(json_file_path)
        print("✅ Data loading completed successfully!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()