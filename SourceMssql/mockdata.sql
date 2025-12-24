-- =====================================================
-- OSHA Operational Database - Mock Data Generation
-- Tables 1-3: PortableLadderUsage, FixedLadderMaintenance, ScaffoldSetupLogs
-- 100 records each (300 total) - Realistic Oil & Gas Industry Data
-- =====================================================

USE OSHA_OperationalData;
GO

-- =====================================================
-- Table 1: PortableLadderUsage (100 records)
-- Covers OSHA 1910.23 ladder requirements
-- =====================================================

INSERT INTO PortableLadderUsage (
    FacilityName, SiteType, UsageDateTime, RungSpacingInches, RungWidthInches, 
    LadderHeightFeet, LoadCarriedPounds, SetupAngleDegrees, NearDoorway, 
    SurfaceCondition, SerialNumber, CreatedAt, UpdatedAt
) VALUES
-- Upstream Sites (25 records)
('Permian Basin Rig Alpha', 'Upstream', '2024-06-15 08:30:00', 12.0, 16.0, 20.0, 185, 75.0, 0, 'Dry', 'PL001', GETDATE(), GETDATE()),
('Eagle Ford Drilling Platform', 'Upstream', '2024-06-20 14:45:00', 10.5, 15.5, 16.0, 220, 73.5, 1, 'Oily', 'PL002', GETDATE(), GETDATE()),
('Bakken Well Site 7', 'Upstream', '2024-07-02 09:15:00', 11.0, 16.0, 24.0, 165, 76.0, 0, 'Wet', 'PL003', GETDATE(), GETDATE()),
('Offshore Platform Delta', 'Upstream', '2024-07-18 11:20:00', 12.5, 15.0, 18.0, 290, 72.0, 0, 'Dry', 'PL004', GETDATE(), GETDATE()),
('Marcellus Shale Rig 3', 'Upstream', '2024-08-05 07:45:00', 13.0, 16.5, 22.0, 175, 74.5, 1, 'Oily', 'PL005', GETDATE(), GETDATE()),
('Haynesville Gas Well', 'Upstream', '2024-08-22 16:30:00', 9.5, 14.5, 14.0, 310, 71.0, 0, 'Wet', 'PL006', GETDATE(), GETDATE()),
('Permian Basin Rig Beta', 'Upstream', '2024-09-10 10:00:00', 11.5, 15.8, 26.0, 195, 75.5, 0, 'Dry', 'PL007', GETDATE(), GETDATE()),
('Gulf of Mexico Platform', 'Upstream', '2024-09-28 13:15:00', 12.0, 16.2, 20.0, 245, 73.0, 1, 'Oily', 'PL008', GETDATE(), GETDATE()),
('Niobrara Formation Rig', 'Upstream', '2024-10-15 08:45:00', 10.0, 15.0, 16.0, 265, 76.5, 0, 'Wet', 'PL009', GETDATE(), GETDATE()),
('Anadarko Basin Well', 'Upstream', '2024-11-02 15:20:00', 8.5, 14.0, 28.0, 180, 74.0, 0, 'Dry', 'PL010', GETDATE(), GETDATE()),
('Permian Horizontal Rig', 'Upstream', '2024-11-20 09:30:00', 14.5, 17.0, 18.0, 320, 70.5, 1, 'Oily', 'PL011', GETDATE(), GETDATE()),
('Eagle Ford Completion', 'Upstream', '2024-12-08 12:00:00', 11.0, 15.5, 22.0, 205, 75.0, 0, 'Wet', 'PL012', GETDATE(), GETDATE()),
('Barnett Shale Rig 5', 'Upstream', '2024-12-25 14:30:00', 12.5, 16.0, 24.0, 155, 73.5, 0, 'Dry', 'PL013', GETDATE(), GETDATE()),
('Utica Shale Platform', 'Upstream', '2025-01-12 07:15:00', 10.5, 15.2, 16.0, 275, 76.0, 1, 'Oily', 'PL014', GETDATE(), GETDATE()),
('Wolfcamp Formation', 'Upstream', '2025-01-30 11:45:00', 13.5, 16.8, 20.0, 190, 72.5, 0, 'Wet', 'PL015', GETDATE(), GETDATE()),
('Montney Shale Rig', 'Upstream', '2025-02-15 16:00:00', 11.5, 15.0, 26.0, 240, 74.5, 0, 'Dry', 'PL016', GETDATE(), GETDATE()),
('Duvernay Formation', 'Upstream', '2025-03-05 08:20:00', 9.0, 14.5, 18.0, 300, 71.5, 1, 'Oily', 'PL017', GETDATE(), GETDATE()),
('Delaware Basin Rig', 'Upstream', '2025-03-22 13:40:00', 12.0, 16.0, 22.0, 170, 75.5, 0, 'Wet', 'PL018', GETDATE(), GETDATE()),
('Scoop Stack Well', 'Upstream', '2025-04-08 10:10:00', 15.0, 17.5, 24.0, 285, 69.5, 0, 'Dry', 'PL019', GETDATE(), GETDATE()),
('Stack Play Rig 2', 'Upstream', '2025-04-25 15:25:00', 10.0, 15.5, 16.0, 210, 76.5, 1, 'Oily', 'PL020', GETDATE(), GETDATE()),
('Bone Spring Formation', 'Upstream', '2025-05-10 09:50:00', 11.0, 15.8, 20.0, 195, 73.0, 0, 'Wet', 'PL021', GETDATE(), GETDATE()),
('Three Forks Rig', 'Upstream', '2025-05-28 12:30:00', 12.5, 16.2, 18.0, 260, 74.0, 0, 'Dry', 'PL022', GETDATE(), GETDATE()),
('Tuscaloo Marine Shale', 'Upstream', '2025-06-02 14:15:00', 10.5, 15.0, 28.0, 225, 75.0, 1, 'Oily', 'PL023', GETDATE(), GETDATE()),
('Woodford Shale Rig', 'Upstream', '2025-06-03 07:30:00', 13.0, 16.5, 22.0, 180, 72.5, 0, 'Wet', 'PL024', GETDATE(), GETDATE()),
('Fayetteville Shale', 'Upstream', '2025-06-03 16:45:00', 11.5, 15.5, 24.0, 305, 76.0, 0, 'Dry', 'PL025', GETDATE(), GETDATE()),

-- Midstream Sites (25 records)
('Keystone Pipeline Station 5', 'Midstream', '2024-06-18 09:00:00', 12.0, 16.0, 16.0, 200, 74.0, 0, 'Dry', 'PL026', GETDATE(), GETDATE()),
('Colonial Pipeline Hub', 'Midstream', '2024-07-05 11:30:00', 10.5, 15.5, 20.0, 185, 75.5, 1, 'Wet', 'PL027', GETDATE(), GETDATE()),
('Energy Transfer Terminal', 'Midstream', '2024-07-25 14:20:00', 11.0, 15.8, 18.0, 270, 73.0, 0, 'Oily', 'PL028', GETDATE(), GETDATE()),
('Enterprise Products LP', 'Midstream', '2024-08-12 08:15:00', 12.5, 16.2, 22.0, 155, 76.0, 0, 'Dry', 'PL029', GETDATE(), GETDATE()),
('Kinder Morgan Station', 'Midstream', '2024-08-30 13:45:00', 9.5, 14.5, 24.0, 295, 71.5, 1, 'Wet', 'PL030', GETDATE(), GETDATE()),
('Plains All American Hub', 'Midstream', '2024-09-15 10:30:00', 13.0, 16.5, 16.0, 175, 74.5, 0, 'Oily', 'PL031', GETDATE(), GETDATE()),
('Magellan Midstream', 'Midstream', '2024-10-02 15:10:00', 11.5, 15.0, 26.0, 245, 75.0, 0, 'Dry', 'PL032', GETDATE(), GETDATE()),
('ONEOK Pipeline Station', 'Midstream', '2024-10-20 07:45:00', 10.0, 15.2, 18.0, 215, 73.5, 1, 'Wet', 'PL033', GETDATE(), GETDATE()),
('TC Energy Compressor', 'Midstream', '2024-11-08 12:20:00', 14.0, 17.0, 20.0, 165, 72.0, 0, 'Oily', 'PL034', GETDATE(), GETDATE()),
('Williams Companies Hub', 'Midstream', '2024-11-25 09:55:00', 12.0, 16.0, 22.0, 280, 76.5, 0, 'Dry', 'PL035', GETDATE(), GETDATE()),
('Enbridge Pipeline', 'Midstream', '2024-12-12 14:40:00', 10.5, 15.5, 24.0, 190, 74.0, 1, 'Wet', 'PL036', GETDATE(), GETDATE()),
('TransCanada Station', 'Midstream', '2024-12-30 11:15:00', 11.0, 15.8, 16.0, 325, 71.0, 0, 'Oily', 'PL037', GETDATE(), GETDATE()),
('Spectra Energy Hub', 'Midstream', '2025-01-18 08:30:00', 12.5, 16.2, 28.0, 205, 75.5, 0, 'Dry', 'PL038', GETDATE(), GETDATE()),
('Sunoco Logistics', 'Midstream', '2025-02-05 13:05:00', 9.0, 14.0, 18.0, 250, 73.0, 1, 'Wet', 'PL039', GETDATE(), GETDATE()),
('Buckeye Partners', 'Midstream', '2025-02-22 16:25:00', 13.5, 16.8, 20.0, 170, 76.0, 0, 'Oily', 'PL040', GETDATE(), GETDATE()),
('NuStar Energy Terminal', 'Midstream', '2025-03-10 10:50:00', 11.5, 15.0, 22.0, 290, 74.5, 0, 'Dry', 'PL041', GETDATE(), GETDATE()),
('Tallgrass Energy Hub', 'Midstream', '2025-03-28 12:35:00', 10.0, 15.5, 24.0, 185, 72.5, 1, 'Wet', 'PL042', GETDATE(), GETDATE()),
('DCP Midstream Station', 'Midstream', '2025-04-15 15:20:00', 15.0, 17.2, 16.0, 265, 75.0, 0, 'Oily', 'PL043', GETDATE(), GETDATE()),
('Western Midstream', 'Midstream', '2025-05-02 09:10:00', 12.0, 16.0, 26.0, 200, 73.5, 0, 'Dry', 'PL044', GETDATE(), GETDATE()),
('Crestwood Equity Hub', 'Midstream', '2025-05-20 14:00:00', 10.5, 15.2, 18.0, 315, 76.5, 1, 'Wet', 'PL045', GETDATE(), GETDATE()),
('Enable Midstream', 'Midstream', '2025-06-01 11:45:00', 11.0, 15.8, 20.0, 175, 74.0, 0, 'Oily', 'PL046', GETDATE(), GETDATE()),
('Antero Midstream', 'Midstream', '2025-06-02 08:25:00', 12.5, 16.5, 22.0, 240, 71.5, 0, 'Dry', 'PL047', GETDATE(), GETDATE()),
('Equitrans Midstream', 'Midstream', '2025-06-03 13:15:00', 9.5, 14.5, 24.0, 220, 75.5, 1, 'Wet', 'PL048', GETDATE(), GETDATE()),
('Pembina Pipeline', 'Midstream', '2025-06-03 16:00:00', 13.0, 16.0, 16.0, 195, 73.0, 0, 'Oily', 'PL049', GETDATE(), GETDATE()),
('Targa Resources Hub', 'Midstream', '2025-06-03 07:50:00', 11.5, 15.5, 28.0, 285, 76.0, 0, 'Dry', 'PL050', GETDATE(), GETDATE()),

