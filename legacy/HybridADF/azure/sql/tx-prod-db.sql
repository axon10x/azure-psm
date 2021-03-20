-- ----------------------------------------
-- Create Database

ALTER DATABASE [TxProdDb] SET QUERY_STORE = ON;
GO

-- ----------------------------------------

-- ----------------------------------------
-- Security

CREATE SCHEMA [data];
GO

CREATE ROLE [ADFRole];
GO

GRANT EXECUTE, SELECT, UPDATE, INSERT, DELETE ON SCHEMA :: [data] TO [ADFRole];
GO
ALTER ROLE [db_datareader] ADD MEMBER [ADFRole];
ALTER ROLE [db_datawriter] ADD MEMBER [ADFRole];
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

CREATE TABLE data.transactions_ingest
(
	tx_guid UNIQUEIDENTIFIER NOT NULL,
	date_tx DATETIME2 NOT NULL,
    store_id INT NULL,
	date_created DATETIME2 NOT NULL,
	date_updated DATETIME2 NULL
);
GO

CREATE TABLE data.transaction_lines_ingest
(
	tx_item_guid UNIQUEIDENTIFIER NOT NULL,
	tx_guid UNIQUEIDENTIFIER NULL,
	tx_type_id INT NULL,
	sku NVARCHAR(50) NULL,
	qty NUMERIC(18,5) NULL,
	unit_amt NUMERIC(18,5) NULL,
	date_created DATETIME2 NOT NULL,
	date_updated DATETIME2 NULL
);
GO


CREATE PROC [data].[prep_ingest_full]
AS
BEGIN
	DELETE FROM data.transactions;
	DELETE FROM data.transaction_lines;
END
GO

CREATE PROC data.get_tx_lines_max_date
AS
BEGIN
	DECLARE	@max_date_created DATETIME2,
			@max_date_updated DATETIME2;

	SELECT	@max_date_created = max(date_created),
			@max_date_updated = max(date_updated)
	FROM	data.transaction_lines;

	SELECT	max_date = CASE WHEN @max_date_created >= @max_date_updated OR @max_date_updated IS NULL THEN @max_date_created ELSE @max_date_updated END;
END
GO

CREATE PROC data.ingest_tx_lines
AS
BEGIN
	-- Handle existing records that were updated
	UPDATE
		data.transaction_lines
	SET
		tx_guid = i.tx_guid,
		tx_type_id = i.tx_type_id,
		sku = i.sku,
		qty = i.qty,
		unit_amt = i.unit_amt,
		date_created = i.date_created,
		date_updated = i.date_updated
	FROM
		data.transaction_lines_ingest i
		INNER JOIN data.transaction_lines t ON i.tx_item_guid = t.tx_item_guid
	WHERE
		t.tx_item_guid = i.tx_item_guid
	;

	-- Handle new records
	INSERT INTO
		data.transaction_lines
		(
			tx_item_guid,
			tx_guid,
			tx_type_id,
			sku,
			qty,
			unit_amt,
			date_created,
			date_updated
		)
	SELECT
		i.tx_item_guid,
		i.tx_guid,
		i.tx_type_id,
		i.sku,
		i.qty,
		i.unit_amt,
		i.date_created,
		i.date_updated
	FROM
		data.transaction_lines_ingest i
		LEFT OUTER JOIN  data.transaction_lines t ON i.tx_item_guid = t.tx_item_guid
	WHERE
		t.tx_item_guid IS NULL
	;

	-- Clean out records that are now in the main table
	DELETE FROM
		data.transaction_lines_ingest
	WHERE
		tx_item_guid IN
		(
			SELECT
				t.tx_item_guid
			FROM
				data.transaction_lines_ingest i
				INNER JOIN data.transaction_lines t on i.tx_item_guid = t.tx_item_guid
		)
	;
END
GO

CREATE PROC data.ingest_txs
AS
BEGIN
	-- Handle existing records that were updated
	UPDATE
		data.transactions
	SET
		date_tx = i.date_tx,
		store_id = i.store_id,
		date_created = i.date_created,
		date_updated = i.date_updated
	FROM
		data.transactions_ingest i
		INNER JOIN data.transactions t ON i.tx_guid = t.tx_guid
	WHERE
		t.tx_guid = i.tx_guid
	;

	-- Handle new records
	INSERT INTO
		data.transactions
		(
			tx_guid,
			date_tx,
			store_id,
			date_created,
			date_updated
		)
	SELECT
		i.tx_guid,
		i.date_tx,
		i.store_id,
		i.date_created,
		i.date_updated
	FROM
		data.transactions_ingest i
		LEFT OUTER JOIN  data.transactions t ON i.tx_guid = t.tx_guid
	WHERE
		t.tx_guid IS NULL
	;

	-- Clean out records that are now in the main table
	DELETE FROM
		data.transactions_ingest
	WHERE
		tx_guid IN
		(
			SELECT
				t.tx_guid
			FROM
				data.transactions_ingest i
				INNER JOIN data.transactions t on i.tx_guid = t.tx_guid
		)
	;
END
GO

CREATE PROC data.get_txs_max_date
AS
BEGIN
	DECLARE	@max_date_created DATETIME2,
			@max_date_updated DATETIME2;

	SELECT	@max_date_created = max(date_created),
			@max_date_updated = max(date_updated)
	FROM	data.transaction_lines;

	SELECT	max_date = CASE WHEN @max_date_created >= @max_date_updated OR @max_date_updated IS NULL THEN @max_date_created ELSE @max_date_updated END;
END
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
			UPDATE	data.transactions
			SET		store_id = @store_id,
					date_updated = getutcdate()
			WHERE	tx_guid = @tx_guid;
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
			UPDATE	data.transaction_lines
			SET		tx_guid = @tx_guid,
					tx_type_id = @tx_type_id,
					sku = @sku,
					qty = @qty,
					unit_amt = @unit_amt,
					date_updated = getutcdate()
			WHERE	tx_item_guid = @tx_item_guid;
		END
END
GO
-- ----------------------------------------
