-- =================================================================
--  PART 2: Configure the Subscriber Database
--  PURPOSE: Creates subscriptions on the 'us_ecommerce_data' DB.
-- =================================================================

-- \c us_ecommerce_data
-- \echo 'Connected to subscriber database -> us_ecommerce_data'


-- \echo '--> Dropping old subscriptions if they exist...'
DROP SUBSCRIPTION IF EXISTS us_reference_data_sub;
DROP SUBSCRIPTION IF EXISTS us_product_variant_price_sub;

-- \echo '--> Creating subscription for core reference data...'
CREATE SUBSCRIPTION us_reference_data_sub
    CONNECTION 'host=localhost port=5432 dbname=ecommerce_reference_data'
    PUBLICATION us_product_publication
    WITH (connect = false); -- connect=false is essential for same-server setup

-- \echo '--> Creating subscription for US product prices...'
CREATE SUBSCRIPTION us_product_variant_price_sub
    CONNECTION 'host=localhost port=5432 dbname=ecommerce_reference_data'
    PUBLICATION us_product_variant_price_publication
    WITH (connect = false);

-- =================================================================
--  PART 4: Enable and Refresh Subscriptions on the Subscriber
--  PURPOSE: Activates the subscriptions to begin data replication.
-- =================================================================

-- \c us_ecommerce_data
-- \echo 'Connected back to subscriber to enable and refresh data...'

-- \echo '--> Enabling and refreshing subscription: us_reference_data_sub'
ALTER SUBSCRIPTION us_reference_data_sub ENABLE;
ALTER SUBSCRIPTION us_reference_data_sub REFRESH PUBLICATION;

-- \echo '--> Enabling and refreshing subscription: us_product_variant_price_sub'
ALTER SUBSCRIPTION us_product_variant_price_sub ENABLE;
ALTER SUBSCRIPTION us_product_variant_price_sub REFRESH PUBLICATION;

-- \echo '*** Script Finished Successfully ***'
