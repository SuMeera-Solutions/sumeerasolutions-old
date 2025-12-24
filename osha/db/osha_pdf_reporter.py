#!/usr/bin/env python3
"""
OSHA Database PDF Reporter
Generates beautiful PDF reports with charts and analysis
Fixed JSON export and added comprehensive PDF generation
"""

import psycopg2
import psycopg2.extras
from datetime import datetime
import logging
from typing import Dict, List, Any, Optional, Tuple
import sys
import json
from collections import defaultdict
import os

# For PDF generation
try:
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import letter, A4
    from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer, PageBreak
    from reportlab.platypus import Image as RLImage
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import inch
    from reportlab.graphics.shapes import Drawing, Rect, String
    from reportlab.graphics.charts.barcharts import VerticalBarChart
    from reportlab.graphics.charts.piecharts import Pie
    from reportlab.graphics import renderPDF
    from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
    PDF_AVAILABLE = True
except ImportError:
    print("⚠️  PDF libraries not available. Install with: pip install reportlab")
    PDF_AVAILABLE = False

# For charts (optional)
try:
    import matplotlib.pyplot as plt
    import matplotlib.patches as mpatches
    from io import BytesIO
    import base64
    CHARTS_AVAILABLE = True
except ImportError:
    print("⚠️  Chart libraries not available. Install with: pip install matplotlib")
    CHARTS_AVAILABLE = False

