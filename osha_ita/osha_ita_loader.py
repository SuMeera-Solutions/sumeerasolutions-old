#!/usr/bin/env python3
"""
OSHA ITA Data Loader - Complete Script
Loads OSHA Injury Tracking Application data from Excel/CSV files into PostgreSQL
Supports both 300A Summary Data and Case Detail Data with full versioning
"""

import os
import json
import pandas as pd
import psycopg2
import psycopg2.extras
from datetime import datetime, date, time
import logging
from typing import Dict, List, Any, Optional, Tuple
import sys
import hashlib
import argparse
from enum import Enum
import uuid
import re
from pathlib import Path
import openpyxl

# Database configuration - UPDATE THESE VALUES
DB_CONFIG = {
    'host': 'rds-dev-compliease-pg.cm9ok286yrdx.us-east-1.rds.amazonaws.com',
    'username': 'postgres',
    'password': '0XNfzbSGvzzvWc40Ra7U',
    'database': 'compliease_sbx',
    'schema': 'osha_ita',
    'port': 5432
}

class LoadMode(Enum):
    """Loading modes for the data loader"""
    FULL_REFRESH = "full_refresh"
    INCREMENTAL = "incremental"
    UPDATE_EXISTING = "update_existing"
    VALIDATE_ONLY = "validate_only"

def setup_logging(log_level: str = "INFO", log_file: str = None):
    """Setup logging with configurable level and optional file output"""
    numeric_level = getattr(logging, log_level.upper(), None)
    if not isinstance(numeric_level, int):
        raise ValueError(f'Invalid log level: {log_level}')
    
    handlers = [logging.StreamHandler()]
    if log_file:
        handlers.append(logging.FileHandler(log_file))
    
    logging.basicConfig(
        level=numeric_level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=handlers
    )
    return logging.getLogger(__name__)

