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
IF OBJECT_ID(N'dbo.UsersUsersProfilesMatch', N'U') IS NULL
CREATE TABLE dbo.UsersUsersProfilesMatch (
    IDUser int NOT NULL REFERENCES dbo.Users(IDUser),
    IDProfile int NOT NULL REFERENCES dbo.UserProfiles(IDUserProfile),
    Validity_From datetime NOT NULL DEFAULT '20000101',
    Validity_To datetime NOT NULL DEFAULT '20991231',
    CONSTRAINT PK_CoreReaUserProfile PRIMARY KEY(IDUser, IDProfile)
);
GO
