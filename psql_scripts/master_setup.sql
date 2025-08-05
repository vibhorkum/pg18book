/*
 Master script to set up the eCommerce structure with multiple databases on the same server

 Sequence:
 0) Check the underlying configuration
 1) reference_data.sql (creates ecommerce_reference_data)
 2) us_ecommerce_data.sql (creates us_ecommerce_data)
 3) replication_setup.sql (sets up product reference replication from ecommerce_reference_data to us_ecommerce_data)
 4) reference_data_set.sql (populates ecommerce_reference_data)

*/

--- make sure psql stops after the first error
\set ON_ERROR_STOP on

SET client_min_messages TO NOTICE;

\c postgres

/*
Check the underlying configuration
- wal_level = logical
- logging_collector=on 
- max_logical_replication_workers>=10 
- log_statement=ddl

*/

\echo 'Checking server configuration'
DO 
$$
DECLARE 
    v_rep_workers INTEGER;
    v_wal_level TEXT;
BEGIN
    SELECT setting INTO v_rep_workers
        FROM pg_settings 
        WHERE name = 'max_logical_replication_workers';
    IF v_rep_workers < 10 THEN
        RAISE EXCEPTION 'Parameter max_logical_replication_workers set to %. Must be above 10', v_rep_workers;
    END IF;
        SELECT setting::TEXT INTO v_wal_level
        FROM pg_settings 
        WHERE name = 'wal_level';
    IF v_wal_level <> 'logical' THEN
        RAISE EXCEPTION 'Parameter wal_level set to %. Must be logical', v_wal_level;
    END IF;
END 
$$;
\echo 'Server config ok'

\echo 'Creating databases ...'
\i database_definitions/create_databases.sql


\echo '.... database_definitions/ecommerce_reference_data.sql'
\i database_definitions/ecommerce_reference_data.sql

\echo '.... executing database_definitions/west_ecommerce_data.sql'
\i database_definitions/west_ecommerce_data.sql

\echo '.... adding shared API definitions to west ecommerce'
\c west_ecommerce_data
\i database_definitions/ecommerce_api.sql


\echo '.... executing database_definitions/east_ecommerce_data.sql'
\i database_definitions/east_ecommerce_data.sql

\echo '.... adding shared API definitions to east ecommerce'
\c east_ecommerce_data
\i database_definitions/ecommerce_api.sql

\echo '.... executing database_definitions/central_analytics.sql'
\i database_definitions/central_analytics.sql

\echo 'Databases defined'

\echo 'Setting up replication ...'

\echo '.... executing replication/product_replication_setup.sql'
\i replication/product_replication_setup.sql

\echo '.... executing replication/customer_sales_replication_setup.sql'
\i replication/customer_sales_replication_setup.sql

\echo 'replication set up'

\echo '.... loading product reference data'

\c ecommerce_reference_data

\i data_sets/ecommerce_reference_data/product_reference/product_brand.sql
\i data_sets/ecommerce_reference_data/product_reference/product_category.sql
\i data_sets/ecommerce_reference_data/product_reference/product.sql
\i data_sets/ecommerce_reference_data/product_reference/product_price.sql

CALL api.update_current_price_flags();

\echo 'Product reference data loaded'

\echo 'Allowing replication to catch up - 5 secs'
SELECT PG_SLEEP(5);


/*
--- this resets the sequences so that the API calls don't conflict

\i data_sets/ecommerce_reference_data/product_reference/alter_product_reference_sequences.sql

*/
\echo '... loading east ecommerce data for customers and sales'

\c east_ecommerce_data

\i data_sets/east_ecommerce_data/east_customer/customer.sql
\i data_sets/east_ecommerce_data/east_sales/sales_transaction.sql
\i data_sets/east_ecommerce_data/east_sales/sales_transaction_line.sql
\i data_sets/east_ecommerce_data/inventory/product_inventory.sql

\echo '... loading west ecommerce data for customers and sales'

\c west_ecommerce_data
\i data_sets/west_ecommerce_data/west_customer/customer.sql
\i data_sets/west_ecommerce_data/west_sales/sales_transaction.sql
\i data_sets/west_ecommerce_data/west_sales/sales_transaction_line.sql
\i data_sets/west_ecommerce_data/inventory/product_inventory.sql

\echo 'Allowing replication to catch up - 20 secs'
SELECT PG_SLEEP(20);

\echo 'Displaying replication results ...'

\c ecommerce_reference_data

\echo 'Reference data counts on ecommerce_reference_data'

SELECT COUNT(*) as product_count from product;
SELECT COUNT(*) as active_product_price_count from product_price where current=true;

\c east_ecommerce_data

\echo 'East data counts'

SELECT COUNT(*) as product_count from product;
SELECT COUNT(*) as active_product_price_count from product_price where current=true;
SELECT COUNT(*) as customer_count from customer;
SELECT COUNT(*) as sales_transaction_count from sales_transaction;
SELECT COUNT(*) as sales_transaction_line_count from sales_transaction_line;

\c west_ecommerce_data

\echo 'West data counts'

SELECT COUNT(*) as product_count from product;
SELECT COUNT(*) as active_product_price_count from product_price where current=true;
SELECT COUNT(*) as customer_count from customer;
SELECT COUNT(*) as sales_transaction_count from sales_transaction;
SELECT COUNT(*) as sales_transaction_line_count from sales_transaction_line;

\c central_analytics
\echo 'Central Analytivs data counts'

SELECT COUNT(*) as product_count from product;
SELECT COUNT(*) as active_product_price_count from product_price where current=true;


SELECT COUNT(*) as east_customer_count from east_customer.customer;
SELECT COUNT(*) as west_customer_count from west_customer.customer;
SELECT COUNT(*) as customer_count from merged_customer.customer;

SELECT COUNT(*) as sales_transaction_count from merged_sales.sales_transaction;
SELECT COUNT(*) as sales_transaction_line_count from merged_sales.sales_transaction_line;
\echo 'Done with setup'

\l
