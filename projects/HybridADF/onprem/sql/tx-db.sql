-- ----------------------------------------
-- Create Database

USE [master];
GO

DROP DATABASE IF EXISTS [TxDb];
GO

CREATE DATABASE [TxDb]
  ON PRIMARY 
( NAME = N'TxDb', FILENAME = N'F:\MSSQL\DATA\TxDb.mdf', SIZE = 128MB , MAXSIZE = UNLIMITED, FILEGROWTH = 128MB )
 LOG ON 
( NAME = N'TxDb_log', FILENAME = N'F:\MSSQL\DATA\TxDb_log.ldf', SIZE = 64MB , MAXSIZE = 2048GB , FILEGROWTH = 64MB )
;
GO

ALTER DATABASE [TxDb] SET RECOVERY SIMPLE;
GO
ALTER DATABASE [TxDb] SET MULTI_USER;
GO
ALTER DATABASE [TxDb] SET READ_WRITE;
GO
ALTER DATABASE [TxDb] SET QUERY_STORE = ON;
GO
-- ----------------------------------------

-- ----------------------------------------
-- Security

CREATE LOGIN SqlAdfUser1 WITH PASSWORD = N'P@ssw0rd2019!';
GO

USE [TxDb];
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

CREATE TABLE data.transactions
(
  tx_guid UNIQUEIDENTIFIER DEFAULT (newsequentialid()) NOT NULL,
  date_tx DATETIME2 DEFAULT (getutcdate()) NOT NULL,
    store_id INT NULL,
  date_created DATETIME2 DEFAULT (getutcdate()) NOT NULL,
  date_updated DATETIME2 NULL
);
GO

CREATE TABLE data.transaction_lines
(
  tx_item_guid UNIQUEIDENTIFIER DEFAULT (newsequentialid()) NOT NULL,
  tx_guid UNIQUEIDENTIFIER NULL,
  tx_type_id INT NULL,
  sku NVARCHAR(50) NULL,
  qty NUMERIC(18,5) NULL,
  unit_amt NUMERIC(18,5) NULL,
  date_created DATETIME2 DEFAULT (getutcdate()) NOT NULL,
  date_updated DATETIME2 NULL
);
GO

CREATE PROC data.save_tx
  @tx_guid UNIQUEIDENTIFIER = NULL OUTPUT,
  @store_id INT = 0
AS
BEGIN
  IF @tx_guid IS NULL
    BEGIN
      SELECT @tx_guid = newid();

      INSERT INTO data.transactions(tx_guid, store_id)
      VALUES (@tx_guid, @store_id);
    END
  ELSE
    BEGIN
      UPDATE  data.transactions
      SET    store_id = @store_id,
          date_updated = getutcdate()
      WHERE  tx_guid = @tx_guid;
    END
END
GO

CREATE PROC data.save_tx_line
  @tx_item_guid UNIQUEIDENTIFIER = NULL OUTPUT,
  @tx_guid UNIQUEIDENTIFIER = NULL,
  @tx_type_id INT = NULL,
  @sku NVARCHAR(50) = NULL,
  @qty NUMERIC(18,5) = NULL,
  @unit_amt NUMERIC(18,5) = NULL
AS
BEGIN
  IF @tx_item_guid IS NULL
    BEGIN
      SELECT @tx_item_guid = newid();

      INSERT INTO data.transaction_lines(tx_item_guid, tx_guid, tx_type_id, sku, qty, unit_amt)
      VALUES (@tx_item_guid, @tx_guid, @tx_type_id, @sku, @qty, @unit_amt);
    END
  ELSE
    BEGIN
      UPDATE  data.transaction_lines
      SET    tx_guid = @tx_guid,
          tx_type_id = @tx_type_id,
          sku = @sku,
          qty = @qty,
          unit_amt = @unit_amt,
          date_updated = getutcdate()
      WHERE  tx_item_guid = @tx_item_guid;
    END
END
GO
-- ----------------------------------------
