/**
truncate table data.transaction_lines;
truncate table data.transactions;
**/

select * from data.transaction_lines order by date_updated desc;
select * from data.transactions order by date_updated desc;

select * from data.transaction_lines_ingest;
select * from data.transactions_ingest;