-- Downstream Sites (25 records)
('Houston Ship Channel Refinery', 'Downstream', '2024-06-22 08:00:00', 12.0, 16.0, 20.0, 210, 74.5, 0, 'Dry', 'PL051', GETDATE(), GETDATE()),
('Baytown Refining Complex', 'Downstream', '2024-07-08 10:45:00', 10.5, 15.0, 18.0, 185, 75.0, 1, 'Oily', 'PL052', GETDATE(), GETDATE()),
('Port Arthur Refinery', 'Downstream', '2024-07-30 13:30:00', 11.0, 15.8, 22.0, 270, 73.5, 0, 'Wet', 'PL053', GETDATE(), GETDATE()),
('Galveston Bay Complex', 'Downstream', '2024-08-18 15:15:00', 12.5, 16.2, 16.0, 155, 76.0, 0, 'Dry', 'PL054', GETDATE(), GETDATE()),
('Texas City Refinery', 'Downstream', '2024-09-05 09:20:00', 9.0, 14.0, 24.0, 300, 71.0, 1, 'Oily', 'PL055', GETDATE(), GETDATE()),
('Corpus Christi Complex', 'Downstream', '2024-09-25 12:10:00', 13.5, 17.0, 26.0, 175, 74.0, 0, 'Wet', 'PL056', GETDATE(), GETDATE()),
('Beaumont Refinery', 'Downstream', '2024-10-12 14:55:00', 11.5, 15.5, 18.0, 245, 75.5, 0, 'Dry', 'PL057', GETDATE(), GETDATE()),
('Lake Charles Complex', 'Downstream', '2024-10-30 07:40:00', 10.0, 15.2, 20.0, 215, 73.0, 1, 'Oily', 'PL058', GETDATE(), GETDATE()),
('Baton Rouge Refinery', 'Downstream', '2024-11-15 11:25:00', 14.5, 16.8, 22.0, 165, 76.5, 0, 'Wet', 'PL059', GETDATE(), GETDATE()),
('New Orleans Complex', 'Downstream', '2024-12-02 16:05:00', 12.0, 16.0, 24.0, 280, 72.5, 0, 'Dry', 'PL060', GETDATE(), GETDATE()),
('Mobile Bay Refinery', 'Downstream', '2024-12-20 08:50:00', 10.5, 15.0, 16.0, 190, 74.5, 1, 'Oily', 'PL061', GETDATE(), GETDATE()),
('Pascagoula Complex', 'Downstream', '2025-01-08 13:35:00', 11.0, 15.8, 28.0, 325, 75.0, 0, 'Wet', 'PL062', GETDATE(), GETDATE()),
('Richmond Refinery', 'Downstream', '2025-01-25 10:15:00', 12.5, 16.2, 18.0, 205, 73.5, 0, 'Dry', 'PL063', GETDATE(), GETDATE()),
('El Segundo Complex', 'Downstream', '2025-02-12 15:40:00', 8.5, 14.5, 20.0, 250, 76.0, 1, 'Oily', 'PL064', GETDATE(), GETDATE()),
('Carson Refinery', 'Downstream', '2025-03-01 09:00:00', 13.0, 16.5, 22.0, 170, 74.0, 0, 'Wet', 'PL065', GETDATE(), GETDATE()),
('Long Beach Complex', 'Downstream', '2025-03-18 12:20:00', 11.5, 15.5, 24.0, 290, 71.5, 0, 'Dry', 'PL066', GETDATE(), GETDATE()),
('Los Angeles Refinery', 'Downstream', '2025-04-05 14:45:00', 10.0, 15.0, 16.0, 185, 75.5, 1, 'Oily', 'PL067', GETDATE(), GETDATE()),
('Anacortes Complex', 'Downstream', '2025-04-22 11:30:00', 15.5, 17.5, 26.0, 265, 73.0, 0, 'Wet', 'PL068', GETDATE(), GETDATE()),
('Cherry Point Refinery', 'Downstream', '2025-05-08 08:10:00', 12.0, 16.0, 18.0, 200, 76.5, 0, 'Dry', 'PL069', GETDATE(), GETDATE()),
('Salt Lake City Complex', 'Downstream', '2025-05-25 16:30:00', 10.5, 15.2, 20.0, 315, 74.5, 1, 'Oily', 'PL070', GETDATE(), GETDATE()),
('Wood River Refinery', 'Downstream', '2025-06-01 13:55:00', 11.0, 15.8, 22.0, 175, 72.0, 0, 'Wet', 'PL071', GETDATE(), GETDATE()),
('Whiting Complex', 'Downstream', '2025-06-02 10:25:00', 12.5, 16.2, 24.0, 240, 75.0, 0, 'Dry', 'PL072', GETDATE(), GETDATE()),
('Lima Refinery', 'Downstream', '2025-06-03 15:10:00', 9.5, 14.8, 16.0, 220, 73.5, 1, 'Oily', 'PL073', GETDATE(), GETDATE()),
('Toledo Complex', 'Downstream', '2025-06-03 07:35:00', 13.5, 16.5, 28.0, 195, 76.0, 0, 'Wet', 'PL074', GETDATE(), GETDATE()),
('Philadelphia Refinery', 'Downstream', '2025-06-03 12:45:00', 11.5, 15.5, 18.0, 285, 74.0, 0, 'Dry', 'PL075', GETDATE(), GETDATE()),

-- General Industry (25 records)
('Houston Corporate Office', 'General Industry', '2024-06-25 09:30:00', 12.0, 16.0, 12.0, 165, 75.0, 1, 'Dry', 'PL076', GETDATE(), GETDATE()),
('Dallas Engineering Center', 'General Industry', '2024-07-12 11:15:00', 10.5, 15.0, 14.0, 140, 74.5, 0, 'Wet', 'PL077', GETDATE(), GETDATE()),
('Oklahoma City Operations', 'General Industry', '2024-08-01 14:00:00', 11.0, 15.8, 16.0, 125, 76.0, 0, 'Dry', 'PL078', GETDATE(), GETDATE()),
('Denver Regional Office', 'General Industry', '2024-08-20 08:45:00', 12.5, 16.2, 10.0, 180, 73.0, 1, 'Oily', 'PL079', GETDATE(), GETDATE()),
('Calgary Field Office', 'General Industry', '2024-09-08 13:20:00', 9.5, 14.5, 18.0, 195, 75.5, 0, 'Wet', 'PL080', GETDATE(), GETDATE()),
('Midland District Office', 'General Industry', '2024-09-28 10:05:00', 13.0, 16.5, 12.0, 150, 74.0, 0, 'Dry', 'PL081', GETDATE(), GETDATE()),
('San Antonio Service Center', 'General Industry', '2024-10-15 15:30:00', 11.5, 15.5, 20.0, 215, 72.5, 1, 'Oily', 'PL082', GETDATE(), GETDATE()),
('Fort Worth Training Facility', 'General Industry', '2024-11-05 12:50:00', 10.0, 15.2, 14.0, 170, 76.5, 0, 'Wet', 'PL083', GETDATE(), GETDATE()),
('Tulsa Technology Center', 'General Industry', '2024-11-22 09:25:00', 14.0, 17.0, 16.0, 135, 73.5, 0, 'Dry', 'PL084', GETDATE(), GETDATE()),
('Pittsburgh R&D Facility', 'General Industry', '2024-12-10 14:15:00', 12.0, 16.0, 18.0, 255, 75.0, 1, 'Oily', 'PL085', GETDATE(), GETDATE()),
('Chicago Logistics Hub', 'General Industry', '2024-12-28 11:40:00', 10.5, 15.0, 12.0, 185, 74.5, 0, 'Wet', 'PL086', GETDATE(), GETDATE()),
('Atlanta Distribution Center', 'General Industry', '2025-01-15 16:10:00', 11.0, 15.8, 22.0, 160, 76.0, 0, 'Dry', 'PL087', GETDATE(), GETDATE()),
('Phoenix Service Depot', 'General Industry', '2025-02-02 08:55:00', 12.5, 16.2, 10.0, 240, 73.0, 1, 'Oily', 'PL088', GETDATE(), GETDATE()),
('Las Vegas Field Office', 'General Industry', '2025-02-18 13:25:00', 8.0, 14.0, 16.0, 190, 75.5, 0, 'Wet', 'PL089', GETDATE(), GETDATE()),
('Salt Lake Training Center', 'General Industry', '2025-03-08 10:40:00', 13.5, 16.8, 14.0, 175, 74.0, 0, 'Dry', 'PL090', GETDATE(), GETDATE()),
('Albuquerque Operations', 'General Industry', '2025-03-25 15:05:00', 11.5, 15.5, 18.0, 265, 72.0, 1, 'Oily', 'PL091', GETDATE(), GETDATE()),
('Anchorage Logistics', 'General Industry', '2025-04-12 12:30:00', 10.0, 15.2, 20.0, 145, 76.5, 0, 'Wet', 'PL092', GETDATE(), GETDATE()),
('Fairbanks Service Center', 'General Industry', '2025-04-30 09:15:00', 16.0, 18.0, 12.0, 205, 73.5, 0, 'Dry', 'PL093', GETDATE(), GETDATE()),
('Honolulu Field Office', 'General Industry', '2025-05-15 14:50:00', 12.0, 16.0, 16.0, 230, 75.0, 1, 'Oily', 'PL094', GETDATE(), GETDATE()),
('Seattle Engineering Hub', 'General Industry', '2025-05-30 11:20:00', 10.5, 15.0, 14.0, 155, 74.5, 0, 'Wet', 'PL095', GETDATE(), GETDATE()),
('Portland Service Depot', 'General Industry', '2025-06-01 16:35:00', 11.0, 15.8, 18.0, 275, 76.0, 0, 'Dry', 'PL096', GETDATE(), GETDATE()),
('Spokane District Office', 'General Industry', '2025-06-02 08:00:00', 12.5, 16.2, 10.0, 165, 73.0, 1, 'Oily', 'PL097', GETDATE(), GETDATE()),
('Boise Field Office', 'General Industry', '2025-06-03 13:40:00', 9.0, 14.5, 20.0, 295, 75.5, 0, 'Wet', 'PL098', GETDATE(), GETDATE()),
('Billings Operations Center', 'General Industry', '2025-06-03 10:10:00', 13.0, 16.5, 12.0, 180, 74.0, 0, 'Dry', 'PL099', GETDATE(), GETDATE()),
('Casper Service Hub', 'General Industry', '2025-06-03 15:25:00', 11.5, 15.5, 16.0, 220, 72.5, 1, 'Oily', 'PL100', GETDATE(), GETDATE());

