-- Minimal synthetic fixture derived from recovered startup/login queries.
-- This is an inferred compatibility schema, not the vendor's complete schema.
IF DB_ID(N'CoreReaFixture') IS NULL CREATE DATABASE CoreReaFixture;
GO
USE CoreReaFixture;
GO
IF OBJECT_ID(N'dbo.Config', N'U') IS NULL
CREATE TABLE dbo.Config (
    IDConfig nvarchar(128) NOT NULL PRIMARY KEY,
    Valore nvarchar(max) NOT NULL DEFAULT N'',
    Descrizione nvarchar(512) NOT NULL DEFAULT N'',
    Categoria nvarchar(128) NOT NULL DEFAULT N''
);
IF OBJECT_ID(N'dbo.Clients', N'U') IS NULL
CREATE TABLE dbo.Clients (
    IDClient int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Name nvarchar(255) NOT NULL UNIQUE,
    Serial nvarchar(255) NOT NULL DEFAULT N''
);
-- User permission columns are added from the source-derived schema manifest
-- by Initialize-Fixture.ps1, without copying any original users or passwords.
IF OBJECT_ID(N'dbo.Users', N'U') IS NULL
CREATE TABLE dbo.Users (
    IDUser int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    UserName nvarchar(128) NOT NULL UNIQUE,
    UserNetName nvarchar(128) NOT NULL DEFAULT N'',
    Password nvarchar(255) NOT NULL,
    Domain nvarchar(255) NOT NULL DEFAULT N'',
    Line nvarchar(255) NOT NULL DEFAULT N'',
    UserGroup nvarchar(255) NOT NULL DEFAULT N'',
    Description nvarchar(255) NOT NULL DEFAULT N'',
    Power int NOT NULL DEFAULT 1
);
-- Monitor's Sessions user lookup filters the synthetic users by this flag.
IF COL_LENGTH(N'dbo.Users', N'Active') IS NULL
    ALTER TABLE dbo.Users ADD Active bit NOT NULL DEFAULT 1;
GO
-- Active-profile selection is a separate gate after credential validation.
-- datetime is intentional: the recovered query uses VALIDITY_TO + 1.
IF OBJECT_ID(N'dbo.UserProfiles', N'U') IS NULL
CREATE TABLE dbo.UserProfiles (
    IDUserProfile int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    IDArea int NOT NULL DEFAULT 1,
    Name nvarchar(128) NOT NULL UNIQUE,
    Description nvarchar(255) NOT NULL DEFAULT N'',
    Line nvarchar(255) NOT NULL DEFAULT N'',
    Power smallint NOT NULL DEFAULT 1,
    Active bit NOT NULL DEFAULT 1,
    Validity_From datetime NOT NULL DEFAULT '20000101',
    Validity_To datetime NOT NULL DEFAULT '20991231'
);
-- Sessions includes users with either DataValidation or ImageHighlighter profiles.
IF COL_LENGTH(N'dbo.UserProfiles', N'ImageHighlighter') IS NULL
    ALTER TABLE dbo.UserProfiles ADD ImageHighlighter bit NOT NULL DEFAULT 0;
