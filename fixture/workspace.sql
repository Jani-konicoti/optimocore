-- Empty workspace contracts inferred from both main forms and frmScegliBatch.
-- No synthetic job is advertised as usable before its Jet/image data is built.
USE CoreReaFixture;
GO
IF COL_LENGTH('dbo.Customview','DATAVALIDATION_BATCH_VIEW_FIELDS_LIST') IS NULL
ALTER TABLE dbo.Customview ADD DATAVALIDATION_BATCH_VIEW_FIELDS_LIST nvarchar(max) NOT NULL DEFAULT N'';
IF COL_LENGTH('dbo.Users','Active') IS NULL
ALTER TABLE dbo.Users ADD Active bit NOT NULL DEFAULT 1;
IF COL_LENGTH('dbo.Operations','Line') IS NULL
ALTER TABLE dbo.Operations ADD Line nvarchar(255) NOT NULL DEFAULT N'';
GO
IF OBJECT_ID('dbo.Areas','U') IS NULL
CREATE TABLE dbo.Areas(IDArea int NOT NULL PRIMARY KEY, Name nvarchar(255) NOT NULL DEFAULT N'', Description nvarchar(255) NOT NULL DEFAULT N'');
IF OBJECT_ID('dbo.Applications','U') IS NULL
CREATE TABLE dbo.Applications(
 IDApplication int IDENTITY PRIMARY KEY, IDArea int NOT NULL DEFAULT 1,
 Active bit NOT NULL DEFAULT 1, Name nvarchar(255) NOT NULL,
 Description nvarchar(255) NOT NULL DEFAULT N'', Customer nvarchar(255) NOT NULL DEFAULT N'',
 WorkPath nvarchar(1024) NOT NULL DEFAULT N'', OutPutPath nvarchar(1024) NOT NULL DEFAULT N'',
 ExportProcess nvarchar(255) NOT NULL DEFAULT N'', InvoiceCountProcess nvarchar(255) NOT NULL DEFAULT N'',
 ArchiveDB nvarchar(255) NOT NULL DEFAULT N'', Parameters nvarchar(max) NOT NULL DEFAULT N'',
 DataValidationReleaseProcess nvarchar(255) NOT NULL DEFAULT N'',
 DataValidationLocalReleaseProcess nvarchar(255) NOT NULL DEFAULT N'',
 DoubleDataEntry bit NOT NULL DEFAULT 0, DuplicateRecordShiftEnter bit NOT NULL DEFAULT 0,
 DuplicateImageWhenSplitRecord bit NOT NULL DEFAULT 0, OnlyDataEntry bit NOT NULL DEFAULT 0,
 GoToWrong bit NOT NULL DEFAULT 1, StartWithThumbs bit NOT NULL DEFAULT 0
);
IF OBJECT_ID('dbo.AreasApplicationsMatch','U') IS NULL
CREATE TABLE dbo.AreasApplicationsMatch(IDArea int NOT NULL, IDApplication int NOT NULL, PRIMARY KEY(IDArea,IDApplication));
IF OBJECT_ID('dbo.Process','U') IS NULL
CREATE TABLE dbo.Process(
 IDProcess int IDENTITY PRIMARY KEY, IDApplication int NOT NULL,
 ProcessName nvarchar(255) NOT NULL, Description nvarchar(255) NOT NULL DEFAULT N'',
 ProcessType nvarchar(255) NOT NULL DEFAULT N'Manuale', Prog int NOT NULL DEFAULT 1,
 [Start] nvarchar(255) NOT NULL DEFAULT N'', Start0 nvarchar(255) NOT NULL DEFAULT N'',
 Exe nvarchar(255) NOT NULL DEFAULT N'', EndInt nvarchar(255) NOT NULL DEFAULT N'',
 EndErr nvarchar(255) NOT NULL DEFAULT N'', EndCor nvarchar(255) NOT NULL DEFAULT N'',
 EndFai nvarchar(255) NOT NULL DEFAULT N'', EndFor nvarchar(255) NOT NULL DEFAULT N'',
 Parameters nvarchar(max) NOT NULL DEFAULT N''
);
IF OBJECT_ID('dbo.UserProfilesProcessMatch','U') IS NULL
CREATE TABLE dbo.UserProfilesProcessMatch(IDUserProfile int NOT NULL, IDProcess int NOT NULL, PRIMARY KEY(IDUserProfile,IDProcess));
IF OBJECT_ID('dbo.Status','U') IS NULL
CREATE TABLE dbo.Status(IDStatus int IDENTITY PRIMARY KEY,IDApplication int NOT NULL,
 Name nvarchar(255) NOT NULL, MinPower int NOT NULL DEFAULT 0, Color int NOT NULL DEFAULT -16777216);