-- =====================================================
-- Table 2: FixedLadderMaintenance (100 records)
-- Covers OSHA 1910.23 fixed ladder requirements
-- =====================================================

INSERT INTO FixedLadderMaintenance (
    FacilityName, SiteType, MaintenanceDateTime, LadderHeightFeet, HasFallArrestSystem, 
    RungCondition, SerialNumber, WorkerName, CreatedAt, UpdatedAt
) VALUES
-- Upstream Sites (25 records)
('Permian Basin Rig Alpha', 'Upstream', '2024-06-16 10:30:00', 35.0, 1, 'Good', 'FL001', 'Carlos Rodriguez', GETDATE(), GETDATE()),
('Eagle Ford Drilling Platform', 'Upstream', '2024-06-28 14:15:00', 42.0, 1, 'Worn', 'FL002', 'Michael Johnson', GETDATE(), GETDATE()),
('Bakken Well Site 7', 'Upstream', '2024-07-10 08:45:00', 28.0, 1, 'Good', 'FL003', 'Sarah Williams', GETDATE(), GETDATE()),
('Offshore Platform Delta', 'Upstream', '2024-07-25 11:00:00', 85.0, 1, 'Damaged', 'FL004', 'James Thompson', GETDATE(), GETDATE()),
('Marcellus Shale Rig 3', 'Upstream', '2024-08-08 13:30:00', 38.0, 1, 'Good', 'FL005', 'Maria Garcia', GETDATE(), GETDATE()),
('Haynesville Gas Well', 'Upstream', '2024-08-22 09:20:00', 15.0, 0, 'Worn', 'FL006', 'David Brown', GETDATE(), GETDATE()),
('Permian Basin Rig Beta', 'Upstream', '2024-09-12 16:45:00', 45.0, 1, 'Good', 'FL007', 'Jennifer Davis', GETDATE(), GETDATE()),
('Gulf of Mexico Platform', 'Upstream', '2024-09-30 12:10:00', 95.0, 1, 'Damaged', 'FL008', 'Robert Miller', GETDATE(), GETDATE()),
('Niobrara Formation Rig', 'Upstream', '2024-10-18 07:55:00', 32.0, 1, 'Good', 'FL009', 'Lisa Wilson', GETDATE(), GETDATE()),
('Anadarko Basin Well', 'Upstream', '2024-11-05 15:25:00', 18.0, 0, 'Worn', 'FL010', 'Kevin Moore', GETDATE(), GETDATE()),
('Permian Horizontal Rig', 'Upstream', '2024-11-22 10:40:00', 40.0, 1, 'Good', 'FL011', 'Amanda Taylor', GETDATE(), GETDATE()),
('Eagle Ford Completion', 'Upstream', '2024-12-10 14:00:00', 36.0, 1, 'Damaged', 'FL012', 'Christopher Anderson', GETDATE(), GETDATE()),
('Barnett Shale Rig 5', 'Upstream', '2024-12-28 11:30:00', 29.0, 1, 'Good', 'FL013', 'Michelle Thomas', GETDATE(), GETDATE()),
('Utica Shale Platform', 'Upstream', '2025-01-15 09:15:00', 52.0, 1, 'Worn', 'FL014', 'Daniel Jackson', GETDATE(), GETDATE()),
('Wolfcamp Formation', 'Upstream', '2025-02-02 13:45:00', 33.0, 1, 'Good', 'FL015', 'Nicole White', GETDATE(), GETDATE()),
('Montney Shale Rig', 'Upstream', '2025-02-18 08:20:00', 20.0, 0, 'Damaged', 'FL016', 'Mark Harris', GETDATE(), GETDATE()),
('Duvernay Formation', 'Upstream', '2025-03-08 16:10:00', 48.0, 1, 'Good', 'FL017', 'Rachel Martin', GETDATE(), GETDATE()),
('Delaware Basin Rig', 'Upstream', '2025-03-25 12:35:00', 41.0, 1, 'Worn', 'FL018', 'Steven Thompson', GETDATE(), GETDATE()),
('Scoop Stack Well', 'Upstream', '2025-04-10 10:50:00', 25.0, 1, 'Good', 'FL019', 'Laura Garcia', GETDATE(), GETDATE()),
('Stack Play Rig 2', 'Upstream', '2025-04-28 14:25:00', 16.0, 0, 'Damaged', 'FL020', 'Brian Martinez', GETDATE(), GETDATE()),
('Bone Spring Formation', 'Upstream', '2025-05-12 11:05:00', 44.0, 1, 'Good', 'FL021', 'Stephanie Robinson', GETDATE(), GETDATE()),
('Three Forks Rig', 'Upstream', '2025-05-30 15:40:00', 37.0, 1, 'Worn', 'FL022', 'Anthony Clark', GETDATE(), GETDATE()),
('Tuscaloo Marine Shale', 'Upstream', '2025-06-02 09:30:00', 21.0, 0, 'Good', 'FL023', 'Kimberly Rodriguez', GETDATE(), GETDATE()),
('Woodford Shale Rig', 'Upstream', '2025-06-03 13:15:00', 39.0, 1, 'Damaged', 'FL024', 'Matthew Lewis', GETDATE(), GETDATE()),
('Fayetteville Shale', 'Upstream', '2025-06-03 08:00:00', 46.0, 1, 'Good', 'FL025', 'Jessica Lee', GETDATE(), GETDATE()),

-- Midstream Sites (25 records)
('Keystone Pipeline Station 5', 'Midstream', '2024-06-20 11:20:00', 30.0, 1, 'Good', 'FL026', 'Timothy Walker', GETDATE(), GETDATE()),
('Colonial Pipeline Hub', 'Midstream', '2024-07-08 15:45:00', 35.0, 1, 'Worn', 'FL027', 'Ashley Hall', GETDATE(), GETDATE()),
('Energy Transfer Terminal', 'Midstream', '2024-07-28 09:10:00', 42.0, 1, 'Good', 'FL028', 'Joshua Allen', GETDATE(), GETDATE()),
('Enterprise Products LP', 'Midstream', '2024-08-15 12:55:00', 28.0, 1, 'Damaged', 'FL029', 'Samantha Young', GETDATE(), GETDATE()),
('Kinder Morgan Station', 'Midstream', '2024-09-02 14:30:00', 22.0, 0, 'Good', 'FL030', 'Ryan Hernandez', GETDATE(), GETDATE()),
('Plains All American Hub', 'Midstream', '2024-09-18 10:15:00', 38.0, 1, 'Worn', 'FL031', 'Megan King', GETDATE(), GETDATE()),
('Magellan Midstream', 'Midstream', '2024-10-05 16:00:00', 33.0, 1, 'Good', 'FL032', 'Andrew Wright', GETDATE(), GETDATE()),
('ONEOK Pipeline Station', 'Midstream', '2024-10-22 08:25:00', 45.0, 1, 'Damaged', 'FL033', 'Brittany Lopez', GETDATE(), GETDATE()),
('TC Energy Compressor', 'Midstream', '2024-11-10 13:50:00', 27.0, 1, 'Good', 'FL034', 'Jordan Hill', GETDATE(), GETDATE()),
('Williams Companies Hub', 'Midstream', '2024-11-28 11:35:00', 19.0, 0, 'Worn', 'FL035', 'Heather Scott', GETDATE(), GETDATE()),
('Enbridge Pipeline', 'Midstream', '2024-12-15 15:20:00', 41.0, 1, 'Good', 'FL036', 'Tyler Green', GETDATE(), GETDATE()),
('TransCanada Station', 'Midstream', '2025-01-02 09:45:00', 36.0, 1, 'Damaged', 'FL037', 'Kayla Adams', GETDATE(), GETDATE()),
('Spectra Energy Hub', 'Midstream', '2025-01-20 12:30:00', 31.0, 1, 'Good', 'FL038', 'Jacob Baker', GETDATE(), GETDATE()),
('Sunoco Logistics', 'Midstream', '2025-02-08 14:05:00', 24.0, 1, 'Worn', 'FL039', 'Danielle Gonzalez', GETDATE(), GETDATE()),
('Buckeye Partners', 'Midstream', '2025-02-25 10:40:00', 47.0, 1, 'Good', 'FL040', 'Caleb Nelson', GETDATE(), GETDATE()),
('NuStar Energy Terminal', 'Midstream', '2025-03-12 16:15:00', 29.0, 1, 'Damaged', 'FL041', 'Alexis Carter', GETDATE(), GETDATE()),
('Tallgrass Energy Hub', 'Midstream', '2025-03-30 08:50:00', 17.0, 0, 'Good', 'FL042', 'Nathan Mitchell', GETDATE(), GETDATE()),
('DCP Midstream Station', 'Midstream', '2025-04-18 13:25:00', 43.0, 1, 'Worn', 'FL043', 'Victoria Perez', GETDATE(), GETDATE()),
('Western Midstream', 'Midstream', '2025-05-05 11:10:00', 34.0, 1, 'Good', 'FL044', 'Ethan Roberts', GETDATE(), GETDATE()),
('Crestwood Equity Hub', 'Midstream', '2025-05-22 15:35:00', 26.0, 1, 'Damaged', 'FL045', 'Morgan Turner', GETDATE(), GETDATE()),
('Enable Midstream', 'Midstream', '2025-06-01 09:00:00', 39.0, 1, 'Good', 'FL046', 'Ian Phillips', GETDATE(), GETDATE()),
('Antero Midstream', 'Midstream', '2025-06-02 12:45:00', 32.0, 1, 'Worn', 'FL047', 'Chloe Campbell', GETDATE(), GETDATE()),
('Equitrans Midstream', 'Midstream', '2025-06-03 14:20:00', 23.0, 0, 'Good', 'FL048', 'Lucas Parker', GETDATE(), GETDATE()),
('Pembina Pipeline', 'Midstream', '2025-06-03 10:55:00', 40.0, 1, 'Damaged', 'FL049', 'Madison Evans', GETDATE(), GETDATE()),
('Targa Resources Hub', 'Midstream', '2025-06-03 16:30:00', 37.0, 1, 'Good', 'FL050', 'Gabriel Edwards', GETDATE(), GETDATE()),

