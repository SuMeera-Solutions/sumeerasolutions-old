


-- Table 1: PortableLadderUsage
-- Description: Tracks usage of portable ladders in maintenance tasks.
CREATE TABLE PortableLadderUsage (
    UsageID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50), -- Upstream, Midstream, Downstream, General Industry
    UsageDateTime DATETIME,
    RungSpacingInches DECIMAL(5,2),
    RungWidthInches DECIMAL(5,2),
    LadderHeightFeet DECIMAL(5,2),
    LoadCarriedPounds INT,
    SetupAngleDegrees DECIMAL(5,2),
    NearDoorway BIT, -- 1 for yes, 0 for no
    SurfaceCondition VARCHAR(50), -- Wet, Dry, Oily
    SerialNumber VARCHAR(50),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 2: FixedLadderMaintenance
-- Description: Logs maintenance activities for fixed ladders.
CREATE TABLE FixedLadderMaintenance (
    MaintenanceID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    MaintenanceDateTime DATETIME,
    LadderHeightFeet DECIMAL(5,2),
    HasFallArrestSystem BIT,
    RungCondition VARCHAR(50), -- Good, Worn, Damaged
    SerialNumber VARCHAR(50),
    WorkerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 3: ScaffoldSetupLogs
-- Description: Records scaffold setup for construction tasks.
CREATE TABLE ScaffoldSetupLogs (
    SetupID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    SetupDateTime DATETIME,
    ScaffoldHeightFeet DECIMAL(5,2),
    HasGuardrails BIT,
    LoadCapacityPounds INT,
    SurfaceType VARCHAR(50), -- Concrete, Wood, Metal
    WorkerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 4: WalkingSurfaceCleaning
-- Description: Tracks cleaning of walking-working surfaces.
CREATE TABLE WalkingSurfaceCleaning (
    CleaningID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    CleaningDateTime DATETIME,
    SurfaceAreaSquareFeet INT,
    IsSlipResistant BIT,
    SurfaceCondition VARCHAR(50), -- Wet, Dry, Oily
    CleaningAgent VARCHAR(50),
    WorkerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 5: FallHarnessUsage
-- Description: Logs usage of fall protection harnesses.
CREATE TABLE FallHarnessUsage (
    HarnessUsageID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    UsageDateTime DATETIME,
    OperationHeightFeet DECIMAL(5,2),
    AnchorPointID VARCHAR(50),
    HarnessSerialNumber VARCHAR(50),
    WorkerName VARCHAR(100),
    UsageDurationHours INT,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 6: ExitRouteInspections
-- Description: Records inspections of exit routes.
CREATE TABLE ExitRouteInspections (
    InspectionID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    InspectionDateTime DATETIME,
    ExitRouteID VARCHAR(50),
    IsUnobstructed BIT,
    SignageCondition VARCHAR(50), -- Visible, Faded, Missing
    InspectorName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 7: EmergencyDrillLogs
-- Description: Tracks emergency evacuation drills.
CREATE TABLE EmergencyDrillLogs (
    DrillID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    DrillDateTime DATETIME,
    DrillType VARCHAR(50), -- Fire, Chemical Spill
    EvacuationTimeMinutes INT,
    ParticipantCount INT,
    CoordinatorName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 8: FirePreventionTasks
-- Description: Logs fire prevention maintenance tasks.
CREATE TABLE FirePreventionTasks (
    TaskID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    TaskDateTime DATETIME,
    TaskType VARCHAR(50), -- Clear Flammables, Inspect Alarms
    AreaInspected VARCHAR(100),
    WorkerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 9: ManliftOperations
-- Description: Tracks usage of manlifts for elevated work.
CREATE TABLE ManliftOperations (
    OperationID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    OperationDateTime DATETIME,
    ManliftSerialNumber VARCHAR(50),
    LoadCarriedPounds INT,
    OperationHeightFeet DECIMAL(5,2),
    OperatorName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 10: PoweredPlatformMaintenance
-- Description: Logs maintenance of powered work platforms.
CREATE TABLE PoweredPlatformMaintenance (
    MaintenanceID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    MaintenanceDateTime DATETIME,
    PlatformSerialNumber VARCHAR(50),
    LoadCapacityPounds INT,
    ComponentInspected VARCHAR(50), -- Motor, Cables
    WorkerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 11: FlammableLiquidStorage
-- Description: Tracks storage of flammable liquids.
CREATE TABLE FlammableLiquidStorage (
    StorageID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    StorageDateTime DATETIME,
    MaterialName VARCHAR(50), -- Gasoline, Diesel
    ContainerVolumeGallons INT,
    StorageTemperatureCelsius DECIMAL(5,2),
    SpillContainment BIT,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 12: CompressedGasHandling
-- Description: Logs handling of compressed gas cylinders.
CREATE TABLE CompressedGasHandling (
    HandlingID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    HandlingDateTime DATETIME,
    GasType VARCHAR(50), -- Oxygen, Acetylene
    CylinderSerialNumber VARCHAR(50),
    StorageCondition VARCHAR(50), -- Secured, Unsecured
    WorkerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 13: HazardousWasteDisposal
-- Description: Tracks disposal of hazardous waste.
CREATE TABLE HazardousWasteDisposal (
    DisposalID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    DisposalDateTime DATETIME,
    WasteType VARCHAR(50), -- Oil, Chemicals
    WasteQuantityKilograms DECIMAL(10,2),
    DisposalMethod VARCHAR(50), -- Incineration, Recycling
    WorkerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 14: PPEIssuance
-- Description: Records issuance of personal protective equipment.
CREATE TABLE PPEIssuance (
    IssuanceID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    IssueDateTime DATETIME,
    PPEType VARCHAR(50), -- Harness, Gloves
    SerialNumber VARCHAR(50),
    WorkerName VARCHAR(100),
    ExpiryDate DATE,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 15: PPEMaintenance
-- Description: Logs maintenance of PPE.
CREATE TABLE PPEMaintenance (
    MaintenanceID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    MaintenanceDateTime DATETIME,
    PPEType VARCHAR(50),
    SerialNumber VARCHAR(50),
    ConditionAfter VARCHAR(50), -- Repaired, Replaced
    WorkerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 16: LockoutTagoutOperations
-- Description: Tracks lockout/tagout procedures.
CREATE TABLE LockoutTagoutOperations (
    LOTOID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    StartDateTime DATETIME,
    EquipmentDescription VARCHAR(100),
    IsolationType VARCHAR(50), -- Electrical, Mechanical
    EndDateTime DATETIME,
    WorkerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 17: SanitationTasks
-- Description: Logs sanitation activities in work areas.
CREATE TABLE SanitationTasks (
    TaskID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    TaskDateTime DATETIME,
    AreaCleaned VARCHAR(100),
    CleaningAgent VARCHAR(50),
    WorkerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 18: ConfinedSpaceEntryLogs
-- Description: Records confined space entries.
CREATE TABLE ConfinedSpaceEntryLogs (
    EntryID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    EntryDateTime DATETIME,
    SpaceID VARCHAR(50),
    AtmosphericTestResult VARCHAR(100), -- Oxygen %, LEL %
    ExitDateTime DATETIME,
    WorkerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 19: FireExtinguisherChecks
-- Description: Tracks fire extinguisher inspections.
CREATE TABLE FireExtinguisherChecks (
    CheckID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    CheckDateTime DATETIME,
    ExtinguisherSerialNumber VARCHAR(50),
    PressureStatus VARCHAR(50), -- Normal, Low
    ExpiryDate DATE,
    InspectorName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 20: FireBrigadeTraining
-- Description: Logs fire brigade training sessions.
CREATE TABLE FireBrigadeTraining (
    TrainingID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    TrainingDateTime DATETIME,
    TrainingTopic VARCHAR(50), -- Firefighting, Evacuation
    ParticipantCount INT,
    TrainerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 21: CraneOperations
-- Description: Tracks crane usage for material handling.
CREATE TABLE CraneOperations (
    OperationID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    OperationDateTime DATETIME,
    CraneSerialNumber VARCHAR(50),
    LoadWeightPounds INT,
    OperatorName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 22: SlingInspections
-- Description: Logs inspections of lifting slings.
CREATE TABLE SlingInspections (
    InspectionID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    InspectionDateTime DATETIME,
    SlingSerialNumber VARCHAR(50),
    Condition VARCHAR(50), -- Good, Worn, Damaged
    InspectorName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 23: RimWheelServicing
-- Description: Tracks servicing of vehicle rim wheels.
CREATE TABLE RimWheelServicing (
    ServiceID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    ServiceDateTime DATETIME,
    VehicleID VARCHAR(50),
    WheelType VARCHAR(50), -- Single-Piece, Multi-Piece
    WorkerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 24: WeldingTasks
-- Description: Logs welding and cutting activities.
CREATE TABLE WeldingTasks (
    TaskID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    TaskDateTime DATETIME,
    WeldingType VARCHAR(50), -- Arc, Gas
    VentilationStatus VARCHAR(50), -- Adequate, Inadequate
    WorkerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 25: ElectricalWiringInstallations
-- Description: Tracks electrical wiring installations.
CREATE TABLE ElectricalWiringInstallations (
    InstallationID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    InstallationDateTime DATETIME,
    CircuitID VARCHAR(50),
    VoltageLevelVolts INT,
    GroundingStatus VARCHAR(50), -- Grounded, Ungrounded
    WorkerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 26: ElectricalEquipmentUsage
-- Description: Logs usage of electrical equipment.
CREATE TABLE ElectricalEquipmentUsage (
    UsageID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    UsageDateTime DATETIME,
    EquipmentSerialNumber VARCHAR(50),
    VoltageLevelVolts INT,
    OperatorName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 27: BenzeneHandling
-- Description: Tracks handling of benzene.
CREATE TABLE BenzeneHandling (
    HandlingID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    HandlingDateTime DATETIME,
    ContainerVolumeLiters DECIMAL(10,2),
    ExposureLevelPPM DECIMAL(5,2),
    WorkerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 28: AirContaminantMonitoring
-- Description: Logs monitoring of air contaminants.
CREATE TABLE AirContaminantMonitoring (
    MonitoringID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    MonitoringDateTime DATETIME,
    ContaminantType VARCHAR(50), -- VOCs, Particulates
    ConcentrationLevelPPM DECIMAL(10,2),
    MonitoringLocation VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 29: ProcessSafetyTasks
-- Description: Tracks process safety management activities.
CREATE TABLE ProcessSafetyTasks (
    TaskID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    TaskDateTime DATETIME,
    ProcessID VARCHAR(50),
    TaskDescription VARCHAR(100), -- Valve Check, Leak Test
    WorkerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 30: ConstructionTrainingSessions
-- Description: Logs safety training for construction workers.
CREATE TABLE ConstructionTrainingSessions (
    TrainingID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    TrainingDateTime DATETIME,
    TrainingTopic VARCHAR(50), -- Fall Protection, Scaffolding
    ParticipantCount INT,
    TrainerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 31: ConstructionConfinedSpaceEntries
-- Description: Tracks confined space entries in construction.
CREATE TABLE ConstructionConfinedSpaceEntries (
    EntryID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    EntryDateTime DATETIME,
    SpaceID VARCHAR(50),
    AtmosphericTestResult VARCHAR(100),
    ExitDateTime DATETIME,
    WorkerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 32: ConstructionPPEIssuance
-- Description: Records PPE issuance for construction workers.
CREATE TABLE ConstructionPPEIssuance (
    IssuanceID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    IssueDateTime DATETIME,
    PPEType VARCHAR(50),
    SerialNumber VARCHAR(50),
    WorkerName VARCHAR(100),
    ExpiryDate DATE,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 33: ConstructionFireSafetyChecks
-- Description: Logs fire safety inspections on construction sites.
CREATE TABLE ConstructionFireSafetyChecks (
    CheckID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    CheckDateTime DATETIME,
    AreaInspected VARCHAR(100),
    FireHazardPresent BIT,
    InspectorName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 34: ConstructionElectricalWork
-- Description: Tracks electrical work in construction.
CREATE TABLE ConstructionElectricalWork (
    WorkID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    WorkDateTime DATETIME,
    CircuitID VARCHAR(50),
    VoltageLevelVolts INT,
    WorkerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 35: ScaffoldInspections
-- Description: Logs inspections of scaffolds in construction.
CREATE TABLE ScaffoldInspections (
    InspectionID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    InspectionDateTime DATETIME,
    ScaffoldID VARCHAR(50),
    GuardrailStatus VARCHAR(50), -- Present, Missing
    InspectorName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 36: ConstructionFallProtectionUsage
-- Description: Tracks usage of fall protection in construction.
CREATE TABLE ConstructionFallProtectionUsage (
    UsageID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    UsageDateTime DATETIME,
    OperationHeightFeet DECIMAL(5,2),
    HarnessSerialNumber VARCHAR(50),
    WorkerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 37: ShipyardPPEIssuance
-- Description: Records PPE issuance for offshore/shipyard workers.
CREATE TABLE ShipyardPPEIssuance (
    IssuanceID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    IssueDateTime DATETIME,
    PPEType VARCHAR(50), -- Life Vest, Harness
    SerialNumber VARCHAR(50),
    WorkerName VARCHAR(100),
    ExpiryDate DATE,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);


-- Table 38: InjuryIllnessReports
-- Description: Records workplace injuries and illnesses for recordkeeping.
CREATE TABLE InjuryIllnessReports (
    ReportID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50), -- Upstream, Midstream, Downstream, General Industry
    IncidentDateTime DATETIME,
    InjuryType VARCHAR(50), -- Sprain, Fracture, Burn
    BodyPartAffected VARCHAR(50),
    IncidentDescription VARCHAR(500),
    WorkerName VARCHAR(100),
    DaysAwayFromWork INT,
    ReportedDateTime DATETIME,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 39: HotWorkPermits
-- Description: Tracks permits issued for hot work activities.
CREATE TABLE HotWorkPermits (
    PermitID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    IssueDateTime DATETIME,
    WorkArea VARCHAR(100),
    FireWatchPresent BIT, -- 1 for yes, 0 for no
    PermitDurationHours INT,
    WorkerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 40: ElectricalPermitLogs
-- Description: Logs permits for electrical work.
CREATE TABLE ElectricalPermitLogs (
    PermitID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    IssueDateTime DATETIME,
    WorkDescription VARCHAR(500),
    VoltageLevelVolts INT,
    EquipmentID VARCHAR(50),
    WorkerName VARCHAR(100),
    ExpiryDateTime DATETIME,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 41: NoiseMonitoringLogs
-- Description: Tracks noise level monitoring in work areas.
CREATE TABLE NoiseMonitoringLogs (
    MonitoringID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    MonitoringDateTime DATETIME,
    AreaMonitored VARCHAR(100),
    NoiseLevelDecibels DECIMAL(5,2),
    MonitoringDurationMinutes INT,
    TechnicianName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 42: VentilationSystemChecks
-- Description: Records inspections of ventilation systems.
CREATE TABLE VentilationSystemChecks (
    CheckID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    CheckDateTime DATETIME,
    SystemID VARCHAR(50),
    AirFlowRateCFM INT,
    FilterCondition VARCHAR(50), -- Clean, Dirty, Replaced
    InspectorName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 43: FireSuppressionTests
-- Description: Logs tests of fire suppression systems.
CREATE TABLE FireSuppressionTests (
    TestID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    TestDateTime DATETIME,
    SystemType VARCHAR(50), -- Sprinkler, Foam
    SystemID VARCHAR(50),
    TestResult VARCHAR(50), -- Pass, Fail
    TechnicianName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 44: VehicleMountedPlatformUsage
-- Description: Tracks usage of vehicle-mounted work platforms.
CREATE TABLE VehicleMountedPlatformUsage (
    UsageID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    UsageDateTime DATETIME,
    PlatformSerialNumber VARCHAR(50),
    OperationHeightFeet DECIMAL(5,2),
    LoadCarriedPounds INT,
    OperatorName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 45: ChemicalSpillResponses
-- Description: Logs responses to chemical spills.
CREATE TABLE ChemicalSpillResponses (
    ResponseID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    SpillDateTime DATETIME,
    ChemicalName VARCHAR(50),
    SpillVolumeLiters DECIMAL(10,2),
    ContainmentStatus VARCHAR(50), -- Contained, Uncontained
    ResponderName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 46: RespiratoryProtectionUsage
-- Description: Tracks usage of respiratory protection equipment.
CREATE TABLE RespiratoryProtectionUsage (
    UsageID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    UsageDateTime DATETIME,
    RespiratorSerialNumber VARCHAR(50),
    UsageDurationHours INT,
    ContaminantType VARCHAR(50), -- Dust, Vapors
    WorkerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 47: SafetyTrainingSessions
-- Description: Logs general safety training sessions.
CREATE TABLE SafetyTrainingSessions (
    TrainingID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    TrainingDateTime DATETIME,
    TrainingTopic VARCHAR(50), -- PPE, Emergency Response
    ParticipantCount INT,
    TrainerName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 48: ForkliftOperations
-- Description: Tracks forklift usage for material handling.
CREATE TABLE ForkliftOperations (
    OperationID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    OperationDateTime DATETIME,
    ForkliftSerialNumber VARCHAR(50),
    LoadWeightPounds INT,
    OperatorName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 49: GasDetectorCalibrations
-- Description: Logs calibrations of gas detection equipment.
CREATE TABLE GasDetectorCalibrations (
    CalibrationID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    CalibrationDateTime DATETIME,
    DetectorSerialNumber VARCHAR(50),
    GasType VARCHAR(50), -- Methane, H2S
    CalibrationResult VARCHAR(50), -- Pass, Fail
    TechnicianName VARCHAR(100),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

-- Table 50: MaintenanceWorkOrders
-- Description: Tracks general maintenance work orders.
CREATE TABLE MaintenanceWorkOrders (
    WorkOrderID INT PRIMARY KEY IDENTITY(1,1),
    FacilityName VARCHAR(100),
    SiteType VARCHAR(50),
    IssueDateTime DATETIME,
    EquipmentDescription VARCHAR(100),
    TaskDescription VARCHAR(500),
    Priority VARCHAR(50), -- Low, Medium, High
    WorkerName VARCHAR(100),
    CompletionDateTime DATETIME,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);