import requests
import pandas as pd
import boto3
import psycopg2
import psycopg2.extras
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
import boto3
import os
import sys
import json
import pandas as pd
import psycopg2
from psycopg2.extras import execute_batch
from datetime import datetime
import logging
import sys
from datetime import datetime
import os
from typing import Dict, List, Tuple, Optional

DB_HOST = 'rds-prd-sumeerasolutions-pg.cm9ok286yrdx.us-east-1.rds.amazonaws.com'
DB_NAME = 'sumeera_solutions'
DB_USER = 'postgres'
DB_PASSWORD = 'shAFYJcxFBANORxkTreO'
DB_PORT = '5432'


logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        port=DB_PORT
    )


def load_staging_tables(excel_file_path):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("SELECT companies_data.get_next_load_id()")
        load_id = cursor.fetchone()[0]
        logger.info(f"Generated load_id: {load_id}")

        # -------------------------
        # Load Companies Sheet
        # -------------------------
        df_companies = pd.read_excel(
            excel_file_path,
            sheet_name="Companies_Details"
        )

        df_companies.columns = (
            df_companies.columns
            .str.strip()
            .str.lower()
            .str.replace(" ", "_")
        )

        cursor.execute("TRUNCATE companies_data.stg_companies")

        companies_data = [
            (
                row.get("companyname"),
                row.get("sectorname"),
                row.get("industryname"),
                row.get("region_name"),
                row.get("country_name"),
                row.get("zipcode"),
                load_id
            )
            for _, row in df_companies.iterrows()
        ]

        execute_batch(cursor, """
            INSERT INTO companies_data.stg_companies (
                companyname, sectorname, industryname,
                region_name, country_name, zipcode, staging_load_id
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, companies_data)

        logger.info(f"Inserted {len(companies_data)} company records")

        # -------------------------
        # Load Regulations Sheet
        # -------------------------
        df_regulations = pd.read_excel(
            excel_file_path,
            sheet_name="Companies_to_Regulations"
        )

        df_regulations.columns = (
            df_regulations.columns
            .str.strip()
            .str.lower()
            .str.replace(" ", "_")
        )

        cursor.execute("TRUNCATE companies_data.stg_company_regulations")

        regulations_data = [
            (
                row.get("company_name"),
                row.get("industry_type"),
                row.get("regulatory_body"),
                row.get("level"),
                row.get("regulations_parts"),
                row.get("regulatory_body_short_name"),
                load_id
            )
            for _, row in df_regulations.iterrows()
        ]

        execute_batch(cursor, """
            INSERT INTO companies_data.stg_company_regulations (
                company_name, industry_type, regulatory_body,
                regulatory_level, regulations_parts,
                regulatory_body_short_name, staging_load_id
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, regulations_data)

        logger.info(f"Inserted {len(regulations_data)} regulation records")

        conn.commit()
        return load_id

    except Exception as e:
        conn.rollback()
        logger.error("Error loading staging tables", exc_info=True)
        raise

    finally:
        cursor.close()
        conn.close()

def download_excel_from_s3(bucket_name, s3_key, local_path):
    s3 = boto3.client("s3")

    try:
        s3.download_file(bucket_name, s3_key, local_path)
        logger.info("S3 download successful")
        return True
    except Exception as e:
        logger.error(f"S3 download failed: {str(e)}", exc_info=True)
        return False


# ------------------------------------------------------------------------------
# Execute Merge
# ------------------------------------------------------------------------------
def execute_merge(load_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        logger.info("Merging companies...")
        cursor.execute(
            "CALL companies_data.merge_companies_from_staging(%s)",
            (load_id,)
        )
        conn.commit()

        logger.info("Merging company regulations...")
        cursor.execute(
            "CALL companies_data.merge_company_regulations_from_staging(%s)",
            (load_id,)
        )
        conn.commit()

        logger.info("Merge completed successfully")

    except Exception:
        conn.rollback()
        logger.error("Error during merge", exc_info=True)
        raise

    finally:
        cursor.close()
        conn.close()


def lambda_handler(event, context):
    
    github_url = "https://raw.githubusercontent.com/SuMeera-Solutions/sumeerasolutions-old/main/sumeera/companies/Company_to_Regulations.xlsx"

    # Download
    response = requests.get(github_url)
    response.raise_for_status()

    # Upload to S3
    s3 = boto3.client("s3")
    s3.put_object(
        Bucket="compliease-cfr-processed",
        Key="loaded/Company_to_Regulations_latest.xlsx",
        Body=response.content
    )
    S3_BUCKET_NAME = "compliease-cfr-processed"
    S3_EXCEL_KEY = "loaded/Company_to_Regulations_latest.xlsx"

    excel_file_path = "/tmp/Company_to_Regulations_latest.xlsx"

    try:
        logger.info("Starting ETL process")

        # Download file
        if not download_excel_from_s3(S3_BUCKET_NAME, S3_EXCEL_KEY, excel_file_path):
            logger.error("Failed to download file from S3")
            return {
                "statusCode": 500,
                "body": "S3 download failed"
            }

        load_id = load_staging_tables(excel_file_path)
        execute_merge(load_id)

        logger.info(f"ETL completed successfully. Load ID: {load_id}")

        return {
            "statusCode": 200,
            "body": f"ETL completed successfully. Load ID: {load_id}"
        }

    except Exception:
        logger.error("Lambda execution failed", exc_info=True)
        return {
            "statusCode": 500,
            "body": "Lambda execution failed"
        }
