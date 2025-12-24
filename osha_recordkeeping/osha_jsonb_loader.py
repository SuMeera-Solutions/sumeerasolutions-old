#!/usr/bin/env python3
"""
Single JSONB Table Loader for 29 CFR Part 1904
Loads the extracted 29 CFR 1904 JSON data into the simplified single JSONB table model
with flexible loading modes and comprehensive validation
"""

import json
import psycopg2
import psycopg2.extras
from datetime import datetime, date
import logging
from typing import Dict, List, Any, Optional
import sys
import hashlib
import argparse
from enum import Enum

# Database configuration
DB_CONFIG = {
    'host': 'rds-dev-compliease-pg.cm9ok286yrdx.us-east-1.rds.amazonaws.com',
    'username': 'postgres',
    'password': '0XNfzbSGvzzvWc40Ra7U',
    'database': 'compliease_sbx',
    'schema': 'osha_1904'
}

class LoadMode(Enum):
    """Loading modes for the data loader"""
    TRUNCATE_LOAD = "truncate_load"
    INCREMENTAL = "incremental"
    UPDATE_EXISTING = "update_existing"
    VALIDATE_ONLY = "validate_only"

def setup_logging(log_level: str = "INFO"):
    """Setup logging with configurable level"""
    numeric_level = getattr(logging, log_level.upper(), None)
    if not isinstance(numeric_level, int):
        raise ValueError(f'Invalid log level: {log_level}')
    
    logging.basicConfig(
        level=numeric_level,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    return logging.getLogger(__name__)

class OSHAJSONBLoader:
    """Simplified loader for OSHA regulation data into single JSONB table"""
    
    def __init__(self, db_config: dict, load_mode: LoadMode = LoadMode.INCREMENTAL, 
                 dry_run: bool = False, backup_enabled: bool = True):
        self.db_config = db_config
        self.load_mode = load_mode
        self.dry_run = dry_run
        self.backup_enabled = backup_enabled
        self.conn = None
        self.cursor = None
        self.logger = logging.getLogger(__name__)
        self.changes_detected = False
        self.backup_tables = []
        
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
            
            if not self.dry_run:
                self.conn.commit()
                
            self.logger.info(f"Connected to database: {self.db_config['database']}, schema: {self.db_config['schema']}")
            self.logger.info(f"Load mode: {self.load_mode.value}, Dry run: {self.dry_run}")
            
        except Exception as e:
            self.logger.error(f"Database connection failed: {e}")
            raise
    
    def disconnect(self):
        """Close database connection"""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()
        self.logger.info("Database connection closed")
    
    def _calculate_content_hash(self, data: dict) -> str:
        """Calculate hash of the data content for change detection"""
        content_str = json.dumps(data, sort_keys=True, default=str)
        return hashlib.sha256(content_str.encode()).hexdigest()
    
    def _parse_date(self, date_str: str) -> Optional[date]:
        """Parse date string into date object"""
        if not date_str:
            return None
        try:
            return datetime.strptime(date_str, '%Y-%m-%d').date()
        except:
            try:
                return datetime.strptime(date_str, '%m/%d/%Y').date()
            except:
                self.logger.warning(f"Could not parse date: {date_str}")
                return None
    
    def _execute_query(self, query: str, params: dict = None, fetch_result: bool = False):
        """Execute query with dry run support"""
        if self.dry_run:
            self.logger.debug(f"DRY RUN - Query: {query}")
            if params:
                self.logger.debug(f"DRY RUN - Params: {params}")
            return None
        else:
            self.cursor.execute(query, params)
            if fetch_result:
                return self.cursor.fetchone()
            return None
    
    def _backup_table(self, table_name: str):
        """Create backup of table before modifications"""
        if not self.backup_enabled or self.dry_run:
            return
            
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_table = f"{table_name}_backup_{timestamp}"
        
        self.logger.info(f"Creating backup: {backup_table}")
        backup_query = f"""
            CREATE TABLE {backup_table} AS 
            SELECT * FROM {table_name}
        """
        self.cursor.execute(backup_query)
        self.backup_tables.append(backup_table)
    
    def create_table_if_not_exists(self):
        """Create the regulations table if it doesn't exist"""
        create_table_sql = """
        CREATE TABLE IF NOT EXISTS regulations (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            regulation_id TEXT NOT NULL,
            version TEXT NOT NULL,
            effective_date DATE NOT NULL,
            last_updated TIMESTAMP NOT NULL,
            parsing_date TIMESTAMP NOT NULL,
            content_hash TEXT NOT NULL,
            source_url TEXT,
            is_current BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP DEFAULT NOW(),
            
            -- Complete regulation content as single JSONB document
            content JSONB NOT NULL,
            
            UNIQUE(regulation_id, version)
        );
        """
        
        if not self.dry_run:
            self.cursor.execute(create_table_sql)
            self.conn.commit()
            self.logger.info("Created regulations table (if not exists)")
        else:
            self.logger.debug("DRY RUN - Would create regulations table")
    
    def create_indexes_if_not_exist(self):
        """Create all necessary indexes"""
        indexes = [
            "CREATE INDEX IF NOT EXISTS idx_regulation_current ON regulations(regulation_id, is_current) WHERE is_current = TRUE",
            "CREATE INDEX IF NOT EXISTS idx_regulation_effective ON regulations(effective_date DESC)",
            "CREATE INDEX IF NOT EXISTS idx_content_gin ON regulations USING GIN (content)",
            "CREATE INDEX IF NOT EXISTS idx_naics_codes ON regulations USING GIN ((content->'company_applicability'->'naics_codes'))",
            "CREATE INDEX IF NOT EXISTS idx_size_exemptions ON regulations USING GIN ((content->'company_applicability'->'size_exemptions'))",
            "CREATE INDEX IF NOT EXISTS idx_decision_tree ON regulations USING GIN ((content->'recording_criteria'->'recordability_decision_tree'))",
            "CREATE INDEX IF NOT EXISTS idx_forms ON regulations USING GIN ((content->'form_requirements'->'required_forms'))",
            "CREATE INDEX IF NOT EXISTS idx_government_reporting ON regulations USING GIN ((content->'government_reporting'))",
        ]
        
        if not self.dry_run:
            for index_sql in indexes:
                try:
                    self.cursor.execute(index_sql)
                    self.logger.debug(f"Created index: {index_sql.split()[5]}")
                except Exception as e:
                    self.logger.warning(f"Could not create index: {e}")
            self.conn.commit()
            self.logger.info("Created all indexes")
        else:
            self.logger.debug(f"DRY RUN - Would create {len(indexes)} indexes")
    
    def create_functions_if_not_exist(self):
        """Create utility functions"""
        functions = [
            """
            CREATE OR REPLACE FUNCTION get_current_regulation(p_regulation_id TEXT DEFAULT '29_CFR_1904')
            RETURNS JSONB AS $$
            BEGIN
                RETURN (
                    SELECT content 
                    FROM regulations 
                    WHERE regulation_id = p_regulation_id AND is_current = TRUE
                    LIMIT 1
                );
            END;
            $$ LANGUAGE plpgsql;
            """,
            """
            CREATE OR REPLACE FUNCTION check_company_applicability(
                p_employee_count INTEGER,
                p_naics_code TEXT
            ) RETURNS JSONB AS $$
            DECLARE
                v_regulation JSONB;
                v_result JSONB;
                v_size_exempt BOOLEAN := FALSE;
                v_industry_exempt BOOLEAN := FALSE;
            BEGIN
                -- Get current regulation
                SELECT content INTO v_regulation
                FROM regulations 
                WHERE regulation_id = '29_CFR_1904' AND is_current = TRUE
                LIMIT 1;
                
                IF v_regulation IS NULL THEN
                    RETURN jsonb_build_object('error', 'No current regulation found');
                END IF;
                
                -- Check size exemption (10 or fewer employees)
                v_size_exempt := p_employee_count <= 10;
                
                -- Check industry exemption  
                SELECT EXISTS(
                    SELECT 1 FROM jsonb_array_elements(
                        v_regulation->'company_applicability'->'industry_exemptions'->0->'naics_codes'
                    ) AS nc
                    WHERE nc->>'code' = p_naics_code
                ) INTO v_industry_exempt;
                
                v_result := jsonb_build_object(
                    'employee_count', p_employee_count,
                    'naics_code', p_naics_code,
                    'is_size_exempt', v_size_exempt,
                    'is_industry_exempt', v_industry_exempt,
                    'must_keep_records', NOT (v_size_exempt OR v_industry_exempt),
                    'exemption_details', jsonb_build_object(
                        'size_exemptions', CASE WHEN v_size_exempt THEN 
                            v_regulation->'company_applicability'->'size_exemptions' 
                            ELSE '[]'::jsonb END,
                        'industry_exemptions', CASE WHEN v_industry_exempt THEN
                            v_regulation->'company_applicability'->'industry_exemptions'
                            ELSE '[]'::jsonb END
                    )
                );
                
                RETURN v_result;
            END;
            $$ LANGUAGE plpgsql;
            """,
            """
            CREATE OR REPLACE FUNCTION insert_regulation_version(
                p_regulation_id TEXT,
                p_version TEXT,
                p_effective_date DATE,
                p_content JSONB
            ) RETURNS UUID AS $$
            DECLARE
                v_id UUID;
            BEGIN
                -- Set all existing versions to not current
                UPDATE regulations 
                SET is_current = FALSE 
                WHERE regulation_id = p_regulation_id;
                
                -- Insert new version
                INSERT INTO regulations (
                    regulation_id, version, effective_date, 
                    last_updated, parsing_date, content_hash, is_current, content
                ) VALUES (
                    p_regulation_id, p_version, p_effective_date,
                    NOW(), NOW(), md5(p_content::text), TRUE, p_content
                ) RETURNING id INTO v_id;
                
                RETURN v_id;
            END;
            $$ LANGUAGE plpgsql;
            """
        ]
        
        if not self.dry_run:
            for function_sql in functions:
                try:
                    self.cursor.execute(function_sql)
                    self.logger.debug("Created function")
                except Exception as e:
                    self.logger.warning(f"Could not create function: {e}")
            self.conn.commit()
            self.logger.info("Created utility functions")
        else:
            self.logger.debug(f"DRY RUN - Would create {len(functions)} functions")
    
    def check_version_exists(self, regulation_id: str, version: str, content_hash: str) -> dict:
        """Check if version already exists and detect changes"""
        self.cursor.execute("""
            SELECT id, content_hash, is_current, last_updated
            FROM regulations 
            WHERE regulation_id = %s AND version = %s
        """, (regulation_id, version))
        
        existing = self.cursor.fetchone()
        
        if existing:
            content_changed = existing['content_hash'] != content_hash
            return {
                'exists': True,
                'regulation_id': existing['id'],
                'content_changed': content_changed,
                'is_current': existing['is_current'],
                'last_updated': existing['last_updated']
            }
        else:
            return {'exists': False, 'content_changed': True}
    
    def validate_json_structure(self, json_data: dict) -> bool:
        """Validate that JSON has required structure"""
        required_sections = [
            'regulation_metadata',
            'company_applicability', 
            'recording_criteria',
            'form_requirements',
            'ongoing_obligations',
            'government_reporting',
            'reference_data'
        ]
        
        missing_sections = []
        for section in required_sections:
            if section not in json_data:
                missing_sections.append(section)
        
        if missing_sections:
            self.logger.error(f"Missing required sections: {missing_sections}")
            return False
        
        # Validate metadata
        metadata = json_data.get('regulation_metadata', {})
        required_metadata = ['regulation_id', 'effective_date']
        missing_metadata = [field for field in required_metadata if field not in metadata]
        
        if missing_metadata:
            self.logger.error(f"Missing required metadata: {missing_metadata}")
            return False
        
        self.logger.info("JSON structure validation passed")
        return True
    
    def load_regulation(self, json_data: dict, force_update: bool = False) -> str:
        """Load regulation data into single JSONB table"""
        
        # Extract metadata
        metadata = json_data.get('regulation_metadata', {})
        regulation_id = metadata.get('regulation_id', '29_CFR_1904')
        version = metadata.get('parsing_version', 'v1.0')
        effective_date = self._parse_date(metadata.get('effective_date'))
        source_url = metadata.get('source_url')
        
        # Calculate content hash
        content_hash = self._calculate_content_hash(json_data)
        
        # Check if version exists
        version_info = self.check_version_exists(regulation_id, version, content_hash)
        
        if self.load_mode == LoadMode.VALIDATE_ONLY:
            if version_info['exists']:
                if version_info['content_changed']:
                    self.logger.info(f"VALIDATION: Content changes detected for {regulation_id} {version}")
                    self.changes_detected = True
                else:
                    self.logger.info(f"VALIDATION: No content changes for {regulation_id} {version}")
            else:
                self.logger.info(f"VALIDATION: New version {regulation_id} {version} would be created")
                self.changes_detected = True
            return version_info.get('regulation_id')
        
        # Handle different load modes
        if self.load_mode == LoadMode.INCREMENTAL and version_info['exists'] and not version_info['content_changed']:
            self.logger.info(f"INCREMENTAL: No changes detected for {regulation_id} {version}, skipping")
            return version_info['regulation_id']
        
        if self.load_mode == LoadMode.UPDATE_EXISTING and version_info['exists']:
            if version_info['content_changed'] or force_update:
                self.logger.info(f"UPDATE: Updating existing version {regulation_id} {version}")
                regulation_record = {
                    'effective_date': effective_date,
                    'last_updated': datetime.now(),
                    'parsing_date': datetime.now(), 
                    'content_hash': content_hash,
                    'source_url': source_url,
                    'content': json.dumps(json_data),
                    'regulation_id': version_info['regulation_id']
                }
                
                update_query = """
                    UPDATE regulations 
                    SET effective_date = %(effective_date)s,
                        last_updated = %(last_updated)s,
                        parsing_date = %(parsing_date)s,
                        content_hash = %(content_hash)s,
                        source_url = %(source_url)s,
                        content = %(content)s::jsonb,
                        is_current = TRUE
                    WHERE id = %(regulation_id)s
                """
                self._execute_query(update_query, regulation_record)
                
                if not self.dry_run:
                    self.conn.commit()
                
                return version_info['regulation_id']
            else:
                self.logger.info(f"UPDATE: No changes detected for {regulation_id} {version}, skipping")
                return version_info['regulation_id']
        
        # For TRUNCATE_LOAD or new versions, create new version
        if self.load_mode == LoadMode.TRUNCATE_LOAD:
            # Backup and truncate
            if self.backup_enabled:
                self._backup_table('regulations')
            
            if not self.dry_run:
                self.cursor.execute("TRUNCATE TABLE regulations")
                self.logger.info("Truncated regulations table")
            else:
                self.logger.debug("DRY RUN - Would truncate regulations table")
        else:
            # Set all existing versions to not current for incremental/update modes
            self._execute_query(
                "UPDATE regulations SET is_current = FALSE WHERE regulation_id = %s",
                (regulation_id,)
            )
        
        # Insert new regulation version
        regulation_record = {
            'regulation_id': regulation_id,
            'version': version,
            'effective_date': effective_date,
            'last_updated': datetime.now(),
            'parsing_date': datetime.now(),
            'content_hash': content_hash,
            'source_url': source_url,
            'is_current': True,
            'content': json.dumps(json_data)
        }
        
        result = self._execute_query("""
            INSERT INTO regulations (
                regulation_id, version, effective_date, 
                last_updated, parsing_date, content_hash, source_url, is_current, content
            ) VALUES (
                %(regulation_id)s, %(version)s, %(effective_date)s,
                %(last_updated)s, %(parsing_date)s, %(content_hash)s, %(source_url)s, %(is_current)s, %(content)s::jsonb
            ) RETURNING id
        """, regulation_record, fetch_result=True)
        
        if not self.dry_run:
            new_id = result['id']
            self.conn.commit()
            self.logger.info(f"Loaded regulation: {regulation_id} {version} (ID: {new_id})")
            return new_id
        else:
            self.logger.info(f"DRY RUN - Would load regulation: {regulation_id} {version}")
            return 'DRY_RUN_ID'
    
    def cleanup_backup_tables(self, keep_backups: bool = False):
        """Clean up backup tables after successful load"""
        if keep_backups or self.dry_run:
            self.logger.info(f"Keeping {len(self.backup_tables)} backup tables")
            return
            
        for backup_table in self.backup_tables:
            try:
                self.cursor.execute(f"DROP TABLE IF EXISTS {backup_table}")
                self.logger.debug(f"Dropped backup table: {backup_table}")
            except Exception as e:
                self.logger.warning(f"Could not drop backup table {backup_table}: {e}")
        
        if self.backup_tables:
            self.conn.commit()
            self.logger.info(f"Cleaned up {len(self.backup_tables)} backup tables")
    
    def test_queries(self):
        """Test some basic queries after loading"""
        if self.dry_run:
            self.logger.info("DRY RUN - Skipping query tests")
            return
        
        test_queries = [
            ("Get current regulation", "SELECT regulation_id, version FROM regulations WHERE is_current = TRUE"),
            ("Test company applicability function", "SELECT check_company_applicability(8, '4412')"),
            ("Get decision tree", "SELECT content->'recording_criteria'->'recordability_decision_tree' FROM regulations WHERE is_current = TRUE"),
            ("Get NAICS codes", """
                SELECT nc.value->>'code' as naics_code, nc.value->>'industry' as industry
                FROM regulations r,
                     jsonb_array_elements(r.content->'company_applicability'->'industry_exemptions'->0->'naics_codes') nc
                WHERE r.is_current = TRUE
                LIMIT 5
            """)
        ]
        
        self.logger.info("Testing queries...")
        for test_name, query in test_queries:
            try:
                self.cursor.execute(query)
                result = self.cursor.fetchone()
                self.logger.info(f"✓ {test_name}: Success")
            except Exception as e:
                self.logger.error(f"✗ {test_name}: {e}")
    
    def generate_load_summary(self, json_data: dict) -> dict:
        """Generate summary of what would be loaded"""
        metadata = json_data.get('regulation_metadata', {})
        
        summary = {
            'regulation_id': metadata.get('regulation_id'),
            'version': metadata.get('parsing_version'),
            'effective_date': metadata.get('effective_date'),
            'load_mode': self.load_mode.value,
            'dry_run': self.dry_run,
            'content_size_kb': len(json.dumps(json_data)) / 1024,
            'main_sections': list(json_data.keys()),
            'structure_valid': self.validate_json_structure(json_data)
        }
        
        # Count some key items
        try:
            company_applicability = json_data.get('company_applicability', {})
            naics_count = 0
            for exemption in company_applicability.get('industry_exemptions', []):
                naics_count += len(exemption.get('naics_codes', []))
            
            recording_criteria = json_data.get('recording_criteria', {})
            decision_steps = len(recording_criteria.get('recordability_decision_tree', {}).get('decision_path', []))
            
            form_requirements = json_data.get('form_requirements', {})
            required_forms = len(form_requirements.get('required_forms', []))
            
            summary['counts'] = {
                'naics_codes': naics_count,
                'decision_tree_steps': decision_steps,
                'required_forms': required_forms,
                'definitions': len(json_data.get('reference_data', {}).get('definitions', {}))
            }
        except Exception as e:
            self.logger.warning(f"Could not generate detailed counts: {e}")
            summary['counts'] = {}
        
        return summary
    
    def load_dataset(self, json_file_path: str, force_update: bool = False, keep_backups: bool = False):
        """Main method to load the entire dataset"""
        
        self.logger.info(f"Starting OSHA 1904 JSONB load from: {json_file_path}")
        self.logger.info(f"Load mode: {self.load_mode.value}, Dry run: {self.dry_run}")
        
        try:
            # Load and validate JSON
            self.logger.info("Loading JSON file...")
            with open(json_file_path, 'r', encoding='utf-8') as f:
                json_data = json.load(f)
            
            # Generate load summary
            summary = self.generate_load_summary(json_data)
            self.logger.info(f"JSON loaded successfully: {summary['content_size_kb']:.1f} KB")
            
            if not summary['structure_valid']:
                raise ValueError("JSON structure validation failed")
            
            # Connect to database
            self.connect()
            
            # Setup database schema
            self.logger.info("Setting up database schema...")
            self.create_table_if_not_exists()
            self.create_indexes_if_not_exist()
            self.create_functions_if_not_exist()
            
            # Load regulation data
            self.logger.info("Loading regulation data...")
            regulation_id = self.load_regulation(json_data, force_update)
            
            if self.load_mode == LoadMode.VALIDATE_ONLY:
                self.logger.info(f"VALIDATION COMPLETE - Changes detected: {self.changes_detected}")
                return summary
            
            # Test queries
            self.test_queries()
            
            # Cleanup
            self.cleanup_backup_tables(keep_backups)
            
            self.logger.info("=== OSHA 1904 JSONB LOAD SUMMARY ===")
            self.logger.info(f"Load Mode: {self.load_mode.value}")
            self.logger.info(f"Dry Run: {self.dry_run}")
            self.logger.info(f"Regulation ID: {summary['regulation_id']}")
            self.logger.info(f"Version: {summary['version']}")
            self.logger.info(f"Effective Date: {summary['effective_date']}")
            self.logger.info(f"Content Size: {summary['content_size_kb']:.1f} KB")
            self.logger.info(f"Changes Detected: {self.changes_detected}")
            if summary['counts']:
                self.logger.info(f"Key Counts: {summary['counts']}")
            if self.backup_tables:
                self.logger.info(f"Backup Tables Created: {len(self.backup_tables)}")
            self.logger.info("Data loading completed successfully!")
            
            return summary
            
        except Exception as e:
            self.logger.error(f"Data loading failed: {e}")
            if self.conn and not self.dry_run:
                self.conn.rollback()
            raise
        finally:
            self.disconnect()

def main():
    """Main entry point with argument parsing"""
    parser = argparse.ArgumentParser(
        description='OSHA 1904 Single JSONB Table Loader',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Loading Modes:
  truncate_load    - Clear all existing data and load fresh (default)
  incremental      - Only load if content has changed since last version
  update_existing  - Update existing version in place if content changed
  validate_only    - Check for changes without loading data

Examples:
  # Standard truncate and load
  python osha_jsonb_loader.py data.json

  # Incremental load (only if changed)
  python osha_jsonb_loader.py data.json --mode incremental

  # Dry run to see what would happen
  python osha_jsonb_loader.py data.json --dry-run

  # Update existing version
  python osha_jsonb_loader.py data.json --mode update_existing

  # Validate changes only
  python osha_jsonb_loader.py data.json --mode validate_only
        """
    )
    
    parser.add_argument('json_file', help='Path to the JSON data file')
    parser.add_argument('--mode', '-m', 
                       choices=[mode.value for mode in LoadMode],
                       default=LoadMode.INCREMENTAL.value,
                       help='Loading mode (default: incremental)')
    parser.add_argument('--dry-run', '-d', action='store_true',
                       help='Perform dry run without making changes')
    parser.add_argument('--no-backup', action='store_true',
                       help='Disable backup table creation')
    parser.add_argument('--force-update', '-f', action='store_true',
                       help='Force update even if no content changes detected')
    parser.add_argument('--keep-backups', action='store_true',
                       help='Keep backup tables after successful load')
    parser.add_argument('--log-level', '-l',
                       choices=['DEBUG', 'INFO', 'WARNING', 'ERROR'],
                       default='INFO',
                       help='Set logging level (default: INFO)')
    
    args = parser.parse_args()
    
    # Setup logging
    logger = setup_logging(args.log_level)
    
    try:
        # Convert string to enum
        load_mode = LoadMode(args.mode)
        
        # Create loader with options
        loader = OSHAJSONBLoader(
            db_config=DB_CONFIG,
            load_mode=load_mode,
            dry_run=args.dry_run,
            backup_enabled=not args.no_backup
        )
        
        # Load dataset
        summary = loader.load_dataset(
            json_file_path=args.json_file,
            force_update=args.force_update,
            keep_backups=args.keep_backups
        )
        
        print("\n" + "="*50)
        print("LOAD COMPLETED SUCCESSFULLY")
        print("="*50)
        print(f"Mode: {args.mode}")
        print(f"Dry Run: {args.dry_run}")
        print(f"File: {args.json_file}")
        if summary:
            print(f"Regulation: {summary.get('regulation_id')}")
            print(f"Version: {summary.get('version')}")
            print(f"Content Size: {summary.get('content_size_kb', 0):.1f} KB")
            if summary.get('counts'):
                print(f"Key Items: {sum(summary['counts'].values())} total")
        
    except Exception as e:
        logger.error(f"Load failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()