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
