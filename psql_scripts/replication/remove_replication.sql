-- =================================================================
--  PSQL SCRIPT FOR ROLLING BACK LOGICAL REPLICATION
--  This script tears down the publications, subscriptions,
--  and replication slots created by the setup script.
-- =================================================================

-- Step 0: Define variables for easier maintenance
\set publisher_db 'ecommerce_reference_data'
\set subscriber_db 'us_ecommerce_data'
\set sub_slot_1 'us_product_reference_data_sub'

SET vars.sub_slot_1 TO :'sub_slot_1';

\echo '*** Rollback Script Started ***'

-- =================================================================
--  Step 1: Disable and Drop Subscriptions on the Subscriber
-- =================================================================
\c :subscriber_db
\echo 'Connected to subscriber database ->' :subscriber_db


\echo '--> Disabling subscription' :'sub_slot_1' 'if it exists...'
-- It's good practice to disable before dropping.
-- And remove slot dependencies
-- The IF EXISTS on the DROP command handles cases where it's already gone.
ALTER SUBSCRIPTION :sub_slot_1 DISABLE;
ALTER SUBSCRIPTION :sub_slot_1 SET (slot_name = NONE);

\echo '--> Dropping subscription' :'sub_slot_1' 'if it exists...'
DROP SUBSCRIPTION IF EXISTS :sub_slot_1;


\echo '--> Subscription dropped.'

-- =================================================================
--  Step 2: Drop Replication Slots on the Publisher
-- =================================================================
\c :publisher_db
SET vars.sub_slot_1 TO :'sub_slot_1';

\echo 'Connected to publisher database ->' :publisher_db

-- Drop the replication slot for the first subscription, if it exists.
-- A DO block is used to conditionally call the drop function.
DO $$
DECLARE
        sub_slot_1 TEXT := current_setting('vars.sub_slot_1');
BEGIN
    IF EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name = sub_slot_1) THEN
        RAISE NOTICE  '--> Dropping replication slot: %', sub_slot_1;
        -- Note: pg_drop_replication_slot is a function, not standard DDL.
        PERFORM pg_drop_replication_slot(sub_slot_1);
    ELSE
        RAISE NOTICE '--> Replication slot : % does not exist. Skipping.', sub_slot_1;
    END IF;
END$$;

\echo '--> Replication slots have been dropped.'


-- =================================================================
--  Step 3: Drop Publications on the Publisher
-- =================================================================
-- This can be done in the same connection to the publisher.

\echo '--> Dropping publication: us_product_publication'
DROP PUBLICATION IF EXISTS us_product_reference_publication;


\echo '--> Publication dropped.'

\echo '*** Rollback Script Finished Successfully ***'
