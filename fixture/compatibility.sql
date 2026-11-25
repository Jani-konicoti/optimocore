-- Upgrade both historical fixture shapes without replacing any table or data.
USE CoreReaFixture;
GO
IF COL_LENGTH('dbo.Areas','Name') IS NULL ALTER TABLE dbo.Areas ADD Name nvarchar(255) NOT NULL DEFAULT N'';
IF COL_LENGTH('dbo.Areas','Description') IS NULL ALTER TABLE dbo.Areas ADD Description nvarchar(255) NOT NULL DEFAULT N'';
IF COL_LENGTH('dbo.Applications','DataValidationReleaseProcess') IS NULL ALTER TABLE dbo.Applications ADD DataValidationReleaseProcess nvarchar(255) NOT NULL DEFAULT N'';
IF COL_LENGTH('dbo.Applications','DataValidationLocalReleaseProcess') IS NULL ALTER TABLE dbo.Applications ADD DataValidationLocalReleaseProcess nvarchar(255) NOT NULL DEFAULT N'';
IF COL_LENGTH('dbo.Applications','DoubleDataEntry') IS NULL ALTER TABLE dbo.Applications ADD DoubleDataEntry bit NOT NULL DEFAULT 0;
IF COL_LENGTH('dbo.Applications','DuplicateRecordShiftEnter') IS NULL ALTER TABLE dbo.Applications ADD DuplicateRecordShiftEnter bit NOT NULL DEFAULT 0;
IF COL_LENGTH('dbo.Applications','DuplicateImageWhenSplitRecord') IS NULL ALTER TABLE dbo.Applications ADD DuplicateImageWhenSplitRecord bit NOT NULL DEFAULT 0;
IF COL_LENGTH('dbo.Applications','GoToWrong') IS NULL ALTER TABLE dbo.Applications ADD GoToWrong bit NOT NULL DEFAULT 1;
IF COL_LENGTH('dbo.Applications','StartWithThumbs') IS NULL ALTER TABLE dbo.Applications ADD StartWithThumbs bit NOT NULL DEFAULT 0;
IF COL_LENGTH('dbo.Process','Prog') IS NULL ALTER TABLE dbo.Process ADD Prog int NOT NULL DEFAULT 1;
IF COL_LENGTH('dbo.Process','Start') IS NULL ALTER TABLE dbo.Process ADD [Start] nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH('dbo.Process','Start0') IS NULL ALTER TABLE dbo.Process ADD Start0 nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH('dbo.Process','Exe') IS NULL ALTER TABLE dbo.Process ADD Exe nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH('dbo.Process','EndInt') IS NULL ALTER TABLE dbo.Process ADD EndInt nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH('dbo.Process','EndErr') IS NULL ALTER TABLE dbo.Process ADD EndErr nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH('dbo.Process','EndCor') IS NULL ALTER TABLE dbo.Process ADD EndCor nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH('dbo.Process','EndFai') IS NULL ALTER TABLE dbo.Process ADD EndFai nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH('dbo.Process','EndFor') IS NULL ALTER TABLE dbo.Process ADD EndFor nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH('dbo.Process','Parameters') IS NULL ALTER TABLE dbo.Process ADD Parameters nvarchar(max) NOT NULL DEFAULT N'';
IF COL_LENGTH('dbo.Batches','DestUser') IS NULL ALTER TABLE dbo.Batches ADD DestUser nvarchar(128) NOT NULL DEFAULT N'';
IF COL_LENGTH('dbo.Batches','FromBatch') IS NULL ALTER TABLE dbo.Batches ADD FromBatch nvarchar(128) NOT NULL DEFAULT N'';
GO