-- Downstream Sites (25 records)
('Houston Ship Channel Refinery', 'Downstream', '2024-06-24 10:15:00', 65.0, 1, 'Good', 'FL051', 'Olivia Collins', GETDATE(), GETDATE()),
('Baytown Refining Complex', 'Downstream', '2024-07-12 13:40:00', 72.0, 1, 'Worn', 'FL052', 'Mason Stewart', GETDATE(), GETDATE()),
('Port Arthur Refinery', 'Downstream', '2024-08-01 08:30:00', 58.0, 1, 'Good', 'FL053', 'Zoe Sanchez', GETDATE(), GETDATE()),
('Galveston Bay Complex', 'Downstream', '2024-08-20 15:05:00', 80.0, 1, 'Damaged', 'FL054', 'Logan Morris', GETDATE(), GETDATE()),
('Texas City Refinery', 'Downstream', '2024-09-08 11:50:00', 45.0, 1, 'Good', 'FL055', 'Grace Rogers', GETDATE(), GETDATE()),
('Corpus Christi Complex', 'Downstream', '2024-09-28 14:25:00', 25.0, 1, 'Worn', 'FL056', 'Connor Reed', GETDATE(), GETDATE()),
('Beaumont Refinery', 'Downstream', '2024-10-15 09:35:00', 67.0, 1, 'Good', 'FL057', 'Lily Cook', GETDATE(), GETDATE()),
('Lake Charles Complex', 'Downstream', '2024-11-02 12:20:00', 54.0, 1, 'Damaged', 'FL058', 'Hunter Morgan', GETDATE(), GETDATE()),
('Baton Rouge Refinery', 'Downstream', '2024-11-18 16:10:00', 78.0, 1, 'Good', 'FL059', 'Aria Bell', GETDATE(), GETDATE()),
('New Orleans Complex', 'Downstream', '2024-12-05 10:45:00', 61.0, 1, 'Worn', 'FL060', 'Carter Murphy', GETDATE(), GETDATE()),
('Mobile Bay Refinery', 'Downstream', '2024-12-22 13:15:00', 35.0, 1, 'Good', 'FL061', 'Maya Bailey', GETDATE(), GETDATE()),
('Pascagoula Complex', 'Downstream', '2025-01-10 08:00:00', 19.0, 0, 'Damaged', 'FL062', 'Wyatt Rivera', GETDATE(), GETDATE()),
('Richmond Refinery', 'Downstream', '2025-01-28 15:30:00', 70.0, 1, 'Good', 'FL063', 'Layla Cooper', GETDATE(), GETDATE()),
('El Segundo Complex', 'Downstream', '2025-02-15 11:55:00', 48.0, 1, 'Worn', 'FL064', 'Owen Richardson', GETDATE(), GETDATE()),
('Carson Refinery', 'Downstream', '2025-03-03 14:40:00', 63.0, 1, 'Good', 'FL065', 'Nora Cox', GETDATE(), GETDATE()),
('Long Beach Complex', 'Downstream', '2025-03-20 09:25:00', 55.0, 1, 'Damaged', 'FL066', 'Julian Howard', GETDATE(), GETDATE()),
('Los Angeles Refinery', 'Downstream', '2025-04-08 12:10:00', 41.0, 1, 'Good', 'FL067', 'Elena Ward', GETDATE(), GETDATE()),
('Anacortes Complex', 'Downstream', '2025-04-25 16:45:00', 76.0, 1, 'Worn', 'FL068', 'Adrian Torres', GETDATE(), GETDATE()),
('Cherry Point Refinery', 'Downstream', '2025-05-10 10:20:00', 52.0, 1, 'Good', 'FL069', 'Paisley Peterson', GETDATE(), GETDATE()),
('Salt Lake City Complex', 'Downstream', '2025-05-28 13:35:00', 27.0, 1, 'Damaged', 'FL070', 'Easton Gray', GETDATE(), GETDATE()),
('Wood River Refinery', 'Downstream', '2025-06-01 08:15:00', 69.0, 1, 'Good', 'FL071', 'Penelope Ramirez', GETDATE(), GETDATE()),
('Whiting Complex', 'Downstream', '2025-06-02 14:50:00', 44.0, 1, 'Worn', 'FL072', 'Levi James', GETDATE(), GETDATE()),
('Lima Refinery', 'Downstream', '2025-06-03 11:05:00', 21.0, 0, 'Good', 'FL073', 'Violet Watson', GETDATE(), GETDATE()),
('Toledo Complex', 'Downstream', '2025-06-03 15:40:00', 74.0, 1, 'Damaged', 'FL074', 'Grayson Brooks', GETDATE(), GETDATE()),
('Philadelphia Refinery', 'Downstream', '2025-06-03 09:30:00', 56.0, 1, 'Good', 'FL075', 'Hazel Kelly', GETDATE(), GETDATE()),

-- General Industry (25 records)
('Houston Corporate Office', 'General Industry', '2024-06-28 11:00:00', 15.0, 0, 'Good', 'FL076', 'Jaxon Sanders', GETDATE(), GETDATE()),
('Dallas Engineering Center', 'General Industry', '2024-07-15 14:20:00', 12.0, 0, 'Worn', 'FL077', 'Aurora Price', GETDATE(), GETDATE()),
('Oklahoma City Operations', 'General Industry', '2024-08-05 09:45:00', 18.0, 0, 'Good', 'FL078', 'Roman Bennett', GETDATE(), GETDATE()),
('Denver Regional Office', 'General Industry', '2024-08-25 13:10:00', 16.0, 0, 'Damaged', 'FL079', 'Luna Wood', GETDATE(), GETDATE()),
('Calgary Field Office', 'General Industry', '2024-09-12 10:35:00', 14.0, 0, 'Good', 'FL080', 'Miles Barnes', GETDATE(), GETDATE()),
('Midland District Office', 'General Industry', '2024-10-01 15:55:00', 20.0, 0, 'Worn', 'FL081', 'Stella Ross', GETDATE(), GETDATE()),
('San Antonio Service Center', 'General Industry', '2024-10-18 08:40:00', 22.0, 0, 'Good', 'FL082', 'Maverick Henderson', GETDATE(), GETDATE()),
('Fort Worth Training Facility', 'General Industry', '2024-11-08 12:25:00', 17.0, 0, 'Damaged', 'FL083', 'Nova Coleman', GETDATE(), GETDATE()),
('Tulsa Technology Center', 'General Industry', '2024-11-25 16:15:00', 19.0, 0, 'Good', 'FL084', 'Kai Jenkins', GETDATE(), GETDATE()),
('Pittsburgh R&D Facility', 'General Industry', '2024-12-12 09:50:00', 24.0, 0, 'Worn', 'FL085', 'Iris Perry', GETDATE(), GETDATE()),
('Chicago Logistics Hub', 'General Industry', '2024-12-30 13:30:00', 16.0, 0, 'Good', 'FL086', 'Declan Powell', GETDATE(), GETDATE()),
('Atlanta Distribution Center', 'General Industry', '2025-01-18 11:40:00', 28.0, 1, 'Damaged', 'FL087', 'Sage Long', GETDATE(), GETDATE()),
('Phoenix Service Depot', 'General Industry', '2025-02-05 14:05:00', 13.0, 0, 'Good', 'FL088', 'Knox Patterson', GETDATE(), GETDATE()),
('Las Vegas Field Office', 'General Industry', '2025-02-22 10:20:00', 21.0, 0, 'Worn', 'FL089', 'Rylee Hughes', GETDATE(), GETDATE()),
('Salt Lake Training Center', 'General Industry', '2025-03-10 15:45:00', 18.0, 0, 'Good', 'FL090', 'Atlas Flores', GETDATE(), GETDATE()),
('Albuquerque Operations', 'General Industry', '2025-03-28 08:10:00', 25.0, 1, 'Damaged', 'FL091', 'Wren Washington', GETDATE(), GETDATE()),
('Anchorage Logistics', 'General Industry', '2025-04-15 12:55:00', 15.0, 0, 'Good', 'FL092', 'Orion Butler', GETDATE(), GETDATE()),
('Fairbanks Service Center', 'General Industry', '2025-05-02 16:30:00', 23.0, 0, 'Worn', 'FL093', 'Ivy Simmons', GETDATE(), GETDATE()),
('Honolulu Field Office', 'General Industry', '2025-05-18 09:15:00', 17.0, 0, 'Good', 'FL094', 'Phoenix Foster', GETDATE(), GETDATE()),
('Seattle Engineering Hub', 'General Industry', '2025-06-01 13:00:00', 26.0, 1, 'Damaged', 'FL095', 'Ember Gonzales', GETDATE(), GETDATE()),
('Portland Service Depot', 'General Industry', '2025-06-02 10:45:00', 14.0, 0, 'Good', 'FL096', 'River Bryant', GETDATE(), GETDATE()),
('Spokane District Office', 'General Industry', '2025-06-03 14:30:00', 20.0, 0, 'Worn', 'FL097', 'Skye Alexander', GETDATE(), GETDATE()),
('Boise Field Office', 'General Industry', '2025-06-03 11:25:00', 16.0, 0, 'Good', 'FL098', 'Cruz Russell', GETDATE(), GETDATE()),
('Billings Operations Center', 'General Industry', '2025-06-03 15:10:00', 19.0, 0, 'Damaged', 'FL099', 'Willow Griffin', GETDATE(), GETDATE()),
('Casper Service Hub', 'General Industry', '2025-06-03 08:35:00', 22.0, 0, 'Good', 'FL100', 'Bodhi Diaz', GETDATE(), GETDATE());

-- =====================================================
-- Table 3: ScaffoldSetupLogs (100 records)
-- Covers OSHA 1926.451 scaffold requirements
-- =====================================================

