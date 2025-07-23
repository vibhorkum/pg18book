-- =================================================================
--  PSQL SCRIPT FOR SETTING UP LOGICAL REPLICATION
--  Publisher: ecommerce_reference_data
--  Subscriber: us_ecommerce_data
-- =================================================================

-- Step 0: Define variables for easier maintenance
\set publisher_db 'ecommerce_reference_data'
\set subscriber_db1 'us_ecommerce_data'
\set subscriber_db2 'eu_ecommerce_data'

\set publisher_conn_string 'host=localhost port=5432 dbname=ecommerce_reference_data'

\set sub_slot_1 'us_product_reference_data_sub'
\set sub_slot_2 'eu_product_reference_data_sub'

\echo '*** Replication Setup Script Started ***'

-- =================================================================
--  Step 1: Configure the Publisher Database (:publisher_db)
-- =================================================================
\c :publisher_db
\echo 'Connected to publisher database ->' :publisher_db

\echo '--> Dropping old publications if they exist...'
DROP PUBLICATION IF EXISTS us_product_reference_publication;
DROP PUBLICATION IF EXISTS eu_product_reference_publication;

-- publishing the reference data to us_ecommerce

\echo '--> Creating the US publication for product reference tables...'
CREATE PUBLICATION us_product_publication
    FOR TABLE 
        product_reference.product_category, 
        product_reference.product_brand, 
        product_reference.product, 
        --- send only rows that pertain to the US and are currently active
        product_reference.product_price WHERE (geography = 'US' AND current = true);

\echo '--> Creating the EU publication for product reference tables...'
CREATE PUBLICATION eu_product_publication
    FOR TABLE 
        product_reference.product_category, 
        product_reference.product_brand, 
        product_reference.product, 
        --- send only rows that pertain to the US and are currently active
        product_reference.product_price WHERE (geography = 'EU' AND current = true);

\echo '--> Verification: Listing tables in publications...'
SELECT pubname, schemaname, tablename FROM pg_publication_tables;

-- =================================================================
--  Step 2: Configure the Subscriber Database (:subscriber_db)
-- =================================================================
\c :subscriber_db1

\echo 'Connected to subscriber database ->' :subscriber_db1

\echo '--> Dropping old subscriptions if they exist...'
DROP SUBSCRIPTION IF EXISTS :sub_slot_1;

\echo '--> Creating subscription for core reference data...'
CREATE SUBSCRIPTION :sub_slot_1
    CONNECTION :'publisher_conn_string'
    PUBLICATION us_product_publication
    WITH (connect = false); -- connect=false is essential for same-server setup

\c :subscriber_db2

\echo 'Connected to subscriber database ->' :subscriber_db2

\echo '--> Dropping old subscriptions if they exist...'
DROP SUBSCRIPTION IF EXISTS :sub_slot_2;

\echo '--> Creating subscription for core reference data...'
CREATE SUBSCRIPTION :sub_slot_2
    CONNECTION :'publisher_conn_string'
    PUBLICATION eu_product_publication
    WITH (connect = false); -- connect=false is essential for same-server setup

-- =================================================================
--  Step 3: Manually Create Replication Slots on the Publisher
-- =================================================================
\c :publisher_db

SET vars.slot_1 TO :'sub_slot_1';
SET vars.slot_2 TO :'sub_slot_2';

\echo 'Connected back to publisher to manage replication slots...'

-- Conditionally create the first slot to avoid errors on re-runs
DO $$
DECLARE
  sub_slot_1 TEXT := current_setting('vars.slot_1');
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name = sub_slot_1) THEN
        RAISE NOTICE '--> Creating replication slot: %', sub_slot_1;
        PERFORM pg_create_logical_replication_slot(sub_slot_1, 'pgoutput');
    ELSE
        RAISE NOTICE '--> Replication slot % already exists. Skipping creation.', sub_slot_1;
    END IF;
END$$;

-- Conditionally create the second slot to avoid errors on re-runs
DO $$
DECLARE
  sub_slot_2 TEXT := current_setting('vars.slot_2');
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name = sub_slot_2) THEN
        RAISE NOTICE '--> Creating replication slot: %', sub_slot_2;
        PERFORM pg_create_logical_replication_slot(sub_slot_2, 'pgoutput');
    ELSE
        RAISE NOTICE '--> Replication slot % already exists. Skipping creation.', sub_slot_2;
    END IF;
END$$;
-- =================================================================
--  Step 4: Enable and Refresh Subscriptions on the Subscriber
-- =================================================================
\c :subscriber_db1
\echo 'Connected back to subscriber to enable and refresh data on ' :subscriber_db1

\echo '--> Enabling and refreshing subscription:' :'sub_slot_1'
ALTER SUBSCRIPTION :sub_slot_1 ENABLE;
ALTER SUBSCRIPTION :sub_slot_1 REFRESH PUBLICATION;


\c :subscriber_db2
\echo 'Connected back to subscriber to enable and refresh data on ' :subscriber_db2

\echo '--> Enabling and refreshing subscription:' :'sub_slot_2'
ALTER SUBSCRIPTION :sub_slot_2 ENABLE;
ALTER SUBSCRIPTION :sub_slot_2 REFRESH PUBLICATION;

\echo '*** Script Finished Successfully ***'
