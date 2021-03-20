/**
select * from data.location_types order by location_type_id;
select * from data.locations order by location_id;
select * from data.stores order by store_id;
select * from data.tx_types order by tx_type_id;
**/

-- The following to integration-test incremental ref data pipeline

DECLARE @now datetime2;
SELECT	@now = GETUTCDATE();

-- Location types
UPDATE	data.location_types
SET		location_type_name = location_type_name + '_2',
		date_updated = @now
WHERE	location_type_id = 1;

UPDATE	data.location_types
SET		is_deleted = 1,
		date_end = @now,
		date_updated = @now
WHERE	location_type_id = 2;

SET IDENTITY_INSERT data.location_types ON;

INSERT INTO	data.location_types (location_type_id, location_type_name, date_start)
VALUES	(2, 'LocType2 Updated', @now);

SET IDENTITY_INSERT data.location_types OFF;

-- Locations
UPDATE	data.locations
SET		location_name = location_name + '_2',
		date_updated = @now
WHERE	location_id = 7;

UPDATE	data.locations
SET		is_deleted = 1,
		date_end = @now,
		date_updated = @now
WHERE	location_id = 1;

SET IDENTITY_INSERT data.locations ON;

INSERT INTO	data.locations (location_id, location_type_id, location_name, address_1, address_2, address_3, locality, postal_code, state_province, country, latitude, longitude, date_start)
VALUES	(1, 1, 'loc_01 Updated', 'a1_01', 'a2_01', 'a3_01', 'loc_01', 'pc01', 'sp_01', 'cy_01', '-1', '-101', @now);

SET IDENTITY_INSERT data.locations OFF;

-- Stores
UPDATE	data.stores
SET		store_name = store_name + '_2',
		date_updated = @now
WHERE	store_id = 2;

UPDATE	data.stores
SET		is_deleted = 1,
		date_end = @now,
		date_updated = @now
WHERE	store_id = 4;

SET IDENTITY_INSERT data.stores ON;

INSERT INTO	data.stores (store_id, location_id, store_name, date_start)
VALUES	(4, 4, 'Store 04 Updated', @now);

SET IDENTITY_INSERT data.stores OFF;

-- Tx Types
UPDATE	data.tx_types
SET		tx_type_name = tx_type_name + '_2',
		date_updated = @now
WHERE	tx_type_id = 1;

UPDATE	data.tx_types
SET		is_deleted = 1,
		date_end = @now,
		date_updated = @now
WHERE	tx_type_id = 3;

SET IDENTITY_INSERT data.tx_types ON;

INSERT INTO	data.tx_types (tx_type_id, tx_type_name, date_start)
VALUES	(3, 'Exchange Updated', @now);

SET IDENTITY_INSERT data.tx_types OFF;