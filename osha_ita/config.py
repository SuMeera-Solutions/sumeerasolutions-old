#!/usr/bin/env python3
"""
OSHA ITA Configuration and Setup
Configuration file and setup utilities for the OSHA ITA data loading system
"""

import os
import json
from pathlib import Path
from typing import Dict, Any

# Default configuration
DEFAULT_CONFIG = {
    "database": {
        "host": "localhost",
        "port": 5432,
        "database": "osha_ita_db",
        "username": "postgres",
        "password": None,  # Will be prompted or set via environment
        "schema": "public",
        "connection_timeout": 30,
        "command_timeout": 300
    },
    "data_loading": {
        "default_load_mode": "incremental",
        "batch_size": 1000,
        "max_errors_per_file": 100,
        "enable_backup": True,
        "auto_commit": True,
        "validate_after_load": True
    },
    "file_processing": {
        "supported_extensions": [".xlsx", ".xls", ".csv"],
        "recursive_directory_scan": True,
        "skip_hidden_files": True,
        "encoding": "utf-8",
        "date_formats": [
            "%Y-%m-%d",
            "%m/%d/%Y", 
            "%d/%m/%Y",
            "%Y-%m-%dT%H:%M:%S",
            "%Y-%m-%dT%H:%M:%S.%fZ"
        ]
    },
    "logging": {
        "level": "INFO",
        "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        "file": None,
        "max_file_size": "10MB",
        "backup_count": 5
    },
    "data_validation": {
        "check_duplicates": True,
        "check_orphaned_records": True,
        "check_data_integrity": True,
        "max_validation_errors": 50
    }
}

# Environment variable mappings
ENV_MAPPINGS = {
    "OSHA_DB_HOST": "database.host",
    "OSHA_DB_PORT": "database.port", 
    "OSHA_DB_NAME": "database.database",
    "OSHA_DB_USER": "database.username",
    "OSHA_DB_PASSWORD": "database.password",
    "OSHA_LOAD_MODE": "data_loading.default_load_mode",
    "OSHA_LOG_LEVEL": "logging.level",
    "OSHA_LOG_FILE": "logging.file"
}

class ConfigManager:
    """Configuration manager for OSHA ITA system"""
    
    def __init__(self, config_file: str = None):
        self.config_file = config_file or "osha_ita_config.json"
        self.config = DEFAULT_CONFIG.copy()
        self._load_config()
        self._load_environment_variables()
    
    def _load_config(self):
        """Load configuration from JSON file if it exists"""
        if os.path.exists(self.config_file):
            try:
                with open(self.config_file, 'r') as f:
                    file_config = json.load(f)
                self._merge_config(self.config, file_config)
                print(f"Loaded configuration from {self.config_file}")
            except Exception as e:
                print(f"Error loading config file {self.config_file}: {e}")
    
    def _load_environment_variables(self):
        """Load configuration from environment variables"""
        for env_var, config_path in ENV_MAPPINGS.items():
            value = os.getenv(env_var)
            if value is not None:
                self._set_config_value(config_path, value)
    
    def _merge_config(self, base: dict, override: dict):
        """Recursively merge configuration dictionaries"""
        for key, value in override.items():
            if key in base and isinstance(base[key], dict) and isinstance(value, dict):
                self._merge_config(base[key], value)
            else:
                base[key] = value
    
    def _set_config_value(self, path: str, value: str):
        """Set configuration value using dot notation path"""
        keys = path.split('.')
        config = self.config
        
        for key in keys[:-1]:
            if key not in config:
                config[key] = {}
            config = config[key]
        
        # Convert value to appropriate type
        final_key = keys[-1]
        if final_key == "port":
            value = int(value)
        elif final_key in ["enable_backup", "auto_commit", "validate_after_load", 
                          "recursive_directory_scan", "skip_hidden_files"]:
            value = value.lower() in ('true', '1', 'yes', 'on')
        
        config[final_key] = value
    
    def get(self, path: str = None, default=None):
        """Get configuration value using dot notation"""
        if path is None:
            return self.config
        
        keys = path.split('.')
        value = self.config
        
        for key in keys:
            if isinstance(value, dict) and key in value:
                value = value[key]
            else:
                return default
        
        return value
    
    def save_config(self, filename: str = None):
        """Save current configuration to file"""
        filename = filename or self.config_file
        with open(filename, 'w') as f:
            json.dump(self.config, f, indent=2)
        print(f"Configuration saved to {filename}")

def create_sample_config():
    """Create a sample configuration file"""
    config_manager = ConfigManager()
    
    # Customize some settings for the sample
    sample_config = DEFAULT_CONFIG.copy()
    sample_config["database"]["host"] = "your-postgresql-host"
    sample_config["database"]["database"] = "osha_ita_production"
    sample_config["database"]["username"] = "osha_user"
    sample_config["logging"]["file"] = "osha_ita_loader.log"
    sample_config["logging"]["level"] = "INFO"
    
    with open("osha_ita_config_sample.json", 'w') as f:
        json.dump(sample_config, f, indent=2)
    
    print("Sample configuration created: osha_ita_config_sample.json")
    print("Copy this to osha_ita_config.json and customize for your environment")