IF OBJECT_ID(N'dbo.UsersUsersProfilesMatch', N'U') IS NULL
CREATE TABLE dbo.UsersUsersProfilesMatch (
    IDUser int NOT NULL REFERENCES dbo.Users(IDUser),
    IDProfile int NOT NULL REFERENCES dbo.UserProfiles(IDUserProfile),
    Validity_From datetime NOT NULL DEFAULT '20000101',
    Validity_To datetime NOT NULL DEFAULT '20991231',
    CONSTRAINT PK_CoreReaUserProfile PRIMARY KEY(IDUser, IDProfile)
);
GO
-- frmMainMonitor.RecuperaStringaricerca accepts no matching rows and returns
-- empty settings. Leave this table empty to preserve that built-in path.
IF OBJECT_ID(N'dbo.Customview', N'U') IS NULL
CREATE TABLE dbo.Customview (
    IDArea int NOT NULL PRIMARY KEY,
    MONITOR_BATCH_VIEW_QUERY nvarchar(max) NOT NULL DEFAULT N'',
    MONITOR_STATUS_FILTER_QUERY nvarchar(max) NOT NULL DEFAULT N''
);
-- Inferred from Utility.LogInOperationDB and both main forms' INSERT lists.
-- IDBatch is text because session events explicitly insert an empty string.
-- No workflow foreign keys: login/session events use zero IDs.
IF OBJECT_ID(N'dbo.Operations', N'U') IS NULL
CREATE TABLE dbo.Operations (
    IDOperation bigint IDENTITY(1,1) NOT NULL PRIMARY KEY,
    IDApplication int NOT NULL DEFAULT 0,
    IDBatch nvarchar(255) NOT NULL DEFAULT N'',
    IDProcess int NOT NULL DEFAULT 0,
    IDUser int NOT NULL DEFAULT 0,
    IDClient int NOT NULL DEFAULT 0,
    IDUserProfile int NOT NULL DEFAULT 0,
    ApplicationName nvarchar(255) NOT NULL DEFAULT N'',
    BatchName nvarchar(255) NOT NULL DEFAULT N'',
    ProcessName nvarchar(255) NOT NULL DEFAULT N'',
    StationName nvarchar(255) NOT NULL DEFAULT N'',
    Activity nvarchar(255) NOT NULL DEFAULT N'',
    Status nvarchar(255) NOT NULL DEFAULT N'',
    UserName nvarchar(255) NOT NULL DEFAULT N'',
    BoxName nvarchar(255) NOT NULL DEFAULT N'',
    Notes nvarchar(max) NOT NULL DEFAULT N'',
    TimeStampOp datetime NOT NULL DEFAULT GETDATE(),
    StartTime datetime NULL,
    EndTime datetime NULL,
    Duration int NOT NULL DEFAULT 0,
    Boxes int NOT NULL DEFAULT 0,
    Images int NOT NULL DEFAULT 0,
    Files int NOT NULL DEFAULT 0,
    Docs int NOT NULL DEFAULT 0,
    ImagesOCR int NOT NULL DEFAULT 0,
    FilesOCR int NOT NULL DEFAULT 0,
    DocsOCR int NOT NULL DEFAULT 0,
    ImagesDV int NOT NULL DEFAULT 0,
    FilesDV int NOT NULL DEFAULT 0,
    DocsDV int NOT NULL DEFAULT 0,
    FieldsDV int NOT NULL DEFAULT 0,
    RecordsDV int NOT NULL DEFAULT 0,
    CharsDV int NOT NULL DEFAULT 0,
    TotalKeysDV int NOT NULL DEFAULT 0
);
-- Sessions search reads the line from each activity row.
IF COL_LENGTH(N'dbo.Operations', N'Line') IS NULL
    ALTER TABLE dbo.Operations ADD Line nvarchar(128) NOT NULL DEFAULT N'';
GO

-- Storici can list a local custom query alongside jobs with configured archives.
CREATE OR ALTER VIEW dbo.ReaBatchPriorityHistory AS
SELECT IDBatch, Activity, UserName, TimeStampOp, Status
FROM dbo.Operations
WHERE IDBatch=N'REA-BATCH-001' AND Activity=N'CAMBIA PRIORITA';
GO
IF OBJECT_ID(N'dbo.StoricoCustom', N'U') IS NULL
CREATE TABLE dbo.StoricoCustom (
    IDArea int NOT NULL,
    Name nvarchar(128) NOT NULL,
    StringConnection nvarchar(512) NOT NULL DEFAULT N'',
    CustomQuery nvarchar(max) NOT NULL,
    PRIMARY KEY (IDArea, Name)
);
IF NOT EXISTS (SELECT 1 FROM dbo.StoricoCustom WHERE IDArea=1 AND Name=N'REA Batch Priority Audit')
    INSERT dbo.StoricoCustom(IDArea,Name,CustomQuery)
    VALUES (1,N'REA Batch Priority Audit',N'SELECT IDBatch, Activity, UserName, TimeStampOp, Status FROM dbo.ReaBatchPriorityHistory');
GO

