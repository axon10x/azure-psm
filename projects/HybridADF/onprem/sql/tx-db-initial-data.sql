DECLARE	@istore INT, @itx INT, @tx_guid UNIQUEIDENTIFIER, @tx_type_id INT, @sku NVARCHAR(50), @qty NUMERIC(18,5), @unit_amt NUMERIC(18,5);
SELECT @istore = 1;

WHILE @istore <= 12
BEGIN
	SELECT @itx = 1;

	WHILE @itx <= 100
	BEGIN
		EXEC data.save_tx @tx_guid OUTPUT, @istore;

		SELECT	@tx_type_id = 1,
				@sku = CONVERT(NVARCHAR(50), @itx % 6),
				@qty = @itx,
				@unit_amt = @itx / 10
		;

		EXEC data.save_tx_line NULL, @tx_guid, @tx_type_id, @sku, @qty, @unit_amt;

		SELECT	@tx_guid = NULL,
				@itx = @itx + 1;
	END

	SELECT @itx = 1;

	WHILE @itx <= 10
	BEGIN
		EXEC data.save_tx @tx_guid OUTPUT, @istore;

		SELECT	@tx_type_id = 2,
				@sku = CONVERT(NVARCHAR(50), @itx % 7),
				@qty = @itx,
				@unit_amt = @itx / 10
		;

		EXEC data.save_tx_line NULL, @tx_guid, @tx_type_id, @sku, @qty, @unit_amt;

		SELECT	@tx_guid = NULL,
				@itx = @itx + 1;
	END

	SELECT @itx = 1;

	WHILE @itx <= 7
	BEGIN
		EXEC data.save_tx @tx_guid OUTPUT, @istore;

		SELECT	@tx_type_id = 3,
				@sku = CONVERT(NVARCHAR(50), @itx % 3),
				@qty = @itx,
				@unit_amt = @itx / 10
		;

		EXEC data.save_tx_line NULL, @tx_guid, @tx_type_id, @sku, @qty, @unit_amt;

		SELECT	@tx_guid = NULL,
				@itx = @itx + 1;
	END

	SELECT @istore = @istore + 1;
END