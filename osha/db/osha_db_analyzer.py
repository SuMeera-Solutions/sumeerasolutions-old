#!/usr/bin/env python3
"""
OSHA Database Analyzer & Quality Reporter
Comprehensive database analysis tool for OSHA rules data
Generates detailed reports on data quality, statistics, and duplicates
"""

import psycopg2
import psycopg2.extras
from datetime import datetime
import logging
from typing import Dict, List, Any, Optional, Tuple
import sys
from collections import defaultdict
import json

# Database configuration
DB_CONFIG = {
    'host': 'rds-dev-compliease-pg.cm9ok286yrdx.us-east-1.rds.amazonaws.com',
    'username': 'postgres',
    'password': '0XNfzbSGvzzvWc40Ra7U',
    'database': 'compliease_sbx',
    'schema': 'osha_rules_v1'  # Updated to v2
}

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class OSHADatabaseAnalyzer:
    """Comprehensive analyzer for OSHA rules database"""
    
    def __init__(self, db_config: dict):
        self.db_config = db_config
        self.conn = None
        self.cursor = None
        self.report_data = {}
        
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

    def print_header(self, title: str, char: str = "=", width: int = 80):
        """Print formatted section header"""
        print(f"\n{char * width}")
        print(f"{title.center(width)}")
        print(f"{char * width}")

    def print_subheader(self, title: str, char: str = "-", width: int = 60):
        """Print formatted subsection header"""
        print(f"\n{char * width}")
        print(f"{title}")
        print(f"{char * width}")

    def execute_query(self, query: str, params: tuple = None) -> List[Dict]:
        """Execute query and return results"""
        try:
            self.cursor.execute(query, params)
            return self.cursor.fetchall()
        except Exception as e:
            logger.error(f"Query execution failed: {e}")
            logger.error(f"Query: {query}")
            return []

    def analyze_basic_statistics(self):
        """Generate basic database statistics"""
        self.print_header("OSHA DATABASE OVERVIEW", "=", 80)
        
        # Basic table counts
        tables = ['regulation', 'rule', 'condition', 'definition', 'appendix', 'training_requirement']
        
        print(f"📊 {'Table':<25} {'Count':<15} {'Description'}")
        print("-" * 70)
        
        total_records = 0
        for table in tables:
            result = self.execute_query(f"SELECT COUNT(*) as count FROM {table}")
            count = result[0]['count'] if result else 0
            total_records += count
            
            descriptions = {
                'regulation': 'Federal regulations (29 CFR parts)',
                'rule': 'Individual safety rules',
                'condition': 'Rule conditions & triggers',
                'definition': 'Regulatory term definitions',
                'appendix': 'Guidance documents',
                'training_requirement': 'Training requirements'
            }
            
            print(f"📋 {table:<25} {count:<15,} {descriptions.get(table, '')}")
        
        print("-" * 70)
        print(f"🎯 {'TOTAL RECORDS':<25} {total_records:<15,}")
        
        # Database info
        db_info = self.execute_query("""
            SELECT 
                pg_size_pretty(pg_database_size(current_database())) as db_size,
                current_database() as db_name,
                current_schema() as schema_name,
                current_timestamp as analysis_time
        """)
        
        if db_info:
            info = db_info[0]
            print(f"\n💾 Database: {info['db_name']} | Schema: {info['schema_name']} | Size: {info['db_size']}")
            print(f"⏰ Analysis Time: {info['analysis_time'].strftime('%Y-%m-%d %H:%M:%S')}")

    def analyze_regulations_by_subpart(self):
        """Analyze regulations grouped by subpart"""
        self.print_header("REGULATIONS BY SUBPART", "=", 80)
        
        query = """
        SELECT 
            r.part,
            r.subpart,
            r.title,
            COUNT(ru.rule_id) as total_rules,
            COUNT(CASE WHEN ru.severity = 'critical' THEN 1 END) as critical_rules,
            COUNT(CASE WHEN ru.severity = 'high' THEN 1 END) as high_rules,
            COUNT(CASE WHEN ru.severity = 'medium' THEN 1 END) as medium_rules,
            COUNT(CASE WHEN ru.severity = 'low' THEN 1 END) as low_rules,
            COUNT(CASE WHEN ru.rule_type = 'mandatory' THEN 1 END) as mandatory_rules,
            COUNT(CASE WHEN ru.rule_type = 'informational' THEN 1 END) as informational_rules,
            r.effective_date,
            r.last_updated
        FROM regulation r
        LEFT JOIN rule ru ON r.regulation_id = ru.regulation_id 
        WHERE ru.is_current = TRUE AND ru.is_deleted = FALSE
        GROUP BY r.regulation_id, r.part, r.subpart, r.title, r.effective_date, r.last_updated
        ORDER BY r.part, r.subpart
        """
        
        results = self.execute_query(query)
        
        if not results:
            print("❌ No regulation data found")
            return
        
        print(f"{'Part':<8} {'Subpart':<10} {'Total':<8} {'Critical':<10} {'High':<8} {'Medium':<8} {'Mandatory':<12} {'Title'}")
        print("-" * 120)
        
        total_rules = 0
        total_critical = 0
        total_mandatory = 0
        
        for reg in results:
            total_rules += reg['total_rules']
            total_critical += reg['critical_rules']
            total_mandatory += reg['mandatory_rules']
            
            title_short = reg['title'][:40] + "..." if len(reg['title']) > 40 else reg['title']
            
            print(f"{reg['part']:<8} {reg['subpart']:<10} {reg['total_rules']:<8,} "
                  f"{reg['critical_rules']:<10,} {reg['high_rules']:<8,} {reg['medium_rules']:<8,} "
                  f"{reg['mandatory_rules']:<12,} {title_short}")
        
        print("-" * 120)
        print(f"{'TOTALS':<19} {total_rules:<8,} {total_critical:<10,} {'':>28} {total_mandatory:<12,}")

    def analyze_duplicate_rules(self):
        """Find and analyze duplicate rules"""
        self.print_header("DUPLICATE RULE ANALYSIS", "=", 80)
        
        # Check for duplicate rule codes
        duplicate_codes_query = """
        SELECT 
            rule_code,
            COUNT(*) as duplicate_count,
            array_agg(rule_id) as rule_ids,
            array_agg(rule_hash) as rule_hashes,
            array_agg(created_at) as created_dates
        FROM rule 
        WHERE is_current = TRUE AND is_deleted = FALSE
        GROUP BY rule_code 
        HAVING COUNT(*) > 1
        ORDER BY COUNT(*) DESC
        """
        
        duplicate_codes = self.execute_query(duplicate_codes_query)
        
        self.print_subheader("🔍 DUPLICATE RULE CODES")
        
        if not duplicate_codes:
            print("✅ No duplicate rule codes found - excellent data quality!")
        else:
            print(f"❌ Found {len(duplicate_codes)} rule codes with duplicates:")
            print(f"{'Rule Code':<30} {'Count':<8} {'Rule IDs'}")
            print("-" * 70)
            
            for dup in duplicate_codes:
                rule_ids_str = ', '.join(map(str, dup['rule_ids']))
                print(f"{dup['rule_code']:<30} {dup['duplicate_count']:<8} {rule_ids_str}")
        
        # Check for identical rule content (same hash)
        identical_content_query = """
        SELECT 
            rule_hash,
            COUNT(*) as duplicate_count,
            array_agg(rule_code) as rule_codes,
            array_agg(rule_id) as rule_ids
        FROM rule 
        WHERE is_current = TRUE AND is_deleted = FALSE AND rule_hash IS NOT NULL
        GROUP BY rule_hash 
        HAVING COUNT(*) > 1
        ORDER BY COUNT(*) DESC
        """
        
        identical_content = self.execute_query(identical_content_query)
        
        self.print_subheader("🔍 IDENTICAL RULE CONTENT (Same Hash)")
        
        if not identical_content:
            print("✅ No rules with identical content found")
        else:
            print(f"⚠️  Found {len(identical_content)} groups of rules with identical content:")
            print(f"{'Hash (first 12)':<15} {'Count':<8} {'Rule Codes'}")
            print("-" * 80)
            
            for dup in identical_content:
                hash_short = dup['rule_hash'][:12] + "..."
                codes_str = ', '.join(dup['rule_codes'])
                if len(codes_str) > 50:
                    codes_str = codes_str[:47] + "..."
                print(f"{hash_short:<15} {dup['duplicate_count']:<8} {codes_str}")

    def analyze_data_quality(self):
        """Comprehensive data quality analysis"""
        self.print_header("DATA QUALITY REPORT", "=", 80)
        
        # Rule completeness analysis
        self.print_subheader("📋 RULE DATA COMPLETENESS")
        
        completeness_query = """
        SELECT 
            COUNT(*) as total_rules,
            COUNT(rule_text) as has_rule_text,
            COUNT(compliance_requirement) as has_requirement,
            COUNT(severity) as has_severity,
            COUNT(trigger_expression) as has_triggers,
            COUNT(exception_expression) as has_exceptions,
            COUNT(CASE WHEN array_length(applies_to, 1) > 0 THEN 1 END) as has_applies_to,
            COUNT(CASE WHEN array_length(work_types, 1) > 0 THEN 1 END) as has_work_types,
            COUNT(CASE WHEN array_length(protections, 1) > 0 THEN 1 END) as has_protections
        FROM rule 
        WHERE is_current = TRUE AND is_deleted = FALSE
        """
        
        completeness = self.execute_query(completeness_query)
        
        if completeness:
            data = completeness[0]
            total = data['total_rules']
            
            print(f"{'Field':<25} {'Count':<12} {'Percentage':<12} {'Status'}")
            print("-" * 60)
            
            fields = [
                ('Rule Text', 'has_rule_text'),
                ('Compliance Requirement', 'has_requirement'),
                ('Severity Level', 'has_severity'),
                ('Trigger Expression', 'has_triggers'),
                ('Exception Expression', 'has_exceptions'),
                ('Applies To', 'has_applies_to'),
                ('Work Types', 'has_work_types'),
                ('Protections', 'has_protections')
            ]
            
            for field_name, field_key in fields:
                count = data[field_key]
                percentage = (count / total * 100) if total > 0 else 0
                status = "✅ Good" if percentage >= 80 else "⚠️  Low" if percentage >= 50 else "❌ Poor"
                print(f"{field_name:<25} {count:<12,} {percentage:<11.1f}% {status}")
        
        # Condition analysis
        self.print_subheader("🔧 CONDITION DATA ANALYSIS")
        
        condition_query = """
        SELECT 
            condition_type,
            COUNT(*) as count,
            COUNT(CASE WHEN parameter IS NOT NULL THEN 1 END) as has_parameter,
            COUNT(CASE WHEN operator IS NOT NULL THEN 1 END) as has_operator,
            COUNT(CASE WHEN value IS NOT NULL THEN 1 END) as has_value,
            COUNT(CASE WHEN unit IS NOT NULL THEN 1 END) as has_unit
        FROM condition
        GROUP BY condition_type
        ORDER BY count DESC
        """
        
        conditions = self.execute_query(condition_query)
        
        if conditions:
            print(f"{'Type':<20} {'Count':<10} {'Has Param':<12} {'Has Operator':<14} {'Has Value':<12}")
            print("-" * 75)
            
            for cond in conditions:
                print(f"{cond['condition_type']:<20} {cond['count']:<10,} "
                      f"{cond['has_parameter']:<12,} {cond['has_operator']:<14,} {cond['has_value']:<12,}")

    def analyze_rules_by_severity(self):
        """Analyze rules by severity level"""
        self.print_subheader("⚡ RULES BY SEVERITY LEVEL")
        
        severity_query = """
        SELECT 
            COALESCE(severity, 'Unknown') as severity_level,
            COUNT(*) as rule_count,
            ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
        FROM rule 
        WHERE is_current = TRUE AND is_deleted = FALSE
        GROUP BY severity
        ORDER BY 
            CASE severity 
                WHEN 'critical' THEN 1 
                WHEN 'high' THEN 2 
                WHEN 'medium' THEN 3 
                WHEN 'low' THEN 4 
                ELSE 5 
            END
        """
        
        severities = self.execute_query(severity_query)
        
        if severities:
            print(f"{'Severity':<15} {'Count':<10} {'Percentage':<12} {'Visual'}")
            print("-" * 55)
            
            for sev in severities:
                level = sev['severity_level']
                count = sev['rule_count']
                pct = sev['percentage']
                
                # Visual bar
                bar_length = int(pct / 2)  # Scale down for display
                bar = "█" * bar_length
                
                # Color coding with emojis
                emoji = {
                    'critical': '🔴',
                    'high': '🟠', 
                    'medium': '🟡',
                    'low': '🟢',
                    'Unknown': '⚪'
                }.get(level, '⚪')
                
                print(f"{emoji} {level:<13} {count:<10,} {pct:<11}% {bar}")

    def analyze_rules_by_type(self):
        """Analyze rules by type"""
        self.print_subheader("📝 RULES BY TYPE")
        
        type_query = """
        SELECT 
            COALESCE(rule_type, 'Unknown') as rule_type,
            COUNT(*) as rule_count,
            ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
        FROM rule 
        WHERE is_current = TRUE AND is_deleted = FALSE
        GROUP BY rule_type
        ORDER BY rule_count DESC
        """
        
        types = self.execute_query(type_query)
        
        if types:
            print(f"{'Type':<20} {'Count':<10} {'Percentage'}")
            print("-" * 40)
            
            for rule_type in types:
                print(f"{rule_type['rule_type']:<20} {rule_type['rule_count']:<10,} {rule_type['percentage']}%")

    def analyze_personnel_requirements(self):
        """Analyze personnel requirements"""
        self.print_subheader("👥 PERSONNEL REQUIREMENTS")
        
        personnel_query = """
        SELECT 
            COALESCE(personnel_required, 'None specified') as personnel_type,
            COUNT(*) as rule_count
        FROM rule 
        WHERE is_current = TRUE AND is_deleted = FALSE
        GROUP BY personnel_required
        ORDER BY rule_count DESC
        """
        
        personnel = self.execute_query(personnel_query)
        
        if personnel:
            print(f"{'Personnel Required':<25} {'Rule Count'}")
            print("-" * 40)
            
            for p in personnel:
                print(f"{p['personnel_type']:<25} {p['rule_count']:<10,}")

    def analyze_orphaned_records(self):
        """Find orphaned records (referential integrity issues)"""
        self.print_subheader("🔗 REFERENTIAL INTEGRITY CHECK")
        
        # Check for conditions without rules
        orphaned_conditions = self.execute_query("""
            SELECT COUNT(*) as count 
            FROM condition c 
            LEFT JOIN rule r ON c.rule_id = r.rule_id 
            WHERE r.rule_id IS NULL
        """)
        
        # Check for definitions without regulations
        orphaned_definitions = self.execute_query("""
            SELECT COUNT(*) as count 
            FROM definition d 
            LEFT JOIN regulation reg ON d.regulation_id = reg.regulation_id 
            WHERE reg.regulation_id IS NULL
        """)
        
        print("🔍 Checking for orphaned records...")
        print(f"   Conditions without rules: {orphaned_conditions[0]['count'] if orphaned_conditions else 0}")
        print(f"   Definitions without regulations: {orphaned_definitions[0]['count'] if orphaned_definitions else 0}")
        
        if orphaned_conditions and orphaned_conditions[0]['count'] == 0 and \
           orphaned_definitions and orphaned_definitions[0]['count'] == 0:
            print("✅ No orphaned records found - excellent referential integrity!")
        else:
            print("⚠️  Some orphaned records found - review data loading process")

    def analyze_recent_changes(self):
        """Analyze recent data changes"""
        self.print_subheader("📅 RECENT DATA CHANGES")
        
        recent_query = """
        SELECT 
            'Rules' as table_name,
            COUNT(*) as total_records,
            COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as last_7_days,
            COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as last_30_days,
            MAX(created_at) as most_recent
        FROM rule
        WHERE is_current = TRUE AND is_deleted = FALSE
        
        UNION ALL
        
        SELECT 
            'Conditions' as table_name,
            COUNT(*) as total_records,
            COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as last_7_days,
            COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as last_30_days,
            MAX(created_at) as most_recent
        FROM condition
        
        UNION ALL
        
        SELECT 
            'Regulations' as table_name,
            COUNT(*) as total_records,
            COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as last_7_days,
            COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as last_30_days,
            MAX(created_at) as most_recent
        FROM regulation
        """
        
        recent = self.execute_query(recent_query)
        
        if recent:
            print(f"{'Table':<15} {'Total':<10} {'Last 7d':<10} {'Last 30d':<10} {'Most Recent'}")
            print("-" * 70)
            
            for rec in recent:
                most_recent = rec['most_recent'].strftime('%Y-%m-%d %H:%M') if rec['most_recent'] else 'N/A'
                print(f"{rec['table_name']:<15} {rec['total_records']:<10,} "
                      f"{rec['last_7_days']:<10,} {rec['last_30_days']:<10,} {most_recent}")

    def generate_executive_summary(self):
        """Generate executive summary"""
        self.print_header("EXECUTIVE SUMMARY", "🎯", 80)
        
        # Get key metrics
        total_rules = self.execute_query("""
            SELECT COUNT(*) as count FROM rule 
            WHERE is_current = TRUE AND is_deleted = FALSE
        """)
        
        total_regulations = self.execute_query("""
            SELECT COUNT(*) as count FROM regulation
        """)
        
        critical_rules = self.execute_query("""
            SELECT COUNT(*) as count FROM rule 
            WHERE is_current = TRUE AND is_deleted = FALSE AND severity = 'critical'
        """)
        
        incomplete_rules = self.execute_query("""
            SELECT COUNT(*) as count FROM rule 
            WHERE is_current = TRUE AND is_deleted = FALSE 
            AND (rule_text IS NULL OR compliance_requirement IS NULL OR severity IS NULL)
        """)
        
        rules_with_conditions = self.execute_query("""
            SELECT COUNT(DISTINCT r.rule_id) as count
            FROM rule r
            INNER JOIN condition c ON r.rule_id = c.rule_id
            WHERE r.is_current = TRUE AND r.is_deleted = FALSE
        """)
        
        # Print summary
        if (total_rules and total_regulations and critical_rules and 
            incomplete_rules and rules_with_conditions):
            
            rules_count = total_rules[0]['count']
            regs_count = total_regulations[0]['count']
            critical_count = critical_rules[0]['count']
            incomplete_count = incomplete_rules[0]['count']
            conditions_count = rules_with_conditions[0]['count']
            
            print(f"📊 Total Active Rules: {rules_count:,}")
            print(f"📋 Total Regulations: {regs_count:,}")
            print(f"🔴 Critical Rules: {critical_count:,} ({critical_count/rules_count*100:.1f}%)")
            print(f"⚠️  Incomplete Rules: {incomplete_count:,} ({incomplete_count/rules_count*100:.1f}%)")
            print(f"🔧 Rules with Conditions: {conditions_count:,} ({conditions_count/rules_count*100:.1f}%)")
            
            # Data quality score
            completeness_score = ((rules_count - incomplete_count) / rules_count * 100) if rules_count > 0 else 0
            
            print(f"\n📈 Data Quality Score: {completeness_score:.1f}%")
            
            if completeness_score >= 90:
                print("✅ Excellent data quality!")
            elif completeness_score >= 75:
                print("🟡 Good data quality with room for improvement")
            else:
                print("🔴 Data quality needs attention")

    def export_report_to_json(self, filename: str = None):
        """Export analysis results to JSON file"""
        if not filename:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"osha_db_analysis_{timestamp}.json"
        
        try:
            with open(filename, 'w') as f:
                json.dump(self.report_data, f, indent=2, default=str)
            print(f"\n💾 Report exported to: {filename}")
        except Exception as e:
            logger.error(f"Failed to export report: {e}")

    def run_complete_analysis(self, export_json: bool = False):
        """Run complete database analysis"""
        try:
            self.connect()
            
            print("🚀 Starting OSHA Database Analysis...")
            
            # Run all analyses
            self.analyze_basic_statistics()
            self.analyze_regulations_by_subpart()
            self.analyze_duplicate_rules()
            self.analyze_data_quality()
            self.analyze_rules_by_severity()
            self.analyze_rules_by_type()
            self.analyze_personnel_requirements()
            self.analyze_orphaned_records()
            self.analyze_recent_changes()
            self.generate_executive_summary()
            
            # Export if requested
            if export_json:
                self.export_report_to_json()
            
            self.print_header("ANALYSIS COMPLETE", "🎉", 80)
            print("Analysis completed successfully!")
            print("For detailed queries or custom reports, use the database connection details provided.")
            
        except Exception as e:
            logger.error(f"Analysis failed: {e}")
            raise
        finally:
            self.disconnect()

def main():
    """Main entry point"""
    print("OSHA Database Analyzer & Quality Reporter")
    print("=" * 50)
    
    # Parse command line arguments
    export_json = '--export' in sys.argv
    
    try:
        analyzer = OSHADatabaseAnalyzer(DB_CONFIG)
        analyzer.run_complete_analysis(export_json=export_json)
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()