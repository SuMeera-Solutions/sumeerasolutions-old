
-- Create the database for OSHA operational data
CREATE DATABASE OSHA_OperationalData;
GO

-- Switch to the new database
USE OSHA_OperationalData;
GO

-- Create the SafetyOps schema
CREATE SCHEMA SafetyOps;
GO

-- Create SQL Server logins for Viewer, Tester, and Admin
-- Note: Running as super user (e.g., sa) ensures permission to create logins
CREATE LOGIN Viewer WITH PASSWORD = 'ViewerPass123!', CHECK_EXPIRATION = OFF, CHECK_POLICY = ON;
CREATE LOGIN Tester WITH PASSWORD = 'TesterPass123!', CHECK_EXPIRATION = OFF, CHECK_POLICY = ON;
CREATE LOGIN developer WITH PASSWORD = 'AdminPass123!', CHECK_EXPIRATION = OFF, CHECK_POLICY = ON;
GO

-- Create database users mapped to the logins
CREATE USER Viewer FOR LOGIN Viewer;
CREATE USER Tester FOR LOGIN Tester;
CREATE USER developer FOR LOGIN developer;
GO

-- Assign permissions to users on the SafetyOps schema
-- Viewer: Read-only access (SELECT)
GRANT SELECT ON SCHEMA::SafetyOps TO Viewer;
GO

-- Tester: Read and write access (SELECT, INSERT, UPDATE, DELETE)
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::SafetyOps TO Tester;
GO

-- Admin: Full control on the schema (includes DDL and DML permissions)
GRANT CONTROL ON SCHEMA::SafetyOps TO developer;
GO

-- Ensure users can connect to the database
GRANT CONNECT TO Viewer;
GRANT CONNECT TO Tester;
GRANT CONNECT TO developer;
GO

-- Optional: Example table to demonstrate schema usage
-- You can add the 50 tables from prior artifacts (e.g., PortableLadderUsage) here
CREATE TABLE SafetyOps.SampleTable (
    SampleID INT PRIMARY KEY IDENTITY(1,1),
    Description VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);
GO

-- Placeholder comment for adding the 50 tables
-- Add the CREATE TABLE statements for the 50 tables (e.g., PortableLadderUsage, InjuryIllnessReports) 
-- from artifact IDs 7e09599b-8b34-4e41-aa5e-582e8f5c2338 and 1304a156-0e19-49ad-94f3-3592f9926c78
-- Prefix each table with 'SafetyOps.' (e.g., CREATE TABLE SafetyOps.PortableLadderUsage ...)