IF OBJECT_ID('dbo.StatusTraslation','U') IS NULL
CREATE TABLE dbo.StatusTraslation(IDApplication int NOT NULL, IDArea int NOT NULL, NewName nvarchar(255) NOT NULL, Color int NOT NULL DEFAULT -16777216);
IF OBJECT_ID('dbo.Lines','U') IS NULL
CREATE TABLE dbo.Lines(IDLine int IDENTITY PRIMARY KEY, IDArea int NOT NULL DEFAULT 1, Description nvarchar(255) NOT NULL DEFAULT N'');
IF OBJECT_ID('dbo.Boxes','U') IS NULL
CREATE TABLE dbo.Boxes(IDBox int IDENTITY PRIMARY KEY, IDApplication int NOT NULL DEFAULT 0, Line nvarchar(255) NOT NULL DEFAULT N'');
IF OBJECT_ID('dbo.Parameters','U') IS NULL
CREATE TABLE dbo.Parameters(IDParameter int IDENTITY PRIMARY KEY, IDApplication int NULL,
 Name nvarchar(255) NOT NULL, Value nvarchar(max) NOT NULL DEFAULT N'',
 Category nvarchar(255) NOT NULL DEFAULT N'', Condition nvarchar(255) NOT NULL DEFAULT N'', Description nvarchar(255) NOT NULL DEFAULT N'');
GO
IF OBJECT_ID('dbo.Batches','U') IS NULL
CREATE TABLE dbo.Batches(
 IDBatch nvarchar(255) NOT NULL PRIMARY KEY, IDApplication int NOT NULL,
 Customer nvarchar(255) NOT NULL DEFAULT N'', Job nvarchar(255) NOT NULL DEFAULT N'',
 Name nvarchar(255) NOT NULL, Status nvarchar(255) NOT NULL DEFAULT N'',
 Priority int NOT NULL DEFAULT 1, NDoc int NOT NULL DEFAULT 0, NPag int NOT NULL DEFAULT 0,
 NImg int NOT NULL DEFAULT 0, NDocExp int NOT NULL DEFAULT 0, NPagExp int NOT NULL DEFAULT 0, NImgExp int NOT NULL DEFAULT 0,
 LockUser nvarchar(255) NOT NULL DEFAULT N'', LockStation nvarchar(255) NOT NULL DEFAULT N'',
 DestUser nvarchar(255) NOT NULL DEFAULT N'', DestLine nvarchar(255) NOT NULL DEFAULT N'',
 InsDate datetime NOT NULL DEFAULT GETDATE(), InsUser nvarchar(255) NOT NULL DEFAULT N'', InsStation nvarchar(255) NOT NULL DEFAULT N'',
 ModDate datetime NULL, ModUser nvarchar(255) NOT NULL DEFAULT N'', ModStation nvarchar(255) NOT NULL DEFAULT N'',
 ExportDate datetime NULL, ExportUser nvarchar(255) NOT NULL DEFAULT N'', ExportStation nvarchar(255) NOT NULL DEFAULT N'',
 Path nvarchar(1024) NOT NULL DEFAULT N'', Note nvarchar(max) NOT NULL DEFAULT N'', Message nvarchar(max) NOT NULL DEFAULT N'',
 Box nvarchar(255) NOT NULL DEFAULT N'', Supporto nvarchar(255) NOT NULL DEFAULT N'', Dimensione nvarchar(255) NOT NULL DEFAULT N'',
 Tipologia1 nvarchar(255) NOT NULL DEFAULT N'', Tipologia2 nvarchar(255) NOT NULL DEFAULT N'',
 Tipologia3 nvarchar(255) NOT NULL DEFAULT N'', Tipologia4 nvarchar(255) NOT NULL DEFAULT N'',
 Tipologia5 nvarchar(255) NOT NULL DEFAULT N'', Tipologia6 nvarchar(255) NOT NULL DEFAULT N'',
 FromBatch nvarchar(255) NOT NULL DEFAULT N'', Inviato bit NOT NULL DEFAULT 0, Convertito bit NOT NULL DEFAULT 0,
 RowVersion rowversion NOT NULL
);
GO
IF NOT EXISTS(SELECT 1 FROM dbo.Areas WHERE IDArea=1)
INSERT dbo.Areas(IDArea,Name,Description) VALUES(1,N'REA Fixture',N'Isolated synthetic workspace');
GO
-- Empty script/field definitions let an explicitly empty job initialize.
-- No field rows are seeded: field validation still needs its own fixture.
IF OBJECT_ID('dbo.Events','U') IS NULL
CREATE TABLE dbo.Events(IDEvent int IDENTITY PRIMARY KEY, IDApplication int NOT NULL,
 Step nvarchar(255) NOT NULL DEFAULT N'', Prog int NOT NULL DEFAULT 0,
 Name nvarchar(255) NOT NULL DEFAULT N'', Script nvarchar(max) NOT NULL DEFAULT N'');
IF OBJECT_ID('dbo.Fields','U') IS NULL
CREATE TABLE dbo.Fields(IDField int IDENTITY PRIMARY KEY, IDApplication int NOT NULL,
 IDDocument int NOT NULL DEFAULT 1, Serial int NOT NULL DEFAULT 1,
 Name nvarchar(255) NOT NULL, LogField bit NOT NULL DEFAULT 0);
GO