-- Monitor batch-list fixture. The seeded process has no profile mapping.
IF OBJECT_ID(N'dbo.Areas', N'U') IS NULL
CREATE TABLE dbo.Areas (IDArea int NOT NULL PRIMARY KEY);
IF OBJECT_ID(N'dbo.Lines', N'U') IS NULL
CREATE TABLE dbo.Lines (
    IDArea int NOT NULL REFERENCES dbo.Areas(IDArea),
    Description nvarchar(128) NOT NULL,
    PRIMARY KEY (IDArea, Description)
);
IF OBJECT_ID(N'dbo.Applications', N'U') IS NULL
CREATE TABLE dbo.Applications (
    IDApplication int NOT NULL PRIMARY KEY,
    IDArea int NOT NULL REFERENCES dbo.Areas(IDArea),
    Active bit NOT NULL,
    Name nvarchar(128) NOT NULL,
    Description nvarchar(255) NOT NULL,
    Customer nvarchar(128) NOT NULL,
    WorkPath nvarchar(255) NOT NULL DEFAULT N'',
    OutPutPath nvarchar(255) NOT NULL DEFAULT N'',
    ExportProcess nvarchar(128) NOT NULL DEFAULT N'',
    InvoiceCountProcess nvarchar(128) NOT NULL DEFAULT N'',
    ArchiveDB nvarchar(255) NOT NULL DEFAULT N'',
    OnlyDataEntry bit NOT NULL DEFAULT 0,
    Parameters nvarchar(max) NOT NULL DEFAULT N''
);
IF OBJECT_ID(N'dbo.AreasApplicationsMatch', N'U') IS NULL
CREATE TABLE dbo.AreasApplicationsMatch (
    IDArea int NOT NULL REFERENCES dbo.Areas(IDArea),
    IDApplication int NOT NULL REFERENCES dbo.Applications(IDApplication),
    PRIMARY KEY (IDArea, IDApplication)
);
IF OBJECT_ID(N'dbo.Process', N'U') IS NULL
CREATE TABLE dbo.Process (
    IDProcess int NOT NULL PRIMARY KEY,
    IDApplication int NOT NULL REFERENCES dbo.Applications(IDApplication),
    ProcessName nvarchar(128) NOT NULL,
    Description nvarchar(255) NOT NULL,
    ProcessType nvarchar(40) NOT NULL
);
IF OBJECT_ID(N'dbo.UserProfilesProcessMatch', N'U') IS NULL
CREATE TABLE dbo.UserProfilesProcessMatch (
    IDUserProfile int NOT NULL REFERENCES dbo.UserProfiles(IDUserProfile),
    IDProcess int NOT NULL REFERENCES dbo.Process(IDProcess),
    PRIMARY KEY (IDUserProfile, IDProcess)
);
IF OBJECT_ID(N'dbo.Status', N'U') IS NULL
CREATE TABLE dbo.Status (
    IDApplication int NOT NULL REFERENCES dbo.Applications(IDApplication),
    Name nvarchar(128) NOT NULL,
    MinPower smallint NOT NULL DEFAULT 0,
    Color int NOT NULL DEFAULT 0,
    PRIMARY KEY (IDApplication, Name)
);
IF OBJECT_ID(N'dbo.Batches', N'U') IS NULL
CREATE TABLE dbo.Batches (
    IDBatch nvarchar(128) NOT NULL PRIMARY KEY,
    IDApplication int NOT NULL REFERENCES dbo.Applications(IDApplication),
    Customer nvarchar(128) NOT NULL,
    Job nvarchar(128) NOT NULL,
    Name nvarchar(128) NOT NULL,
    NDoc int NOT NULL DEFAULT 0,
    NPag int NOT NULL DEFAULT 0,
    NImg int NOT NULL DEFAULT 0,
    Status nvarchar(128) NOT NULL,
    Priority int NOT NULL DEFAULT 0,
    LockUser nvarchar(128) NOT NULL DEFAULT N'',
    LockStation nvarchar(128) NOT NULL DEFAULT N'',
    InsDate datetime NOT NULL DEFAULT GETDATE(),
    InsUser nvarchar(128) NOT NULL DEFAULT N'',
    InsStation nvarchar(128) NOT NULL DEFAULT N'',
    Path nvarchar(255) NOT NULL DEFAULT N'',
    Note nvarchar(255) NOT NULL DEFAULT N'',
    Message nvarchar(255) NOT NULL DEFAULT N'',
    DestLine nvarchar(128) NOT NULL DEFAULT N'',
    RowVersion rowversion NOT NULL
);
GO
-- Monitor's default batch projection reads these even for an ID-only search.
-- Infer display types for the synthetic fixture and upgrade existing volumes in place.
IF COL_LENGTH(N'dbo.Batches', N'Box') IS NULL
    ALTER TABLE dbo.Batches ADD Box nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH(N'dbo.Batches', N'Supporto') IS NULL
    ALTER TABLE dbo.Batches ADD Supporto nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH(N'dbo.Batches', N'Dimensione') IS NULL
    ALTER TABLE dbo.Batches ADD Dimensione nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH(N'dbo.Batches', N'Tipologia1') IS NULL
    ALTER TABLE dbo.Batches ADD Tipologia1 nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH(N'dbo.Batches', N'Tipologia2') IS NULL
    ALTER TABLE dbo.Batches ADD Tipologia2 nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH(N'dbo.Batches', N'Tipologia3') IS NULL
    ALTER TABLE dbo.Batches ADD Tipologia3 nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH(N'dbo.Batches', N'Tipologia4') IS NULL
    ALTER TABLE dbo.Batches ADD Tipologia4 nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH(N'dbo.Batches', N'Tipologia5') IS NULL
    ALTER TABLE dbo.Batches ADD Tipologia5 nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH(N'dbo.Batches', N'Tipologia6') IS NULL
    ALTER TABLE dbo.Batches ADD Tipologia6 nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH(N'dbo.Batches', N'NDocExp') IS NULL
    ALTER TABLE dbo.Batches ADD NDocExp int NOT NULL DEFAULT 0;
