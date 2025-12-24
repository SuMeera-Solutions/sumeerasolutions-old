"""
Complete Python Data Loader for Companies Database
Loads Excel data into PostgreSQL database with proper error handling and logging
Fixed for Windows Unicode issues and duplicate key handling
"""

import pandas as pd
import psycopg2
import psycopg2.extras
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
import logging
import sys
from datetime import datetime
import os
from typing import Dict, List, Tuple, Optional

# Configure logging with UTF-8 encoding for Windows compatibility
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('data_loading.log', encoding='utf-8'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class CompaniesDataLoader:
    """
    Complete data loader for Companies database from Excel spreadsheet
    Fixed for Windows Unicode and duplicate key handling
    """
    
    def __init__(self, db_config: Dict[str, str], excel_file_path: str):
        """
        Initialize the data loader
        
        Args:
            db_config: Database connection configuration
            excel_file_path: Path to the Excel file with company data
        """
        self.db_config = db_config
        self.excel_file_path = excel_file_path
        self.connection = None
        self.cursor = None
        
        # Data containers
        self.companies_df = None
        self.regulations_df = None
        
        # ID mapping containers for handling duplicate names
        self.industry_id_mapping = {}
        self.sector_id_mapping = {}
        self.region_id_mapping = {}
        
        # Stats tracking
        self.load_stats = {
            'industries': 0,
            'sectors': 0,
            'regions': 0,
            'regulatory_bodies': 0,
            'regulations': 0,
            'companies': 0,
            'company_regulations': 0
        }
    
    def clean_regulatory_level(self, level_value: str) -> str:
        """
        Clean and standardize regulatory level values
        
        Args:
            level_value: Raw regulatory level from data
            
        Returns:
            str: Cleaned regulatory level that matches enum values
        """
        if pd.isna(level_value):
            return 'Federal'  # Default value
        
        level_str = str(level_value).strip().lower()
        
        # Clean and map regulatory levels to enum values
        if 'federal' in level_str:
            return 'Federal'
        elif 'state' in level_str or 'provincial' in level_str:
            return 'State'
        elif 'local' in level_str or 'municipal' in level_str or 'county' in level_str:
            return 'Local'
        elif 'international' in level_str or 'global' in level_str:
            return 'International'
        else:
            # Default to Federal for unknown values
            return 'Federal'
    
    def clean_company_name(self, name: str) -> str:
        """
        Clean company names to handle special characters and encoding issues
        
        Args:
            name: Raw company name
            
        Returns:
            str: Cleaned company name
        """
        if pd.isna(name):
            return ''
        
        # Convert to string and clean
        clean_name = str(name).strip()
        
        # Remove or replace problematic characters
        clean_name = clean_name.replace("'", "''")  # Handle single quotes for SQL
        clean_name = clean_name.replace('\r', ' ').replace('\n', ' ')  # Remove line breaks
        clean_name = ' '.join(clean_name.split())  # Remove extra whitespace
        
        return clean_name
    
    def connect_database(self) -> bool:
        """
        Establish connection to PostgreSQL database
        
        Returns:
            bool: True if connection successful, False otherwise
        """
        try:
            self.connection = psycopg2.connect(
                host=self.db_config['host'],
                database=self.db_config['database'],
                user=self.db_config['user'],
                password=self.db_config['password'],
                port=self.db_config.get('port', 5432)
            )
            self.connection.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
            self.cursor = self.connection.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
            
            # Set search path to companies_data schema
            self.cursor.execute("SET search_path TO companies_data;")
            
            logger.info("SUCCESS: Successfully connected to PostgreSQL database")
            return True
            
        except Exception as e:
            logger.error(f"ERROR: Failed to connect to database: {e}")
            return False
    
    def clean_regulation_name(self, reg_name: str) -> str:
        """
        Clean regulation names
        
        Args:
            reg_name: Raw regulation name
            
        Returns:
            str: Cleaned regulation name
        """
        if pd.isna(reg_name):
            return ''
        
        clean_name = str(reg_name).strip()
        clean_name = clean_name.replace("'", "''")  # Handle single quotes for SQL
        clean_name = ' '.join(clean_name.split())  # Remove extra whitespace
        
        # Truncate if too long (regulation_name is VARCHAR(500))
        if len(clean_name) > 500:
            clean_name = clean_name[:497] + '...'
        
        return clean_name
        """
        Establish connection to PostgreSQL database
        
        Returns:
            bool: True if connection successful, False otherwise
        """
        try:
            self.connection = psycopg2.connect(
                host=self.db_config['host'],
                database=self.db_config['database'],
                user=self.db_config['user'],
                password=self.db_config['password'],
                port=self.db_config.get('port', 5432)
            )
            self.connection.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
            self.cursor = self.connection.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
            
            # Set search path to companies_data schema
            self.cursor.execute("SET search_path TO companies_data;")
            
            logger.info("SUCCESS: Successfully connected to PostgreSQL database")
            return True
            
        except Exception as e:
            logger.error(f"ERROR: Failed to connect to database: {e}")
            return False
    
    def load_excel_data(self) -> bool:
        """
        Load data from Excel file into pandas DataFrames
        
        Returns:
            bool: True if loading successful, False otherwise
        """
        try:
            logger.info(f"LOADING: Excel file: {self.excel_file_path}")
            
            # Load Companies_Details sheet
            self.companies_df = pd.read_excel(
                self.excel_file_path, 
                sheet_name='Companies_Details'
            )
            
            # Load Companies_to_Regulations sheet  
            self.regulations_df = pd.read_excel(
                self.excel_file_path,
                sheet_name='Companies_to_Regulations'
            )
            
            # Clean column names (remove extra spaces)
            self.companies_df.columns = self.companies_df.columns.str.strip()
            self.regulations_df.columns = self.regulations_df.columns.str.strip()
            
            logger.info(f"SUCCESS: Loaded {len(self.companies_df)} companies records")
            logger.info(f"SUCCESS: Loaded {len(self.regulations_df)} regulation mappings")
            
            # Display column info
            logger.info(f"Companies columns: {list(self.companies_df.columns)}")
            logger.info(f"Regulations columns: {list(self.regulations_df.columns)}")
            
            return True
            
        except Exception as e:
            logger.error(f"ERROR: Failed to load Excel file: {e}")
            return False
    
    def clear_existing_data(self) -> bool:
        """
        Clear existing data to allow fresh load (optional)
        
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            logger.info("CLEARING: Existing data for fresh load...")
            
            # Clear in reverse order due to foreign key dependencies
            clear_queries = [
                "DELETE FROM company_regulations;",
                "DELETE FROM companies;", 
                "DELETE FROM regulations;",
                "DELETE FROM regulatory_bodies;",
                "DELETE FROM regions;",
                "DELETE FROM sectors;",
                "DELETE FROM industries;"
            ]
            
            for query in clear_queries:
                self.cursor.execute(query)
            
            logger.info("SUCCESS: Cleared existing data")
            return True
            
        except Exception as e:
            logger.error(f"ERROR: Failed to clear existing data: {e}")
            return False
    
    def load_industries(self) -> bool:
        """
        Load unique industries into the industries table
        Handle case where multiple industry IDs map to same industry name
        
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            logger.info("LOADING: Industries...")
            
            # Get all industry mappings from the data
            industry_mappings = {}
            industry_names_to_ids = {}
            
            for _, row in self.companies_df.iterrows():
                if pd.notna(row.get('industryid')) and pd.notna(row.get('industryname')):
                    industry_id = int(row['industryid'])
                    industry_name = str(row['industryname']).strip()
                    
                    # Track the mapping
                    industry_mappings[industry_id] = industry_name
                    
                    # For each industry name, keep track of the first ID we see
                    if industry_name not in industry_names_to_ids:
                        industry_names_to_ids[industry_name] = industry_id
            
            logger.info(f"Found {len(industry_mappings)} industry ID mappings for {len(industry_names_to_ids)} unique industry names")
            
            # Insert only the unique industry names (using the first ID we found for each name)
            successful_inserts = 0
            for industry_name, industry_id in industry_names_to_ids.items():
                try:
                    insert_query = """
                        INSERT INTO industries (industry_id, industry_name) 
                        VALUES (%s, %s) 
                        ON CONFLICT (industry_name) DO NOTHING
                    """
                    self.cursor.execute(insert_query, (industry_id, industry_name))
                    successful_inserts += 1
                except Exception as e:
                    logger.warning(f"Failed to insert industry {industry_id} ({industry_name}): {e}")
                    continue
            
            # Create mapping for companies to use
            logger.info("Creating industry ID mapping for companies...")
            self.industry_id_mapping = {}
            for original_id, industry_name in industry_mappings.items():
                canonical_id = industry_names_to_ids[industry_name]
                self.industry_id_mapping[original_id] = canonical_id
            
            self.load_stats['industries'] = successful_inserts
            
            logger.info(f"SUCCESS: Loaded {successful_inserts} unique industries")
            logger.info(f"Created mapping for {len(self.industry_id_mapping)} industry IDs")
            return True
            
        except Exception as e:
            logger.error(f"ERROR: Failed to load industries: {e}")
            return False
    
    def load_sectors(self) -> bool:
        """
        Load unique sectors into the sectors table
        Handle case where multiple sector IDs map to same sector name
        
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            logger.info("LOADING: Sectors...")
            
            # Get all sector mappings from the data
            sector_mappings = {}
            sector_names_to_ids = {}
            
            for _, row in self.companies_df.iterrows():
                if pd.notna(row.get('sectorid')) and pd.notna(row.get('Sectorname')):
                    sector_id = int(row['sectorid'])
                    sector_name = str(row['Sectorname']).strip()
                    
                    # Track the mapping
                    sector_mappings[sector_id] = sector_name
                    
                    # For each sector name, keep track of the first ID we see
                    if sector_name not in sector_names_to_ids:
                        sector_names_to_ids[sector_name] = sector_id
            
            logger.info(f"Found {len(sector_mappings)} sector ID mappings for {len(sector_names_to_ids)} unique sector names")
            
            # Insert only the unique sector names (using the first ID we found for each name)
            successful_inserts = 0
            for sector_name, sector_id in sector_names_to_ids.items():
                try:
                    insert_query = """
                        INSERT INTO sectors (sector_id, sector_name) 
                        VALUES (%s, %s) 
                        ON CONFLICT (sector_name) DO NOTHING
                    """
                    self.cursor.execute(insert_query, (sector_id, sector_name))
                    successful_inserts += 1
                except Exception as e:
                    logger.warning(f"Failed to insert sector {sector_id} ({sector_name}): {e}")
                    continue
            
            # Now we need to create a mapping table or handle the multiple IDs
            # For now, let's update companies to use the canonical sector ID
            logger.info("Creating sector ID mapping for companies...")
            self.sector_id_mapping = {}
            for original_id, sector_name in sector_mappings.items():
                canonical_id = sector_names_to_ids[sector_name]
                self.sector_id_mapping[original_id] = canonical_id
            
            self.load_stats['sectors'] = successful_inserts
            
            logger.info(f"SUCCESS: Loaded {successful_inserts} unique sectors")
            logger.info(f"Created mapping for {len(self.sector_id_mapping)} sector IDs")
            return True
            
        except Exception as e:
            logger.error(f"ERROR: Failed to load sectors: {e}")
            return False
    
    def load_regions(self) -> bool:
        """
        Load unique regions into the regions table
        Handle case where multiple region IDs map to same region name
        
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            logger.info("LOADING: Regions...")
            
            # Get all region mappings from the data
            region_mappings = {}
            region_names_to_ids = {}
            
            for _, row in self.companies_df.iterrows():
                if (pd.notna(row.get('regionid')) and 
                    pd.notna(row.get('Region Name')) and 
                    pd.notna(row.get('Country Name'))):
                    region_id = int(row['regionid'])
                    region_name = str(row['Region Name']).strip()
                    country_name = str(row['Country Name']).strip()
                    region_key = f"{region_name}_{country_name}"  # Unique key for region+country
                    
                    # Track the mapping
                    region_mappings[region_id] = {
                        'region_name': region_name,
                        'country_name': country_name,
                        'key': region_key
                    }
                    
                    # For each region+country combination, keep track of the first ID we see
                    if region_key not in region_names_to_ids:
                        region_names_to_ids[region_key] = {
                            'region_id': region_id,
                            'region_name': region_name,
                            'country_name': country_name
                        }
            
            logger.info(f"Found {len(region_mappings)} region ID mappings for {len(region_names_to_ids)} unique regions")
            
            # Insert only the unique regions (using the first ID we found for each region+country)
            successful_inserts = 0
            for region_key, region_data in region_names_to_ids.items():
                try:
                    insert_query = """
                        INSERT INTO regions (region_id, region_name, country_name) 
                        VALUES (%s, %s, %s) 
                        ON CONFLICT (region_id) DO UPDATE SET
                            region_name = EXCLUDED.region_name,
                            country_name = EXCLUDED.country_name
                    """
                    self.cursor.execute(insert_query, (
                        region_data['region_id'], 
                        region_data['region_name'], 
                        region_data['country_name']
                    ))
                    successful_inserts += 1
                except Exception as e:
                    logger.warning(f"Failed to insert region {region_data['region_id']}: {e}")
                    continue
            
            # Create mapping for companies to use
            logger.info("Creating region ID mapping for companies...")
            self.region_id_mapping = {}
            for original_id, region_info in region_mappings.items():
                region_key = region_info['key']
                canonical_id = region_names_to_ids[region_key]['region_id']
                self.region_id_mapping[original_id] = canonical_id
            
            self.load_stats['regions'] = successful_inserts
            
            logger.info(f"SUCCESS: Loaded {successful_inserts} unique regions")
            logger.info(f"Created mapping for {len(self.region_id_mapping)} region IDs")
            return True
            
        except Exception as e:
            logger.error(f"ERROR: Failed to load regions: {e}")
            return False
    
    def load_regulatory_bodies(self) -> bool:
        """
        Load unique regulatory bodies into the regulatory_bodies table
        
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            logger.info("LOADING: Regulatory bodies...")
            
            # Get unique regulatory bodies and clean the data
            reg_bodies = self.regulations_df[['Regulatory Body', 'Level']].dropna().drop_duplicates()
            
            # Insert regulatory bodies one by one with data cleaning
            successful_inserts = 0
            for _, row in reg_bodies.iterrows():
                try:
                    # Clean the data
                    clean_body_name = self.clean_company_name(row['Regulatory Body'])
                    clean_level = self.clean_regulatory_level(row['Level'])
                    
                    if not clean_body_name:  # Skip if name is empty after cleaning
                        continue
                    
                    insert_query = """
                        INSERT INTO regulatory_bodies (regulatory_body_name, regulatory_level) 
                        VALUES (%s, %s) 
                        ON CONFLICT (regulatory_body_name) DO NOTHING
                    """
                    self.cursor.execute(insert_query, (clean_body_name, clean_level))
                    successful_inserts += 1
                    
                except Exception as e:
                    logger.warning(f"Skipped regulatory body {row['Regulatory Body']}: {e}")
                    continue
            
            self.load_stats['regulatory_bodies'] = successful_inserts
            
            logger.info(f"SUCCESS: Loaded {successful_inserts} regulatory bodies (skipped duplicates)")
            return True
            
        except Exception as e:
            logger.error(f"ERROR: Failed to load regulatory bodies: {e}")
            return False
    
    def load_regulations(self) -> bool:
        """
        Load unique regulations into the regulations table
        
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            logger.info("LOADING: Regulations...")
            
            # Get unique regulations with their regulatory bodies
            regulations = self.regulations_df[['Regulations Parts', 'Regulatory Body']].dropna().drop_duplicates()
            
            # Insert regulations one by one with data cleaning
            successful_inserts = 0
            for _, row in regulations.iterrows():
                try:
                    # Clean the data
                    clean_reg_name = self.clean_regulation_name(row['Regulations Parts'])
                    clean_body_name = self.clean_company_name(row['Regulatory Body'])
                    
                    if not clean_reg_name or not clean_body_name:
                        continue
                    
                    insert_query = """
                        INSERT INTO regulations (regulation_name, regulatory_body_id) 
                        VALUES (%s, (
                            SELECT regulatory_body_id 
                            FROM regulatory_bodies 
                            WHERE regulatory_body_name = %s
                        )) 
                        ON CONFLICT DO NOTHING
                    """
                    
                    self.cursor.execute(insert_query, (clean_reg_name, clean_body_name))
                    successful_inserts += 1
                    
                except Exception as e:
                    logger.warning(f"Skipped regulation {row['Regulations Parts']}: {e}")
                    continue
            
            self.load_stats['regulations'] = successful_inserts
            
            logger.info(f"SUCCESS: Loaded {successful_inserts} regulations (skipped duplicates)")
            return True
            
        except Exception as e:
            logger.error(f"ERROR: Failed to load regulations: {e}")
            return False
    
    def load_companies(self) -> bool:
        """
        Load companies into the companies table using canonical IDs
        
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            logger.info("LOADING: Companies...")
            
            # Insert companies with data cleaning and ID mapping
            successful_inserts = 0
            batch_size = 1000
            
            for i in range(0, len(self.companies_df), batch_size):
                batch_df = self.companies_df.iloc[i:i + batch_size]
                
                for _, row in batch_df.iterrows():
                    try:
                        # Clean the data
                        clean_name = self.clean_company_name(row['companyname'])
                        clean_zipcode = str(row.get('zipcode', '')).strip() if pd.notna(row.get('zipcode')) else None
                        
                        if not clean_name:  # Skip if company name is empty
                            continue
                        
                        # Map IDs to canonical versions
                        original_industry_id = int(row.get('industryid')) if pd.notna(row.get('industryid')) else None
                        original_sector_id = int(row.get('sectorid')) if pd.notna(row.get('sectorid')) else None
                        original_region_id = int(row.get('regionid')) if pd.notna(row.get('regionid')) else None
                        
                        # Use mapped IDs
                        canonical_industry_id = self.industry_id_mapping.get(original_industry_id, original_industry_id) if original_industry_id else None
                        canonical_sector_id = self.sector_id_mapping.get(original_sector_id, original_sector_id) if original_sector_id else None
                        canonical_region_id = self.region_id_mapping.get(original_region_id, original_region_id) if original_region_id else None
                        
                        insert_query = """
                            INSERT INTO companies (
                                company_id, company_name, zipcode, 
                                industry_id, sector_id, region_id
                            ) 
                            VALUES (%s, %s, %s, %s, %s, %s) 
                            ON CONFLICT (company_id) DO UPDATE SET
                                company_name = EXCLUDED.company_name,
                                zipcode = EXCLUDED.zipcode,
                                industry_id = EXCLUDED.industry_id,
                                sector_id = EXCLUDED.sector_id,
                                region_id = EXCLUDED.region_id
                        """
                        
                        self.cursor.execute(insert_query, (
                            int(row['companyid']),
                            clean_name,
                            clean_zipcode,
                            canonical_industry_id,
                            canonical_sector_id,
                            canonical_region_id
                        ))
                        successful_inserts += 1
                        
                    except Exception as e:
                        logger.warning(f"Skipped company {row.get('companyname', 'Unknown')}: {e}")
                        continue
                
                logger.info(f"Processed companies batch {i//batch_size + 1}/{(len(self.companies_df)-1)//batch_size + 1}")
            
            self.load_stats['companies'] = successful_inserts
            
            logger.info(f"SUCCESS: Loaded {successful_inserts} companies")
            return True
            
        except Exception as e:
            logger.error(f"ERROR: Failed to load companies: {e}")
            return False
    
    def load_company_regulations(self) -> bool:
        """
        Load company-regulation mappings into the company_regulations table
        
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            logger.info("LOADING: Company-regulation mappings...")
            
            # Insert company-regulation mappings with data cleaning
            successful_inserts = 0
            for _, row in self.regulations_df.iterrows():
                try:
                    # Clean the data
                    clean_company_name = self.clean_company_name(row['Company Name'])
                    clean_regulation_name = self.clean_regulation_name(row['Regulations Parts'])
                    
                    if not clean_company_name or not clean_regulation_name:
                        continue
                    
                    insert_query = """
                        INSERT INTO company_regulations (company_id, regulation_id, compliance_status) 
                        VALUES (
                            (SELECT company_id FROM companies WHERE company_name = %s),
                            (SELECT regulation_id FROM regulations WHERE regulation_name = %s),
                            'Under Review'
                        ) 
                        ON CONFLICT (company_id, regulation_id) DO NOTHING
                    """
                    
                    self.cursor.execute(insert_query, (clean_company_name, clean_regulation_name))
                    successful_inserts += 1
                    
                except Exception as e:
                    logger.warning(f"Skipped mapping for {row.get('Company Name', 'Unknown')}: {e}")
                    continue
            
            self.load_stats['company_regulations'] = successful_inserts
            
            logger.info(f"SUCCESS: Loaded {successful_inserts} company-regulation mappings")
            return True
            
        except Exception as e:
            logger.error(f"ERROR: Failed to load company-regulation mappings: {e}")
            return False
    
    def verify_data_load(self) -> bool:
        """
        Verify that data was loaded correctly by running validation queries
        
        Returns:
            bool: True if verification successful, False otherwise
        """
        try:
            logger.info("VERIFYING: Data load...")
            
            # Check record counts
            verification_queries = [
                ("industries", "SELECT COUNT(*) FROM industries"),
                ("sectors", "SELECT COUNT(*) FROM sectors"),
                ("regions", "SELECT COUNT(*) FROM regions"),
                ("regulatory_bodies", "SELECT COUNT(*) FROM regulatory_bodies"),
                ("regulations", "SELECT COUNT(*) FROM regulations"),
                ("companies", "SELECT COUNT(*) FROM companies"),
                ("company_regulations", "SELECT COUNT(*) FROM company_regulations")
            ]
            
            logger.info("\n=== DATA LOAD VERIFICATION ===")
            for table_name, query in verification_queries:
                self.cursor.execute(query)
                count = self.cursor.fetchone()[0]
                logger.info(f"SUCCESS: {table_name}: {count} records")
            
            # Test a sample query to verify relationships work
            test_query = """
                SELECT 
                    c.company_name,
                    i.industry_name,
                    s.sector_name,
                    r.region_name,
                    COUNT(cr.regulation_id) as regulation_count
                FROM companies c
                LEFT JOIN industries i ON c.industry_id = i.industry_id
                LEFT JOIN sectors s ON c.sector_id = s.sector_id  
                LEFT JOIN regions r ON c.region_id = r.region_id
                LEFT JOIN company_regulations cr ON c.company_id = cr.company_id
                GROUP BY c.company_id, c.company_name, i.industry_name, s.sector_name, r.region_name
                LIMIT 5
            """
            
            self.cursor.execute(test_query)
            results = self.cursor.fetchall()
            
            logger.info("\n=== SAMPLE QUERY RESULTS ===")
            for row in results:
                logger.info(f"Company: {row['company_name']}, Industry: {row['industry_name']}, "
                          f"Sector: {row['sector_name']}, Region: {row['region_name']}, "
                          f"Regulations: {row['regulation_count']}")
            
            return True
            
        except Exception as e:
            logger.error(f"ERROR: Data verification failed: {e}")
            return False
    
    def close_connection(self):
        """Close database connection"""
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()
        logger.info("INFO: Database connection closed")
    
    def load_all_data(self, clear_existing: bool = False) -> bool:
        """
        Execute the complete data loading process
        
        Args:
            clear_existing: Whether to clear existing data first
        
        Returns:
            bool: True if all data loaded successfully, False otherwise
        """
        start_time = datetime.now()
        logger.info("STARTING: Complete data loading process...")
        
        try:
            # Step 1: Connect to database
            if not self.connect_database():
                return False
            
            # Step 1.5: Optionally clear existing data
            if clear_existing:
                if not self.clear_existing_data():
                    return False
            
            # Step 2: Load Excel data
            if not self.load_excel_data():
                return False
            
            # Step 3: Load reference data (order matters due to foreign keys)
            steps = [
                ("Industries", self.load_industries),
                ("Sectors", self.load_sectors),
                ("Regions", self.load_regions),
                ("Regulatory Bodies", self.load_regulatory_bodies),
                ("Regulations", self.load_regulations),
                ("Companies", self.load_companies),
                ("Company-Regulation Mappings", self.load_company_regulations)
            ]
            
            for step_name, step_function in steps:
                logger.info(f"\n--- Loading {step_name} ---")
                if not step_function():
                    logger.error(f"ERROR: Failed to load {step_name}")
                    return False
            
            # Step 4: Verify data load
            if not self.verify_data_load():
                return False
            
            # Calculate and log timing
            end_time = datetime.now()
            duration = end_time - start_time
            
            logger.info(f"\nSUCCESS: DATA LOADING COMPLETED!")
            logger.info(f"TIME: Total time: {duration}")
            logger.info(f"STATS: Final statistics: {self.load_stats}")
            
            return True
            
        except Exception as e:
            logger.error(f"ERROR: Data loading process failed: {e}")
            return False
        
        finally:
            self.close_connection()


def main():
    """
    Main function to run the data loading process
    """
    
    # Database configuration - AWS RDS PostgreSQL
    db_config = {
        'host': 'rds-prd-sumeerasolutions-pg.cm9ok286yrdx.us-east-1.rds.amazonaws.com',
        'database': 'sumeera_solutions',
        'user': 'postgres',
        'password': 'shAFYJcxFBANORxkTreO',
        'port': 5432
    }
    
    # Path to Excel file - UPDATE THIS PATH
    excel_file_path = 'Company_to_Regulations.xlsx'
    
    # Verify Excel file exists
    if not os.path.exists(excel_file_path):
        logger.error(f"ERROR: Excel file not found: {excel_file_path}")
        return False
    
    # Ask user if they want to clear existing data
    print("\nDo you want to clear existing data before loading? (y/n): ", end="")
    try:
        clear_choice = input().lower().strip()
        clear_existing = clear_choice in ['y', 'yes']
    except:
        clear_existing = False
    
    # Create and run data loader
    loader = CompaniesDataLoader(db_config, excel_file_path)
    success = loader.load_all_data(clear_existing=clear_existing)
    
    if success:
        print("\nSUCCESS! All data has been loaded into the database.")
        print("You can now run queries on your companies_data schema!")
    else:
        print("\nFAILED! Check the logs for details.")
    
    return success


if __name__ == "__main__":
    main()