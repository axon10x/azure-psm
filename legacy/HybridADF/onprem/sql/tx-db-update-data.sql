/**
select * from data.transaction_lines order by date_updated desc;
select * from data.transactions order by date_updated desc;
**/

-- The following to integration-test incremental tx data pipeline

DECLARE @now datetime2;
SELECT	@now = GETUTCDATE();

DECLARE	@tx_guid_mod		UNIQUEIDENTIFIER,
		@tx_item_guid_mod	UNIQUEIDENTIFIER,
		@tx_guid_new		UNIQUEIDENTIFIER,
		@tx_item_guid_new	UNIQUEIDENTIFIER
;

SET ROWCOUNT 1;

SELECT		@tx_item_guid_mod = tx_item_guid
FROM		data.transaction_lines
ORDER BY	date_updated ASC
;

SELECT		@tx_guid_mod = tx_guid
FROM		data.transactions
ORDER BY	date_updated ASC
;

SET ROWCOUNT 0;


UPDATE	data.transaction_lines
SET		sku = sku + '_2',
		qty = 2 * qty,
		date_updated = @now
WHERE	tx_item_guid = @tx_item_guid_mod;

UPDATE	data.transactions
SET		date_tx = '11/11/2011',
		date_updated = @now
WHERE	tx_guid = @tx_guid_mod;


SELECT	@tx_item_guid_new = newid(),
		@tx_guid_new = newid();

INSERT INTO	data.transaction_lines(tx_item_guid, tx_guid, tx_type_id, sku, qty, unit_amt)
VALUES	(@tx_item_guid_new, @tx_guid_new, 11, 'this one goes to 11', 1111, 11.11);

INSERT INTO data.transactions(tx_guid, date_tx, store_id)
VALUES	(@tx_guid_new, '11/11/2011', 11);
