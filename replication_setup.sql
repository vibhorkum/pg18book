

--- connect to reference data database

\c ecommerce_reference_data

DROP PUBLICATION IF EXISTS us_product_publication;
DROP PUBLICATION IF EXISTS us_product_variant_price_publication;

CREATE PUBLICATION us_product_publication 
    FOR TABLE product_category, product_brand, product, product_variant;

CREATE PUBLICATION us_product_variant_price_publication 
    FOR TABLE product_variant_price (id, product_variant_id, price, currency)
    WHERE (geography = 'US' AND current = true);

\echo List of publications tables on ecommerce_reference_data
SELECT * FROM pg_publication_tables;

\c us_ecommerce_data

\echo dropping subscription us_reference_data_sub if exists

DROP SUBSCRIPTION IF EXISTS us_reference_data_sub;
DROP SUBSCRIPTION IF EXISTS us_product_variant_price_sub;

\echo dropped us_reference_data_sub and us_product_variant_price_sub (if existed)

\echo creating new subscription
CREATE SUBSCRIPTION us_reference_data_sub
    CONNECTION 'host=localhost port=5432 dbname=ecommerce_reference_data'
    PUBLICATION us_product_publication
    WITH (connect=false); --- this is needed as both pub and sub are on the same server
\echo us_reference_data_sub created

CREATE SUBSCRIPTION us_product_variant_price_sub
    CONNECTION 'host=localhost port=5432 dbname=ecommerce_reference_data'
    PUBLICATION us_product_variant_price_publication
    WITH (connect=false); --- this is needed as both pub and sub are on the same server
\echo us_product_variant_price_sub created

\c ecommerce_reference_data

--- create the slots (this is needed as both pub and sub are on the same server)
SELECT * FROM pg_create_logical_replication_slot('us_reference_data_sub', 'pgoutput');
SELECT * FROM pg_create_logical_replication_slot('us_product_variant_price_sub', 'pgoutput');

\c us_ecommerce_data

ALTER SUBSCRIPTION us_reference_data_sub ENABLE;
ALTER SUBSCRIPTION us_reference_data_sub REFRESH PUBLICATION;
\echo us_reference_data_sub enabled and refreshed

ALTER SUBSCRIPTION us_product_variant_price_sub ENABLE;
ALTER SUBSCRIPTION us_product_variant_price_sub REFRESH PUBLICATION;
\echo us_product_variant_price_sub enabled and refreshed