-- ----------------------------------------
-- Create Database

USE [master];
GO

DROP DATABASE IF EXISTS [RefDb];
GO

CREATE DATABASE [RefDb]
  ON PRIMARY 
( NAME = N'RefDb', FILENAME = N'F:\MSSQL\DATA\RefDb.mdf', SIZE = 128MB , MAXSIZE = UNLIMITED, FILEGROWTH = 128MB )
 LOG ON 
( NAME = N'RefDb_log', FILENAME = N'F:\MSSQL\DATA\RefDb_log.ldf', SIZE = 64MB , MAXSIZE = 2048GB , FILEGROWTH = 64MB )
;
GO

ALTER DATABASE [RefDb] SET RECOVERY SIMPLE;
GO
ALTER DATABASE [RefDb] SET MULTI_USER;
GO
ALTER DATABASE [RefDb] SET READ_WRITE;
GO
ALTER DATABASE [RefDb] SET QUERY_STORE = ON;
GO
-- ----------------------------------------

-- ----------------------------------------
-- Security

CREATE LOGIN SqlAdfUser1 WITH PASSWORD = N'P@ssw0rd2019!';
GO

USE [RefDb];
GO

CREATE SCHEMA [data];
GO

CREATE ROLE [ADFRole];
GO

-- Can add Windows/AD principals here - they must already be associated to server logins unless contained authentication is used
-- CREATE USER [GroupLogin] FOR LOGIN [DOMAIN\Group];
-- GO
-- ALTER ROLE [ADFRole] ADD MEMBER [GroupLogin];
-- GO

CREATE USER SqlAdfUser1 FOR LOGIN SqlAdfUser1 WITH DEFAULT_SCHEMA=[data];
GO
ALTER ROLE [ADFRole] ADD MEMBER [SqlAdfUser1];
GO

GRANT EXECUTE, SELECT ON SCHEMA :: [data] TO [ADFRole];
GO

-- ----------------------------------------

-- ----------------------------------------
-- DDL/DML

CREATE TABLE data.stores
(
    store_id INT IDENTITY(1, 1) NOT NULL,
    location_id INT NULL,
    store_name NVARCHAR(50) NULL,
  date_start DATETIME2 NULL,
  date_end DATETIME2 NULL,
    is_deleted BIT DEFAULT 0 NOT NULL,
  date_created DATETIME2 DEFAULT (getutcdate()) NOT NULL,
  date_updated DATETIME2 NULL
);
GO

CREATE TABLE data.locations
(
    location_id INT IDENTITY(1, 1) NOT NULL,
    location_type_id INT NULL,
    location_name NVARCHAR(50) NULL,
    address_1 NVARCHAR(50) NULL,
    address_2 NVARCHAR(50) NULL,
    address_3 NVARCHAR(50) NULL,
    locality NVARCHAR(50) NULL,
    postal_code NVARCHAR(50) NULL,
    state_province NVARCHAR(50) NULL,
    country NVARCHAR(50) NULL,
    latitude NUMERIC(18,8) NULL,
    longitude NUMERIC(18,8) NULL,
  date_start DATETIME2 NULL,
  date_end DATETIME2 NULL,
    is_deleted BIT DEFAULT 0 NOT NULL,
  date_created DATETIME2 DEFAULT (getutcdate()) NOT NULL,
  date_updated DATETIME2 NULL
);
GO

CREATE TABLE data.location_types
(
    location_type_id INT IDENTITY(1, 1) NOT NULL,
    location_type_name NVARCHAR(50) NULL,
  date_start DATETIME2 NULL,
  date_end DATETIME2 NULL,
    is_deleted BIT DEFAULT 0 NOT NULL,
  date_created DATETIME2 DEFAULT (getutcdate()) NOT NULL,
  date_updated DATETIME2 NULL
);
GO

CREATE TABLE data.tx_types
(
    tx_type_id INT IDENTITY(1, 1) NOT NULL,
    tx_type_name NVARCHAR(50) NULL,
  date_start DATETIME2 NULL,
  date_end DATETIME2 NULL,
    is_deleted BIT DEFAULT 0 NOT NULL,
  date_created DATETIME2 DEFAULT (getutcdate()) NOT NULL,
  date_updated DATETIME2 NULL
);
GO

-- ----------------------------------------