def setup_database_schema():
    """Setup script to create the database schema"""
    print("""
To set up the OSHA ITA database schema:

1. Create PostgreSQL database:
   createdb osha_ita_db

2. Run the schema creation script:
   psql -d osha_ita_db -f osha_ita_schema.sql

3. Verify the installation:
   psql -d osha_ita_db -c "\\dt"

4. Optional: Create dedicated user:
   psql -d osha_ita_db -c "CREATE USER osha_user WITH PASSWORD 'secure_password';"
   psql -d osha_ita_db -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO osha_user;"
   psql -d osha_ita_db -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO osha_user;"
""")

def check_dependencies():
    """Check if all required Python packages are installed"""
    required_packages = [
        'pandas',
        'psycopg2-binary', 
        'openpyxl',
        'pathlib'
    ]
    
    missing_packages = []
    
    for package in required_packages:
        try:
            __import__(package.replace('-', '_'))
            print(f"✓ {package}")
        except ImportError:
            missing_packages.append(package)
            print(f"✗ {package} - MISSING")
    
    if missing_packages:
        print(f"\nInstall missing packages:")
        print(f"pip install {' '.join(missing_packages)}")
        return False
    else:
        print("\nAll required packages are installed!")
        return True

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="OSHA ITA Setup and Configuration")
    parser.add_argument('--create-config', action='store_true',
                       help='Create sample configuration file')
    parser.add_argument('--check-deps', action='store_true',
                       help='Check Python dependencies')
    parser.add_argument('--setup-db', action='store_true',
                       help='Show database setup instructions')
    
    args = parser.parse_args()
    
    if args.create_config:
        create_sample_config()
    
    if args.check_deps:
        check_dependencies()
    
    if args.setup_db:
        setup_database_schema()
    
    if not any(vars(args).values()):
        parser.print_help()

# Usage examples and documentation
USAGE_EXAMPLES = """
OSHA ITA Data Loader - Usage Examples

1. BASIC USAGE:
   # Process single Excel file
   python osha_ita_loader.py data.xlsx
   
   # Process entire directory
   python osha_ita_loader.py --directory /path/to/ita/data

2. CONFIGURATION:
   # Use custom config file
   python osha_ita_loader.py --config custom_config.json data.xlsx
   
   # Override database settings
   export OSHA_DB_HOST=production-server
   export OSHA_DB_PASSWORD=secure_password
   python osha_ita_loader.py data.xlsx

3. LOAD MODES:
   # Full refresh (clear all data and reload)
   python osha_ita_loader.py --mode full_refresh --directory /data
   
   # Incremental (only load new/changed data)
   python osha_ita_loader.py --mode incremental --directory /data
   
   # Update existing (update in place)
   python osha_ita_loader.py --mode update_existing file.xlsx
   
   # Validation only (check what would happen)
   python osha_ita_loader.py --mode validate_only --directory /data

4. DRY RUN AND TESTING:
   # See what would happen without making changes
   python osha_ita_loader.py --dry-run --directory /data
   
   # Detailed logging
   python osha_ita_loader.py --log-level DEBUG --log-file debug.log data.xlsx

5. DIRECTORY STRUCTURE EXAMPLES:
   /ita_data/
   ├── ITA Data CY 2016/
   │   ├── ita_300a_summary_2016.xlsx
   │   └── ita_case_detail_2016.csv
   ├── ITA Data CY 2017/
   │   └── combined_ita_2017.xlsx
   ├── ITA-data-cy2022/
   │   └── summary_and_cases.xlsx
   └── ITA_300A_Summary_Data_2024_through_04-30-2025/
       └── current_data.xlsx

6. ADVANCED USAGE:
   # Process with specific year override
   python osha_ita_loader.py --year 2023 historical_data.xlsx
   
   # Generate report file
   python osha_ita_loader.py --report-file load_report.txt --directory /data
   
   # Quiet mode (minimal output)
   python osha_ita_loader.py --quiet --directory /data

7. TROUBLESHOOTING:
   # Check what files would be processed
   python osha_ita_loader.py --dry-run --log-level DEBUG --directory /data
   
   # Validate existing data
   python osha_ita_loader.py --mode validate_only existing_file.xlsx
   
   # Process single problematic file
   python osha_ita_loader.py --log-level DEBUG problem_file.xlsx

CONFIGURATION HIERARCHY (highest to lowest priority):
1. Command line arguments
2. Environment variables (OSHA_*)
3. Configuration file (osha_ita_config.json)
4. Default values

ENVIRONMENT VARIABLES:
- OSHA_DB_HOST: Database host
- OSHA_DB_PORT: Database port  
- OSHA_DB_NAME: Database name
- OSHA_DB_USER: Database username
- OSHA_DB_PASSWORD: Database password
- OSHA_LOAD_MODE: Default load mode
- OSHA_LOG_LEVEL: Logging level
- OSHA_LOG_FILE: Log file path
"""