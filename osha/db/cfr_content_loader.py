#!/usr/bin/env python3
"""
CFR Content Loader - Specialized for CFR Extended Schema
Loads CFR content from JSON into cfr_content and related tables
Focuses specifically on the CFR content structure
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
    'schema': 'osha_rules_v1'
}

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class CFRContentLoader:
    """Specialized loader for CFR content into extended schema"""
    
    def __init__(self, db_config: dict):
        self.db_config = db_config
        self.conn = None
        self.cursor = None
        self.content_type_map = {}
        self.regulation_id = None
        
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
            self.cursor.execute(f"SET search_path TO {self.db_config['schema']}")
            self.conn.commit()
            
            logger.info(f"Connected to database: {self.db_config['database']}")
            self._load_content_type_mapping()
            
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
    
    def _load_content_type_mapping(self):
        """Load content type IDs for quick lookup"""
        self.cursor.execute("SELECT content_type_id, type_name FROM cfr_content_type")
        for row in self.cursor.fetchall():
            self.content_type_map[row['type_name']] = row['content_type_id']
        logger.info(f"Loaded {len(self.content_type_map)} content types: {list(self.content_type_map.keys())}")
    
    def find_or_create_regulation(self, document_metadata: dict) -> int:
        """Find existing regulation or create new one"""
        cfr_citation = document_metadata.get('cfr_citation', '')
        
        # Try to find existing regulation
        self.cursor.execute(
            "SELECT regulation_id FROM regulation WHERE regulation_code = %s",
            (cfr_citation,)
        )
        result = self.cursor.fetchone()
        
        if result:
            self.regulation_id = result['regulation_id']
            logger.info(f"Found existing regulation: {cfr_citation} (ID: {self.regulation_id})")
            return self.regulation_id
        
        # Create new regulation
        parts = cfr_citation.split()
        title_num = 29  # Default for OSHA
        part = ""
        subpart = ""
        
        if len(parts) >= 4:
            title_num = int(parts[0]) if parts[0].isdigit() else 29
            part = parts[2] if len(parts) > 2 else ""
            if len(parts) > 3:
                subpart = " ".join(parts[3:])
        
        regulation_record = {
            'regulation_code': cfr_citation,
            'title_number': title_num,
            'title': document_metadata.get('title'),
            'part': part,
            'subpart': subpart,
            'section_title': document_metadata.get('title'),
            'authority': document_metadata.get('authority'),
            'effective_date': document_metadata.get('effective_date'),
            'last_updated': document_metadata.get('last_updated'),
            'applies_to': 'All employments except maritime, construction, and agriculture',
            'excludes': [],
            'source_data': json.dumps(document_metadata),
            'created_by': 'cfr_content_loader',
            'updated_by': 'cfr_content_loader'
        }
        
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
        RETURNING regulation_id
        """
        
        self.cursor.execute(insert_sql, regulation_record)
        self.regulation_id = self.cursor.fetchone()['regulation_id']
        self.conn.commit()
        
        logger.info(f"Created new regulation: {cfr_citation} (ID: {self.regulation_id})")
        return self.regulation_id
    
    def load_content_item(self, content_item: dict) -> Optional[int]:
        """Load a single CFR content item"""
        
        content_type = content_item.get('content_type')
        if content_type not in self.content_type_map:
            logger.error(f"Unknown content type: {content_type}")
            return None
        
        content_type_id = self.content_type_map[content_type]
        source_location = content_item.get('source_location', {})
        content_data = content_item.get('content', {})
        
        # Build content code from source location
        section = source_location.get('section', '')
        subsection = source_location.get('subsection', '')
        content_code = f"{section}{subsection}" if subsection else section
        
        content_record = {
            'regulation_id': self.regulation_id,
            'content_type_id': content_type_id,
            'content_code': content_code,
            'title': content_data.get('title'),
            'section_number': source_location.get('section'),
            'subsection': source_location.get('subsection'),
            'paragraph': source_location.get('paragraph'),
            'page_number': source_location.get('page_number'),
            'line_reference': source_location.get('line_reference'),
            'hierarchy_path': content_item.get('hierarchy_path'),
            'content_text': content_data.get('text'),
            'summary': content_data.get('summary'),
            'category': content_data.get('category'),
            'status': content_data.get('status'),
            'source_location': json.dumps(source_location),
            'cross_references': json.dumps(content_item.get('cross_references', [])),
            'related_terms': self._convert_to_array(content_item.get('related_terms', [])),
            'rule_id': None,  # Will be set separately if needed
            'source_data': json.dumps(content_item),
            'created_by': 'cfr_content_loader',
            'updated_by': 'cfr_content_loader'
        }
        
        insert_sql = """
        INSERT INTO cfr_content (
            regulation_id, content_type_id, content_code, title,
            section_number, subsection, paragraph, page_number, line_reference,
            hierarchy_path, content_text, summary, category, status,
            source_location, cross_references, related_terms, rule_id,
            source_data, created_by, updated_by
        ) VALUES (
            %(regulation_id)s, %(content_type_id)s, %(content_code)s, %(title)s,
            %(section_number)s, %(subsection)s, %(paragraph)s, %(page_number)s, %(line_reference)s,
            %(hierarchy_path)s, %(content_text)s, %(summary)s, %(category)s, %(status)s,
            %(source_location)s, %(cross_references)s, %(related_terms)s, %(rule_id)s,
            %(source_data)s, %(created_by)s, %(updated_by)s
        ) 
        ON CONFLICT (content_code) WHERE is_current = TRUE AND is_deleted = FALSE
        DO UPDATE SET
            title = EXCLUDED.title,
            content_text = EXCLUDED.content_text,
            summary = EXCLUDED.summary,
            category = EXCLUDED.category,
            status = EXCLUDED.status,
            source_location = EXCLUDED.source_location,
            cross_references = EXCLUDED.cross_references,
            related_terms = EXCLUDED.related_terms,
            source_data = EXCLUDED.source_data,
            updated_by = EXCLUDED.updated_by,
            updated_at = CURRENT_TIMESTAMP
        RETURNING content_id
        """
        
        try:
            self.cursor.execute(insert_sql, content_record)
            content_id = self.cursor.fetchone()['content_id']
            self.conn.commit()
            
            logger.info(f"Loaded content: {content_type} - {content_code} - {content_data.get('title')} (ID: {content_id})")
            return content_id
            
        except Exception as e:
            self.conn.rollback()
            logger.error(f"Failed to load content {content_code}: {e}")
            return None
    
    def load_training_details(self, content_id: int, content_item: dict) -> bool:
        """Load training-specific details"""
        
        training_details = content_item.get('training_details', {})
        procedure_steps = content_item.get('procedure_steps', [])
        required_elements = content_item.get('required_elements', [])
        
        training_record = {
            'content_id': content_id,
            'frequency': training_details.get('frequency'),
            'scope': training_details.get('scope'),
            'trainer_requirements': training_details.get('trainer_requirements'),
            'audience': training_details.get('audience'),
            'quality_benchmark': training_details.get('quality_benchmark'),
            'example_institutions': self._convert_to_array(training_details.get('example_institutions', [])),
            'industry_specific': training_details.get('industry_specific'),
            'trigger_condition': training_details.get('trigger'),
            'performance_standard': training_details.get('performance_standard'),
            'procedure_steps': self._convert_to_array(procedure_steps),
            'required_elements': self._convert_to_array(required_elements)
        }
        
        insert_sql = """
        INSERT INTO cfr_training_details (
            content_id, frequency, scope, trainer_requirements, audience,
            quality_benchmark, example_institutions, industry_specific,
            trigger_condition, performance_standard, procedure_steps, required_elements
        ) VALUES (
            %(content_id)s, %(frequency)s, %(scope)s, %(trainer_requirements)s, %(audience)s,
            %(quality_benchmark)s, %(example_institutions)s, %(industry_specific)s,
            %(trigger_condition)s, %(performance_standard)s, %(procedure_steps)s, %(required_elements)s
        )
        """
        
        try:
            self.cursor.execute(insert_sql, training_record)
            self.conn.commit()
            logger.info(f"Loaded training details for content_id {content_id}")
            return True
        except Exception as e:
            self.conn.rollback()
            logger.error(f"Failed to load training details for content_id {content_id}: {e}")
            return False
    
    def load_reference_details(self, content_id: int, content_item: dict) -> bool:
        """Load reference-specific details"""
        
        reference_details = content_item.get('reference_details', {})
        
        reference_record = {
            'content_id': content_id,
            'standard_id': reference_details.get('standard_id'),
            'reference_title': reference_details.get('title'),
            'organization': reference_details.get('organization'),
            'publication_year': reference_details.get('publication_year'),
            'purpose': reference_details.get('purpose'),
            'incorporation_method': reference_details.get('incorporation_method'),
            'publication_title': reference_details.get('publication_title')
        }
        
        insert_sql = """
        INSERT INTO cfr_reference_details (
            content_id, standard_id, reference_title, organization,
            publication_year, purpose, incorporation_method, publication_title
        ) VALUES (
            %(content_id)s, %(standard_id)s, %(reference_title)s, %(organization)s,
            %(publication_year)s, %(purpose)s, %(incorporation_method)s, %(publication_title)s
        )
        """
        
        try:
            self.cursor.execute(insert_sql, reference_record)
            self.conn.commit()
            logger.info(f"Loaded reference details for content_id {content_id}")
            return True
        except Exception as e:
            self.conn.rollback()
            logger.error(f"Failed to load reference details for content_id {content_id}: {e}")
            return False
    
    def load_appendix_details(self, content_id: int, content_item: dict) -> bool:
        """Load appendix-specific details"""
        
        appendix_details = content_item.get('appendix_details', {})
        
        appendix_record = {
            'content_id': content_id,
            'appendix_type': appendix_details.get('type'),
            'purpose': appendix_details.get('purpose'),
            'scope': appendix_details.get('scope'),
            'content_areas': self._convert_to_array(appendix_details.get('content_areas', [])),
            'organizations': self._convert_to_array(appendix_details.get('organizations', [])),
            'coverage': appendix_details.get('coverage'),
            'test_methods': self._convert_to_array(appendix_details.get('test_methods', [])),
            'includes': self._convert_to_array(appendix_details.get('includes', []))
        }
        
        insert_sql = """
        INSERT INTO cfr_appendix_details (
            content_id, appendix_type, purpose, scope, content_areas,
            organizations, coverage, test_methods, includes
        ) VALUES (
            %(content_id)s, %(appendix_type)s, %(purpose)s, %(scope)s, %(content_areas)s,
            %(organizations)s, %(coverage)s, %(test_methods)s, %(includes)s
        )
        """
        
        try:
            self.cursor.execute(insert_sql, appendix_record)
            self.conn.commit()
            logger.info(f"Loaded appendix details for content_id {content_id}")
            return True
        except Exception as e:
            self.conn.rollback()
            logger.error(f"Failed to load appendix details for content_id {content_id}: {e}")
            return False
    
    def _convert_to_array(self, value: Any) -> List[str]:
        """Convert various formats to PostgreSQL array format"""
        if isinstance(value, list):
            return [str(item).strip() for item in value if item and str(item).strip()]
        elif isinstance(value, str) and value.strip():
            return [value.strip()]
        else:
            return []
    
    def cleanup_existing_content(self, regulation_id: int):
        """Clean up existing CFR content for this regulation"""
        try:
            # Delete detail tables first (foreign key constraints)
            self.cursor.execute("""
                DELETE FROM cfr_training_details 
                WHERE content_id IN (SELECT content_id FROM cfr_content WHERE regulation_id = %s)
            """, (regulation_id,))
            
            self.cursor.execute("""
                DELETE FROM cfr_reference_details 
                WHERE content_id IN (SELECT content_id FROM cfr_content WHERE regulation_id = %s)
            """, (regulation_id,))
            
            self.cursor.execute("""
                DELETE FROM cfr_appendix_details 
                WHERE content_id IN (SELECT content_id FROM cfr_content WHERE regulation_id = %s)
            """, (regulation_id,))
            
            # Delete main content
            self.cursor.execute("DELETE FROM cfr_content WHERE regulation_id = %s", (regulation_id,))
            
            self.conn.commit()
            logger.info(f"Cleaned up existing CFR content for regulation_id {regulation_id}")
            
        except Exception as e:
            self.conn.rollback()
            logger.error(f"Failed to cleanup existing content: {e}")
            raise
    
    def load_cfr_dataset(self, json_file_path: str, clean_existing: bool = True):
        """Main method to load CFR dataset"""
        
        logger.info(f"Starting CFR content load from: {json_file_path}")
        
        try:
            # Load JSON
            with open(json_file_path, 'r', encoding='utf-8') as f:
                json_data = json.load(f)
            
            # Validate structure
            if 'document_metadata' not in json_data or 'extracted_content' not in json_data:
                raise ValueError("Invalid JSON structure - missing document_metadata or extracted_content")
            
            # Connect to database
            self.connect()
            
            # Find or create regulation
            logger.info("Phase 1: Processing regulation...")
            regulation_id = self.find_or_create_regulation(json_data['document_metadata'])
            
            # Clean existing content if requested
            if clean_existing:
                logger.info("Phase 2: Cleaning existing content...")
                self.cleanup_existing_content(regulation_id)
            
            # Load content items
            logger.info("Phase 3: Loading CFR content items...")
            extracted_content = json_data['extracted_content']
            loaded_counts = {
                'definition': 0,
                'training': 0, 
                'procedure': 0,
                'reference': 0,
                'appendix': 0
            }
            
            detail_counts = {
                'training_details': 0,
                'reference_details': 0,
                'appendix_details': 0
            }
            
            for content_item in extracted_content:
                content_type = content_item.get('content_type')
                content_id = self.load_content_item(content_item)
                
                if content_id:
                    loaded_counts[content_type] = loaded_counts.get(content_type, 0) + 1
                    
                    # Load specialized details for specific content types
                    if content_type == 'training' and 'training_details' in content_item:
                        if self.load_training_details(content_id, content_item):
                            detail_counts['training_details'] += 1
                    
                    elif content_type == 'reference' and 'reference_details' in content_item:
                        if self.load_reference_details(content_id, content_item):
                            detail_counts['reference_details'] += 1
                    
                    elif content_type == 'appendix' and 'appendix_details' in content_item:
                        if self.load_appendix_details(content_id, content_item):
                            detail_counts['appendix_details'] += 1
            
            # Generate summary
            logger.info("=== CFR LOAD SUMMARY ===")
            logger.info(f"Regulation ID: {regulation_id}")
            for content_type, count in loaded_counts.items():
                logger.info(f"{content_type.title()}: {count}")
            
            logger.info("--- Detail Tables ---")
            for detail_type, count in detail_counts.items():
                logger.info(f"{detail_type}: {count}")
            
            total_content = sum(loaded_counts.values())
            total_details = sum(detail_counts.values())
            logger.info(f"Total content items: {total_content}")
            logger.info(f"Total detail records: {total_details}")
            logger.info("========================")
            
            logger.info("CFR content loading completed successfully!")
            
        except Exception as e:
            logger.error(f"CFR content loading failed: {e}")
            raise
        finally:
            self.disconnect()

def main():
    """Main entry point"""
    if len(sys.argv) < 2:
        print("Usage: python cfr_content_loader.py <json_file_path> [--keep-existing]")
        print("Example: python cfr_content_loader.py cfr_fire_protection_extraction.json")
        print("Options:")
        print("  --keep-existing    Don't clean existing content before loading")
        sys.exit(1)
    
    json_file_path = sys.argv[1]
    clean_existing = '--keep-existing' not in sys.argv
    
    try:
        loader = CFRContentLoader(DB_CONFIG)
        loader.load_cfr_dataset(json_file_path, clean_existing)
        print("CFR content loading completed successfully!")
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()