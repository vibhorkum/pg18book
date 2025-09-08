-- =================================================================
--  PART 1: Configure the Publisher Database
--  PURPOSE: Creates publications on the 'ecommerce_reference_data' DB.
-- =================================================================

-- Step 0: psql variables are not used in pgAdmin. Values are hardcoded below.
-- \set publisher_db 'ecommerce_reference_data'
-- \set subscriber_db 'us_ecommerce_data'
-- \set publisher_conn_string 'host=localhost port=5432 dbname=ecommerce_reference_data'
-- \set sub_slot_1 'us_reference_data_sub'
-- \set sub_slot_2 'us_product_variant_price_sub'

-- \echo '*** Script Started ***'

-- =================================================================
--  Step 1: Configure the Publisher Database
-- =================================================================
-- \c ecommerce_reference_data
-- \echo 'Connected to publisher database -> ecommerce_reference_data'

-- \echo '--> Dropping old publications if they exist...'
DROP PUBLICATION IF EXISTS us_product_publication;
DROP PUBLICATION IF EXISTS us_product_variant_price_publication;

-- \echo '--> Creating publication for core product tables...'
CREATE PUBLICATION us_product_publication
    FOR TABLE category, brand, product, product_variant;

-- \echo '--> Creating publication for row-filtered US product variant prices...'
CREATE PUBLICATION us_product_variant_price_publication
    FOR TABLE product_variant_price
    WHERE (geography = 'US' AND current = true);

-- \echo '--> Verification: Listing tables in publications...'
-- To verify, you can run this SELECT statement after the main script.
SELECT pubname, schemaname, tablename FROM pg_publication_tables;


-- Conditionally create the first slot to avoid errors on re-runs
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name = 'us_reference_data_sub') THEN
        RAISE NOTICE '--> Creating replication slot: us_reference_data_sub';
        PERFORM pg_create_logical_replication_slot('us_reference_data_sub', 'pgoutput');
    ELSE
        RAISE NOTICE '--> Replication slot us_reference_data_sub already exists. Skipping creation.';
    END IF;
END$$;

-- Conditionally create the second slot
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name = 'us_product_variant_price_sub') THEN
        RAISE NOTICE '--> Creating replication slot: us_product_variant_price_sub';
        PERFORM pg_create_logical_replication_slot('us_product_variant_price_sub', 'pgoutput');
    ELSE
        RAISE NOTICE '--> Replication slot us_product_variant_price_sub already exists. Skipping creation.';
    END IF;
END$$;