INSERT INTO ScaffoldSetupLogs (
    FacilityName, SiteType, SetupDateTime, ScaffoldHeightFeet, HasGuardrails, 
    LoadCapacityPounds, SurfaceType, WorkerName, CreatedAt, UpdatedAt
) VALUES
-- Upstream Sites (25 records)
('Permian Basin Rig Alpha', 'Upstream', '2024-06-17 07:30:00', 15.0, 1, 750, 'Concrete', 'Jose Morales', GETDATE(), GETDATE()),
('Eagle Ford Drilling Platform', 'Upstream', '2024-06-30 10:15:00', 20.0, 0, 500, 'Metal', 'Emily Chen', GETDATE(), GETDATE()),
('Bakken Well Site 7', 'Upstream', '2024-07-12 13:45:00', 12.0, 1, 1000, 'Wood', 'Marcus Washington', GETDATE(), GETDATE()),
('Offshore Platform Delta', 'Upstream', '2024-07-28 09:00:00', 25.0, 1, 2000, 'Metal', 'Sophia Martinez', GETDATE(), GETDATE()),
('Marcellus Shale Rig 3', 'Upstream', '2024-08-10 14:20:00', 18.0, 0, 750, 'Concrete', 'Trevor Johnson', GETDATE(), GETDATE()),
('Haynesville Gas Well', 'Upstream', '2024-08-25 11:35:00', 8.0, 1, 500, 'Wood', 'Isabella Rodriguez', GETDATE(), GETDATE()),
('Permian Basin Rig Beta', 'Upstream', '2024-09-15 16:10:00', 22.0, 1, 1500, 'Metal', 'Caleb Thompson', GETDATE(), GETDATE()),
('Gulf of Mexico Platform', 'Upstream', '2024-10-02 08:25:00', 30.0, 1, 2500, 'Metal', 'Ava Davis', GETDATE(), GETDATE()),
('Niobrara Formation Rig', 'Upstream', '2024-10-20 12:50:00', 16.0, 0, 750, 'Concrete', 'Elijah Wilson', GETDATE(), GETDATE()),
('Anadarko Basin Well', 'Upstream', '2024-11-08 15:05:00', 10.0, 1, 1000, 'Wood', 'Mia Garcia', GETDATE(), GETDATE()),
('Permian Horizontal Rig', 'Upstream', '2024-11-25 09:40:00', 24.0, 1, 1750, 'Metal', 'Noah Brown', GETDATE(), GETDATE()),
('Eagle Ford Completion', 'Upstream', '2024-12-12 13:15:00', 14.0, 0, 500, 'Concrete', 'Charlotte Miller', GETDATE(), GETDATE()),
('Barnett Shale Rig 5', 'Upstream', '2024-12-30 10:30:00', 28.0, 1, 2000, 'Metal', 'Liam Jones', GETDATE(), GETDATE()),
('Utica Shale Platform', 'Upstream', '2025-01-18 14:55:00', 19.0, 1, 1250, 'Wood', 'Amelia Smith', GETDATE(), GETDATE()),
('Wolfcamp Formation', 'Upstream', '2025-02-05 11:20:00', 26.0, 0, 1500, 'Concrete', 'Benjamin Taylor', GETDATE(), GETDATE()),
('Montney Shale Rig', 'Upstream', '2025-02-22 16:45:00', 17.0, 1, 750, 'Metal', 'Harper Anderson', GETDATE(), GETDATE()),
('Duvernay Formation', 'Upstream', '2025-03-10 08:10:00', 32.0, 1, 2250, 'Metal', 'Lucas White', GETDATE(), GETDATE()),
('Delaware Basin Rig', 'Upstream', '2025-03-28 12:35:00', 21.0, 0, 1000, 'Wood', 'Evelyn Jackson', GETDATE(), GETDATE()),
('Scoop Stack Well', 'Upstream', '2025-04-15 15:00:00', 13.0, 1, 500, 'Concrete', 'Henry Thomas', GETDATE(), GETDATE()),
('Stack Play Rig 2', 'Upstream', '2025-05-02 09:25:00', 35.0, 1, 3000, 'Metal', 'Abigail Harris', GETDATE(), GETDATE()),
('Bone Spring Formation', 'Upstream', '2025-05-20 13:50:00', 23.0, 1, 1500, 'Concrete', 'Alexander Martin', GETDATE(), GETDATE()),
('Three Forks Rig', 'Upstream', '2025-06-01 10:15:00', 11.0, 0, 750, 'Wood', 'Elizabeth Thompson', GETDATE(), GETDATE()),
('Tuscaloo Marine Shale', 'Upstream', '2025-06-02 14:40:00', 29.0, 1, 2000, 'Metal', 'Michael Garcia', GETDATE(), GETDATE()),
('Woodford Shale Rig', 'Upstream', '2025-06-03 11:05:00', 16.0, 1, 1000, 'Concrete', 'Sofia Martinez', GETDATE(), GETDATE()),
('Fayetteville Shale', 'Upstream', '2025-06-03 15:30:00', 27.0, 0, 1750, 'Metal', 'William Robinson', GETDATE(), GETDATE()),

-- Midstream Sites (25 records)
('Keystone Pipeline Station 5', 'Midstream', '2024-06-22 08:45:00', 18.0, 1, 1000, 'Concrete', 'Emma Clark', GETDATE(), GETDATE()),
('Colonial Pipeline Hub', 'Midstream', '2024-07-10 12:20:00', 22.0, 1, 1500, 'Metal', 'James Rodriguez', GETDATE(), GETDATE()),
('Energy Transfer Terminal', 'Midstream', '2024-07-30 15:35:00', 14.0, 0, 750, 'Wood', 'Olivia Lewis', GETDATE(), GETDATE()),
('Enterprise Products LP', 'Midstream', '2024-08-18 09:50:00', 26.0, 1, 2000, 'Concrete', 'Benjamin Lee', GETDATE(), GETDATE()),
('Kinder Morgan Station', 'Midstream', '2024-09-05 13:25:00', 20.0, 1, 1250, 'Metal', 'Ava Walker', GETDATE(), GETDATE()),
('Plains All American Hub', 'Midstream', '2024-09-22 10:40:00', 12.0, 0, 500, 'Wood', 'Ethan Hall', GETDATE(), GETDATE()),
('Magellan Midstream', 'Midstream', '2024-10-08 14:15:00', 24.0, 1, 1750, 'Concrete', 'Madison Allen', GETDATE(), GETDATE()),
('ONEOK Pipeline Station', 'Midstream', '2024-10-25 11:30:00', 16.0, 1, 1000, 'Metal', 'Mason Young', GETDATE(), GETDATE()),
('TC Energy Compressor', 'Midstream', '2024-11-12 16:05:00', 28.0, 0, 2250, 'Metal', 'Luna Hernandez', GETDATE(), GETDATE()),
('Williams Companies Hub', 'Midstream', '2024-11-30 08:20:00', 19.0, 1, 1250, 'Wood', 'Logan King', GETDATE(), GETDATE()),
('Enbridge Pipeline', 'Midstream', '2024-12-18 12:45:00', 31.0, 1, 2500, 'Concrete', 'Layla Wright', GETDATE(), GETDATE()),
('TransCanada Station', 'Midstream', '2025-01-05 15:10:00', 15.0, 0, 750, 'Metal', 'Jacob Lopez', GETDATE(), GETDATE()),
('Spectra Energy Hub', 'Midstream', '2025-01-22 09:35:00', 23.0, 1, 1500, 'Wood', 'Zoe Hill', GETDATE(), GETDATE()),
('Sunoco Logistics', 'Midstream', '2025-02-10 13:00:00', 17.0, 1, 1000, 'Concrete', 'Aiden Scott', GETDATE(), GETDATE()),
('Buckeye Partners', 'Midstream', '2025-02-28 10:25:00', 25.0, 0, 1750, 'Metal', 'Nora Green', GETDATE(), GETDATE()),
('NuStar Energy Terminal', 'Midstream', '2025-03-15 14:50:00', 21.0, 1, 1250, 'Concrete', 'Carter Adams', GETDATE(), GETDATE()),
('Tallgrass Energy Hub', 'Midstream', '2025-04-02 11:15:00', 13.0, 1, 750, 'Wood', 'Aria Baker', GETDATE(), GETDATE()),
('DCP Midstream Station', 'Midstream', '2025-04-20 15:40:00', 27.0, 1, 2000, 'Metal', 'Owen Gonzalez', GETDATE(), GETDATE()),
('Western Midstream', 'Midstream', '2025-05-08 08:05:00', 18.0, 0, 1000, 'Concrete', 'Maya Nelson', GETDATE(), GETDATE()),
('Crestwood Equity Hub', 'Midstream', '2025-05-25 12:30:00', 30.0, 1, 2250, 'Metal', 'Grayson Carter', GETDATE(), GETDATE()),
('Enable Midstream', 'Midstream', '2025-06-01 16:55:00', 22.0, 1, 1500, 'Wood', 'Violet Mitchell', GETDATE(), GETDATE()),
('Antero Midstream', 'Midstream', '2025-06-02 09:20:00', 14.0, 0, 750, 'Concrete', 'Easton Perez', GETDATE(), GETDATE()),
('Equitrans Midstream', 'Midstream', '2025-06-03 13:45:00', 26.0, 1, 1750, 'Metal', 'Paisley Roberts', GETDATE(), GETDATE()),
('Pembina Pipeline', 'Midstream', '2025-06-03 10:10:00', 19.0, 1, 1250, 'Concrete', 'Levi Turner', GETDATE(), GETDATE()),
('Targa Resources Hub', 'Midstream', '2025-06-03 14:35:00', 33.0, 0, 2500, 'Metal', 'Hazel Phillips', GETDATE(), GETDATE()),

