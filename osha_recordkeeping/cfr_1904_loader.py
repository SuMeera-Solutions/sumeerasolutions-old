#!/usr/bin/env python3
"""
Enhanced 29 CFR Part 1904 Data Loader
Loads the extracted 29 CFR 1904 JSON data into the PostgreSQL data model
with flexible loading modes: truncate/load, incremental, and update capabilities
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
    'schema': 'osha_recordkeeping'
}

class LoadMode(Enum):
    """Loading modes for the data loader"""
    TRUNCATE_LOAD = "truncate_load"
    INCREMENTAL = "incremental"
    UPDATE_EXISTING = "update_existing"
    VALIDATE_ONLY = "validate_only"

# Setup logging
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

class CFR1904EnhancedLoader:
    """Enhanced loader for 29 CFR Part 1904 data with flexible loading modes"""
    
    def __init__(self, db_config: dict, load_mode: LoadMode = LoadMode.INCREMENTAL, 
                 dry_run: bool = False, backup_enabled: bool = True):
        self.db_config = db_config
        self.load_mode = load_mode
        self.dry_run = dry_run
        self.backup_enabled = backup_enabled
        self.conn = None
        self.cursor = None
        self.version_id = None
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
    
    def _truncate_all_tables(self):
        """Truncate all tables in dependency order"""
        tables_to_truncate = [
            'required_reporting_information',
            'reporting_methods',
            'immediate_reporting_requirements',
            'first_aid_treatments',
            'regulatory_definitions',
            'privacy_concern_cases',
            'form_required_information',
            'required_forms',
            'specific_recording_criteria',
            'criterion_additional_requirements',
            'general_recording_criteria',
            'work_relatedness_exceptions',
            'work_relatedness_criteria',
            'decision_tree_steps',
            'naics_codes',
            'size_exemption_exceptions',
            'size_exemptions',
            'regulation_amendments',
            'regulation_authorities',
            'regulation_versions'
        ]
        
        if self.backup_enabled:
            for table in reversed(tables_to_truncate):  # Backup in reverse order
                self._backup_table(table)
        
        self.logger.info("Truncating all tables...")
        for table in tables_to_truncate:
            if not self.dry_run:
                self.cursor.execute(f"TRUNCATE TABLE {table} CASCADE")
                self.logger.debug(f"Truncated table: {table}")
            else:
                self.logger.debug(f"DRY RUN - Would truncate table: {table}")
    
    def check_version_exists(self, regulation_id: str, version_number: str, content_hash: str) -> dict:
        """Check if version already exists and detect changes"""
        self.cursor.execute("""
            SELECT id, content_hash, is_current, last_updated
            FROM regulation_versions 
            WHERE regulation_id = %s AND version_number = %s
        """, (regulation_id, version_number))
        
        existing = self.cursor.fetchone()
        
        if existing:
            content_changed = existing['content_hash'] != content_hash
            return {
                'exists': True,
                'version_id': existing['id'],
                'content_changed': content_changed,
                'is_current': existing['is_current'],
                'last_updated': existing['last_updated']
            }
        else:
            return {'exists': False, 'content_changed': True}
    
    def create_regulation_version(self, metadata: dict, force_update: bool = False) -> str:
        """Create or update regulation version based on load mode"""
        regulation_id = metadata.get('regulation_id', '29_CFR_1904')
        version_number = metadata.get('parsing_version', 'v1.0')
        effective_date = self._parse_date(metadata.get('effective_date'))
        content_hash = metadata.get('content_hash', '')
        source_url = metadata.get('source_url')
        
        # Check if version exists
        version_info = self.check_version_exists(regulation_id, version_number, content_hash)
        
        if self.load_mode == LoadMode.VALIDATE_ONLY:
            if version_info['exists']:
                if version_info['content_changed']:
                    self.logger.info(f"VALIDATION: Content changes detected for {regulation_id} {version_number}")
                    self.changes_detected = True
                else:
                    self.logger.info(f"VALIDATION: No content changes for {regulation_id} {version_number}")
            else:
                self.logger.info(f"VALIDATION: New version {regulation_id} {version_number} would be created")
                self.changes_detected = True
            return version_info.get('version_id')
        
        # Handle different load modes
        if self.load_mode == LoadMode.INCREMENTAL and version_info['exists'] and not version_info['content_changed']:
            self.logger.info(f"INCREMENTAL: No changes detected for {regulation_id} {version_number}, skipping")
            self.version_id = version_info['version_id']
            return version_info['version_id']
        
        if self.load_mode == LoadMode.UPDATE_EXISTING and version_info['exists']:
            if version_info['content_changed'] or force_update:
                self.logger.info(f"UPDATE: Updating existing version {regulation_id} {version_number}")
                self._delete_version_data(version_info['version_id'])
                self.version_id = version_info['version_id']
                # Update the existing record
                update_query = """
                    UPDATE regulation_versions 
                    SET effective_date = %(effective_date)s,
                        last_updated = %(last_updated)s,
                        parsing_date = %(parsing_date)s,
                        content_hash = %(content_hash)s,
                        source_url = %(source_url)s,
                        is_current = TRUE
                    WHERE id = %(version_id)s
                """
                self._execute_query(update_query, {
                    'effective_date': effective_date,
                    'last_updated': datetime.now(),
                    'parsing_date': datetime.now(),
                    'content_hash': content_hash,
                    'source_url': source_url,
                    'version_id': version_info['version_id']
                })
                return version_info['version_id']
            else:
                self.logger.info(f"UPDATE: No changes detected for {regulation_id} {version_number}, skipping")
                self.version_id = version_info['version_id']
                return version_info['version_id']
        
        # For TRUNCATE_LOAD or new versions, create new version
        if self.load_mode != LoadMode.TRUNCATE_LOAD and not version_info['exists']:
            # Set all existing versions to not current for incremental/update modes
            self._execute_query(
                "UPDATE regulation_versions SET is_current = FALSE WHERE regulation_id = %s",
                (regulation_id,)
            )
        
        # Insert new version
        version_record = {
            'regulation_id': regulation_id,
            'version_number': version_number,
            'effective_date': effective_date,
            'last_updated': datetime.now(),
            'parsing_date': datetime.now(),
            'content_hash': content_hash,
            'source_url': source_url,
            'is_current': True
        }
        
        result = self._execute_query("""
            INSERT INTO regulation_versions (
                regulation_id, version_number, effective_date, 
                last_updated, parsing_date, content_hash, source_url, is_current
            ) VALUES (
                %(regulation_id)s, %(version_number)s, %(effective_date)s,
                %(last_updated)s, %(parsing_date)s, %(content_hash)s, %(source_url)s, %(is_current)s
            ) RETURNING id
        """, version_record, fetch_result=True)
        
        if not self.dry_run:
            version_id = result['id']
            self.version_id = version_id
            self.conn.commit()
        else:
            self.version_id = 'DRY_RUN_VERSION_ID'
            version_id = self.version_id
        
        self.logger.info(f"Created regulation version: {regulation_id} {version_number} (ID: {version_id})")
        return version_id
    
    def _delete_version_data(self, version_id: str):
        """Delete all data for a specific version (for updates)"""
        delete_tables = [
            'required_reporting_information',
            'reporting_methods', 
            'immediate_reporting_requirements',
            'first_aid_treatments',
            'regulatory_definitions',
            'privacy_concern_cases',
            'form_required_information',
            'required_forms',
            'specific_recording_criteria',
            'criterion_additional_requirements',
            'general_recording_criteria',
            'work_relatedness_exceptions',
            'work_relatedness_criteria',
            'decision_tree_steps',
            'naics_codes',
            'size_exemption_exceptions',
            'size_exemptions',
            'regulation_amendments',
            'regulation_authorities'
        ]
        
        for table in delete_tables:
            if 'version_id' in self._get_table_columns(table):
                self._execute_query(f"DELETE FROM {table} WHERE version_id = %s", (version_id,))
            elif table in ['work_relatedness_exceptions', 'criterion_additional_requirements']:
                # These tables have foreign keys to tables with version_id
                continue  # Will be deleted by CASCADE
    
    def _get_table_columns(self, table_name: str) -> List[str]:
        """Get column names for a table"""
        if self.dry_run:
            return ['version_id']  # Assume version_id exists for dry run
        
        self.cursor.execute("""
            SELECT column_name 
            FROM information_schema.columns 
            WHERE table_name = %s AND table_schema = %s
        """, (table_name, self.db_config['schema']))
        
        return [row['column_name'] for row in self.cursor.fetchall()]
    
    def load_regulation_authorities(self, legal_basis: List[str]):
        """Load legal authorities"""
        if self.load_mode == LoadMode.VALIDATE_ONLY:
            self.logger.debug(f"VALIDATION: Would load {len(legal_basis)} legal authorities")
            return
            
        for citation in legal_basis:
            authority_type = 'USC' if 'U.S.C.' in citation else 'CFR' if 'CFR' in citation else 'Other'
            
            authority_record = {
                'version_id': self.version_id,
                'authority_type': authority_type,
                'citation': citation,
                'description': None
            }
            
            self._execute_query("""
                INSERT INTO regulation_authorities (version_id, authority_type, citation, description)
                VALUES (%(version_id)s, %(authority_type)s, %(citation)s, %(description)s)
            """, authority_record)
        
        if not self.dry_run:
            self.conn.commit()
        self.logger.info(f"Loaded {len(legal_basis)} legal authorities")
    
    def load_regulation_amendments(self, editorial_notes: List[dict]):
        """Load editorial notes and amendments"""
        if self.load_mode == LoadMode.VALIDATE_ONLY:
            self.logger.debug(f"VALIDATION: Would load {len(editorial_notes)} editorial notes")
            return
            
        for note in editorial_notes:
            amendment_record = {
                'version_id': self.version_id,
                'amendment_date': self._parse_date(note.get('date')),
                'federal_register_citation': note.get('citation'),
                'amendment_type': 'modification',
                'description': note.get('note', '')
            }
            
            self._execute_query("""
                INSERT INTO regulation_amendments (version_id, amendment_date, federal_register_citation, amendment_type, description)
                VALUES (%(version_id)s, %(amendment_date)s, %(federal_register_citation)s, %(amendment_type)s, %(description)s)
            """, amendment_record)
        
        if not self.dry_run:
            self.conn.commit()
        self.logger.info(f"Loaded {len(editorial_notes)} editorial notes")
    
    def load_size_exemptions(self, size_exemptions: List[dict]):
        """Load size-based exemptions"""
        if self.load_mode == LoadMode.VALIDATE_ONLY:
            self.logger.debug(f"VALIDATION: Would load {len(size_exemptions)} size exemptions")
            return
            
        for exemption in size_exemptions:
            exemption_record = {
                'version_id': self.version_id,
                'exemption_id': exemption.get('exemption_id'),
                'regulation_ref': exemption.get('regulation_ref'),
                'employee_threshold': 10,  # Extract from condition
                'condition_description': exemption.get('condition'),
                'scope': exemption.get('scope'),
                'result_description': exemption.get('result'),
                'verbatim_text': exemption.get('verbatim_text')
            }
            
            result = self._execute_query("""
                INSERT INTO size_exemptions (version_id, exemption_id, regulation_ref, employee_threshold, 
                                           condition_description, scope, result_description, verbatim_text)
                VALUES (%(version_id)s, %(exemption_id)s, %(regulation_ref)s, %(employee_threshold)s,
                        %(condition_description)s, %(scope)s, %(result_description)s, %(verbatim_text)s)
                RETURNING id
            """, exemption_record, fetch_result=True)
            
            if not self.dry_run:
                exemption_id = result['id']
            else:
                exemption_id = 'DRY_RUN_EXEMPTION_ID'
            
            # Load exceptions
            for exception in exemption.get('exceptions', []):
                exception_record = {
                    'size_exemption_id': exemption_id,
                    'exception_type': exception.get('exception_type'),
                    'requirement_description': exception.get('requirement'),
                    'regulation_ref': exception.get('regulation_ref')
                }
                
                self._execute_query("""
                    INSERT INTO size_exemption_exceptions (size_exemption_id, exception_type, requirement_description, regulation_ref)
                    VALUES (%(size_exemption_id)s, %(exception_type)s, %(requirement_description)s, %(regulation_ref)s)
                """, exception_record)
        
        if not self.dry_run:
            self.conn.commit()
        self.logger.info(f"Loaded {len(size_exemptions)} size exemptions")
    
    def load_naics_codes(self, company_applicability: dict):
        """Load NAICS codes from all sources"""
        if self.load_mode == LoadMode.VALIDATE_ONLY:
            self.logger.debug("VALIDATION: Would load NAICS codes")
            return
            
        naics_loaded = 0
        
        # Load from industry exemptions
        for exemption in company_applicability.get('industry_exemptions', []):
            for naics_item in exemption.get('naics_codes', []):
                naics_record = {
                    'version_id': self.version_id,
                    'naics_code': naics_item.get('code'),
                    'industry_description': naics_item.get('industry'),
                    'exemption_type': 'partial_exemption',
                    'appendix_reference': 'A'
                }
                
                self._execute_query("""
                    INSERT INTO naics_codes (version_id, naics_code, industry_description, exemption_type, appendix_reference)
                    VALUES (%(version_id)s, %(naics_code)s, %(industry_description)s, %(exemption_type)s, %(appendix_reference)s)
                """, naics_record)
                naics_loaded += 1
        
        # Load from reference data appendices
        reference_data = company_applicability.get('reference_data', {}).get('naics_codes', {})
        
        for appendix_key, naics_list in reference_data.items():
            exemption_type = appendix_key.replace('appendix_', '').replace('_', '_')
            appendix_ref = 'A' if 'appendix_a' in appendix_key else 'B' if 'appendix_b' in appendix_key else 'Other'
            
            for naics_item in naics_list:
                naics_record = {
                    'version_id': self.version_id,
                    'naics_code': naics_item.get('naics_code'),
                    'industry_description': naics_item.get('industry'),
                    'exemption_type': exemption_type,
                    'appendix_reference': appendix_ref
                }
                
                self._execute_query("""
                    INSERT INTO naics_codes (version_id, naics_code, industry_description, exemption_type, appendix_reference)
                    VALUES (%(version_id)s, %(naics_code)s, %(industry_description)s, %(exemption_type)s, %(appendix_reference)s)
                """, naics_record)
                naics_loaded += 1
        
        if not self.dry_run:
            self.conn.commit()
        self.logger.info(f"Loaded {naics_loaded} NAICS codes")
    
    def load_decision_tree_steps(self, recording_criteria: dict):
        """Load recording decision tree steps"""
        if self.load_mode == LoadMode.VALIDATE_ONLY:
            self.logger.debug("VALIDATION: Would load decision tree steps")
            return
            
        decision_tree = recording_criteria.get('recordability_decision_tree', {})
        decision_path = decision_tree.get('decision_path', [])
        
        for step in decision_path:
            step_record = {
                'version_id': self.version_id,
                'step_number': step.get('step'),
                'question': step.get('question'),
                'regulation_ref': step.get('regulation_ref'),
                'yes_path_action': step.get('yes_path'),
                'no_path_action': step.get('no_path'),
                'determination_method': step.get('determination_method'),
                'notes': step.get('notes')
            }
            
            self._execute_query("""
                INSERT INTO decision_tree_steps (version_id, step_number, question, regulation_ref, 
                                               yes_path_action, no_path_action, determination_method, notes)
                VALUES (%(version_id)s, %(step_number)s, %(question)s, %(regulation_ref)s,
                        %(yes_path_action)s, %(no_path_action)s, %(determination_method)s, %(notes)s)
            """, step_record)
        
        if not self.dry_run:
            self.conn.commit()
        self.logger.info(f"Loaded {len(decision_path)} decision tree steps")
    
    def load_work_relatedness_criteria(self, recording_criteria: dict):
        """Load work-relatedness criteria and exceptions"""
        if self.load_mode == LoadMode.VALIDATE_ONLY:
            self.logger.debug("VALIDATION: Would load work-relatedness criteria")
            return
            
        work_criteria = recording_criteria.get('work_relatedness_criteria', {})
        
        criteria_record = {
            'version_id': self.version_id,
            'regulation_ref': work_criteria.get('regulation_ref'),
            'basic_requirement': work_criteria.get('basic_requirement'),
            'presumption_rule': work_criteria.get('presumption'),
            'work_environment_definition': work_criteria.get('work_environment_definition')
        }
        
        result = self._execute_query("""
            INSERT INTO work_relatedness_criteria (version_id, regulation_ref, basic_requirement, presumption_rule, work_environment_definition)
            VALUES (%(version_id)s, %(regulation_ref)s, %(basic_requirement)s, %(presumption_rule)s, %(work_environment_definition)s)
            RETURNING id
        """, criteria_record, fetch_result=True)
        
        if not self.dry_run:
            criteria_id = result['id']
        else:
            criteria_id = 'DRY_RUN_CRITERIA_ID'
        
        # Load exceptions
        for exception in work_criteria.get('exceptions', []):
            exception_record = {
                'criteria_id': criteria_id,
                'exception_type': exception.get('exception'),
                'description': exception.get('description'),
                'notes': exception.get('note', '')
            }
            
            self._execute_query("""
                INSERT INTO work_relatedness_exceptions (criteria_id, exception_type, description, notes)
                VALUES (%(criteria_id)s, %(exception_type)s, %(description)s, %(notes)s)
            """, exception_record)
        
        if not self.dry_run:
            self.conn.commit()
        self.logger.info(f"Loaded work-relatedness criteria with {len(work_criteria.get('exceptions', []))} exceptions")
    
    def load_general_recording_criteria(self, recording_criteria: dict):
        """Load general recording criteria"""
        if self.load_mode == LoadMode.VALIDATE_ONLY:
            self.logger.debug("VALIDATION: Would load general recording criteria")
            return
            
        general_criteria = recording_criteria.get('general_recording_criteria', [])
        
        for criterion in general_criteria:
            criterion_record = {
                'version_id': self.version_id,
                'criterion_name': criterion.get('criterion'),
                'regulation_ref': criterion.get('regulation_ref'),
                'condition_description': criterion.get('condition'),
                'form_name': criterion.get('form_action', {}).get('form'),
                'form_action': criterion.get('form_action', {}).get('action')
            }
            
            result = self._execute_query("""
                INSERT INTO general_recording_criteria (version_id, criterion_name, regulation_ref, condition_description, form_name, form_action)
                VALUES (%(version_id)s, %(criterion_name)s, %(regulation_ref)s, %(condition_description)s, %(form_name)s, %(form_action)s)
                RETURNING id
            """, criterion_record, fetch_result=True)
            
            if not self.dry_run:
                criterion_id = result['id']
            else:
                criterion_id = 'DRY_RUN_CRITERION_ID'
            
            # Load additional requirements
            for req in criterion.get('additional_requirements', []):
                req_record = {
                    'criterion_id': criterion_id,
                    'requirement_type': req.get('requirement'),
                    'timing': req.get('timing'),
                    'regulation_ref': req.get('regulation_ref'),
                    'description': req.get('requirement')
                }
                
                self._execute_query("""
                    INSERT INTO criterion_additional_requirements (criterion_id, requirement_type, timing, regulation_ref, description)
                    VALUES (%(criterion_id)s, %(requirement_type)s, %(timing)s, %(regulation_ref)s, %(description)s)
                """, req_record)
        
        if not self.dry_run:
            self.conn.commit()
        self.logger.info(f"Loaded {len(general_criteria)} general recording criteria")
    
    def load_specific_recording_criteria(self, recording_criteria: dict):
        """Load specific recording criteria (needlestick, hearing loss, etc.)"""
        if self.load_mode == LoadMode.VALIDATE_ONLY:
            self.logger.debug("VALIDATION: Would load specific recording criteria")
            return
            
        specific_criteria = recording_criteria.get('specific_recording_criteria', {})
        
        for criterion_type, details in specific_criteria.items():
            criterion_record = {
                'version_id': self.version_id,
                'criterion_type': criterion_type,
                'regulation_ref': details.get('regulation_ref'),
                'requirement_description': details.get('requirement'),
                'form_entry_instructions': details.get('form_entry'),
                'privacy_protection_required': details.get('privacy_protection') == 'may_not_enter_employee_name_use_privacy_case_procedures'
            }
            
            self._execute_query("""
                INSERT INTO specific_recording_criteria (version_id, criterion_type, regulation_ref, requirement_description, form_entry_instructions, privacy_protection_required)
                VALUES (%(version_id)s, %(criterion_type)s, %(regulation_ref)s, %(requirement_description)s, %(form_entry_instructions)s, %(privacy_protection_required)s)
            """, criterion_record)
        
        if not self.dry_run:
            self.conn.commit()
        self.logger.info(f"Loaded {len(specific_criteria)} specific recording criteria")
    
    def load_required_forms(self, form_requirements: dict):
        """Load required forms and their details"""
        if self.load_mode == LoadMode.VALIDATE_ONLY:
            self.logger.debug("VALIDATION: Would load required forms")
            return
            
        required_forms = form_requirements.get('required_forms', [])
        
        for form in required_forms:
            form_record = {
                'version_id': self.version_id,
                'form_id': form.get('form_id'),
                'form_name': form.get('form_name'),
                'regulation_ref': form.get('regulation_ref'),
                'purpose_description': form.get('purpose'),
                'completion_deadline': form.get('completion_timing', {}).get('deadline'),
                'completion_trigger': form.get('completion_timing', {}).get('trigger')
            }
            
            result = self._execute_query("""
                INSERT INTO required_forms (version_id, form_id, form_name, regulation_ref, purpose_description, completion_deadline, completion_trigger)
                VALUES (%(version_id)s, %(form_id)s, %(form_name)s, %(regulation_ref)s, %(purpose_description)s, %(completion_deadline)s, %(completion_trigger)s)
                RETURNING id
            """, form_record, fetch_result=True)
            
            if not self.dry_run:
                form_db_id = result['id']
            else:
                form_db_id = 'DRY_RUN_FORM_ID'
            
            # Load required information
            for info in form.get('required_information', []):
                info_record = {
                    'form_id': form_db_id,
                    'information_type': info,
                    'description': info,
                    'is_required': True
                }
                
                self._execute_query("""
                    INSERT INTO form_required_information (form_id, information_type, description, is_required)
                    VALUES (%(form_id)s, %(information_type)s, %(description)s, %(is_required)s)
                """, info_record)
        
        if not self.dry_run:
            self.conn.commit()
        self.logger.info(f"Loaded {len(required_forms)} required forms")
    
    def load_privacy_concern_cases(self, form_requirements: dict):
        """Load privacy concern cases"""
        if self.load_mode == LoadMode.VALIDATE_ONLY:
            self.logger.debug("VALIDATION: Would load privacy concern cases")
            return
            
        privacy_protections = form_requirements.get('privacy_protections', {})
        privacy_cases = privacy_protections.get('complete_list_privacy_concern_cases', [])
        
        for case_type in privacy_cases:
            case_record = {
                'version_id': self.version_id,
                'case_type': case_type,
                'description': case_type.replace('_', ' ').title(),
                'handling_instructions': privacy_protections.get('privacy_case_procedures', {}).get('log_entry')
            }
            
            self._execute_query("""
                INSERT INTO privacy_concern_cases (version_id, case_type, description, handling_instructions)
                VALUES (%(version_id)s, %(case_type)s, %(description)s, %(handling_instructions)s)
            """, case_record)
        
        if not self.dry_run:
            self.conn.commit()
        self.logger.info(f"Loaded {len(privacy_cases)} privacy concern cases")
    
    def load_immediate_reporting_requirements(self, government_reporting: dict):
        """Load immediate reporting requirements"""
        if self.load_mode == LoadMode.VALIDATE_ONLY:
            self.logger.debug("VALIDATION: Would load immediate reporting requirements")
            return
            
        immediate_reporting = government_reporting.get('immediate_reporting', [])
        
        for requirement in immediate_reporting:
            req_record = {
                'version_id': self.version_id,
                'trigger_event': requirement.get('trigger'),
                'regulation_ref': requirement.get('regulation_ref'),
                'deadline': requirement.get('deadline'),
                'recipient': requirement.get('recipient')
            }
            
            result = self._execute_query("""
                INSERT INTO immediate_reporting_requirements (version_id, trigger_event, regulation_ref, deadline, recipient)
                VALUES (%(version_id)s, %(trigger_event)s, %(regulation_ref)s, %(deadline)s, %(recipient)s)
                RETURNING id
            """, req_record, fetch_result=True)
            
            if not self.dry_run:
                req_id = result['id']
            else:
                req_id = 'DRY_RUN_REQ_ID'
            
            # Load reporting methods
            for method in requirement.get('reporting_methods', []):
                method_record = {
                    'reporting_requirement_id': req_id,
                    'method_description': method,
                    'contact_info': None
                }
                
                self._execute_query("""
                    INSERT INTO reporting_methods (reporting_requirement_id, method_description, contact_info)
                    VALUES (%(reporting_requirement_id)s, %(method_description)s, %(contact_info)s)
                """, method_record)
        
        # Load required information
        required_info = government_reporting.get('required_information', [])
        for info in required_info:
            info_record = {
                'reporting_requirement_id': req_id,  # Using last req_id as example
                'information_type': info,
                'description': info,
                'is_required': True
            }
            
            self._execute_query("""
                INSERT INTO required_reporting_information (reporting_requirement_id, information_type, description, is_required)
                VALUES (%(reporting_requirement_id)s, %(information_type)s, %(description)s, %(is_required)s)
            """, info_record)
        
        if not self.dry_run:
            self.conn.commit()
        self.logger.info(f"Loaded {len(immediate_reporting)} immediate reporting requirements")
    
    def load_regulatory_definitions(self, reference_data: dict):
        """Load regulatory definitions"""
        if self.load_mode == LoadMode.VALIDATE_ONLY:
            self.logger.debug("VALIDATION: Would load regulatory definitions")
            return
            
        definitions = reference_data.get('definitions', {})
        
        for term, definition_data in definitions.items():
            if isinstance(definition_data, dict):
                def_record = {
                    'version_id': self.version_id,
                    'term': term,
                    'regulation_ref': definition_data.get('regulation_ref'),
                    'definition_type': definition_data.get('definition_type'),
                    'definition_text': definition_data.get('basic_definition') or definition_data.get('completeness_note') or str(definition_data),
                    'examples': None,
                    'exceptions': None
                }
            else:
                def_record = {
                    'version_id': self.version_id,
                    'term': term,
                    'regulation_ref': None,
                    'definition_type': 'basic_definition',
                    'definition_text': str(definition_data),
                    'examples': None,
                    'exceptions': None
                }
            
            self._execute_query("""
                INSERT INTO regulatory_definitions (version_id, term, regulation_ref, definition_type, definition_text, examples, exceptions)
                VALUES (%(version_id)s, %(term)s, %(regulation_ref)s, %(definition_type)s, %(definition_text)s, %(examples)s, %(exceptions)s)
            """, def_record)
        
        if not self.dry_run:
            self.conn.commit()
        self.logger.info(f"Loaded {len(definitions)} regulatory definitions")
    
    def load_first_aid_treatments(self, reference_data: dict):
        """Load first aid treatments"""
        if self.load_mode == LoadMode.VALIDATE_ONLY:
            self.logger.debug("VALIDATION: Would load first aid treatments")
            return
            
        first_aid = reference_data.get('definitions', {}).get('first_aid', {})
        treatments = first_aid.get('items', [])
        
        for treatment in treatments:
            treatment_record = {
                'version_id': self.version_id,
                'treatment_name': treatment.get('treatment'),
                'treatment_details': treatment.get('details'),
                'exceptions': treatment.get('exception')
            }
            
            self._execute_query("""
                INSERT INTO first_aid_treatments (version_id, treatment_name, treatment_details, exceptions)
                VALUES (%(version_id)s, %(treatment_name)s, %(treatment_details)s, %(exceptions)s)
            """, treatment_record)
        
        if not self.dry_run:
            self.conn.commit()
        self.logger.info(f"Loaded {len(treatments)} first aid treatments")
    
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
    
    def generate_load_summary(self, json_data: dict) -> dict:
        """Generate summary of what would be loaded"""
        summary = {
            'regulation_id': json_data.get('regulation_metadata', {}).get('regulation_id'),
            'version_number': json_data.get('regulation_metadata', {}).get('parsing_version'),
            'effective_date': json_data.get('regulation_metadata', {}).get('effective_date'),
            'content_hash': json_data.get('regulation_metadata', {}).get('content_hash'),
            'load_mode': self.load_mode.value,
            'dry_run': self.dry_run,
            'counts': {}
        }
        
        # Count items that would be loaded
        summary['counts']['legal_authorities'] = len(json_data.get('regulation_metadata', {}).get('legal_basis', []))
        summary['counts']['editorial_notes'] = len(json_data.get('regulation_metadata', {}).get('editorial_notes', []))
        summary['counts']['size_exemptions'] = len(json_data.get('company_applicability', {}).get('size_exemptions', []))
        
        # Count NAICS codes
        naics_count = 0
        company_applicability = json_data.get('company_applicability', {})
        for exemption in company_applicability.get('industry_exemptions', []):
            naics_count += len(exemption.get('naics_codes', []))
        reference_data = company_applicability.get('reference_data', {}).get('naics_codes', {})
        for naics_list in reference_data.values():
            naics_count += len(naics_list)
        summary['counts']['naics_codes'] = naics_count
        
        # Count other items
        recording_criteria = json_data.get('recording_criteria', {})
        summary['counts']['decision_tree_steps'] = len(recording_criteria.get('recordability_decision_tree', {}).get('decision_path', []))
        summary['counts']['general_recording_criteria'] = len(recording_criteria.get('general_recording_criteria', []))
        summary['counts']['specific_recording_criteria'] = len(recording_criteria.get('specific_recording_criteria', {}))
        
        form_requirements = json_data.get('form_requirements', {})
        summary['counts']['required_forms'] = len(form_requirements.get('required_forms', []))
        summary['counts']['privacy_concern_cases'] = len(form_requirements.get('privacy_protections', {}).get('complete_list_privacy_concern_cases', []))
        
        government_reporting = json_data.get('government_reporting', {})
        summary['counts']['immediate_reporting_requirements'] = len(government_reporting.get('immediate_reporting', []))
        
        reference_data = json_data.get('reference_data', {})
        summary['counts']['regulatory_definitions'] = len(reference_data.get('definitions', {}))
        summary['counts']['first_aid_treatments'] = len(reference_data.get('definitions', {}).get('first_aid', {}).get('items', []))
        
        return summary
    
    def load_dataset(self, json_file_path: str, force_update: bool = False, keep_backups: bool = False):
        """Main method to load the entire dataset with enhanced flexibility"""
        
        self.logger.info(f"Starting enhanced 29 CFR 1904 data load from: {json_file_path}")
        self.logger.info(f"Load mode: {self.load_mode.value}, Dry run: {self.dry_run}")
        
        try:
            # Load and validate JSON
            with open(json_file_path, 'r', encoding='utf-8') as f:
                json_data = json.load(f)
            
            # Calculate content hash if not provided
            if 'content_hash' not in json_data.get('regulation_metadata', {}):
                content_hash = self._calculate_content_hash(json_data)
                json_data['regulation_metadata']['content_hash'] = content_hash
            
            # Generate load summary
            summary = self.generate_load_summary(json_data)
            self.logger.info(f"Load summary: {summary}")
            
            # Connect to database
            self.connect()
            
            # Handle truncate mode
            if self.load_mode == LoadMode.TRUNCATE_LOAD:
                self.logger.info("TRUNCATE MODE: Clearing all existing data...")
                self._truncate_all_tables()
            
            # Phase 1: Create regulation version
            self.logger.info("Phase 1: Creating/updating regulation version...")
            metadata = json_data.get('regulation_metadata', {})
            version_id = self.create_regulation_version(metadata, force_update)
            
            if self.load_mode == LoadMode.VALIDATE_ONLY:
                self.logger.info(f"VALIDATION COMPLETE - Changes detected: {self.changes_detected}")
                return summary
            
            # Skip loading if no changes in incremental mode
            if (self.load_mode == LoadMode.INCREMENTAL and 
                hasattr(self, 'version_id') and 
                not self.changes_detected and 
                not force_update):
                self.logger.info("INCREMENTAL: No changes detected, skipping data load")
                return summary
            
            # Phase 2: Load core metadata
            self.logger.info("Phase 2: Loading core metadata...")
            legal_basis = metadata.get('legal_basis', [])
            editorial_notes = metadata.get('editorial_notes', [])
            
            if legal_basis:
                self.load_regulation_authorities(legal_basis)
            if editorial_notes:
                self.load_regulation_amendments(editorial_notes)
            
            # Phase 3: Load company applicability
            self.logger.info("Phase 3: Loading company applicability...")
            company_applicability = json_data.get('company_applicability', {})
            
            size_exemptions = company_applicability.get('size_exemptions', [])
            if size_exemptions:
                self.load_size_exemptions(size_exemptions)
            
            self.load_naics_codes(company_applicability)
            
            # Phase 4: Load recording criteria
            self.logger.info("Phase 4: Loading recording criteria...")
            recording_criteria = json_data.get('recording_criteria', {})
            
            self.load_decision_tree_steps(recording_criteria)
            self.load_work_relatedness_criteria(recording_criteria)
            self.load_general_recording_criteria(recording_criteria)
            self.load_specific_recording_criteria(recording_criteria)
            
            # Phase 5: Load form requirements
            self.logger.info("Phase 5: Loading form requirements...")
            form_requirements = json_data.get('form_requirements', {})
            
            self.load_required_forms(form_requirements)
            self.load_privacy_concern_cases(form_requirements)
            
            # Phase 6: Load government reporting
            self.logger.info("Phase 6: Loading government reporting...")
            government_reporting = json_data.get('government_reporting', {})
            
            self.load_immediate_reporting_requirements(government_reporting)
            
            # Phase 7: Load reference data
            self.logger.info("Phase 7: Loading reference data...")
            reference_data = json_data.get('reference_data', {})
            
            self.load_regulatory_definitions(reference_data)
            self.load_first_aid_treatments(reference_data)
            
            # Final commit and cleanup
            if not self.dry_run:
                self.conn.commit()
                self.cleanup_backup_tables(keep_backups)
            
            self.logger.info("=== ENHANCED 29 CFR 1904 LOAD SUMMARY ===")
            self.logger.info(f"Load Mode: {self.load_mode.value}")
            self.logger.info(f"Dry Run: {self.dry_run}")
            self.logger.info(f"Version ID: {self.version_id}")
            self.logger.info(f"Regulation: {metadata.get('regulation_id')}")
            self.logger.info(f"Version: {metadata.get('parsing_version')}")
            self.logger.info(f"Effective Date: {metadata.get('effective_date')}")
            self.logger.info(f"Changes Detected: {self.changes_detected}")
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
    """Enhanced main entry point with argument parsing"""
    parser = argparse.ArgumentParser(
        description='Enhanced 29 CFR Part 1904 Data Loader with flexible loading modes',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Loading Modes:
  truncate_load    - Clear all existing data and load fresh (default)
  incremental      - Only load if content has changed since last version
  update_existing  - Update existing version in place if content changed
  validate_only    - Check for changes without loading data

Examples:
  # Standard truncate and load
  python cfr_1904_enhanced_loader.py data.json

  # Incremental load (only if changed)
  python cfr_1904_enhanced_loader.py data.json --mode incremental

  # Dry run to see what would happen
  python cfr_1904_enhanced_loader.py data.json --dry-run

  # Update existing version with backups disabled
  python cfr_1904_enhanced_loader.py data.json --mode update_existing --no-backup

  # Validate changes only
  python cfr_1904_enhanced_loader.py data.json --mode validate_only
        """
    )
    
    parser.add_argument('json_file', help='Path to the JSON data file')
    parser.add_argument('--mode', '-m', 
                       choices=[mode.value for mode in LoadMode],
                       default=LoadMode.TRUNCATE_LOAD.value,
                       help='Loading mode (default: truncate_load)')
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
        loader = CFR1904EnhancedLoader(
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
            print(f"Version: {summary.get('version_number')}")
            print(f"Items processed: {sum(summary.get('counts', {}).values())}")
        
    except Exception as e:
        logger.error(f"Load failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()