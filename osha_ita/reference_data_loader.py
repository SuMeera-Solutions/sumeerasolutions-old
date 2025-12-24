#!/usr/bin/env python3
"""
OSHA ITA Reference Data Loader
Loads basic reference data into OSHA ITA database tables
- State codes
- NAICS codes (basic set)
- SOC codes (basic set)
- Size categories
- Establishment types
"""

import psycopg2
import psycopg2.extras
import logging
import sys
from typing import List, Dict, Any
import json

# Database configuration - UPDATE THESE VALUES
DB_CONFIG = {
    'host': 'rds-dev-compliease-pg.cm9ok286yrdx.us-east-1.rds.amazonaws.com',
    'username': 'postgres',
    'password': '0XNfzbSGvzzvWc40Ra7U',
    'database': 'compliease_sbx',
    'schema': 'osha_ita',
    'port': 5432
}

def setup_logging():
    """Setup logging"""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    return logging.getLogger(__name__)

class ReferenceDataLoader:
    """Loads reference data into OSHA ITA database"""
    
    def __init__(self, db_config: dict):
        self.db_config = db_config
        self.conn = None
        self.cursor = None
        self.logger = logging.getLogger(__name__)
        
    def connect(self):
        """Establish database connection"""
        try:
            self.conn = psycopg2.connect(
                host=self.db_config['host'],
                user=self.db_config['username'],
                password=self.db_config['password'],
                database=self.db_config['database'],
                port=self.db_config.get('port', 5432)
            )
            self.cursor = self.conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
            
            # Set schema if specified
            if 'schema' in self.db_config and self.db_config['schema']:
                self.cursor.execute(f"SET search_path TO {self.db_config['schema']}")
                self.conn.commit()  # Commit the schema change
            
            self.logger.info(f"Connected to database: {self.db_config['database']}")
            if 'schema' in self.db_config:
                self.logger.info(f"Using schema: {self.db_config['schema']}")
                
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
    
    def load_state_codes(self):
        """Load US state and territory codes"""
        self.logger.info("Loading state codes...")
        
        states_data = [
            ('AL', 'Alabama', False),
            ('AK', 'Alaska', False),
            ('AZ', 'Arizona', False),
            ('AR', 'Arkansas', False),
            ('CA', 'California', False),
            ('CO', 'Colorado', False),
            ('CT', 'Connecticut', False),
            ('DE', 'Delaware', False),
            ('FL', 'Florida', False),
            ('GA', 'Georgia', False),
            ('HI', 'Hawaii', False),
            ('ID', 'Idaho', False),
            ('IL', 'Illinois', False),
            ('IN', 'Indiana', False),
            ('IA', 'Iowa', False),
            ('KS', 'Kansas', False),
            ('KY', 'Kentucky', False),
            ('LA', 'Louisiana', False),
            ('ME', 'Maine', False),
            ('MD', 'Maryland', False),
            ('MA', 'Massachusetts', False),
            ('MI', 'Michigan', False),
            ('MN', 'Minnesota', False),
            ('MS', 'Mississippi', False),
            ('MO', 'Missouri', False),
            ('MT', 'Montana', False),
            ('NE', 'Nebraska', False),
            ('NV', 'Nevada', False),
            ('NH', 'New Hampshire', False),
            ('NJ', 'New Jersey', False),
            ('NM', 'New Mexico', False),
            ('NY', 'New York', False),
            ('NC', 'North Carolina', False),
            ('ND', 'North Dakota', False),
            ('OH', 'Ohio', False),
            ('OK', 'Oklahoma', False),
            ('OR', 'Oregon', False),
            ('PA', 'Pennsylvania', False),
            ('RI', 'Rhode Island', False),
            ('SC', 'South Carolina', False),
            ('SD', 'South Dakota', False),
            ('TN', 'Tennessee', False),
            ('TX', 'Texas', False),
            ('UT', 'Utah', False),
            ('VT', 'Vermont', False),
            ('VA', 'Virginia', False),
            ('WA', 'Washington', False),
            ('WV', 'West Virginia', False),
            ('WI', 'Wisconsin', False),
            ('WY', 'Wyoming', False),
            ('DC', 'District of Columbia', True),
            ('PR', 'Puerto Rico', True),
            ('VI', 'U.S. Virgin Islands', True),
            ('AS', 'American Samoa', True),
            ('GU', 'Guam', True),
            ('MP', 'Northern Mariana Islands', True)
        ]
        
        # Clear existing data
        self.cursor.execute("DELETE FROM ref_states")
        
        # Insert state data
        insert_query = """
            INSERT INTO ref_states (state_code, state_name, is_territory)
            VALUES (%s, %s, %s)
            ON CONFLICT (state_code) DO UPDATE SET
                state_name = EXCLUDED.state_name,
                is_territory = EXCLUDED.is_territory
        """
        
        self.cursor.executemany(insert_query, states_data)
        self.logger.info(f"Loaded {len(states_data)} state/territory codes")
    
    def load_basic_naics_codes(self):
        """Load basic NAICS codes commonly found in OSHA data"""
        self.logger.info("Loading basic NAICS codes...")
        
        # Common NAICS codes from OSHA data
        naics_data = [
            ('11', 2022, 'Agriculture, Forestry, Fishing and Hunting', '11', 'Agriculture, Forestry, Fishing and Hunting'),
            ('21', 2022, 'Mining, Quarrying, and Oil and Gas Extraction', '21', 'Mining, Quarrying, and Oil and Gas Extraction'),
            ('22', 2022, 'Utilities', '22', 'Utilities'),
            ('23', 2022, 'Construction', '23', 'Construction'),
            ('31', 2022, 'Manufacturing', '31-33', 'Manufacturing'),
            ('32', 2022, 'Manufacturing', '31-33', 'Manufacturing'),
            ('33', 2022, 'Manufacturing', '31-33', 'Manufacturing'),
            ('42', 2022, 'Wholesale Trade', '42', 'Wholesale Trade'),
            ('44', 2022, 'Retail Trade', '44-45', 'Retail Trade'),
            ('45', 2022, 'Retail Trade', '44-45', 'Retail Trade'),
            ('48', 2022, 'Transportation and Warehousing', '48-49', 'Transportation and Warehousing'),
            ('49', 2022, 'Transportation and Warehousing', '48-49', 'Transportation and Warehousing'),
            ('51', 2022, 'Information', '51', 'Information'),
            ('52', 2022, 'Finance and Insurance', '52', 'Finance and Insurance'),
            ('53', 2022, 'Real Estate and Rental and Leasing', '53', 'Real Estate and Rental and Leasing'),
            ('54', 2022, 'Professional, Scientific, and Technical Services', '54', 'Professional, Scientific, and Technical Services'),
            ('55', 2022, 'Management of Companies and Enterprises', '55', 'Management of Companies and Enterprises'),
            ('56', 2022, 'Administrative and Support and Waste Management and Remediation Services', '56', 'Administrative and Support and Waste Management'),
            ('61', 2022, 'Educational Services', '61', 'Educational Services'),
            ('62', 2022, 'Health Care and Social Assistance', '62', 'Health Care and Social Assistance'),
            ('71', 2022, 'Arts, Entertainment, and Recreation', '71', 'Arts, Entertainment, and Recreation'),
            ('72', 2022, 'Accommodation and Food Services', '72', 'Accommodation and Food Services'),
            ('81', 2022, 'Other Services (except Public Administration)', '81', 'Other Services'),
            ('92', 2022, 'Public Administration', '92', 'Public Administration'),
            
            # Specific common codes from OSHA data
            ('111', 2022, 'Crop Production', '11', 'Agriculture, Forestry, Fishing and Hunting'),
            ('236', 2022, 'Construction of Buildings', '23', 'Construction'),
            ('311', 2022, 'Food Manufacturing', '31-33', 'Manufacturing'),
            ('321', 2022, 'Wood Product Manufacturing', '31-33', 'Manufacturing'),
            ('336', 2022, 'Transportation Equipment Manufacturing', '31-33', 'Manufacturing'),
            ('484', 2022, 'Truck Transportation', '48-49', 'Transportation and Warehousing'),
            ('621', 2022, 'Ambulatory Health Care Services', '62', 'Health Care and Social Assistance'),
            ('623', 2022, 'Nursing and Residential Care Facilities', '62', 'Health Care and Social Assistance'),
            ('722', 2022, 'Food Services and Drinking Places', '72', 'Accommodation and Food Services'),
            
            # Specific 6-digit codes commonly seen
            ('111110', 2022, 'Soybean Farming', '11', 'Agriculture, Forestry, Fishing and Hunting'),
            ('236220', 2022, 'Commercial and Institutional Building Construction', '23', 'Construction'),
            ('311421', 2022, 'Fruit and Vegetable Canning', '31-33', 'Manufacturing'),
            ('336111', 2022, 'Automobile Manufacturing', '31-33', 'Manufacturing'),
            ('484110', 2022, 'General Freight Trucking, Local', '48-49', 'Transportation and Warehousing'),
            ('621111', 2022, 'Offices of Physicians (except Mental Health Specialists)', '62', 'Health Care and Social Assistance'),
            ('623110', 2022, 'Nursing Care Facilities (Skilled Nursing Facilities)', '62', 'Health Care and Social Assistance'),
            ('722511', 2022, 'Full-Service Restaurants', '72', 'Accommodation and Food Services')
        ]
        
        # Clear existing data
        self.cursor.execute("DELETE FROM ref_naics_codes")
        
        # Insert NAICS data
        insert_query = """
            INSERT INTO ref_naics_codes (naics_code, naics_year, industry_title, sector_code, sector_title)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (naics_code) DO UPDATE SET
                naics_year = EXCLUDED.naics_year,
                industry_title = EXCLUDED.industry_title,
                sector_code = EXCLUDED.sector_code,
                sector_title = EXCLUDED.sector_title
        """
        
        self.cursor.executemany(insert_query, naics_data)
        self.logger.info(f"Loaded {len(naics_data)} NAICS codes")
    
    def load_basic_soc_codes(self):
        """Load basic SOC codes commonly found in OSHA data"""
        self.logger.info("Loading basic SOC codes...")
        
        # Common SOC codes from OSHA data
        soc_data = [
            ('11-0000', 2018, 'Management Occupations', 'Management', 'Management Occupations', 'Management Occupations'),
            ('13-0000', 2018, 'Business and Financial Operations Occupations', 'Business and Financial Operations', 'Business and Financial Operations Occupations', 'Business and Financial Operations'),
            ('15-0000', 2018, 'Computer and Mathematical Occupations', 'Computer and Mathematical', 'Computer and Mathematical Occupations', 'Computer and Mathematical'),
            ('17-0000', 2018, 'Architecture and Engineering Occupations', 'Architecture and Engineering', 'Architecture and Engineering Occupations', 'Architecture and Engineering'),
            ('19-0000', 2018, 'Life, Physical, and Social Science Occupations', 'Life, Physical, and Social Science', 'Life, Physical, and Social Science Occupations', 'Life, Physical, and Social Science'),
            ('21-0000', 2018, 'Community and Social Service Occupations', 'Community and Social Service', 'Community and Social Service Occupations', 'Community and Social Service'),
            ('23-0000', 2018, 'Legal Occupations', 'Legal', 'Legal Occupations', 'Legal'),
            ('25-0000', 2018, 'Educational Instruction and Library Occupations', 'Educational Instruction and Library', 'Educational Instruction and Library Occupations', 'Educational Instruction and Library'),
            ('27-0000', 2018, 'Arts, Design, Entertainment, Sports, and Media Occupations', 'Arts, Design, Entertainment, Sports, and Media', 'Arts, Design, Entertainment, Sports, and Media Occupations', 'Arts, Design, Entertainment, Sports, and Media'),
            ('29-0000', 2018, 'Healthcare Practitioners and Technical Occupations', 'Healthcare Practitioners and Technical', 'Healthcare Practitioners and Technical Occupations', 'Healthcare Practitioners and Technical'),
            ('31-0000', 2018, 'Healthcare Support Occupations', 'Healthcare Support', 'Healthcare Support Occupations', 'Healthcare Support'),
            ('33-0000', 2018, 'Protective Service Occupations', 'Protective Service', 'Protective Service Occupations', 'Protective Service'),
            ('35-0000', 2018, 'Food Preparation and Serving Related Occupations', 'Food Preparation and Serving Related', 'Food Preparation and Serving Related Occupations', 'Food Preparation and Serving Related'),
            ('37-0000', 2018, 'Building and Grounds Cleaning and Maintenance Occupations', 'Building and Grounds Cleaning and Maintenance', 'Building and Grounds Cleaning and Maintenance Occupations', 'Building and Grounds Cleaning and Maintenance'),
            ('39-0000', 2018, 'Personal Care and Service Occupations', 'Personal Care and Service', 'Personal Care and Service Occupations', 'Personal Care and Service'),
            ('41-0000', 2018, 'Sales and Related Occupations', 'Sales and Related', 'Sales and Related Occupations', 'Sales and Related'),
            ('43-0000', 2018, 'Office and Administrative Support Occupations', 'Office and Administrative Support', 'Office and Administrative Support Occupations', 'Office and Administrative Support'),
            ('45-0000', 2018, 'Farming, Fishing, and Forestry Occupations', 'Farming, Fishing, and Forestry', 'Farming, Fishing, and Forestry Occupations', 'Farming, Fishing, and Forestry'),
            ('47-0000', 2018, 'Construction and Extraction Occupations', 'Construction and Extraction', 'Construction and Extraction Occupations', 'Construction and Extraction'),
            ('49-0000', 2018, 'Installation, Maintenance, and Repair Occupations', 'Installation, Maintenance, and Repair', 'Installation, Maintenance, and Repair Occupations', 'Installation, Maintenance, and Repair'),
            ('51-0000', 2018, 'Production Occupations', 'Production', 'Production Occupations', 'Production'),
            ('53-0000', 2018, 'Transportation and Material Moving Occupations', 'Transportation and Material Moving', 'Transportation and Material Moving Occupations', 'Transportation and Material Moving'),
            
            # Specific common codes
            ('11-1011', 2018, 'Chief Executives', 'Management', 'Top Executives', 'Chief Executives'),
            ('43-2011', 2018, 'Switchboard Operators, Including Answering Service', 'Office and Administrative Support', 'Communications Equipment Operators', 'Switchboard Operators'),
            ('29-1141', 2018, 'Registered Nurses', 'Healthcare Practitioners and Technical', 'Health Diagnosing and Treating Practitioners', 'Registered Nurses'),
            ('51-1011', 2018, 'First-Line Supervisors of Production and Operating Workers', 'Production', 'Supervisors of Production Workers', 'First-Line Supervisors of Production Workers'),
            ('53-3032', 2018, 'Heavy and Tractor-Trailer Truck Drivers', 'Transportation and Material Moving', 'Motor Vehicle Operators', 'Heavy and Tractor-Trailer Truck Drivers'),
            ('47-2061', 2018, 'Construction Laborers', 'Construction and Extraction', 'Construction Trades Workers', 'Construction Laborers'),
            ('35-3021', 2018, 'Combined Food Preparation and Serving Workers, Including Fast Food', 'Food Preparation and Serving Related', 'Food and Beverage Serving Workers', 'Combined Food Preparation and Serving Workers'),
            ('9999', 2018, 'Uncoded', 'Uncoded', 'Uncoded', 'Uncoded')
        ]
        
        # Clear existing data
        self.cursor.execute("DELETE FROM ref_soc_codes")
        
        # Insert SOC data
        insert_query = """
            INSERT INTO ref_soc_codes (soc_code, soc_year, title, major_group, minor_group, broad_occupation)
            VALUES (%s, %s, %s, %s, %s, %s)
            ON CONFLICT (soc_code) DO UPDATE SET
                soc_year = EXCLUDED.soc_year,
                title = EXCLUDED.title,
                major_group = EXCLUDED.major_group,
                minor_group = EXCLUDED.minor_group,
                broad_occupation = EXCLUDED.broad_occupation
        """
        
        self.cursor.executemany(insert_query, soc_data)
        self.logger.info(f"Loaded {len(soc_data)} SOC codes")
    
    def create_lookup_functions(self):
        """Create useful lookup functions"""
        self.logger.info("Creating lookup functions...")
        
        # Function to get NAICS sector from code
        naics_sector_function = """
        CREATE OR REPLACE FUNCTION get_naics_sector(naics_code_input TEXT)
        RETURNS TEXT AS $$
        BEGIN
            RETURN (
                SELECT sector_title 
                FROM ref_naics_codes 
                WHERE naics_code = LEFT(naics_code_input, LENGTH(naics_code))
                ORDER BY LENGTH(naics_code) DESC 
                LIMIT 1
            );
        END;
        $$ LANGUAGE plpgsql;
        """
        
        # Function to get SOC major group from code
        soc_group_function = """
        CREATE OR REPLACE FUNCTION get_soc_major_group(soc_code_input TEXT)
        RETURNS TEXT AS $$
        BEGIN
            RETURN (
                SELECT major_group 
                FROM ref_soc_codes 
                WHERE soc_code = soc_code_input
                   OR soc_code = LEFT(soc_code_input, 7) || '0'
                   OR soc_code = LEFT(soc_code_input, 5) || '000'
                   OR soc_code = LEFT(soc_code_input, 2) || '-0000'
                ORDER BY LENGTH(soc_code) DESC 
                LIMIT 1
            );
        END;
        $$ LANGUAGE plpgsql;
        """
        
        self.cursor.execute(naics_sector_function)
        self.cursor.execute(soc_group_function)
        self.logger.info("Created lookup functions")
    
    def create_data_validation_views(self):
        """Create views for data validation"""
        self.logger.info("Creating validation views...")
        
        # View for establishment data quality
        establishment_quality_view = """
        CREATE OR REPLACE VIEW v_establishment_data_quality AS
        SELECT 
            'Missing EIN' as issue_type,
            COUNT(*) as count
        FROM establishments 
        WHERE ein IS NULL OR ein = ''
        
        UNION ALL
        
        SELECT 
            'Missing Establishment Name' as issue_type,
            COUNT(*) as count
        FROM establishments 
        WHERE establishment_name IS NULL OR establishment_name = ''
        
        UNION ALL
        
        SELECT 
            'Invalid State Code' as issue_type,
            COUNT(*) as count
        FROM establishments e
        LEFT JOIN ref_states s ON e.state_code = s.state_code
        WHERE e.state_code IS NOT NULL AND s.state_code IS NULL
        
        UNION ALL
        
        SELECT 
            'Unknown NAICS Code' as issue_type,
            COUNT(*) as count
        FROM establishments e
        LEFT JOIN ref_naics_codes n ON e.primary_naics_code = n.naics_code
        WHERE e.primary_naics_code IS NOT NULL AND n.naics_code IS NULL;
        """
        
        self.cursor.execute(establishment_quality_view)
        self.logger.info("Created validation views")
    
    def load_all_reference_data(self):
        """Load all reference data"""
        try:
            self.connect()
            
            # Load basic reference data
            self.load_state_codes()
            self.load_basic_naics_codes()
            self.load_basic_soc_codes()
            
            # Create helper functions
            self.create_lookup_functions()
            self.create_data_validation_views()
            
            # Commit all changes
            self.conn.commit()
            self.logger.info("All reference data loaded successfully!")
            
        except Exception as e:
            self.logger.error(f"Failed to load reference data: {e}")
            if self.conn:
                self.conn.rollback()
            raise
        finally:
            self.disconnect()
    
    def test_connection(self):
        """Test database connection and schema access"""
        try:
            self.logger.info("Testing database connection...")
            self.connect()
            
            # Test basic query
            self.cursor.execute("SELECT current_database(), current_schema()")
            result = self.cursor.fetchone()
            self.logger.info(f"Connected to database: {result[0]}, schema: {result[1]}")
            
            # Test if we can see tables
            self.cursor.execute("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = current_schema()
                ORDER BY table_name
            """)
            tables = self.cursor.fetchall()
            self.logger.info(f"Found {len(tables)} tables in current schema")
            for table in tables:
                self.logger.info(f"  - {table[0]}")
                
            self.disconnect()
            return True
            
        except Exception as e:
            self.logger.error(f"Connection test failed: {e}")
            if self.conn:
                self.disconnect()
            return False
        """Check if required tables exist"""
        self.logger.info("Validating table structure...")
        
        required_tables = [
            'ref_states',
            'ref_naics_codes', 
            'ref_soc_codes',
            'establishments',
            'summary_300a_data',
            'case_detail_data',
            'data_loads'
        ]
        
        self.connect()
        
        for table in required_tables:
            self.cursor.execute("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_schema = %s AND table_name = %s
                )
            """, (self.db_config.get('schema', 'public'), table))
            
            exists = self.cursor.fetchone()[0]
            if exists:
                self.logger.info(f"✓ Table {table} exists")
            else:
                self.logger.error(f"✗ Table {table} does not exist")
                
        self.disconnect()

def main():
    """Main function"""
    logger = setup_logging()
    
    try:
        loader = ReferenceDataLoader(DB_CONFIG)
        
        # First test the connection
        if not loader.test_connection():
            logger.error("Connection test failed. Please check your database configuration.")
            sys.exit(1)
        
        # Validate tables exist
        loader.validate_tables_exist()
        
        # Load reference data
        loader.load_all_reference_data()
        
        logger.info("Reference data loading completed successfully!")
        
    except Exception as e:
        logger.error(f"Reference data loading failed: {e}")
        import traceback
        logger.error(traceback.format_exc())
        sys.exit(1)

if __name__ == "__main__":
    main()