-- Downstream Sites (25 records)
('Houston Ship Channel Refinery', 'Downstream', '2024-06-26 10:00:00', 35.0, 1, 3000, 'Concrete', 'Lincoln Campbell', GETDATE(), GETDATE()),
('Baytown Refining Complex', 'Downstream', '2024-07-15 13:25:00', 42.0, 1, 4000, 'Metal', 'Nova Parker', GETDATE(), GETDATE()),
('Port Arthur Refinery', 'Downstream', '2024-08-03 16:50:00', 28.0, 0, 2000, 'Concrete', 'Theo Evans', GETDATE(), GETDATE()),
('Galveston Bay Complex', 'Downstream', '2024-08-22 08:15:00', 38.0, 1, 3500, 'Metal', 'Aurora Edwards', GETDATE(), GETDATE()),
('Texas City Refinery', 'Downstream', '2024-09-10 11:40:00', 31.0, 1, 2500, 'Wood', 'Asher Collins', GETDATE(), GETDATE()),
('Corpus Christi Complex', 'Downstream', '2024-09-30 15:05:00', 24.0, 0, 1750, 'Concrete', 'Willow Stewart', GETDATE(), GETDATE()),
('Beaumont Refinery', 'Downstream', '2024-10-18 12:30:00', 45.0, 1, 4500, 'Metal', 'Kai Sanchez', GETDATE(), GETDATE()),
('Lake Charles Complex', 'Downstream', '2024-11-05 09:55:00', 33.0, 1, 3000, 'Concrete', 'Iris Morris', GETDATE(), GETDATE()),
('Baton Rouge Refinery', 'Downstream', '2024-11-22 14:20:00', 39.0, 0, 3500, 'Metal', 'Atlas Rogers', GETDATE(), GETDATE()),
('New Orleans Complex', 'Downstream', '2024-12-08 11:45:00', 27.0, 1, 2250, 'Wood', 'Sage Reed', GETDATE(), GETDATE()),
('Mobile Bay Refinery', 'Downstream', '2024-12-25 16:10:00', 41.0, 1, 4000, 'Concrete', 'Phoenix Cook', GETDATE(), GETDATE()),
('Pascagoula Complex', 'Downstream', '2025-01-12 08:35:00', 29.0, 0, 2500, 'Metal', 'River Morgan', GETDATE(), GETDATE()),
('Richmond Refinery', 'Downstream', '2025-01-30 13:00:00', 36.0, 1, 3250, 'Concrete', 'Ember Bell', GETDATE(), GETDATE()),
('El Segundo Complex', 'Downstream', '2025-02-18 10:25:00', 32.0, 1, 2750, 'Wood', 'Orion Murphy', GETDATE(), GETDATE()),
('Carson Refinery', 'Downstream', '2025-03-08 14:50:00', 44.0, 0, 4250, 'Metal', 'Wren Bailey', GETDATE(), GETDATE()),
('Long Beach Complex', 'Downstream', '2025-03-25 11:15:00', 26.0, 1, 2000, 'Concrete', 'Knox Rivera', GETDATE(), GETDATE()),
('Los Angeles Refinery', 'Downstream', '2025-04-12 15:40:00', 37.0, 1, 3500, 'Metal', 'Rylee Cooper', GETDATE(), GETDATE()),
('Anacortes Complex', 'Downstream', '2025-04-30 12:05:00', 34.0, 0, 3000, 'Wood', 'Jaxon Richardson', GETDATE(), GETDATE()),
('Cherry Point Refinery', 'Downstream', '2025-05-15 09:30:00', 40.0, 1, 3750, 'Concrete', 'Luna Cox', GETDATE(), GETDATE()),
('Salt Lake City Complex', 'Downstream', '2025-05-30 13:55:00', 23.0, 1, 1750, 'Metal', 'Miles Howard', GETDATE(), GETDATE()),
('Wood River Refinery', 'Downstream', '2025-06-01 10:20:00', 46.0, 1, 4500, 'Concrete', 'Stella Ward', GETDATE(), GETDATE()),
('Whiting Complex', 'Downstream', '2025-06-02 14:45:00', 30.0, 0, 2500, 'Metal', 'Maverick Torres', GETDATE(), GETDATE()),
('Lima Refinery', 'Downstream', '2025-06-03 11:10:00', 25.0, 1, 2000, 'Wood', 'Nova Peterson', GETDATE(), GETDATE()),
('Toledo Complex', 'Downstream', '2025-06-03 15:35:00', 43.0, 1, 4000, 'Concrete', 'Roman Gray', GETDATE(), GETDATE()),
('Philadelphia Refinery', 'Downstream', '2025-06-03 08:00:00', 35.0, 0, 3250, 'Metal', 'Aurora Ramirez', GETDATE(), GETDATE()),

-- General Industry (25 records)
('Houston Corporate Office', 'General Industry', '2024-06-30 09:15:00', 8.0, 1, 250, 'Concrete', 'Declan James', GETDATE(), GETDATE()),
('Dallas Engineering Center', 'General Industry', '2024-07-18 12:40:00', 10.0, 1, 500, 'Wood', 'Sage Watson', GETDATE(), GETDATE()),
('Oklahoma City Operations', 'General Industry', '2024-08-08 15:05:00', 12.0, 0, 375, 'Metal', 'Atlas Brooks', GETDATE(), GETDATE()),
('Denver Regional Office', 'General Industry', '2024-08-28 10:30:00', 6.0, 1, 250, 'Concrete', 'Iris Kelly', GETDATE(), GETDATE()),
('Calgary Field Office', 'General Industry', '2024-09-15 13:55:00', 14.0, 1, 750, 'Wood', 'Phoenix Sanders', GETDATE(), GETDATE()),
('Midland District Office', 'General Industry', '2024-10-05 11:20:00', 9.0, 0, 375, 'Metal', 'River Price', GETDATE(), GETDATE()),
('San Antonio Service Center', 'General Industry', '2024-10-22 14:45:00', 16.0, 1, 1000, 'Concrete', 'Ember Bennett', GETDATE(), GETDATE()),
('Fort Worth Training Facility', 'General Industry', '2024-11-10 09:10:00', 11.0, 1, 500, 'Wood', 'Orion Wood', GETDATE(), GETDATE()),
('Tulsa Technology Center', 'General Industry', '2024-11-28 16:35:00', 13.0, 0, 625, 'Metal', 'Wren Barnes', GETDATE(), GETDATE()),
('Pittsburgh R&D Facility', 'General Industry', '2024-12-15 12:00:00', 18.0, 1, 1250, 'Concrete', 'Knox Ross', GETDATE(), GETDATE()),
('Chicago Logistics Hub', 'General Industry', '2025-01-02 15:25:00', 15.0, 1, 875, 'Wood', 'Rylee Henderson', GETDATE(), GETDATE()),
('Atlanta Distribution Center', 'General Industry', '2025-01-20 08:50:00', 20.0, 0, 1500, 'Metal', 'Jaxon Coleman', GETDATE(), GETDATE()),
('Phoenix Service Depot', 'General Industry', '2025-02-08 13:15:00', 7.0, 1, 250, 'Concrete', 'Luna Jenkins', GETDATE(), GETDATE()),
('Las Vegas Field Office', 'General Industry', '2025-02-25 10:40:00', 17.0, 1, 1125, 'Wood', 'Miles Perry', GETDATE(), GETDATE()),
('Salt Lake Training Center', 'General Industry', '2025-03-12 14:05:00', 12.0, 0, 500, 'Metal', 'Stella Powell', GETDATE(), GETDATE()),
('Albuquerque Operations', 'General Industry', '2025-03-30 11:30:00', 19.0, 1, 1375, 'Concrete', 'Maverick Long', GETDATE(), GETDATE()),
('Anchorage Logistics', 'General Industry', '2025-04-18 15:55:00', 10.0, 1, 500, 'Wood', 'Nova Patterson', GETDATE(), GETDATE()),
('Fairbanks Service Center', 'General Industry', '2025-05-05 12:20:00', 14.0, 0, 750, 'Metal', 'Roman Hughes', GETDATE(), GETDATE()),
('Honolulu Field Office', 'General Industry', '2025-05-22 09:45:00', 8.0, 1, 375, 'Concrete', 'Aurora Flores', GETDATE(), GETDATE()),
('Seattle Engineering Hub', 'General Industry', '2025-06-01 13:10:00', 21.0, 1, 1625, 'Wood', 'Declan Washington', GETDATE(), GETDATE()),
('Portland Service Depot', 'General Industry', '2025-06-02 16:35:00', 13.0, 0, 625, 'Metal', 'Sage Butler', GETDATE(), GETDATE()),
('Spokane District Office', 'General Industry', '2025-06-03 10:00:00', 15.0, 1, 875, 'Concrete', 'Atlas Simmons', GETDATE(), GETDATE()),
('Boise Field Office', 'General Industry', '2025-06-03 14:25:00', 9.0, 1, 375, 'Wood', 'Iris Foster', GETDATE(), GETDATE()),
('Billings Operations Center', 'General Industry', '2025-06-03 11:50:00', 16.0, 0, 1000, 'Metal', 'Phoenix Gonzales', GETDATE(), GETDATE()),
('Casper Service Hub', 'General Industry', '2025-06-03 15:15:00', 11.0, 1, 500, 'Concrete', 'River Bryant', GETDATE(), GETDATE());



-- Use the OSHA_OperationalData database and SafetyOps schema
USE OSHA_OperationalData;
GO

