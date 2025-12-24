import pyodbc
import random
from datetime import datetime, timedelta
from faker import Faker
from tqdm import tqdm

# Connection details
server = 'rds-prd-tenant-mssql.cm9ok286yrdx.us-east-1.rds.amazonaws.com'
database = 'OSHA_OperationalData'
username = 'admin'
password = 'jMc7LxUrl2z3DGXuTpi1'

conn_str = (
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={server};DATABASE={database};UID={username};PWD={password}"
)

fake = Faker()
conn = pyodbc.connect(conn_str)
cursor = conn.cursor()

# Constants
site_types = ['Upstream', 'Midstream', 'Downstream', 'General Industry']
surface_conditions = ['Dry', 'Wet', 'Oily']
rung_conditions = ['Good', 'Worn', 'Damaged']
surface_types = ['Concrete', 'Metal', 'Wood']
workers = [fake.name() for _ in range(100)]

def random_date():
    return fake.date_time_between(start_date='-1y', end_date='now')

def insert_portable_ladders(batch_size=5000, total=1_000_000):
    print("Loading PortableLadderUsage...")
    for _ in tqdm(range(0, total, batch_size)):
        rows = []
        for _ in range(batch_size):
            serial_number = f"PL{random.randint(100000, 999999)}"
            rows.append((
                fake.company(),
                random.choice(site_types),
                random_date(),
                round(random.uniform(8.0, 15.0), 1),
                round(random.uniform(14.0, 17.0), 1),
                round(random.uniform(10.0, 30.0), 1),
                random.randint(100, 320),
                round(random.uniform(70.0, 80.0), 1),
                random.randint(0, 1),
                random.choice(surface_conditions),
                serial_number,
                datetime.now(),
                datetime.now()
            ))
        cursor.executemany("""
            INSERT INTO dbo.PortableLadderUsage (
                FacilityName, SiteType, UsageDateTime, RungSpacingInches, RungWidthInches,
                LadderHeightFeet, LoadCarriedPounds, SetupAngleDegrees, NearDoorway,
                SurfaceCondition, SerialNumber, CreatedAt, UpdatedAt
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, rows)
        conn.commit()


def insert_fixed_ladders(batch_size=5000, total=1_000_000):
    print("Loading FixedLadderMaintenance...")
    for _ in tqdm(range(0, total, batch_size)):
        rows = []
        for _ in range(batch_size):
            rows.append((
                fake.company(),
                random.choice(site_types),
                random_date(),
                round(random.uniform(10.0, 95.0), 1),
                random.randint(0, 1),
                random.choice(rung_conditions),
                fake.unique.bothify(text='FL###'),
                random.choice(workers),
                datetime.now(),
                datetime.now()
            ))
        cursor.executemany("""
            INSERT INTO SafetyOps.FixedLadderMaintenance (
                FacilityName, SiteType, MaintenanceDateTime, LadderHeightFeet,
                HasFallArrestSystem, RungCondition, SerialNumber, WorkerName,
                CreatedAt, UpdatedAt
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, rows)
        conn.commit()

def insert_scaffold_logs(batch_size=5000, total=1_000_000):
    print("Loading ScaffoldSetupLogs...")
    for _ in tqdm(range(0, total, batch_size)):
        rows = []
        for _ in range(batch_size):
            rows.append((
                fake.company(),
                random.choice(site_types),
                random_date(),
                round(random.uniform(6.0, 46.0), 1),
                random.randint(0, 1),
                random.randint(250, 4500),
                random.choice(surface_types),
                random.choice(workers),
                datetime.now(),
                datetime.now()
            ))
        cursor.executemany("""
            INSERT INTO SafetyOps.ScaffoldSetupLogs (
                FacilityName, SiteType, SetupDateTime, ScaffoldHeightFeet, HasGuardrails,
                LoadCapacityPounds, SurfaceType, WorkerName, CreatedAt, UpdatedAt
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, rows)
        conn.commit()

# Call the loaders (run one by one to avoid overload)
insert_portable_ladders()
insert_fixed_ladders()
insert_scaffold_logs()

cursor.close()
conn.close()