# Database configuration
DB_CONFIG = {
    'host': 'rds-dev-compliease-pg.cm9ok286yrdx.us-east-1.rds.amazonaws.com',
    'username': 'postgres',
    'password': '0XNfzbSGvzzvWc40Ra7U',
    'database': 'compliease_sbx',
    'schema': 'osha_rules_v1'  # Fixed to v1
}

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class OSHAPDFReporter:
    """Enhanced OSHA database analyzer with PDF report generation"""
    
    def __init__(self, db_config: dict):
        self.db_config = db_config
        self.conn = None
        self.cursor = None
        self.report_data = {}
        self.styles = None
        
        if PDF_AVAILABLE:
            self.styles = getSampleStyleSheet()
            # Custom styles
            self.styles.add(ParagraphStyle(
                name='CustomTitle',
                parent=self.styles['Heading1'],
                fontSize=24,
                spaceAfter=30,
                alignment=TA_CENTER,
                textColor=colors.darkblue
            ))
            self.styles.add(ParagraphStyle(
                name='CustomHeading',
                parent=self.styles['Heading2'], 
                fontSize=16,
                spaceAfter=12,
                textColor=colors.darkblue
            ))
            self.styles.add(ParagraphStyle(
                name='CustomSubheading',
                parent=self.styles['Heading3'],
                fontSize=14,
                spaceAfter=8,
                textColor=colors.darkgreen
            ))
        
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

    def execute_query(self, query: str, params: tuple = None) -> List[Dict]:
        """Execute query and return results"""
        try:
            self.cursor.execute(query, params)
            return self.cursor.fetchall()
        except Exception as e:
            logger.error(f"Query execution failed: {e}")
            logger.error(f"Query: {query}")
            return []

    def collect_all_data(self):
        """Collect all analysis data for reporting"""
        self.report_data = {
            'metadata': {
                'generated_at': datetime.now().isoformat(),
                'database': self.db_config['database'],
                'schema': self.db_config['schema']
            }
        }
        
        # Basic statistics
        self.report_data['basic_stats'] = self._collect_basic_stats()
        
        # Regulations by subpart
        self.report_data['regulations_by_subpart'] = self._collect_regulations_by_subpart()
        
        # Duplicate analysis
        self.report_data['duplicate_analysis'] = self._collect_duplicate_analysis()
        
        # Data quality
        self.report_data['data_quality'] = self._collect_data_quality()
        
        # Rules by severity
        self.report_data['rules_by_severity'] = self._collect_rules_by_severity()
        
        # Rules by type
        self.report_data['rules_by_type'] = self._collect_rules_by_type()
        
        # Personnel requirements
        self.report_data['personnel_requirements'] = self._collect_personnel_requirements()
        
        # Integrity check
        self.report_data['integrity_check'] = self._collect_integrity_check()
        
        # Recent changes
        self.report_data['recent_changes'] = self._collect_recent_changes()
        
        # Executive summary
        self.report_data['executive_summary'] = self._collect_executive_summary()

    def _collect_basic_stats(self):
        """Collect basic database statistics"""
        tables = ['regulation', 'rule', 'condition', 'definition', 'appendix', 'training_requirement']
        stats = {}
        
        for table in tables:
            result = self.execute_query(f"SELECT COUNT(*) as count FROM {table}")
            stats[table] = result[0]['count'] if result else 0
        
        # Database info
        db_info = self.execute_query("""
            SELECT 
                pg_size_pretty(pg_database_size(current_database())) as db_size,
                current_database() as db_name,
                current_schema() as schema_name,
                current_timestamp as analysis_time
        """)
        
        if db_info:
            stats['database_info'] = dict(db_info[0])
        
        return stats

    def _collect_regulations_by_subpart(self):
        """Collect regulations grouped by subpart"""
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
        return [dict(row) for row in results] if results else []

    def _collect_duplicate_analysis(self):
        """Collect duplicate analysis data"""
        # Duplicate codes
        duplicate_codes_query = """
        SELECT 
            rule_code,
            COUNT(*) as duplicate_count,
            array_agg(rule_id) as rule_ids
        FROM rule 
        WHERE is_current = TRUE AND is_deleted = FALSE
        GROUP BY rule_code 
        HAVING COUNT(*) > 1
        ORDER BY COUNT(*) DESC
        """
        
        duplicate_codes = self.execute_query(duplicate_codes_query)
        
        # Identical content
        identical_content_query = """
        SELECT 
            rule_hash,
            COUNT(*) as duplicate_count,
            array_agg(rule_code) as rule_codes
        FROM rule 
        WHERE is_current = TRUE AND is_deleted = FALSE AND rule_hash IS NOT NULL
        GROUP BY rule_hash 
        HAVING COUNT(*) > 1
        ORDER BY COUNT(*) DESC
        """
        
        identical_content = self.execute_query(identical_content_query)
        
        return {
            'duplicate_codes': [dict(row) for row in duplicate_codes] if duplicate_codes else [],
            'identical_content': [dict(row) for row in identical_content] if identical_content else []
        }

    def _collect_data_quality(self):
        """Collect data quality metrics"""
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
        
        return {
            'completeness': dict(completeness[0]) if completeness else {},
            'conditions': [dict(row) for row in conditions] if conditions else []
        }

    def _collect_rules_by_severity(self):
        """Collect rules by severity"""
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
        
        results = self.execute_query(severity_query)
        return [dict(row) for row in results] if results else []

    def _collect_rules_by_type(self):
        """Collect rules by type"""
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
        
        results = self.execute_query(type_query)
        return [dict(row) for row in results] if results else []

    def _collect_personnel_requirements(self):
        """Collect personnel requirements"""
        personnel_query = """
        SELECT 
            COALESCE(personnel_required, 'None specified') as personnel_type,
            COUNT(*) as rule_count
        FROM rule 
        WHERE is_current = TRUE AND is_deleted = FALSE
        GROUP BY personnel_required
        ORDER BY rule_count DESC
        """
        
        results = self.execute_query(personnel_query)
        return [dict(row) for row in results] if results else []

    def _collect_integrity_check(self):
        """Collect integrity check results"""
        orphaned_conditions = self.execute_query("""
            SELECT COUNT(*) as count 
            FROM condition c 
            LEFT JOIN rule r ON c.rule_id = r.rule_id 
            WHERE r.rule_id IS NULL
        """)
        
        orphaned_definitions = self.execute_query("""
            SELECT COUNT(*) as count 
            FROM definition d 
            LEFT JOIN regulation reg ON d.regulation_id = reg.regulation_id 
            WHERE reg.regulation_id IS NULL
        """)
        
        return {
            'orphaned_conditions': orphaned_conditions[0]['count'] if orphaned_conditions else 0,
            'orphaned_definitions': orphaned_definitions[0]['count'] if orphaned_definitions else 0
        }

    def _collect_recent_changes(self):
        """Collect recent changes data"""
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
        
        results = self.execute_query(recent_query)
        return [dict(row) for row in results] if results else []

    def _collect_executive_summary(self):
        """Collect executive summary metrics"""
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
        
        return {
            'total_rules': total_rules[0]['count'] if total_rules else 0,
            'total_regulations': total_regulations[0]['count'] if total_regulations else 0,
            'critical_rules': critical_rules[0]['count'] if critical_rules else 0,
            'incomplete_rules': incomplete_rules[0]['count'] if incomplete_rules else 0,
            'rules_with_conditions': rules_with_conditions[0]['count'] if rules_with_conditions else 0
        }

    def create_severity_chart(self):
        """Create severity distribution chart"""
        if not CHARTS_AVAILABLE:
            return None
            
        severity_data = self.report_data.get('rules_by_severity', [])
        if not severity_data:
            return None
        
        # Prepare data
        labels = []
        sizes = []
        colors_map = {
            'critical': '#FF0000',
            'high': '#FF8C00', 
            'medium': '#FFD700',
            'low': '#90EE90',
            'Unknown': '#D3D3D3'
        }
        chart_colors = []
        
        for item in severity_data:
            labels.append(f"{item['severity_level'].title()}\n({item['rule_count']} rules)")
            sizes.append(item['rule_count'])
            chart_colors.append(colors_map.get(item['severity_level'], '#D3D3D3'))
        
        # Create chart
        fig, ax = plt.subplots(figsize=(10, 6))
        wedges, texts, autotexts = ax.pie(sizes, labels=labels, colors=chart_colors, autopct='%1.1f%%', startangle=90)
        
        ax.set_title('Rules Distribution by Severity Level', fontsize=16, fontweight='bold')
        
        # Save to bytes
        img_buffer = BytesIO()
        plt.savefig(img_buffer, format='png', dpi=300, bbox_inches='tight')
        img_buffer.seek(0)
        plt.close()
        
        return img_buffer

    def generate_pdf_report(self, filename: str = None):
        """Generate comprehensive PDF report"""
        if not PDF_AVAILABLE:
            print("❌ PDF generation not available. Install reportlab: pip install reportlab")
            return False
        
        if not filename:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"osha_database_report_{timestamp}.pdf"
        
        try:
            # Create PDF document
            doc = SimpleDocTemplate(filename, pagesize=A4)
            story = []
            
            # Title page
            story.append(Paragraph("OSHA Database Analysis Report", self.styles['CustomTitle']))
            story.append(Spacer(1, 20))
            
            # Metadata
            metadata = self.report_data.get('metadata', {})
            story.append(Paragraph(f"Generated: {metadata.get('generated_at', 'Unknown')}", self.styles['Normal']))
            story.append(Paragraph(f"Database: {metadata.get('database', 'Unknown')}", self.styles['Normal']))
            story.append(Paragraph(f"Schema: {metadata.get('schema', 'Unknown')}", self.styles['Normal']))
            story.append(Spacer(1, 30))
            
            # Executive Summary
            exec_summary = self.report_data.get('executive_summary', {})
            story.append(Paragraph("Executive Summary", self.styles['CustomHeading']))
            
            summary_data = [
                ['Metric', 'Value'],
                ['Total Active Rules', f"{exec_summary.get('total_rules', 0):,}"],
                ['Total Regulations', f"{exec_summary.get('total_regulations', 0):,}"],
                ['Critical Rules', f"{exec_summary.get('critical_rules', 0):,}"],
                ['Incomplete Rules', f"{exec_summary.get('incomplete_rules', 0):,}"],
                ['Rules with Conditions', f"{exec_summary.get('rules_with_conditions', 0):,}"]
            ]
            
            summary_table = Table(summary_data, colWidths=[3*inch, 2*inch])
            summary_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.darkblue),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, 0), 12),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
                ('GRID', (0, 0), (-1, -1), 1, colors.black)
            ]))
            
            story.append(summary_table)
            story.append(Spacer(1, 20))
            
            # Data quality score
            total_rules = exec_summary.get('total_rules', 0)
            incomplete_rules = exec_summary.get('incomplete_rules', 0)
            quality_score = ((total_rules - incomplete_rules) / total_rules * 100) if total_rules > 0 else 0
            
            story.append(Paragraph(f"Data Quality Score: {quality_score:.1f}%", self.styles['CustomSubheading']))
            
            if quality_score >= 90:
                story.append(Paragraph("✅ Excellent data quality!", self.styles['Normal']))
            elif quality_score >= 75:
                story.append(Paragraph("🟡 Good data quality with room for improvement", self.styles['Normal']))
            else:
                story.append(Paragraph("🔴 Data quality needs attention", self.styles['Normal']))
            
            story.append(PageBreak())
            
            # Basic Statistics
            story.append(Paragraph("Database Overview", self.styles['CustomHeading']))
            
            basic_stats = self.report_data.get('basic_stats', {})
            
            # Remove database_info for the table
            stats_for_table = {k: v for k, v in basic_stats.items() if k != 'database_info'}
            
            stats_data = [['Table', 'Record Count']]
            for table, count in stats_for_table.items():
                stats_data.append([table.replace('_', ' ').title(), f"{count:,}"])
            
            stats_table = Table(stats_data, colWidths=[3*inch, 2*inch])
            stats_table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), colors.darkgreen),
                ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, 0), 12),
                ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                ('BACKGROUND', (0, 1), (-1, -1), colors.lightgrey),
                ('GRID', (0, 0), (-1, -1), 1, colors.black)
            ]))
            
            story.append(stats_table)
            story.append(Spacer(1, 20))
            
            # Database info
            db_info = basic_stats.get('database_info', {})
            if db_info:
                story.append(Paragraph(f"Database Size: {db_info.get('db_size', 'Unknown')}", self.styles['Normal']))
            
            story.append(PageBreak())
            
            # Regulations by Subpart
            story.append(Paragraph("Regulations by Subpart", self.styles['CustomHeading']))
            
            reg_data = self.report_data.get('regulations_by_subpart', [])
            if reg_data:
                reg_table_data = [['Part', 'Subpart', 'Total Rules', 'Critical', 'High', 'Medium', 'Mandatory']]
                
                for reg in reg_data:
                    reg_table_data.append([
                        reg.get('part', ''),
                        reg.get('subpart', ''),
                        f"{reg.get('total_rules', 0):,}",
                        f"{reg.get('critical_rules', 0):,}",
                        f"{reg.get('high_rules', 0):,}",
                        f"{reg.get('medium_rules', 0):,}",
                        f"{reg.get('mandatory_rules', 0):,}"
                    ])
                
                reg_table = Table(reg_table_data, colWidths=[0.8*inch, 0.8*inch, 1*inch, 0.8*inch, 0.8*inch, 0.8*inch, 1*inch])
                reg_table.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (-1, 0), colors.darkblue),
                    ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                    ('FONTSIZE', (0, 0), (-1, 0), 10),
                    ('FONTSIZE', (0, 1), (-1, -1), 9),
                    ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                    ('BACKGROUND', (0, 1), (-1, -1), colors.lightgrey),
                    ('GRID', (0, 0), (-1, -1), 1, colors.black)
                ]))
                
                story.append(reg_table)
            
            story.append(PageBreak())
            
            # Rules by Severity
            story.append(Paragraph("Rules by Severity Level", self.styles['CustomHeading']))
            
            severity_data = self.report_data.get('rules_by_severity', [])
            if severity_data:
                severity_table_data = [['Severity Level', 'Rule Count', 'Percentage']]
                
                for sev in severity_data:
                    severity_table_data.append([
                        sev.get('severity_level', '').title(),
                        f"{sev.get('rule_count', 0):,}",
                        f"{sev.get('percentage', 0):.1f}%"
                    ])
                
                severity_table = Table(severity_table_data, colWidths=[2*inch, 1.5*inch, 1.5*inch])
                severity_table.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (-1, 0), colors.darkred),
                    ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                    ('FONTSIZE', (0, 0), (-1, 0), 12),
                    ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                    ('BACKGROUND', (0, 1), (-1, -1), colors.lightgrey),
                    ('GRID', (0, 0), (-1, -1), 1, colors.black)
                ]))
                
                story.append(severity_table)
            
            story.append(Spacer(1, 20))
            
            # Add severity chart if available
            chart_buffer = self.create_severity_chart()
            if chart_buffer:
                try:
                    # Save chart to temp file
                    chart_filename = f"temp_chart_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png"
                    with open(chart_filename, 'wb') as f:
                        f.write(chart_buffer.getvalue())
                    
                    # Add to PDF
                    chart_img = RLImage(chart_filename, width=5*inch, height=3*inch)
                    story.append(chart_img)
                    
                    # Clean up temp file
                    os.remove(chart_filename)
                    
                except Exception as e:
                    logger.warning(f"Could not add chart to PDF: {e}")
            
            story.append(PageBreak())
            
            # Data Quality Analysis
            story.append(Paragraph("Data Quality Analysis", self.styles['CustomHeading']))
            
            data_quality = self.report_data.get('data_quality', {})
            completeness = data_quality.get('completeness', {})
            
            if completeness:
                total = completeness.get('total_rules', 0)
                
                quality_data = [['Field', 'Count', 'Percentage', 'Status']]
                
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
                    count = completeness.get(field_key, 0)
                    percentage = (count / total * 100) if total > 0 else 0
                    status = "Good" if percentage >= 80 else "Low" if percentage >= 50 else "Poor"
                    quality_data.append([field_name, f"{count:,}", f"{percentage:.1f}%", status])
                
                quality_table = Table(quality_data, colWidths=[2.5*inch, 1*inch, 1*inch, 1*inch])
                quality_table.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (-1, 0), colors.darkorange),
                    ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                    ('FONTSIZE', (0, 0), (-1, 0), 11),
                    ('FONTSIZE', (0, 1), (-1, -1), 9),
                    ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                    ('BACKGROUND', (0, 1), (-1, -1), colors.lightgrey),
                    ('GRID', (0, 0), (-1, -1), 1, colors.black)
                ]))
                
                story.append(quality_table)
            
            story.append(PageBreak())
            
            # Duplicate Analysis
            story.append(Paragraph("Duplicate Analysis", self.styles['CustomHeading']))
            
            duplicate_analysis = self.report_data.get('duplicate_analysis', {})
            duplicate_codes = duplicate_analysis.get('duplicate_codes', [])
            identical_content = duplicate_analysis.get('identical_content', [])
            
            if not duplicate_codes and not identical_content:
                story.append(Paragraph("No duplicate rules found - excellent data quality!", self.styles['Normal']))
            else:
                if duplicate_codes:
                    story.append(Paragraph("Duplicate Rule Codes Found:", self.styles['CustomSubheading']))
                    dup_data = [['Rule Code', 'Duplicate Count']]
                    for dup in duplicate_codes[:10]:  # Limit to top 10
                        dup_data.append([dup['rule_code'], str(dup['duplicate_count'])])
                    
                    dup_table = Table(dup_data, colWidths=[4*inch, 1.5*inch])
                    dup_table.setStyle(TableStyle([
                        ('BACKGROUND', (0, 0), (-1, 0), colors.red),
                        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                        ('GRID', (0, 0), (-1, -1), 1, colors.black)
                    ]))
                    story.append(dup_table)
                
                if identical_content:
                    story.append(Spacer(1, 10))
                    story.append(Paragraph("Identical Content Found:", self.styles['CustomSubheading']))
                    identical_data = [['Hash (First 12)', 'Count', 'Rule Codes']]
                    for ident in identical_content[:5]:  # Limit to top 5
                        hash_short = ident['rule_hash'][:12] + "..."
                        codes_str = ', '.join(ident['rule_codes'][:3])  # First 3 codes
                        if len(ident['rule_codes']) > 3:
                            codes_str += "..."
                        identical_data.append([hash_short, str(ident['duplicate_count']), codes_str])
                    
                    identical_table = Table(identical_data, colWidths=[2*inch, 1*inch, 3*inch])
                    identical_table.setStyle(TableStyle([
                        ('BACKGROUND', (0, 0), (-1, 0), colors.orange),
                        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                        ('GRID', (0, 0), (-1, -1), 1, colors.black)
                    ]))
                    story.append(identical_table)
            
            story.append(PageBreak())
            
            # Personnel Requirements
            story.append(Paragraph("Personnel Requirements", self.styles['CustomHeading']))
            
            personnel_data = self.report_data.get('personnel_requirements', [])
            if personnel_data:
                personnel_table_data = [['Personnel Type', 'Rule Count']]
                
                for person in personnel_data:
                    personnel_table_data.append([
                        person.get('personnel_type', ''),
                        f"{person.get('rule_count', 0):,}"
                    ])
                
                personnel_table = Table(personnel_table_data, colWidths=[4*inch, 1.5*inch])
                personnel_table.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (-1, 0), colors.darkgreen),
                    ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                    ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
                    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                    ('FONTSIZE', (0, 0), (-1, 0), 12),
                    ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                    ('BACKGROUND', (0, 1), (-1, -1), colors.lightgrey),
                    ('GRID', (0, 0), (-1, -1), 1, colors.black)
                ]))
                
                story.append(personnel_table)
            
            story.append(Spacer(1, 20))
            
            # Integrity Check
            story.append(Paragraph("Data Integrity Check", self.styles['CustomHeading']))
            
            integrity = self.report_data.get('integrity_check', {})
            orphaned_conditions = integrity.get('orphaned_conditions', 0)
            orphaned_definitions = integrity.get('orphaned_definitions', 0)
            
            story.append(Paragraph(f"Orphaned Conditions: {orphaned_conditions}", self.styles['Normal']))
            story.append(Paragraph(f"Orphaned Definitions: {orphaned_definitions}", self.styles['Normal']))
            
            if orphaned_conditions == 0 and orphaned_definitions == 0:
                story.append(Paragraph("No orphaned records found - excellent referential integrity!", self.styles['Normal']))
            else:
                story.append(Paragraph("Some orphaned records found - review data loading process", self.styles['Normal']))
            
            story.append(Spacer(1, 20))
            
            # Recent Changes
            story.append(Paragraph("Recent Data Changes", self.styles['CustomHeading']))
            
            recent_changes = self.report_data.get('recent_changes', [])
            if recent_changes:
                changes_data = [['Table', 'Total Records', 'Last 7 Days', 'Last 30 Days', 'Most Recent']]
                
                for change in recent_changes:
                    most_recent = change.get('most_recent')
                    if most_recent:
                        most_recent_str = most_recent.strftime('%Y-%m-%d %H:%M') if hasattr(most_recent, 'strftime') else str(most_recent)
                    else:
                        most_recent_str = 'N/A'
                    
                    changes_data.append([
                        change.get('table_name', ''),
                        f"{change.get('total_records', 0):,}",
                        f"{change.get('last_7_days', 0):,}",
                        f"{change.get('last_30_days', 0):,}",
                        most_recent_str
                    ])
                
                changes_table = Table(changes_data, colWidths=[1.2*inch, 1.2*inch, 1*inch, 1*inch, 1.6*inch])
                changes_table.setStyle(TableStyle([
                    ('BACKGROUND', (0, 0), (-1, 0), colors.purple),
                    ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
                    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
                    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                    ('FONTSIZE', (0, 0), (-1, 0), 10),
                    ('FONTSIZE', (0, 1), (-1, -1), 9),
                    ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
                    ('BACKGROUND', (0, 1), (-1, -1), colors.lightgrey),
                    ('GRID', (0, 0), (-1, -1), 1, colors.black)
                ]))
                
                story.append(changes_table)
            
            # Footer
            story.append(Spacer(1, 40))
            story.append(Paragraph("--- End of Report ---", self.styles['Normal']))
            story.append(Paragraph(f"Generated by OSHA Database Analyzer on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}", self.styles['Normal']))
            
            # Build PDF
            doc.build(story)
            
            print(f"📄 PDF report generated: {filename}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to generate PDF report: {e}")
            return False

    def export_json_report(self, filename: str = None):
        """Export complete analysis to JSON file (fixed version)"""
        if not filename:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"osha_db_analysis_{timestamp}.json"
        
        try:
            # Convert datetime objects to strings for JSON serialization
            def convert_datetime(obj):
                if hasattr(obj, 'isoformat'):
                    return obj.isoformat()
                elif isinstance(obj, dict):
                    return {k: convert_datetime(v) for k, v in obj.items()}
                elif isinstance(obj, list):
                    return [convert_datetime(item) for item in obj]
                else:
                    return obj
            
            json_data = convert_datetime(self.report_data)
            
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(json_data, f, indent=2, ensure_ascii=False)
            
            print(f"📊 JSON report exported: {filename}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to export JSON report: {e}")
            return False

    def print_console_summary(self):
        """Print a brief console summary"""
        print("\n" + "="*80)
        print("                    OSHA DATABASE ANALYSIS SUMMARY")
        print("="*80)
        
        exec_summary = self.report_data.get('executive_summary', {})
        
        print(f"📊 Total Active Rules: {exec_summary.get('total_rules', 0):,}")
        print(f"📋 Total Regulations: {exec_summary.get('total_regulations', 0):,}")
        print(f"🔴 Critical Rules: {exec_summary.get('critical_rules', 0):,}")
        print(f"⚠️  Incomplete Rules: {exec_summary.get('incomplete_rules', 0):,}")
        print(f"🔧 Rules with Conditions: {exec_summary.get('rules_with_conditions', 0):,}")
        
        # Data quality score
        total_rules = exec_summary.get('total_rules', 0)
        incomplete_rules = exec_summary.get('incomplete_rules', 0)
        quality_score = ((total_rules - incomplete_rules) / total_rules * 100) if total_rules > 0 else 0
        
        print(f"\n📈 Data Quality Score: {quality_score:.1f}%")
        
        if quality_score >= 90:
            print("✅ Excellent data quality!")
        elif quality_score >= 75:
            print("🟡 Good data quality with room for improvement")
        else:
            print("🔴 Data quality needs attention")
        
        # Duplicate check
        duplicate_analysis = self.report_data.get('duplicate_analysis', {})
        duplicate_codes = duplicate_analysis.get('duplicate_codes', [])
        identical_content = duplicate_analysis.get('identical_content', [])
        
        if not duplicate_codes and not identical_content:
            print("✅ No duplicate rules found")
        else:
            print(f"⚠️  Found {len(duplicate_codes)} duplicate rule codes and {len(identical_content)} identical content groups")
        
        print("="*80)

    def run_complete_analysis(self, export_pdf: bool = True, export_json: bool = True):
        """Run complete analysis and generate reports"""
        try:
            self.connect()
            
            print("🚀 Starting OSHA Database Analysis...")
            
            # Collect all data
            print("📊 Collecting database statistics...")
            self.collect_all_data()
            
            # Print console summary
            self.print_console_summary()
            
            # Generate PDF report
            if export_pdf:
                print("\n📄 Generating PDF report...")
                if self.generate_pdf_report():
                    print("✅ PDF report generated successfully!")
                else:
                    print("❌ PDF report generation failed")
            
            # Export JSON report
            if export_json:
                print("\n📊 Exporting JSON report...")
                if self.export_json_report():
                    print("✅ JSON report exported successfully!")
                else:
                    print("❌ JSON report export failed")
            
            print("\n🎉 Analysis completed successfully!")
            
        except Exception as e:
            logger.error(f"Analysis failed: {e}")
            raise
        finally:
            self.disconnect()