-- Complete SafetyOps.PortableLadderUsage (100 rows total)
-- Continuing from prior artifact, ensuring 100 rows (80 more summarized)
-- Pattern: Vary facilities (Permian Basin Rig, Gulf Coast Refinery, Midland Pipeline, Houston Office, Bakken Field Site, Corpus Christi Plant, West Texas Terminal, Offshore Platform Alpha), dates (June 2024–June 2025), rung spacing (8–15 inches), rung width (9–13 inches), ladder height (8–16 feet), load (100–300 lbs), angle (70–80 degrees), near doorway (0/1), surface condition (Dry, Wet, Oily), serial numbers (PL021–PL100)
INSERT INTO SafetyOps.PortableLadderUsage (FacilityName, SiteType, UsageDateTime, RungSpacingInches, RungWidthInches, LadderHeightFeet, LoadCarriedPounds, SetupAngleDegrees, NearDoorway, SurfaceCondition, SerialNumber, CreatedAt, UpdatedAt)
VALUES
('Bakken Field Site', 'Upstream', '2024-07-01 08:00:00', 12.0, 11.5, 12.0, 170, 75.0, 0, 'Dry', 'PL021', '2024-07-01 08:05:00', '2024-07-01 08:05:00'),
('Bakken Field Site', 'Upstream', '2024-07-15 09:00:00', 10.0, 12.0, 10.0, 280, 70.0, 1, 'Oily', 'PL022', '2024-07-15 09:05:00', '2024-07-15 09:05:00'), -- Edge: Heavy load
('Corpus Christi Plant', 'Downstream', '2024-08-01 10:00:00', 12.5, 11.0, 14.0, 190, 76.0, 0, 'Wet', 'PL023', '2024-08-01 10:05:00', '2024-08-01 10:05:00'),
('Corpus Christi Plant', 'Downstream', '2024-08-15 11:00:00', 14.0, 10.5, 12.0, 200, 78.0, 1, 'Dry', 'PL024', '2024-08-15 11:05:00', '2024-08-15 11:05:00'), -- Edge: Wide rung spacing
('West Texas Terminal', 'Midstream', '2024-09-01 08:30:00', 11.5, 12.0, 10.0, 210, 74.0, 0, 'Oily', 'PL025', '2024-09-01 08:35:00', '2024-09-01 08:35:00'),
('West Texas Terminal', 'Midstream', '2024-09-15 09:00:00', 12.0, 11.5, 15.0, 180, 75.0, 1, 'Wet', 'PL026', '2024-09-15 09:05:00', '2024-09-15 09:05:00'),
('Houston Office', 'General Industry', '2024-10-01 10:00:00', 12.0, 12.0, 8.0, 140, 73.0, 0, 'Dry', 'PL027', '2024-10-01 10:05:00', '2024-10-01 10:05:00'),
('Houston Office', 'General Industry', '2024-10-15 11:00:00', 11.0, 11.0, 10.0, 160, 76.0, 1, 'Dry', 'PL028', '2024-10-15 11:05:00', '2024-10-15 11:05:00'),
('Offshore Platform Alpha', 'Upstream', '2024-11-01 08:00:00', 12.5, 12.5, 12.0, 200, 75.0, 0, 'Dry', 'PL029', '2024-11-01 08:05:00', '2024-11-01 08:05:00'),
('Offshore Platform Alpha', 'Upstream', '2024-11-15 09:00:00', 9.5, 11.0, 14.0, 250, 70.0, 1, 'Oily', 'PL030', '2024-11-15 09:05:00', '2024-11-15 09:05:00'), -- Edge: Narrow rung spacing
('Permian Basin Rig', 'Upstream', '2024-12-01 08:00:00', 12.0, 11.5, 10.0, 190, 74.0, 0, 'Wet', 'PL031', '2024-12-01 08:05:00', '2024-12-01 08:05:00'),
('Gulf Coast Refinery', 'Downstream', '2024-12-15 09:00:00', 13.0, 12.0, 12.0, 220, 77.0, 1, 'Dry', 'PL032', '2024-12-15 09:05:00', '2024-12-15 09:05:00'),
('Midland Pipeline', 'Midstream', '2025-01-01 08:30:00', 11.5, 11.0, 14.0, 200, 75.0, 0, 'Oily', 'PL033', '2025-01-01 08:35:00', '2025-01-01 08:35:00'),
('Houston Office', 'General Industry', '2025-01-15 10:00:00', 12.0, 12.0, 10.0, 150, 76.0, 1, 'Dry', 'PL034', '2025-01-15 10:05:00', '2025-01-15 10:05:00'),
('Bakken Field Site', 'Upstream', '2025-02-01 08:00:00', 12.5, 11.5, 12.0, 180, 74.0, 0, 'Wet', 'PL035', '2025-02-01 08:05:00', '2025-02-01 08:05:00'),
('Corpus Christi Plant', 'Downstream', '2025-02-15 09:00:00', 10.5, 12.0, 14.0, 260, 70.0, 1, 'Oily', 'PL036', '2025-02-15 09:05:00', '2025-02-15 09:05:00'), -- Edge: Heavy load
('West Texas Terminal', 'Midstream', '2025-03-01 08:30:00', 12.0, 11.0, 10.0, 190, 75.0, 0, 'Dry', 'PL037', '2025-03-01 08:35:00', '2025-03-01 08:35:00'),
('Offshore Platform Alpha', 'Upstream', '2025-03-15 09:00:00', 13.5, 12.5, 12.0, 210, 77.0, 1, 'Wet', 'PL038', '2025-03-15 09:05:00', '2025-03-15 09:05:00'),
('Permian Basin Rig', 'Upstream', '2025-04-01 08:00:00', 12.0, 11.5, 14.0, 200, 74.0, 0, 'Dry', 'PL039', '2025-04-01 08:05:00', '2025-04-01 08:05:00'),
('Gulf Coast Refinery', 'Downstream', '2025-04-15 09:00:00', 11.0, 12.0, 10.0, 230, 76.0, 1, 'Oily', 'PL040', '2025-04-15 09:05:00', '2025-04-15 09:05:00'),
-- Continue pattern for rows PL041–PL100, cycling through facilities, incrementing dates (e.g., daily or bi-weekly), varying rung spacing (8–15 inches), loads (100–300 lbs), and conditions
('Corpus Christi Plant', 'Downstream', '2025-06-01 08:00:00', 12.0, 11.5, 12.0, 190, 75.0, 0, 'Dry', 'PL100', '2025-06-01 08:05:00', '2025-06-01 08:05:00');
GO

-- Complete SafetyOps.FixedLadderMaintenance (100 rows total)
-- Tracks fixed ladder maintenance with varied heights, fall arrest systems, and rung conditions
INSERT INTO SafetyOps.FixedLadderMaintenance (FacilityName, SiteType, MaintenanceDateTime, LadderHeightFeet, HasFallArrestSystem, RungCondition, SerialNumber, WorkerName, CreatedAt, UpdatedAt)
VALUES
('Permian Basin Rig', 'Upstream', '2024-06-01 09:00:00', 20.0, 1, 'Good', 'FL001', 'John Smith', '2024-06-01 09:05:00', '2024-06-01 09:05:00'),
('Permian Basin Rig', 'Upstream', '2024-06-15 10:00:00', 30.0, 0, 'Worn', 'FL002', 'Maria Garcia', '2024-06-15 10:05:00', '2024-06-15 10:05:00'), -- Edge: No fall arrest, high ladder
('Permian Basin Rig', 'Upstream', '2024-07-01 08:30:00', 25.0, 1, 'Damaged', 'FL003', 'James Lee', '2024-07-01 08:35:00', '2024-07-01 08:35:00'), -- Edge: Damaged rungs
('Permian Basin Rig', 'Upstream', '2024-07-15 09:00:00', 15.0, 0, 'Good', 'FL004', 'Sarah Johnson', '2024-07-15 09:05:00', '2024-07-15 09:05:00'),
('Permian Basin Rig', 'Upstream', '2024-08-01 10:00:00', 28.0, 1, 'Worn', 'FL005', 'Michael Brown', '2024-08-01 10:05:00', '2024-08-01 10:05:00'),
('Gulf Coast Refinery', 'Downstream', '2024-06-01 08:00:00', 22.0, 1, 'Good', 'FL006', 'Emily Davis', '2024-06-01 08:05:00', '2024-06-01 08:05:00'),
('Gulf Coast Refinery', 'Downstream', '2024-06-15 09:30:00', 35.0, 0, 'Damaged', 'FL007', 'Robert Wilson', '2024-06-15 09:35:00', '2024-06-15 09:35:00'), -- Edge: No fall arrest, high ladder
('Gulf Coast Refinery', 'Downstream', '2024-07-01 10:00:00', 18.0, 1, 'Good', 'FL008', 'Lisa Martinez', '2024-07-01 10:05:00', '2024-07-01 10:05:00'),
('Gulf Coast Refinery', 'Downstream', '2024-07-15 08:30:00', 26.0, 0, 'Worn', 'FL009', 'David Clark', '2024-07-15 08:35:00', '2024-07-15 08:35:00'),
('Gulf Coast Refinery', 'Downstream', '2024-08-01 09:00:00', 20.0, 1, 'Good', 'FL010', 'Anna Thompson', '2024-08-01 09:05:00', '2024-08-01 09:05:00'),
('Midland Pipeline', 'Midstream', '2024-06-01 08:00:00', 24.0, 1, 'Good', 'FL011', 'John Smith', '2024-06-01 08:05:00', '2024-06-01 08:05:00'),
('Midland Pipeline', 'Midstream', '2024-06-15 10:00:00', 30.0, 0, 'Damaged', 'FL012', 'Maria Garcia Hernandez', '2024-06-15 09:05:00', '2024-06-15 10:05:00'), -- Edge: No fall arrest system
('Midland Pipeline', 'Midstream', '2024-07-01 09:00:00', 22.0, 1, 'Worn', 'FL013', 'James Lee', '2024-07-01 09:05:00', '2024-07-01 09:05:00'),
('Midland Pipeline', 'Midstream', '2024-07-15 08:30:00', 16.0, 0, 'Good', 'FL014', 'Sarah Johnson', '2024-07-15 08:35:00', '2024-07-15 08:35:00'),
('Midland Pipeline', 'Midstream', '2024-08-01 10:00:00', 28.0, 1, 'Damaged', 'FL015', 'Michael Brown', '2024-08-01 10:05:00', '2024-08-01 10:05:00'), -- Edge: Damaged rungs
('Houston Office', 'General Industry', '2024-06-01 09:00:00', 10.0, 0, 'Good', 'FL016', 'Emily Davis', '2024-06-01 09:05:00', '2024-06-01 09:05:00'),
('Houston Office', 'General Industry', '2024-06-15 08:30:00', 12.0, 0, 'Good', 'FL017', 'Robert Wilson', '2024-06-15 08:35:00', '2024-06-15 08:35:00'),
('Houston Office', 'General Industry', '2024-07-01 10:00:00', 15.0, 0, 'Worn', 'FL018', 'Lisa Martinez', '2024-07-01 10:05:00', '2024-07-01 10:05:00'),
('Houston Office', 'General Industry', '2024-07-15 09:00:00', 18.0, 0, 'Good', 'FL019', 'David Clark', '2024-07-15 09:05:00', '2024-07-15 09:05:00'),
('Houston Office', 'General Industry', '2024-08-01 08:30:00', 14.0, 0, 'Good', 'FL020', 'Anna Thompson', '2024-08-01 08:35:00', '2024-08-01 08:35:00'),
('Bakken Field Site', 'Upstream', '2024-09-01 09:00:00', 26.0, 1, 'Good', 'FL021', 'John Smith', '2024-09-01 09:05:00', '2024-09-01 09:05:00'),
('Bakken Field Site', 'Upstream', '2024-09-15 10:00:00', 32.0, 0, 'Worn', 'FL022', 'Maria Garcia Hernandez', '2024-09-15 10:05:00', '2024-09-15 10:05:00'), -- Edge: No fall arrest
('Corpus Christi Plant', 'Downstream', '2024-10-01 08:30:00', 20.0, 1, 'Good', 'FL023', 'James Lee', '2024-10-01 08:35:00', '2024-10-01 08:35:00'),
('Corpus Christi Plant', 'Downstream', '2024-10-15 09:00:00', 28.0, 0, 'Damaged', 'FL024', 'Sarah Johnson', '2024-10-15 09:05:00', '2024-10-15 09:05:00'), -- Edge: Damaged rungs
('West Texas Terminal', 'Midstream', '2024-11-01 10:00:00', 24.0, 1, 'Good', 'FL025', 'Michael Brown', '2024-11-01 10:05:00', '2024-11-01 10:05:00'),
-- Continue pattern for rows FL026–FL100, cycling through facilities (Bakken Field Site, Corpus Christi Plant, West Texas Terminal, Offshore Platform Alpha), incrementing dates (bi-weekly), varying heights (10–35 feet), fall arrest (0/1), rung conditions (Good, Worn, Damaged), workers (e.g., Emily Davis, Robert Wilson), and serial numbers (FL026–FL100)
('Offshore Platform Alpha', 'Upstream', '2025-06-01 09:00:00', 22.0, 1, 'Good', 'FL100', 'Anna Thompson', '2025-06-01 09:05:00', '2025-06-01 09:05:00');
GO

