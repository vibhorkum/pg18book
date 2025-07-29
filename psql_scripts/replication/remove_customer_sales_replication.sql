-- =================================================================
--  PSQL SCRIPT FOR ROLLING BACK LOGICAL REPLICATION FOR customer and sales data
--  This script tears down the publications, subscriptions,
--  and replication slots created by the setup script.
-- =================================================================

-- Step 0: Define variables for easier maintenance
\set publisher_db2 'west_ecommerce_data'
\set publisher_db3 'east_ecommerce_data'

\set subscriber_db4 'central_analytics'

\set publisher_conn_string2 'host=localhost port=5432 dbname=west_ecommerce_data'
\set publisher_conn_string3 'host=localhost port=5432 dbname=east_ecommerce_data'

\set sub_slot_4 'west_customer_sales_data_sub'
\set sub_slot_5 'east_customer_sales_data_sub'


\echo '*** Rollback Script Started ***'

-- =================================================================
--  Step 1: Disable and Drop Subscriptions on the Subscriber
-- =================================================================
\c :subscriber_db4
\echo 'Connected to subscriber database ->' :subscriber_db4


\echo '--> Disabling subscription' :'sub_slot_4' 'if it exists...'
-- It's good practice to disable before dropping.
-- And remove slot dependencies
-- The IF EXISTS on the DROP command handles cases where it's already gone.
ALTER SUBSCRIPTION :sub_slot_4 DISABLE;
ALTER SUBSCRIPTION :sub_slot_4 SET (slot_name = NONE);

\echo '--> Dropping subscription' :'sub_slot_1' 'if it exists...'
DROP SUBSCRIPTION IF EXISTS :sub_slot_4;

\echo '--> Disabling subscription' :'sub_slot_5' 'if it exists...'
-- It's good practice to disable before dropping.
-- And remove slot dependencies
-- The IF EXISTS on the DROP command handles cases where it's already gone.
ALTER SUBSCRIPTION :sub_slot_5 DISABLE;
ALTER SUBSCRIPTION :sub_slot_5 SET (slot_name = NONE);

\echo '--> Dropping subscription' :'sub_slot_1' 'if it exists...'
DROP SUBSCRIPTION IF EXISTS :sub_slot_5;


\echo '--> Subscriptions dropped.'

-- =================================================================
--  Step 2: Drop Replication Slots on the Publisher ecommerce reference
-- =================================================================
\c :publisher_db2
SET vars.sub_slot_4 TO :'sub_slot_4';

\echo 'Connected to publisher database ->' :publisher_db2

-- Drop the replication slot for the first subscription, if it exists.
-- A DO block is used to conditionally call the drop function.
DO $$
DECLARE
        sub_slot_1 TEXT := current_setting('vars.sub_slot_4');
BEGIN
    IF EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name = sub_slot_4) THEN
        RAISE NOTICE  '--> Dropping replication slot: %', sub_slot_4;
        PERFORM pg_drop_replication_slot(sub_slot_4);
    ELSE
        RAISE NOTICE '--> Replication slot : % does not exist. Skipping.', sub_slot_4;
    END IF;
END$$;

\c :publisher_db3
SET vars.sub_slot_5 TO :'sub_slot_5';

-- Drop the replication slot for the second subscription, if it exists.
-- A DO block is used to conditionally call the drop function.
DO $$
DECLARE
        sub_slot_5 TEXT := current_setting('vars.sub_slot_5');
BEGIN
    IF EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name = sub_slot_5) THEN
        RAISE NOTICE  '--> Dropping replication slot: %', sub_slot_5;
        PERFORM pg_drop_replication_slot(sub_slot_5);
    ELSE
        RAISE NOTICE '--> Replication slot : % does not exist. Skipping.', sub_slot_5;
    END IF;
END$$;




-- =================================================================
--  Step 3: Drop Publications on the Publisher
-- =================================================================
\c :publisher_db2

\echo '--> Dropping publication: west_product_publication'
DROP PUBLICATION IF EXISTS west_customer_sales_pub;

\c :publisher_db3

\echo '--> Dropping publication: east_product_publication'
DROP PUBLICATION IF EXISTS east_customer_sales_pub;


\echo '--> Publications dropped.'

\echo '*** Rollback Script Finished Successfully ***'
