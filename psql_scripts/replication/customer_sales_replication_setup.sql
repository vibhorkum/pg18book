/*
Create the replication of the customers and sales data from east and west ecommerce
site to central analytics

*/

-- ================================================================================
--  Step 1: Create the customer and sales publication on east/west_ecommercedata
-- ================================================================================

\set publisher_db2 'west_ecommerce_data'
\set publisher_db3 'east_ecommerce_data'

\set subscriber_db4 'central_analytics'

-- this needs to change
\set publisher_conn_string2 'host=localhost port=5432 dbname=west_ecommerce_data user=postgres password=postgres'
\set publisher_conn_string3 'host=localhost port=5432 dbname=east_ecommerce_data user=postgres password=postgres'

\set sub_slot_4 'west_customer_sales_data_sub'
\set sub_slot_5 'east_customer_sales_data_sub'

\c :publisher_db2
\echo 'Connected to publisher database ->' :publisher_db2

\echo '--> Dropping old publications if they exist...'
DROP PUBLICATION IF EXISTS west_customer_sales_publication;

-- publishing the east/west sales and customer data to central analytics

\echo '--> Creating the west publication for customers amd sales tables...'
CREATE PUBLICATION west_customer_sales_publication
    FOR TABLE 
        west_customer.customer, 
        west_sales.sales_transaction, 
        west_sales.sales_transaction_line;


\c :publisher_db3
\echo 'Connected to publisher database ->' :publisher_db3

\echo '--> Dropping old publications if they exist...'
DROP PUBLICATION IF EXISTS east_customer_sales_publication;

-- publishing the east sales and customer data to central analytics

\echo '--> Creating the east publication for customers amd sales tables...'
CREATE PUBLICATION east_customer_sales_publication
    FOR TABLE 
        east_customer.customer, 
        east_sales.sales_transaction, 
        east_sales.sales_transaction_line;     

-- ================================================================================
--  Step 2: Create the customer and sales subscriptions on central analytics
-- ================================================================================

\c :subscriber_db4

\echo 'Connected to subscriber database ->' :subscriber_db4

\echo '--> Dropping old subscriptions if they exist...'
DROP SUBSCRIPTION IF EXISTS :sub_slot_4;

\echo '--> Creating subscription for core reference data...'
CREATE SUBSCRIPTION :sub_slot_4
    CONNECTION :'publisher_conn_string2'
    PUBLICATION west_customer_sales_publication
    WITH (connect = false); -- connect=false is essential for same-server setup


\echo '--> Dropping old subscriptions if they exist...'
DROP SUBSCRIPTION IF EXISTS :sub_slot_5;

\echo '--> Creating subscription for core reference data...'
CREATE SUBSCRIPTION :sub_slot_5
    CONNECTION :'publisher_conn_string3'
    PUBLICATION east_customer_sales_publication
    WITH (connect = false); -- connect=false is essential for same-server setup


-- =================================================================
--  Step 3: Create Replication Slots on the east/west_ecommerce_data
-- =================================================================
\c :publisher_db2

SET vars.slot_4 TO :'sub_slot_4';

\echo 'Connected back to publisher to manage replication slots...'

-- Conditionally create the  slot to avoid errors on re-runs
DO $$
DECLARE
  sub_slot_4 TEXT := current_setting('vars.slot_4');
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name = sub_slot_4) THEN
        RAISE NOTICE '--> Creating replication slot: %', sub_slot_4;
        PERFORM pg_create_logical_replication_slot(sub_slot_4, 'pgoutput');
    ELSE
        RAISE NOTICE '--> Replication slot % already exists. Skipping creation.', sub_slot_4;
    END IF;
END$$;


\c :publisher_db3
SET vars.slot_5 TO :'sub_slot_5';

\echo 'Connected back to publisher % to manage replication slots' , :publisher_db3

-- Conditionally create the  slot to avoid errors on re-runs
DO $$
DECLARE
  sub_slot_5 TEXT := current_setting('vars.slot_5');
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name = sub_slot_5) THEN
        RAISE NOTICE '--> Creating replication slot: %', sub_slot_5;
        PERFORM pg_create_logical_replication_slot(sub_slot_5, 'pgoutput');
    ELSE
        RAISE NOTICE '--> Replication slot % already exists. Skipping creation.', sub_slot_5;
    END IF;
END$$;

-- ================================================================================
--  Step 4: Enable and Refresh the customer sales transaction on Subscriber
-- ================================================================================
\c :subscriber_db4
\echo 'Connected back to subscriber to enable and refresh data on ' :subscriber_db4

\echo '--> Enabling and refreshing subscription:' :'sub_slot_4'
ALTER SUBSCRIPTION :sub_slot_4 ENABLE;
ALTER SUBSCRIPTION :sub_slot_4 REFRESH PUBLICATION;

\echo '--> Enabling and refreshing subscription:' :'sub_slot_5'
ALTER SUBSCRIPTION :sub_slot_5 ENABLE;
ALTER SUBSCRIPTION :sub_slot_5 REFRESH PUBLICATION;