class OSHAITADataLoader:
    """Main data loader for OSHA ITA data with versioning and audit support"""
    
    def __init__(self, db_config: dict, load_mode: LoadMode = LoadMode.INCREMENTAL, 
                 dry_run: bool = False):
        self.db_config = db_config
        self.load_mode = load_mode
        self.dry_run = dry_run
        self.conn = None
        self.cursor = None
        self.logger = logging.getLogger(__name__)
        self.load_statistics = {
            'files_processed': 0,
            'establishments_created': 0,
            'establishments_updated': 0,
            'summary_records_loaded': 0,
            'case_records_loaded': 0,
            'errors': 0
        }
        
    def connect(self):
        """Establish database connection"""
        try:
            # Connect with autocommit initially set based on dry_run mode
            self.conn = psycopg2.connect(
                host=self.db_config['host'],
                user=self.db_config['username'],
                password=self.db_config['password'],
                database=self.db_config['database'],
                port=self.db_config.get('port', 5432)
            )
            
            # Set autocommit mode before creating cursor
            if self.dry_run:
                self.conn.autocommit = True
            else:
                self.conn.autocommit = False
                
            self.cursor = self.conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
            
            # Set schema if specified
            if 'schema' in self.db_config and self.db_config['schema']:
                self.cursor.execute(f"SET search_path TO {self.db_config['schema']}")
                if not self.dry_run:
                    self.conn.commit()  # Commit the schema change
                
            self.logger.info(f"Connected to database: {self.db_config['database']}")
            if 'schema' in self.db_config:
                self.logger.info(f"Using schema: {self.db_config['schema']}")
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
    
    def _execute_query(self, query: str, params: tuple = None, fetch_one: bool = False, fetch_all: bool = False):
        """Execute query with dry run support"""
        if self.dry_run:
            self.logger.debug(f"DRY RUN - Query: {query[:100]}...")
            if params:
                self.logger.debug(f"DRY RUN - Params: {params}")
            return {'load_id': str(uuid.uuid4())} if fetch_one else []
        else:
            try:
                self.cursor.execute(query, params)
                if fetch_one:
                    return self.cursor.fetchone()
                elif fetch_all:
                    return self.cursor.fetchall()
                return None
            except Exception as e:
                self.logger.error(f"Query execution failed: {e}")
                self.logger.error(f"Query: {query}")
                self.logger.error(f"Params: {params}")
                raise
    
    def _safe_convert(self, value, target_type, default=None):
        """Safely convert values to target type"""
        if pd.isna(value) or value == '' or value is None:
            return default
            
        try:
            if target_type == int:
                if isinstance(value, str) and value.strip() == '':
                    return default
                return int(float(value))  # Handle strings like "123.0"
            elif target_type == float:
                return float(value)
            elif target_type == str:
                return str(value).strip()
            elif target_type == bool:
                if isinstance(value, str):
                    return value.lower() in ['true', '1', 'yes', 'y']
                return bool(value)
            elif target_type == datetime:
                return self._parse_timestamp(value)
            elif target_type == date:
                return self._parse_date(value)
            elif target_type == time:
                return self._parse_time(value)
            else:
                return value
        except (ValueError, TypeError) as e:
            self.logger.debug(f"Conversion failed for value '{value}' to {target_type}: {e}")
            return default
    
    def _parse_timestamp(self, timestamp_str):
        """Parse various timestamp formats from OSHA ITA data"""
        if pd.isna(timestamp_str) or timestamp_str == '':
            return None
            
        timestamp_str = str(timestamp_str).strip()
        
        # Handle OSHA ITA format: "01JAN25:15:03:00"
        if re.match(r'^\d{2}[A-Z]{3}\d{2}:\d{2}:\d{2}:\d{2}$', timestamp_str):
            try:
                return datetime.strptime(timestamp_str, '%d%b%y:%H:%M:%S')
            except ValueError:
                pass
        
        # Handle ISO format: "2024-01-22T06:00:00.000Z"
        if 'T' in timestamp_str:
            try:
                timestamp_str = timestamp_str.replace('Z', '+00:00')
                return datetime.fromisoformat(timestamp_str.replace('Z', ''))
            except ValueError:
                pass
        
        # Handle Excel datetime
        try:
            if timestamp_str.replace('.', '').isdigit():
                excel_date = float(timestamp_str)
                return datetime(1899, 12, 30) + pd.Timedelta(days=excel_date)
        except ValueError:
            pass
        
        return None
    
    def _parse_date(self, date_str):
        """Parse date from various formats"""
        if pd.isna(date_str) or date_str == '':
            return None
            
        try:
            # Handle ISO format
            if 'T' in str(date_str):
                dt = self._parse_timestamp(date_str)
                return dt.date() if dt else None
            
            # Handle Excel date numbers
            if str(date_str).replace('.', '').isdigit():
                excel_date = float(date_str)
                base_date = datetime(1899, 12, 30)
                return (base_date + pd.Timedelta(days=excel_date)).date()
            
            # Try pandas date parsing
            return pd.to_datetime(date_str).date()
        except:
            return None
    
    def _parse_time(self, time_str):
        """Parse time from various formats"""
        if pd.isna(time_str) or time_str == '':
            return None
            
        try:
            # Handle Excel time (decimal days)
            if isinstance(time_str, (int, float)):
                total_seconds = int(time_str * 24 * 60 * 60)
                hours = total_seconds // 3600
                minutes = (total_seconds % 3600) // 60
                seconds = total_seconds % 60
                return time(hours % 24, minutes, seconds)
            
            # Handle ISO timestamp
            if 'T' in str(time_str):
                dt = self._parse_timestamp(time_str)
                return dt.time() if dt else None
            
            # Try direct time parsing
            return pd.to_datetime(time_str).time()
        except:
            return None
    
    def create_data_load_record(self, source_file: str, load_type: str, data_year: int) -> str:
        """Create a data load record and return load_id"""
        file_hash = self._calculate_file_hash(source_file)
        
        query = """
            INSERT INTO data_loads (
                load_type, source_file_name, source_file_hash, data_year, 
                load_status, loaded_by
            ) VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING load_id
        """
        
        result = self._execute_query(
            query, 
            (load_type, source_file, file_hash, data_year, 'in_progress', 'python_loader'),
            fetch_one=True
        )
        
        return str(result['load_id'])
    
    def _calculate_file_hash(self, file_path: str) -> str:
        """Calculate SHA256 hash of file"""
        try:
            with open(file_path, 'rb') as f:
                return hashlib.sha256(f.read()).hexdigest()
        except:
            return hashlib.sha256(str(datetime.now()).encode()).hexdigest()
    
    def update_load_record(self, load_id: str, status: str = 'completed', 
                          loaded: int = 0, updated: int = 0, failed: int = 0):
        """Update data load record with final statistics"""
        query = """
            UPDATE data_loads 
            SET load_status = %s, records_loaded = %s, records_updated = %s, 
                records_failed = %s, updated_at = CURRENT_TIMESTAMP
            WHERE load_id = %s
        """
        
        self._execute_query(query, (status, loaded, updated, failed, load_id))
    
    def upsert_establishment(self, row_data: dict, year: int) -> str:
        """Upsert establishment and return establishment_uuid"""
        
        # Extract establishment data
        establishment_data = {
            'establishment_id': self._safe_convert(row_data.get('establishment_id'), int),
            'establishment_name': self._safe_convert(row_data.get('establishment_name'), str),
            'ein': self._safe_convert(row_data.get('ein'), str),
            'company_name': self._safe_convert(row_data.get('company_name'), str),
            'street_address': self._safe_convert(row_data.get('street_address'), str),
            'city': self._safe_convert(row_data.get('city'), str),
            'state_code': self._safe_convert(row_data.get('state'), str),
            'zip_code': self._safe_convert(row_data.get('zip_code'), str),
            'naics_code': self._safe_convert(row_data.get('naics_code'), str),
            'naics_year': self._safe_convert(row_data.get('naics_year'), int, 2012),
            'industry_description': self._safe_convert(row_data.get('industry_description'), str),
            'establishment_type': self._safe_convert(row_data.get('establishment_type'), int, 1),
            'size_category': self._safe_convert(row_data.get('size'), int)
        }
        
        # Create address and NAICS JSON
        address_json = {
            'street_address': establishment_data['street_address'],
            'city': establishment_data['city'],
            'state': establishment_data['state_code'],
            'zip_code': establishment_data['zip_code']
        }
        
        naics_json = {
            'code': establishment_data['naics_code'],
            'year': establishment_data['naics_year'],
            'description': establishment_data['industry_description']
        }
        
        # First, try to find existing establishment
        if establishment_data['ein'] and establishment_data['establishment_name']:
            query = """
                SELECT establishment_uuid FROM establishments 
                WHERE ein = %s AND establishment_name = %s
            """
            result = self._execute_query(
                query, 
                (establishment_data['ein'], establishment_data['establishment_name']),
                fetch_one=True
            )
            
            if result and not self.dry_run:
                establishment_uuid = str(result['establishment_uuid'])
                
                # Update existing establishment
                update_query = """
                    UPDATE establishments SET
                        establishment_id = %s,
                        current_address = %s,
                        street_address = %s,
                        city = %s,
                        state_code = %s,
                        zip_code = %s,
                        current_naics = %s,
                        primary_naics_code = %s,
                        naics_year = %s,
                        industry_description = %s,
                        establishment_type = %s,
                        size_category = %s,
                        last_seen_year = GREATEST(last_seen_year, %s),
                        updated_at = CURRENT_TIMESTAMP
                    WHERE establishment_uuid = %s
                """
                
                self._execute_query(update_query, (
                    establishment_data['establishment_id'],
                    json.dumps(address_json),
                    establishment_data['street_address'],
                    establishment_data['city'],
                    establishment_data['state_code'],
                    establishment_data['zip_code'],
                    json.dumps(naics_json),
                    establishment_data['naics_code'],
                    establishment_data['naics_year'],
                    establishment_data['industry_description'],
                    establishment_data['establishment_type'],
                    establishment_data['size_category'],
                    year,
                    establishment_uuid
                ))
                
                self.load_statistics['establishments_updated'] += 1
                return establishment_uuid
        
        # Create new establishment
        insert_query = """
            INSERT INTO establishments (
                establishment_id, establishment_name, ein, company_name,
                current_address, street_address, city, state_code, zip_code,
                current_naics, primary_naics_code, naics_year, industry_description,
                establishment_type, size_category, first_seen_year, last_seen_year
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
            ) RETURNING establishment_uuid
        """
        
        result = self._execute_query(insert_query, (
            establishment_data['establishment_id'],
            establishment_data['establishment_name'],
            establishment_data['ein'],
            establishment_data['company_name'],
            json.dumps(address_json),
            establishment_data['street_address'],
            establishment_data['city'],
            establishment_data['state_code'],
            establishment_data['zip_code'],
            json.dumps(naics_json),
            establishment_data['naics_code'],
            establishment_data['naics_year'],
            establishment_data['industry_description'],
            establishment_data['establishment_type'],
            establishment_data['size_category'],
            year,
            year
        ), fetch_one=True)
        
        if self.dry_run:
            establishment_uuid = str(uuid.uuid4())
        else:
            establishment_uuid = str(result['establishment_uuid'])
        
        self.load_statistics['establishments_created'] += 1
        return establishment_uuid
    
    def load_300a_summary_data(self, df: pd.DataFrame, load_id: str, year: int):
        """Load 300A summary data from DataFrame"""
        self.logger.info(f"Loading 300A summary data: {len(df)} records for year {year}")
        
        for index, row in df.iterrows():
            try:
                # Upsert establishment
                establishment_uuid = self.upsert_establishment(row.to_dict(), year)
                
                # Create establishment snapshot
                establishment_snapshot = {
                    'establishment_name': self._safe_convert(row.get('establishment_name'), str),
                    'company_name': self._safe_convert(row.get('company_name'), str),
                    'address': {
                        'street': self._safe_convert(row.get('street_address'), str),
                        'city': self._safe_convert(row.get('city'), str),
                        'state': self._safe_convert(row.get('state'), str),
                        'zip': self._safe_convert(row.get('zip_code'), str)
                    },
                    'naics': {
                        'code': self._safe_convert(row.get('naics_code'), str),
                        'year': self._safe_convert(row.get('naics_year'), int),
                        'description': self._safe_convert(row.get('industry_description'), str)
                    },
                    'filing_year': year
                }
                
                # Insert summary record
                summary_query = """
                    INSERT INTO summary_300a_data (
                        establishment_uuid, load_id, ita_id, ita_establishment_id,
                        establishment_snapshot, annual_average_employees, total_hours_worked,
                        no_injuries_illnesses, total_deaths, total_dafw_cases, total_djtr_cases,
                        total_other_cases, total_dafw_days, total_djtr_days, total_injuries,
                        total_skin_disorders, total_respiratory_conditions, total_poisonings,
                        total_hearing_loss, total_other_illnesses, year_filing_for,
                        created_timestamp, ita_created_at, change_reason, sector, zipcode, naics_char
                    ) VALUES (
                        %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                    )
                """
                
                self._execute_query(summary_query, (
                    establishment_uuid,
                    load_id,
                    self._safe_convert(row.get('id'), int),
                    self._safe_convert(row.get('establishment_id'), int),
                    json.dumps(establishment_snapshot),
                    self._safe_convert(row.get('annual_average_employees'), int),
                    self._safe_convert(row.get('total_hours_worked'), int),
                    self._safe_convert(row.get('no_injuries_illnesses'), int),
                    self._safe_convert(row.get('total_deaths'), int, 0),
                    self._safe_convert(row.get('total_dafw_cases'), int, 0),
                    self._safe_convert(row.get('total_djtr_cases'), int, 0),
                    self._safe_convert(row.get('total_other_cases'), int, 0),
                    self._safe_convert(row.get('total_dafw_days'), int, 0),
                    self._safe_convert(row.get('total_djtr_days'), int, 0),
                    self._safe_convert(row.get('total_injuries'), int, 0),
                    self._safe_convert(row.get('total_skin_disorders'), int, 0),
                    self._safe_convert(row.get('total_respiratory_conditions'), int, 0),
                    self._safe_convert(row.get('total_poisonings'), int, 0),
                    self._safe_convert(row.get('total_hearing_loss'), int, 0),
                    self._safe_convert(row.get('total_other_illnesses'), int, 0),
                    year,
                    self._safe_convert(row.get('created_timestamp'), str),
                    self._parse_timestamp(row.get('created_timestamp')),
                    self._safe_convert(row.get('change_reason'), str),
                    self._safe_convert(row.get('sector'), str),
                    self._safe_convert(row.get('zipcode'), str),
                    self._safe_convert(row.get('naics_char'), str)
                ))
                
                self.load_statistics['summary_records_loaded'] += 1
                
            except Exception as e:
                self.logger.error(f"Error loading 300A record {index}: {e}")
                self.load_statistics['errors'] += 1
                continue
    
    def load_case_detail_data(self, df: pd.DataFrame, load_id: str, year: int):
        """Load case detail data from DataFrame"""
        self.logger.info(f"Loading case detail data: {len(df)} records for year {year}")
        
        for index, row in df.iterrows():
            try:
                # Upsert establishment
                establishment_uuid = self.upsert_establishment(row.to_dict(), year)
                
                # Create establishment snapshot
                establishment_snapshot = {
                    'establishment_name': self._safe_convert(row.get('establishment_name'), str),
                    'company_name': self._safe_convert(row.get('company_name'), str),
                    'address': {
                        'street': self._safe_convert(row.get('street_address'), str),
                        'city': self._safe_convert(row.get('city'), str),
                        'state': self._safe_convert(row.get('state'), str),
                        'zip': self._safe_convert(row.get('zip_code'), str)
                    },
                    'naics': {
                        'code': self._safe_convert(row.get('naics_code'), str),
                        'year': self._safe_convert(row.get('naics_year'), int),
                        'description': self._safe_convert(row.get('industry_description'), str)
                    },
                    'filing_year': year
                }
                
                # Create incident narratives JSON
                incident_narratives = {
                    'location': self._safe_convert(row.get('new_incident_location'), str),
                    'description': self._safe_convert(row.get('NEW_INCIDENT_DESCRIPTION'), str),
                    'before_incident': self._safe_convert(row.get('new_nar_before_incident'), str),
                    'what_happened': self._safe_convert(row.get('new_nar_what_happened'), str),
                    'injury_illness': self._safe_convert(row.get('new_nar_injury_illness'), str),
                    'object_substance': self._safe_convert(row.get('new_nar_object_substance'), str)
                }
                
                # Insert case detail record
                case_query = """
                    INSERT INTO case_detail_data (
                        establishment_uuid, load_id, ita_id, ita_establishment_id,
                        case_number, establishment_snapshot, job_description,
                        soc_code, soc_description, soc_reviewed, soc_probability,
                        date_of_incident, time_started_work, time_of_incident, time_unknown,
                        incident_outcome, type_of_incident, dafw_num_away, djtr_num_tr,
                        date_of_death, incident_location, incident_description,
                        narrative_before_incident, narrative_what_happened,
                        narrative_injury_illness, narrative_object_substance,
                        incident_narratives, year_filing_for, created_timestamp, ita_created_at
                    ) VALUES (
                        %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                    )
                """
                
                self._execute_query(case_query, (
                    establishment_uuid,
                    load_id,
                    self._safe_convert(row.get('id'), int),
                    self._safe_convert(row.get('establishment_id'), int),
                    self._safe_convert(row.get('case_number'), str),
                    json.dumps(establishment_snapshot),
                    self._safe_convert(row.get('job_description'), str),
                    self._safe_convert(row.get('soc_code'), str),
                    self._safe_convert(row.get('soc_description'), str),
                    self._safe_convert(row.get('soc_reviewed'), int),
                    self._safe_convert(row.get('soc_probability'), float),
                    self._parse_date(row.get('date_of_incident')),
                    self._parse_time(row.get('time_started_work')),
                    self._parse_time(row.get('time_of_incident')),
                    self._safe_convert(row.get('time_unknown'), bool, False),
                    self._safe_convert(row.get('incident_outcome'), int),
                    self._safe_convert(row.get('type_of_incident'), int),
                    self._safe_convert(row.get('dafw_num_away'), int),
                    self._safe_convert(row.get('djtr_num_tr'), int),
                    self._parse_date(row.get('date_of_death')),
                    self._safe_convert(row.get('new_incident_location'), str),
                    self._safe_convert(row.get('NEW_INCIDENT_DESCRIPTION'), str),
                    self._safe_convert(row.get('new_nar_before_incident'), str),
                    self._safe_convert(row.get('new_nar_what_happened'), str),
                    self._safe_convert(row.get('new_nar_injury_illness'), str),
                    self._safe_convert(row.get('new_nar_object_substance'), str),
                    json.dumps(incident_narratives),
                    year,
                    self._safe_convert(row.get('created_timestamp'), str),
                    self._parse_timestamp(row.get('created_timestamp'))
                ))
                
                self.load_statistics['case_records_loaded'] += 1
                
            except Exception as e:
                self.logger.error(f"Error loading case detail record {index}: {e}")
                self.load_statistics['errors'] += 1
                continue
    
    def read_excel_file(self, file_path: str) -> Dict[str, pd.DataFrame]:
        """Read Excel file and return dictionary of DataFrames by sheet name"""
        try:
            # Use openpyxl engine for better compatibility
            excel_file = pd.ExcelFile(file_path, engine='openpyxl')
            sheets = {}
            
            for sheet_name in excel_file.sheet_names:
                self.logger.debug(f"Reading sheet: {sheet_name}")
                df = pd.read_excel(excel_file, sheet_name=sheet_name)
                
                # Clean column names
                df.columns = df.columns.str.lower().str.strip()
                
                # Remove empty rows
                df = df.dropna(how='all')
                
                sheets[sheet_name] = df
                self.logger.debug(f"Sheet {sheet_name}: {len(df)} rows, {len(df.columns)} columns")
            
            return sheets
            
        except Exception as e:
            self.logger.error(f"Error reading Excel file {file_path}: {e}")
            raise
    
    def read_csv_file(self, file_path: str) -> pd.DataFrame:
        """Read CSV file and return DataFrame"""
        try:
            df = pd.read_csv(file_path, encoding='utf-8', low_memory=False)
            
            # Clean column names
            df.columns = df.columns.str.lower().str.strip()
            
            # Remove empty rows
            df = df.dropna(how='all')
            
            self.logger.debug(f"CSV file {file_path}: {len(df)} rows, {len(df.columns)} columns")
            return df
            
        except Exception as e:
            self.logger.error(f"Error reading CSV file {file_path}: {e}")
            raise
    
    def process_file(self, file_path: str, data_year: int = None):
        """Process a single Excel or CSV file"""
        file_path = Path(file_path)
        self.logger.info(f"Processing file: {file_path}")
        
        # Detect data year from filename or path if not provided
        if data_year is None:
            data_year = self._extract_year_from_path(str(file_path))
        
        # Determine file type and load mode
        if file_path.suffix.lower() in ['.xlsx', '.xls']:
            sheets = self.read_excel_file(str(file_path))
            
            for sheet_name, df in sheets.items():
                if len(df) == 0:
                    continue
                    
                # Determine data type based on columns
                columns = set(df.columns)
                
                if self._is_300a_summary_data(columns):
                    load_id = self.create_data_load_record(str(file_path), '300A_summary', data_year)
                    self.load_300a_summary_data(df, load_id, data_year)
                    self.update_load_record(load_id, 'completed', 
                                          self.load_statistics['summary_records_loaded'])
                    
                elif self._is_case_detail_data(columns):
                    load_id = self.create_data_load_record(str(file_path), 'case_detail', data_year)
                    self.load_case_detail_data(df, load_id, data_year)
                    self.update_load_record(load_id, 'completed', 
                                          self.load_statistics['case_records_loaded'])
                    
                else:
                    self.logger.warning(f"Unknown data type in sheet {sheet_name} of {file_path}")
                    
        elif file_path.suffix.lower() == '.csv':
            df = self.read_csv_file(str(file_path))
            
            if len(df) == 0:
                return
                
            columns = set(df.columns)
            
            if self._is_300a_summary_data(columns):
                load_id = self.create_data_load_record(str(file_path), '300A_summary', data_year)
                self.load_300a_summary_data(df, load_id, data_year)
                self.update_load_record(load_id, 'completed', 
                                      self.load_statistics['summary_records_loaded'])
                
            elif self._is_case_detail_data(columns):
                load_id = self.create_data_load_record(str(file_path), 'case_detail', data_year)
                self.load_case_detail_data(df, load_id, data_year)
                self.update_load_record(load_id, 'completed', 
                                      self.load_statistics['case_records_loaded'])
                
            else:
                self.logger.warning(f"Unknown data type in CSV file {file_path}")
        
        self.load_statistics['files_processed'] += 1
    
    def _is_300a_summary_data(self, columns: set) -> bool:
        """Determine if DataFrame contains 300A summary data"""
        summary_indicators = {
            'annual_average_employees', 'total_hours_worked', 'total_deaths',
            'total_dafw_cases', 'total_djtr_cases', 'total_injuries'
        }
        return len(summary_indicators.intersection(columns)) >= 3
    
    def _is_case_detail_data(self, columns: set) -> bool:
        """Determine if DataFrame contains case detail data"""
        case_indicators = {
            'case_number', 'date_of_incident', 'incident_outcome',
            'type_of_incident', 'job_description'
        }
        return len(case_indicators.intersection(columns)) >= 3
    
    def _extract_year_from_path(self, file_path: str) -> int:
        """Extract year from file path or filename based on your structure"""
        file_path_str = str(file_path)
        
        # Look for specific patterns in your folder structure
        patterns = [
            r'ITA Data CY (\d{4})',  # "ITA Data CY 2016"
            r'ITA-Data-CY-(\d{4})',  # "ITA-Data-CY-2020"
            r'ITA-data-cy(\d{4})',   # "ITA-data-cy2021"
            r'CY(\d{4})',            # "CY2022"
            r'(\d{4})_through',      # "2024_through_04-30-2025"
            r'Data_(\d{4})',         # "ITA_Case_Detail_Data_2024"
            r'_(\d{4})_',            # Generic year in filename
            r'(\d{4})',              # Any 4-digit year
        ]
        
        years_found = []
        
        for pattern in patterns:
            matches = re.findall(pattern, file_path_str, re.IGNORECASE)
            for match in matches:
                try:
                    year = int(match)
                    if 2010 <= year <= 2030:  # Reasonable year range for OSHA data
                        years_found.append(year)
                except ValueError:
                    continue
        
        if years_found:
            # Return the most recent year found
            return max(years_found)
        
        # Default to current year if no year found
        self.logger.warning(f"Could not extract year from path: {file_path_str}")
        return datetime.now().year
    
    def process_directory(self, root_dir: str, recursive: bool = True):
        """Process all Excel and CSV files in a directory structure"""
        root_path = Path(root_dir)
        self.logger.info(f"Processing directory: {root_path}")
        
        # Define file patterns to look for
        file_patterns = ['*.xlsx', '*.xls', '*.csv']
        
        files_found = []
        for pattern in file_patterns:
            if recursive:
                files_found.extend(root_path.rglob(pattern))
            else:
                files_found.extend(root_path.glob(pattern))
        
        # Filter out dictionary files and other non-data files
        data_files = []
        for file_path in files_found:
            filename_lower = file_path.name.lower()
            if any(skip_word in filename_lower for skip_word in ['dictionary', 'readme', 'documentation']):
                self.logger.debug(f"Skipping non-data file: {file_path}")
                continue
            data_files.append(file_path)
        
        self.logger.info(f"Found {len(data_files)} data files to process")
        
        # Log what files will be processed
        for file_path in sorted(data_files):
            year = self._extract_year_from_path(str(file_path))
            self.logger.info(f"Will process: {file_path} (Year: {year})")
        
        # Process files in order
        for file_path in sorted(data_files):
            try:
                self.logger.info(f"Processing: {file_path}")
                self.process_file(file_path)
                
                # Commit after each file if not in dry run mode
                if not self.dry_run:
                    self.conn.commit()
                    self.logger.debug(f"Committed changes for file: {file_path}")
                    
            except Exception as e:
                self.logger.error(f"Failed to process file {file_path}: {e}")
                if not self.dry_run:
                    self.conn.rollback()
                self.load_statistics['errors'] += 1
                continue
    
    def validate_data_integrity(self) -> Dict[str, Any]:
        """Validate data integrity after loading"""
        validation_results = {
            'total_establishments': 0,
            'total_300a_records': 0,
            'total_case_records': 0,
            'data_years': [],
            'missing_establishments': 0,
            'duplicate_records': 0,
            'validation_errors': []
        }
        
        if self.dry_run:
            self.logger.info("Skipping validation in dry run mode")
            return validation_results
        
        try:
            # Count total establishments
            result = self._execute_query(
                "SELECT COUNT(*) as count FROM establishments",
                fetch_one=True
            )
            validation_results['total_establishments'] = result['count']
            
            # Count 300A records
            result = self._execute_query(
                "SELECT COUNT(*) as count FROM summary_300a_data WHERE is_current = true",
                fetch_one=True
            )
            validation_results['total_300a_records'] = result['count']
            
            # Count case detail records
            result = self._execute_query(
                "SELECT COUNT(*) as count FROM case_detail_data WHERE is_current = true",
                fetch_one=True
            )
            validation_results['total_case_records'] = result['count']
            
            # Get data years
            result = self._execute_query(
                "SELECT DISTINCT year_filing_for FROM summary_300a_data ORDER BY year_filing_for",
                fetch_all=True
            )
            if result:
                validation_results['data_years'] = [row['year_filing_for'] for row in result]
            
            # Check for orphaned records
            result = self._execute_query("""
                SELECT COUNT(*) as count FROM summary_300a_data s
                WHERE NOT EXISTS (SELECT 1 FROM establishments e WHERE e.establishment_uuid = s.establishment_uuid)
            """, fetch_one=True)
            if result:
                validation_results['missing_establishments'] += result['count']
            
            result = self._execute_query("""
                SELECT COUNT(*) as count FROM case_detail_data c
                WHERE NOT EXISTS (SELECT 1 FROM establishments e WHERE e.establishment_uuid = c.establishment_uuid)
            """, fetch_one=True)
            if result:
                validation_results['missing_establishments'] += result['count']
            
        except Exception as e:
            validation_results['validation_errors'].append(str(e))
            
        return validation_results
    
    def generate_load_report(self) -> str:
        """Generate a comprehensive load report"""
        report = []
        report.append("=" * 60)
        report.append("OSHA ITA DATA LOAD REPORT")
        report.append("=" * 60)
        report.append(f"Load Mode: {self.load_mode.value}")
        report.append(f"Dry Run: {self.dry_run}")
        report.append(f"Load Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append("")
        
        report.append("LOAD STATISTICS:")
        report.append("-" * 20)
        for key, value in self.load_statistics.items():
            report.append(f"  {key.replace('_', ' ').title()}: {value:,}")
        report.append("")
        
        # Get validation results
        validation = self.validate_data_integrity()
        report.append("DATA VALIDATION:")
        report.append("-" * 20)
        report.append(f"  Total Establishments: {validation['total_establishments']:,}")
        report.append(f"  Total 300A Records: {validation['total_300a_records']:,}")
        report.append(f"  Total Case Records: {validation['total_case_records']:,}")
        if validation['data_years']:
            report.append(f"  Data Years: {', '.join(map(str, validation['data_years']))}")
        
        if validation['missing_establishments'] > 0:
            report.append(f"  WARNING: {validation['missing_establishments']} orphaned records found")
        
        if validation['validation_errors']:
            report.append("  VALIDATION ERRORS:")
            for error in validation['validation_errors']:
                report.append(f"    - {error}")
        
        report.append("")
        report.append("=" * 60)
        
        return "\n".join(report)


def main():
    """Main entry point with comprehensive argument parsing"""
    parser = argparse.ArgumentParser(
        description='OSHA ITA Data Loader - Load Excel/CSV files into PostgreSQL database',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Process single file
  python osha_ita_loader.py single_file.xlsx

  # Process entire directory structure  
  python osha_ita_loader.py --directory "C:\\Users\\Neera\\Downloads\\Oshareporting\\oshadata"

  # Dry run to see what would happen
  python osha_ita_loader.py --directory "C:\\Users\\Neera\\Downloads\\Oshareporting\\oshadata" --dry-run

  # Process with debug logging
  python osha_ita_loader.py --directory "C:\\Users\\Neera\\Downloads\\Oshareporting\\oshadata" --log-level DEBUG

Directory Structure Expected:
  C:\\Users\\Neera\\Downloads\\Oshareporting\\oshadata\\
  ├── ITA Data CY 2016\\
  ├── ITA Data CY 2017\\
  ├── ITA-data-cy2021\\
  ├── CY2022\\
  └── ITA_300A_Summary_Data_2024_through_04-30-2025\\
        """
    )
    
    # File/directory arguments
    parser.add_argument('input_path', nargs='?', 
                       help='Path to Excel/CSV file or directory containing data files')
    parser.add_argument('--directory', '-d', 
                       help='Process all files in this directory (alternative to input_path)')
    parser.add_argument('--recursive', '-r', action='store_true', default=True,
                       help='Process directories recursively (default: True)')
    
    # Data processing options
    parser.add_argument('--mode', '-m', 
                       choices=[mode.value for mode in LoadMode],
                       default=LoadMode.INCREMENTAL.value,
                       help='Loading mode (default: incremental)')
    parser.add_argument('--year', '-y', type=int,
                       help='Override data year (auto-detected from path if not specified)')
    parser.add_argument('--dry-run', action='store_true',
                       help='Perform dry run without making database changes')
    
    # Database configuration (uses DB_CONFIG by default)
    parser.add_argument('--host', default=DB_CONFIG['host'],
                       help=f'PostgreSQL host (default: {DB_CONFIG["host"]})')
    parser.add_argument('--port', type=int, default=DB_CONFIG['port'],
                       help=f'PostgreSQL port (default: {DB_CONFIG["port"]})')
    parser.add_argument('--database', default=DB_CONFIG['database'],
                       help=f'Database name (default: {DB_CONFIG["database"]})')
    parser.add_argument('--username', default=DB_CONFIG['username'],
                       help=f'Database username (default: {DB_CONFIG["username"]})')
    parser.add_argument('--password', default=DB_CONFIG['password'],
                       help='Database password (uses config default if not provided)')
    
    # Logging options
    parser.add_argument('--log-level', '-l',
                       choices=['DEBUG', 'INFO', 'WARNING', 'ERROR'],
                       default='INFO',
                       help='Set logging level (default: INFO)')
    parser.add_argument('--log-file', 
                       help='Write logs to file (in addition to console)')
    
    # Output options
    parser.add_argument('--report-file', 
                       help='Write load report to file')
    parser.add_argument('--quiet', '-q', action='store_true',
                       help='Suppress console output (except errors)')
    
    args = parser.parse_args()
    
    # Validate arguments
    if not args.input_path and not args.directory:
        parser.error("Must specify either input_path or --directory")
    
    # Setup logging
    if args.quiet:
        log_level = 'ERROR'
    else:
        log_level = args.log_level
    
    logger = setup_logging(log_level, args.log_file)
    
    # Use configured credentials by default, but allow command line overrides
    db_config = {
        'host': args.host,
        'port': args.port,
        'database': args.database,
        'username': args.username,
        'password': args.password
    }
    
    # Add schema from DB_CONFIG if it exists
    if 'schema' in DB_CONFIG:
        db_config['schema'] = DB_CONFIG['schema']
    
    try:
        # Create loader
        load_mode = LoadMode(args.mode)
        loader = OSHAITADataLoader(
            db_config=db_config,
            load_mode=load_mode,
            dry_run=args.dry_run
        )
        
        # Connect to database
        loader.connect()
        
        # Process data
        input_path = args.directory or args.input_path
        if os.path.isdir(input_path):
            loader.process_directory(input_path, args.recursive)
        else:
            loader.process_file(input_path, args.year)
        
        # Commit final transaction
        if not args.dry_run:
            loader.conn.commit()
        
        # Generate report
        report = loader.generate_load_report()
        
        if not args.quiet:
            print(report)
        
        if args.report_file:
            with open(args.report_file, 'w') as f:
                f.write(report)
            logger.info(f"Report written to: {args.report_file}")
        
        logger.info("Data loading completed successfully!")
        
    except KeyboardInterrupt:
        logger.info("Data loading interrupted by user")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Data loading failed: {e}")
        import traceback
        logger.error(traceback.format_exc())
        sys.exit(1)
    finally:
        if 'loader' in locals():
            loader.disconnect()


if __name__ == "__main__":
    main()