def install_dependencies():
    """Check and suggest installation of required dependencies"""
    missing_deps = []
    
    if not PDF_AVAILABLE:
        missing_deps.append("reportlab")
    
    if not CHARTS_AVAILABLE:
        missing_deps.append("matplotlib")
    
    if missing_deps:
        print("📦 Missing dependencies for full functionality:")
        print(f"   Install with: pip install {' '.join(missing_deps)}")
        print("\n   Basic analysis will still work, but PDF/chart generation may be limited.")
        return False
    
    return True

def main():
    """Main entry point"""
    print("🎯 OSHA Database PDF Reporter")
    print("=" * 50)
    
    # Check dependencies
    all_deps_available = install_dependencies()
    
    # Parse command line arguments
    export_pdf = '--pdf' in sys.argv or '--all' in sys.argv or len(sys.argv) == 1  # Default to PDF
    export_json = '--json' in sys.argv or '--all' in sys.argv
    
    if '--help' in sys.argv:
        print("\nUsage: python osha_pdf_reporter.py [options]")
        print("Options:")
        print("  --pdf     Generate PDF report (default)")
        print("  --json    Export JSON data")
        print("  --all     Generate both PDF and JSON")
        print("  --help    Show this help message")
        print("\nExamples:")
        print("  python osha_pdf_reporter.py           # PDF only")
        print("  python osha_pdf_reporter.py --json    # JSON only")
        print("  python osha_pdf_reporter.py --all     # Both PDF and JSON")
        return
    
    if not export_pdf and not export_json:
        export_pdf = True  # Default to PDF if nothing specified
    
    try:
        reporter = OSHAPDFReporter(DB_CONFIG)
        reporter.run_complete_analysis(export_pdf=export_pdf, export_json=export_json)
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()


