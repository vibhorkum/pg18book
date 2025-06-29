-- =================================================================
--  PSQL SCRIPT FOR SETTING UP LOGICAL REPLICATION
--  Publisher: ecommerce_reference_data
--  Subscriber: us_ecommerce_data
-- =================================================================

-- Step 0: Define variables for easier maintenance
\set publisher_db 'ecommerce_reference_data'
\set subscriber_db 'us_ecommerce_data'
\set publisher_conn_string 'host=localhost port=5432 dbname=ecommerce_reference_data'
\set sub_slot_1 'us_reference_data_sub'
\set sub_slot_2 'us_product_variant_price_sub'

\echo '*** Script Started ***'

-- =================================================================
--  Step 1: Configure the Publisher Database (:publisher_db)
-- =================================================================
\c :publisher_db
\echo 'Connected to publisher database ->' :publisher_db

-- Use a transaction to ensure both publications are created or neither are.
BEGIN;

\echo '--> Dropping old publications if they exist...'
DROP PUBLICATION IF EXISTS us_product_publication;
DROP PUBLICATION IF EXISTS us_product_variant_price_publication;

\echo '--> Creating publication for core product tables...'
CREATE PUBLICATION us_product_publication
    FOR TABLE product_category, product_brand, product, product_variant;

\echo '--> Creating publication for row-filtered US product variant prices...'
CREATE PUBLICATION us_product_variant_price_publication
    FOR TABLE product_variant_price
    WHERE (geography = 'US' AND current = true);

COMMIT;

\echo '--> Verification: Listing tables in publications...'
SELECT pubname, schemaname, tablename FROM pg_publication_tables;

-- =================================================================
--  Step 2: Configure the Subscriber Database (:subscriber_db)
-- =================================================================
\c :subscriber_db

\echo 'Connected to subscriber database ->' :subscriber_db


\echo '--> Dropping old subscriptions if they exist...'
DROP SUBSCRIPTION IF EXISTS :sub_slot_1;
DROP SUBSCRIPTION IF EXISTS :sub_slot_2;

\echo '--> Creating subscription for core reference data...'
CREATE SUBSCRIPTION :sub_slot_1
    CONNECTION :'publisher_conn_string'
    PUBLICATION us_product_publication
    WITH (connect = false); -- connect=false is essential for same-server setup

\echo '--> Creating subscription for US product prices...'
CREATE SUBSCRIPTION :sub_slot_2
    CONNECTION :'publisher_conn_string'
    PUBLICATION us_product_variant_price_publication
    WITH (connect = false);

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

-- Conditionally create the second slot
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
\c :subscriber_db
\echo 'Connected back to subscriber to enable and refresh data...'


\echo '--> Enabling and refreshing subscription:' :'sub_slot_1'
ALTER SUBSCRIPTION :sub_slot_1 ENABLE;
ALTER SUBSCRIPTION :sub_slot_1 REFRESH PUBLICATION;

\echo '--> Enabling and refreshing subscription:' :'sub_slot_2'
ALTER SUBSCRIPTION :sub_slot_2 ENABLE;
ALTER SUBSCRIPTION :sub_slot_2 REFRESH PUBLICATION;

\echo '*** Script Finished Successfully ***'