IF COL_LENGTH(N'dbo.Batches', N'NPagExp') IS NULL
    ALTER TABLE dbo.Batches ADD NPagExp int NOT NULL DEFAULT 0;
IF COL_LENGTH(N'dbo.Batches', N'NImgExp') IS NULL
    ALTER TABLE dbo.Batches ADD NImgExp int NOT NULL DEFAULT 0;
IF COL_LENGTH(N'dbo.Batches', N'ModDate') IS NULL
    ALTER TABLE dbo.Batches ADD ModDate datetime NULL;
IF COL_LENGTH(N'dbo.Batches', N'ModUser') IS NULL
    ALTER TABLE dbo.Batches ADD ModUser nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH(N'dbo.Batches', N'ModStation') IS NULL
    ALTER TABLE dbo.Batches ADD ModStation nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH(N'dbo.Batches', N'ExportDate') IS NULL
    ALTER TABLE dbo.Batches ADD ExportDate datetime NULL;
IF COL_LENGTH(N'dbo.Batches', N'ExportUser') IS NULL
    ALTER TABLE dbo.Batches ADD ExportUser nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH(N'dbo.Batches', N'ExportStation') IS NULL
    ALTER TABLE dbo.Batches ADD ExportStation nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH(N'dbo.Batches', N'Inviato') IS NULL
    ALTER TABLE dbo.Batches ADD Inviato nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH(N'dbo.Batches', N'Convertito') IS NULL
    ALTER TABLE dbo.Batches ADD Convertito nvarchar(128) NOT NULL DEFAULT N'';
GO
IF NOT EXISTS (SELECT 1 FROM dbo.Areas WHERE IDArea=1)
    INSERT dbo.Areas(IDArea) VALUES (1);
IF NOT EXISTS (SELECT 1 FROM dbo.Lines WHERE IDArea=1 AND Description=N'REA Test Line')
    INSERT dbo.Lines(IDArea,Description) VALUES (1,N'REA Test Line');
IF NOT EXISTS (SELECT 1 FROM dbo.Applications WHERE IDApplication=1)
    INSERT dbo.Applications(IDApplication,IDArea,Active,Name,Description,Customer)
    VALUES (1,1,1,N'REA Monitor',N'Synthetic Monitor application',N'REA Synthetic Customer');
IF NOT EXISTS (SELECT 1 FROM dbo.AreasApplicationsMatch WHERE IDArea=1 AND IDApplication=1)
    INSERT dbo.AreasApplicationsMatch(IDArea,IDApplication) VALUES (1,1);
IF NOT EXISTS (SELECT 1 FROM dbo.Process WHERE IDProcess=1)
    INSERT dbo.Process(IDProcess,IDApplication,ProcessName,Description,ProcessType)
    VALUES (1,1,N'REA Batch List',N'Synthetic process reference',N'Fixture');
IF NOT EXISTS (SELECT 1 FROM dbo.Status WHERE IDApplication=1 AND Name=N'READY')
    INSERT dbo.Status(IDApplication,Name) VALUES (1,N'READY');
IF NOT EXISTS (SELECT 1 FROM dbo.Batches WHERE IDBatch=N'REA-BATCH-001')
    INSERT dbo.Batches(IDBatch,IDApplication,Customer,Job,Name,Status,Note)
    VALUES (N'REA-BATCH-001',1,N'REA Synthetic Customer',N'REA Job',N'REA Test Batch',N'READY',N'Synthetic list and filter test');
GO