# ===============================
# QUICK START GUIDE
# ===============================
"""
1. Install dependencies:
   pip install reportlab matplotlib psycopg2-binary

2. Run the script:
   python osha_pdf_reporter.py

3. Generated files:
   - osha_database_report_YYYYMMDD_HHMMSS.pdf
   - osha_db_analysis_YYYYMMDD_HHMMSS.json

===============================
SAMPLE USAGE COMMANDS
===============================

# Generate PDF only (default)
python osha_pdf_reporter.py

# Generate JSON only  
python osha_pdf_reporter.py --json

# Generate both PDF and JSON
python osha_pdf_reporter.py --all

# Show help and options
python osha_pdf_reporter.py --help

===============================
EXPECTED OUTPUT
===============================

Console Output:
🎯 OSHA Database PDF Reporter
==================================================
📊 Collecting database statistics...

================================================================================
                    OSHA DATABASE ANALYSIS SUMMARY
================================================================================
📊 Total Active Rules: 525
📋 Total Regulations: 11  
🔴 Critical Rules: 282
⚠️  Incomplete Rules: 0
🔧 Rules with Conditions: 443

📈 Data Quality Score: 100.0%
✅ Excellent data quality!
✅ No duplicate rules found
================================================================================

📄 Generating PDF report...
✅ PDF report generated successfully!

📊 Exporting JSON report...
✅ JSON report exported successfully!

🎉 Analysis completed successfully!

Files Generated:
- osha_database_report_20250630_180900.pdf
- osha_db_analysis_20250630_180900.json

===============================
TROUBLESHOOTING
===============================

If you get import errors:
1. Install missing packages: pip install reportlab matplotlib
2. Ensure database connection is working
3. Check schema name in DB_CONFIG (should be 'osha_rules_v1')

The script will work even without reportlab/matplotlib, 
but PDF generation and charts will be disabled.
"""