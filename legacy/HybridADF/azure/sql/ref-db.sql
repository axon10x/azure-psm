-- ----------------------------------------

ALTER DATABASE [RefDb] SET QUERY_STORE = ON;
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

CREATE TABLE data.location_types
(
    location_type_id INT NOT NULL,
    location_type_name NVARCHAR(50) NULL,
	date_start DATETIME2 NULL,
	date_end DATETIME2 NULL,
    is_deleted BIT DEFAULT 0 NOT NULL,
	date_created DATETIME2 DEFAULT (getutcdate()) NOT NULL,
	date_updated DATETIME2 NULL
);
GO

CREATE TABLE data.locations
(
    location_id INT NOT NULL,
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

CREATE TABLE data.stores
(
    store_id INT NOT NULL,
    location_id INT NULL,
    store_name NVARCHAR(50) NULL,
	date_start DATETIME2 NULL,
	date_end DATETIME2 NULL,
    is_deleted BIT DEFAULT 0 NOT NULL,
	date_created DATETIME2 DEFAULT (getutcdate()) NOT NULL,
	date_updated DATETIME2 NULL
);
GO

CREATE TABLE data.tx_types
(
    tx_type_id INT NOT NULL,
    tx_type_name NVARCHAR(50) NULL,
	date_start DATETIME2 NULL,
	date_end DATETIME2 NULL,
    is_deleted BIT DEFAULT 0 NOT NULL,
	date_created DATETIME2 DEFAULT (getutcdate()) NOT NULL,
	date_updated DATETIME2 NULL
);
GO

CREATE TABLE data.location_types_ingest
(
    location_type_id INT NOT NULL,
    location_type_name NVARCHAR(50) NULL,
	date_start DATETIME2 NULL,
	date_end DATETIME2 NULL,
    is_deleted BIT NOT NULL,
	date_created DATETIME2 NOT NULL,
	date_updated DATETIME2 NULL
);
GO

CREATE TABLE data.locations_ingest
(
    location_id INT NOT NULL,
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
    is_deleted BIT NOT NULL,
	date_created DATETIME2 NOT NULL,
	date_updated DATETIME2 NULL
);
GO

CREATE TABLE data.stores_ingest
(
    store_id INT NOT NULL,
    location_id INT NULL,
    store_name NVARCHAR(50) NULL,
	date_start DATETIME2 NULL,
	date_end DATETIME2 NULL,
    is_deleted BIT NOT NULL,
	date_created DATETIME2 NOT NULL,
	date_updated DATETIME2 NULL
);
GO

CREATE TABLE data.tx_types_ingest
(
    tx_type_id INT NOT NULL,
    tx_type_name NVARCHAR(50) NULL,
	date_start DATETIME2 NULL,
	date_end DATETIME2 NULL,
    is_deleted BIT NOT NULL,
	date_created DATETIME2 NOT NULL,
	date_updated DATETIME2 NULL
);
GO





CREATE PROC data.prep_ingest_full
AS
BEGIN
	-- Could also use the more efficient TRUNCATE TABLE if the executing identity has appropriate privileges

	DELETE FROM data.location_types;
	DELETE FROM data.locations;
	DELETE FROM data.stores;
	DELETE FROM data.tx_types;
END
GO

CREATE PROC data.get_location_types_max_date
AS
BEGIN
	DECLARE	@max_date_created DATETIME2,
			@max_date_updated DATETIME2;

	SELECT	@max_date_created = max(date_created),
			@max_date_updated = max(date_updated)
	FROM	data.location_types;

	SELECT	max_date = CASE WHEN @max_date_created >= @max_date_updated OR @max_date_updated IS NULL THEN @max_date_created ELSE @max_date_updated END;
END
GO

CREATE PROC data.get_locations_max_date
AS
BEGIN
	DECLARE	@max_date_created DATETIME2,
			@max_date_updated DATETIME2;

	SELECT	@max_date_created = max(date_created),
			@max_date_updated = max(date_updated)
	FROM	data.locations;

	SELECT	max_date = CASE WHEN @max_date_created >= @max_date_updated OR @max_date_updated IS NULL THEN @max_date_created ELSE @max_date_updated END;
END
GO

CREATE PROC data.get_stores_max_date
AS
BEGIN
	DECLARE	@max_date_created DATETIME2,
			@max_date_updated DATETIME2;

	SELECT	@max_date_created = max(date_created),
			@max_date_updated = max(date_updated)
	FROM	data.stores;

	SELECT	max_date = CASE WHEN @max_date_created >= @max_date_updated OR @max_date_updated IS NULL THEN @max_date_created ELSE @max_date_updated END;
END
GO

CREATE PROC data.get_tx_types_max_date
AS
BEGIN
	DECLARE	@max_date_created DATETIME2,
			@max_date_updated DATETIME2;

	SELECT	@max_date_created = max(date_created),
			@max_date_updated = max(date_updated)
	FROM	data.tx_types;

	SELECT	max_date = CASE WHEN @max_date_created >= @max_date_updated OR @max_date_updated IS NULL THEN @max_date_created ELSE @max_date_updated END;
END
GO

CREATE PROC data.ingest_location_types
AS
BEGIN
	-- SCD2 so check equality on both ID and date_created since may have multiple records with same ID

	-- Handle existing records that were updated.
	UPDATE
		data.location_types
	SET
		location_type_id = i.location_type_id,
		location_type_name = i.location_type_name,
		date_start = i.date_start,
		date_end = i.date_end,
		is_deleted = i.is_deleted,
		date_created = i.date_created,
		date_updated = i.date_updated
	FROM
		data.location_types_ingest i
		INNER JOIN data.location_types t ON i.location_type_id = t.location_type_id AND i.date_created = t.date_created
	WHERE
		t.location_type_id = i.location_type_id AND
		t.date_created = i.date_created
	;

	-- Handle new records
	INSERT INTO
		data.location_types
		(
			location_type_id,
			location_type_name,
			date_start,
			date_end,
			is_deleted,
			date_created,
			date_updated
		)
	SELECT
		i.location_type_id,
		i.location_type_name,
		i.date_start,
		i.date_end,
		i.is_deleted,
		i.date_created,
		i.date_updated
	FROM
		data.location_types_ingest i
		LEFT OUTER JOIN data.location_types t ON i.location_type_id = t.location_type_id AND i.date_created = t.date_created
	WHERE
		t.location_type_id IS NULL
	;

	-- Clean out records that are now in the main table
	DELETE FROM
		data.location_types_ingest
	WHERE
		location_type_id IN
		(
			SELECT
				t.location_type_id
			FROM
				data.location_types_ingest i
				INNER JOIN data.location_types t on i.location_type_id = t.location_type_id AND i.date_created = t.date_created
		)
	;
END
GO

CREATE PROC data.ingest_locations
AS
BEGIN
	-- SCD2 so check equality on both ID and date_created since may have multiple records with same ID

	-- Handle existing records that were updated.
	UPDATE
		data.locations
	SET
		location_id = i.location_id,
		location_type_id = i.location_type_id,
		location_name = i.location_name,
		address_1 = i.address_1,
		address_2 = i.address_2,
		address_3 = i.address_3,
		locality = i.locality,
		postal_code = i.postal_code,
		state_province = i.state_province,
		country = i.country,
		latitude = i.latitude,
		longitude = i.longitude,
		date_start = i.date_start,
		date_end = i.date_end,
		is_deleted = i.is_deleted,
		date_created = i.date_created,
		date_updated = i.date_updated
	FROM
		data.locations_ingest i
		INNER JOIN data.locations t ON i.location_id = t.location_id AND i.date_created = t.date_created
	WHERE
		t.location_id = i.location_id AND
		t.date_created = i.date_created
	;

	-- Handle new records
	INSERT INTO
		data.locations
		(
			location_id,
			location_type_id,
			location_name,
			address_1,
			address_2,
			address_3,
			locality,
			postal_code,
			state_province,
			country,
			latitude,
			longitude,
			date_start,
			date_end,
			is_deleted,
			date_created,
			date_updated
		)
	SELECT
		i.location_id,
		i.location_type_id,
		i.location_name,
		i.address_1,
		i.address_2,
		i.address_3,
		i.locality,
		i.postal_code,
		i.state_province,
		i.country,
		i.latitude,
		i.longitude,
		i.date_start,
		i.date_end,
		i.is_deleted,
		i.date_created,
		i.date_updated
	FROM
		data.locations_ingest i
		LEFT OUTER JOIN data.locations t ON i.location_id = t.location_id AND i.date_created = t.date_created
	WHERE
		t.location_id IS NULL
	;

	-- Clean out records that are now in the main table
	DELETE FROM
		data.locations_ingest
	WHERE
		location_id IN
		(
			SELECT
				t.location_id
			FROM
				data.locations_ingest i
				INNER JOIN data.locations t on i.location_id = t.location_id AND i.date_created = t.date_created
		)
	;
END
GO

CREATE PROC data.ingest_stores
AS
BEGIN
	-- SCD2 so check equality on both ID and date_created since may have multiple records with same ID

	-- Handle existing records that were updated.
	UPDATE
		data.stores
	SET
		store_id = i.store_id,
		location_id = i.location_id,
		store_name = i.store_name,
		date_start = i.date_start,
		date_end = i.date_end,
		is_deleted = i.is_deleted,
		date_created = i.date_created,
		date_updated = i.date_updated
	FROM
		data.stores_ingest i
		INNER JOIN data.stores t ON i.store_id = t.store_id AND i.date_created = t.date_created
	WHERE
		t.store_id = i.store_id AND
		t.date_created = i.date_created
	;

	-- Handle new records
	INSERT INTO
		data.stores
		(
			store_id,
			location_id,
			store_name,
			date_start,
			date_end,
			is_deleted,
			date_created,
			date_updated
		)
	SELECT
		i.store_id,
		i.location_id,
		i.store_name,
		i.date_start,
		i.date_end,
		i.is_deleted,
		i.date_created,
		i.date_updated
	FROM
		data.stores_ingest i
		LEFT OUTER JOIN data.stores t ON i.store_id = t.store_id AND i.date_created = t.date_created
	WHERE
		t.store_id IS NULL
	;

	-- Clean out records that are now in the main table
	DELETE FROM
		data.stores_ingest
	WHERE
		store_id IN
		(
			SELECT
				t.store_id
			FROM
				data.stores_ingest i
				INNER JOIN data.stores t on i.store_id = t.store_id AND i.date_created = t.date_created
		)
	;
END
GO

CREATE PROC data.ingest_tx_types
AS
BEGIN
	-- SCD2 so check equality on both ID and date_created since may have multiple records with same ID

	-- Handle existing records that were updated.
	UPDATE
		data.tx_types
	SET
		tx_type_id = i.tx_type_id,
		tx_type_name = i.tx_type_name,
		date_start = i.date_start,
		date_end = i.date_end,
		is_deleted = i.is_deleted,
		date_created = i.date_created,
		date_updated = i.date_updated
	FROM
		data.tx_types_ingest i
		INNER JOIN data.tx_types t ON i.tx_type_id = t.tx_type_id AND i.date_created = t.date_created
	WHERE
		t.tx_type_id = i.tx_type_id AND
		t.date_created = i.date_created
	;

	-- Handle new records
	INSERT INTO
		data.tx_types
		(
			tx_type_id,
			tx_type_name,
			date_start,
			date_end,
			is_deleted,
			date_created,
			date_updated
		)
	SELECT
		i.tx_type_id,
		i.tx_type_name,
		i.date_start,
		i.date_end,
		i.is_deleted,
		i.date_created,
		i.date_updated
	FROM
		data.tx_types_ingest i
		LEFT OUTER JOIN data.tx_types t ON i.tx_type_id = t.tx_type_id AND i.date_created = t.date_created
	WHERE
		t.tx_type_id IS NULL
	;

	-- Clean out records that are now in the main table
	DELETE FROM
		data.tx_types_ingest
	WHERE
		tx_type_id IN
		(
			SELECT
				t.tx_type_id
			FROM
				data.tx_types_ingest i
				INNER JOIN data.tx_types t on i.tx_type_id = t.tx_type_id AND i.date_created = t.date_created
		)
	;
END
GO


-- ----------------------------------------