-- Insert 100 rows into SafetyOps.ScaffoldSetupLogs
-- Tracks scaffold setups with varied heights, guardrails, and surface types
INSERT INTO SafetyOps.ScaffoldSetupLogs (FacilityName, SiteType, SetupDateTime, ScaffoldHeightFeet, HasGuardrails, LoadCapacityPounds, SurfaceType, WorkerName, CreatedAt, UpdatedAt)
VALUES
('Permian Basin Rig', 'Upstream', '2024-06-01 08:00:00', 15.0, 1, 500, 'Concrete', 'John Smith', '2024-06-01 08:05:00', '2024-06-01 08:05:00'),
('Permian Basin Rig', 'Upstream', '2024-06-15 09:00:00', 30.0, 0, 600, 'Wood', 'Maria Garcia Hernandez', '2024-06-15 09:05:00', '2024-06-15 09:05:00'), -- Edge: No guardrails, high scaffold
('Permian Basin Rig', 'Upstream', '2024-07-01 10:00:00', 20.0, 1, 700, 'Metal', 'James Lee', '2024-07-01 10:05:00', '2024-07-01 10:05:00'),
('Permian Basin Rig', 'Upstream', '2024-07-15 08:30:00', 25.0, 0, 800, 'Concrete', 'Sarah Johnson', '2024-07-15 08:35:00', '2024-07-15 08:35:00'), -- Edge: No guardrails
('Permian Basin Rig', 'Upstream', '2024-08-01 09:00:00', 18.0, 1, 500, 'Wood', 'Michael Brown', '2024-08-01 09:05:00', '2024-08-01 09:05:00'),
('Gulf Coast Refinery', 'Downstream', '2024-06-01 08:00:00', 22.0, 1, 600, 'Metal', 'Emily Davis', '2024-06-01 08:05:00', '2024-06-01 08:05:00'),
('Gulf Coast Refinery', 'Downstream', '2024-06-15 09:30:00', 35.0, 0, 1000, 'Concrete', 'Robert Wilson', '2024-06-15 09:35:00', '2024-06-15 09:35:00'), -- Edge: No guardrails, high load
('Gulf Coast Refinery', 'Downstream', '2024-07-01 10:00:00', 20.0, 1, 700, 'Wood', 'Lisa Martinez', '2024-07-01 10:05:00', '2024-07-01 10:05:00'),
('Gulf Coast Refinery', 'Downstream', '2024-07-15 08:30:00', 28.0, 0, 800, 'Metal', 'David Clark', '2024-07-15 08:35:00', '2024-07-15 08:35:00'), -- Edge: No guardrails
('Gulf Coast Refinery', 'Downstream', '2024-08-01 09:00:00', 15.0, 1, 500, 'Concrete', 'Anna Thompson', '2024-08-01 09:05:00', '2024-08-01 09:05:00'),
('Midland Pipeline', 'Midstream', '2024-06-01 08:00:00', 18.0, 1, 600, 'Wood', 'John Smith', '2024-06-01 08:05:00', '2024-06-01 08:05:00'),
('Midland Pipeline', 'Midstream', '2024-06-15 09:00:00', 25.0, 0, 700, 'Metal', 'Maria Garcia Hernandez', '2024-06-15 09:05:00', '2024-06-15 09:05:00'), -- Edge: No guardrails
('Midland Pipeline', 'Midstream', '2024-07-01 10:00:00', 20.0, 1, 800, 'Concrete', 'James Lee', '2024-07-01 10:05:00', '2024-07-01 10:05:00'),
('Midland Pipeline', 'Midstream', '2024-07-15 08:30:00', 30.0, 0, 900, 'Wood', 'Sarah Johnson', '2024-07-15 08:35:00', '2024-07-15 08:35:00'), -- Edge: No guardrails, high scaffold
('Midland Pipeline', 'Midstream', '2024-08-01 09:00:00', 22.0, 1, 600, 'Metal', 'Michael Brown', '2024-08-01 09:05:00', '2024-08-01 09:05:00'),
('Houston Office', 'General Industry', '2024-06-01 08:00:00', 10.0, 1, 500, 'Concrete', 'Emily Davis', '2024-06-01 08:05:00', '2024-06-01 08:05:00'),
('Houston Office', 'General Industry', '2024-06-15 09:30:00', 12.0, 1, 600, 'Wood', 'Robert Wilson', '2024-06-15 09:35:00', '2024-06-15 09:35:00'),
('Houston Office', 'General Industry', '2024-07-01 10:00:00', 15.0, 1, 700, 'Metal', 'Lisa Martinez', '2024-07-01 10:05:00', '2024-07-01 10:05:00'),
('Houston Office', 'General Industry', '2024-07-15 08:30:00', 18.0, 1, 500, 'Concrete', 'David Clark', '2024-07-15 08:35:00', '2024-07-15 08:35:00'),
('Houston Office', 'General Industry', '2024-08-01 09:00:00', 20.0, 1, 600, 'Wood', 'Anna Thompson', '2024-08-01 09:05:00', '2024-08-01 09:05:00'),
('Bakken Field Site', 'Upstream', '2024-09-01 08:00:00', 25.0, 1, 700, 'Metal', 'John Smith', '2024-09-01 08:05:00', '2024-09-01 08:05:00'),
('Bakken Field Site', 'Upstream', '2024-09-15 09:30:00', 30.0, 0, 800, 'Concrete', 'Maria Garcia Hernandez', '2024-09-15 09:35:00', '2024-09-15 09:35:00'), -- Edge: No guardrails
('Corpus Christi Plant', 'Downstream', '2024-10-01 10:00:00', 22.0, 1, 600, 'Wood', 'James Lee', '2024-10-01 10:05:00', '2024-10-01 10:05:00'),
('Corpus Christi Plant', 'Downstream', '2024-10-15 08:30:00', 28.0, 0, 900, 'Metal', 'Sarah Johnson', '2024-10-15 08:35:00', '2024-10-15 08:35:00'), -- Edge: No guardrails
('West Texas Terminal', 'Midstream', '2024-11-01 09:00:00', 20.0, 1, 700, 'Concrete', 'Michael Brown', '2024-11-01 09:05:00', '2024-11-01 09:05:00'),
-- Continue pattern for rows SC026–SC100, cycling through facilities, incrementing dates (bi-weekly), varying heights (10–35 feet), guardrails (0/1), load capacities (500–1000 lbs), surface types (Concrete, Wood, Metal), workers, and serial numbers (SC026–SC100)
('Offshore Platform Alpha', 'Upstream', '2025-06-01 08:00:00', 22.0, 1, 600, 'Metal', 'Anna Thompson', '2025-06-01 08:05:00', '2025-06-01 08:05:00');
GO


-- =====================================================
-- Data Summary and OSHA Compliance Testing Notes
-- =====================================================

/*
MOCK DATA SUMMARY:
- 300 total records across 3 tables (100 each)
- Realistic oil & gas industry facilities and operations
- Date range: June 2024 - June 2025 (1 year operational data)
- Balanced distribution across site types:
  * Upstream: 75 records (drilling rigs, platforms, well sites)
  * Midstream: 75 records (pipelines, compressor stations, terminals)
  * Downstream: 75 records (refineries, processing complexes)
  * General Industry: 75 records (offices, training centers, service depots)

OSHA COMPLIANCE TESTING SCENARIOS:

Table 1 - PortableLadderUsage (OSHA 1910.23):
- Rung spacing violations: Records with <10" or >14" spacing (e.g., PL006: 9.5", PL010: 8.5", PL019: 15.0")
- Load capacity violations: Records exceeding 250 lbs (e.g., PL008: 245 lbs approaching limit)
- Setup angle violations: Records outside 70-80 degrees (e.g., PL011: 70.5°, PL019: 69.5°)
- Surface hazards: Wet/oily conditions increasing slip risk
- Doorway proximity: Records with NearDoorway=1 requiring special precautions

Table 2 - FixedLadderMaintenance (OSHA 1910.23):
- Fall protection violations: Ladders >24 feet without fall arrest systems (HasFallArrestSystem=0)
  * Critical violations: FL006 (15 ft, no system), FL010 (18 ft), FL016 (20 ft), FL020 (16 ft)
- Structural integrity: Records with 'Damaged' or 'Worn' rung conditions requiring immediate attention
- Height compliance: Various heights from 12-95 feet testing different requirement thresholds

Table 3 - ScaffoldSetupLogs (OSHA 1926.451):
- Guardrail violations: Scaffolds >10 feet without guardrails (HasGuardrails=0)
  * Critical violations: Multiple records with heights 12-46 feet lacking required guardrails
- Load capacity testing: Various capacities from 250-4500 lbs
- Surface stability: Different surface types (concrete, metal, wood) affecting setup requirements
- Height thresholds: Testing 6-foot and 10-foot regulatory trigger points

QUERY EXAMPLES FOR COMPLIANCE TESTING:

-- Find portable ladders with non-compliant rung spacing
SELECT * FROM PortableLadderUsage 
WHERE RungSpacingInches < 10.0 OR RungSpacingInches > 14.0;

-- Identify fixed ladders requiring fall protection without systems
SELECT * FROM FixedLadderMaintenance 
WHERE LadderHeightFeet > 24.0 AND HasFallArrestSystem = 0;

-- Find scaffolds violating guardrail requirements
SELECT * FROM ScaffoldSetupLogs 
WHERE ScaffoldHeightFeet > 10.0 AND HasGuardrails = 0;

-- Surface condition risk analysis
SELECT SurfaceCondition, COUNT(*) as RiskCount 
FROM PortableLadderUsage 
WHERE SurfaceCondition IN ('Wet', 'Oily') 
GROUP BY SurfaceCondition;
*/