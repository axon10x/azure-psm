DECLARE @i INT, @is VARCHAR(2);

-- Location Types
INSERT INTO data.location_types (location_type_name, date_start)
VALUES ('LocType1', '1/1/1956');

INSERT INTO data.location_types (location_type_name, date_start)
VALUES ('LocType2', '1/1/1966');

INSERT INTO data.location_types (location_type_name, date_start)
VALUES ('LocType3', '1/1/1976');

-- Locations
DECLARE @location_type_id INT;
SELECT @i = 1;

WHILE (@i <= 12)
BEGIN
    SELECT @is = CASE WHEN @i < 10 THEN '0' ELSE '' END + CONVERT(VARCHAR(2), @i);

    SELECT @location_type_id = FLOOR((@i - 1) / 4) + 1;

    INSERT INTO data.locations (location_type_id, location_name, address_1, address_2, address_3, locality, postal_code, state_province, country, latitude, longitude, date_start)
    VALUES
    (
        @location_type_id,
        'loc_' + @is,
        'a1_' + @is,
        'a2_' + @is,
        'a3_' + @is,
        'loc_' + @is,
        'pc_' + @is,
        'sp_' + @is,
        'cy_' + @is,
        (-1 * @i),
        -100 + (-1 * @i),
        '1/1/2000'
    );

    SELECT  @i = @i + 1;
END

-- Stores
SELECT @i = 1;

WHILE (@i <= 12)
BEGIN
    SELECT @is = CASE WHEN @i < 10 THEN '0' ELSE '' END + CONVERT(VARCHAR(2), @i);

    INSERT INTO data.stores(location_id, store_name, date_start)
    VALUES (@i, 'Store ' + @is, '1/1/2000');

    SELECT  @i = @i + 1;
END

-- Tx Types
INSERT INTO data.tx_types (tx_type_name, date_start)
VALUES ('Purchase', '1/1/1956');

INSERT INTO data.tx_types (tx_type_name, date_start)
VALUES ('Return', '1/1/1956');

INSERT INTO data.tx_types (tx_type_name, date_start)
VALUES ('Exchange', '1/1/1956');
