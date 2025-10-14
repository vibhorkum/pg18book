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

\echo 'Defining the DBA users'
\i database_definitions/define_roles.sql

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

\echo '.... executing database_definitions/aidb.sql'
\i database_definitions/aidb.sql

\echo '.... adding pgbench-specific stored procedures to east_ecommerce_data'
\i sample_scripts/pgbench-scripts/pgbench-stored-procedures.sql


\echo 'Databases defined'
\echo '--------------------------------------------------------------------'

\echo 'Setting up replication ...'

\echo '.... executing replication/product_replication_setup.sql'
\i replication/product_replication_setup.sql

\echo '.... executing replication/customer_sales_replication_setup.sql'
\i replication/customer_sales_replication_setup.sql

\echo 'replication set up'

\echo '.... loading product reference data'

\c ecommerce_reference_data
\i data_sets/ecommerce_reference_data/product/brand.sql
\i data_sets/ecommerce_reference_data/product/category.sql
\i data_sets/ecommerce_reference_data/product/product.sql
\i data_sets/ecommerce_reference_data/product/product_variant.sql
\i data_sets/ecommerce_reference_data/product/product_variant_price.sql
\i data_sets/ecommerce_reference_data/product/country_of_origin.sql



\echo 'Product reference data loaded'

\echo 'Allowing replication to catch up - 10 secs'
SELECT PG_SLEEP(10);


--- this resets the sequences so that the API calls don't conflict

\i data_sets/ecommerce_reference_data/product/alter_product_sequences.sql

\echo '... loading east ecommerce data for customers and sales'

\c east_ecommerce_data

-- load the customer data first
\i data_sets/east_ecommerce_data/east_customer/customer.sql
\i data_set_generation/generate_inventory.sql
\i data_set_generation/generate_sales.sql



/*
\i data_sets/east_ecommerce_data/east_customer/customer.sql
\i data_sets/east_ecommerce_data/inventory/product_variant_inventory.sql
\i data_sets/east_ecommerce_data/east_sales/sales_transaction.sql
\i data_sets/east_ecommerce_data/east_sales/sales_transaction_line.sql
*/

\echo '... loading west ecommerce data for customers and sales'

\c west_ecommerce_data
-- load the customer data first
\i data_sets/west_ecommerce_data/west_customer/customer.sql
\i data_set_generation/generate_inventory.sql
\i data_set_generation/generate_sales.sql

/*
\i data_sets/west_ecommerce_data/inventory/product_variant_inventory.sql
\i data_sets/west_ecommerce_data/west_sales/sales_transaction.sql
\i data_sets/west_ecommerce_data/west_sales/sales_transaction_line.sql

*/
\echo 'Allowing replication to catch up - 10 secs'
SELECT PG_SLEEP(10);

\echo 'Displaying replication results ...'

\c ecommerce_reference_data

\echo 'Reference data counts on ecommerce_reference_data'

SELECT COUNT(*) as product_count from product;
-- sets the variable ecommerce_product_count
\gset ecommerce_

SELECT COUNT(*) as active_product_price_count from product_variant_price where current=true;
-- sets the variable ecommerce_active_product_price_count
\gset ecommerce_

\c east_ecommerce_data

\echo 'East data counts'

SELECT COUNT(*) as product_count from product;
-- sets the variable east_ecommerce_data_product_count
\gset east_ecommerce_data_
SELECT COUNT(*) as active_product_price_count from product_variant_price where current=true;
-- sets the variable east_ecommerce_data_active_product_price_count
\gset east_ecommerce_data_

SELECT COUNT(*) as customer_count from customer;
-- sets the variable east_ecommerce_data_customer_count
\gset east_ecommerce_data_
SELECT COUNT(*) as sales_transaction_count from sales_transaction;
-- sets the variable east_ecommerce_data_sales_transaction_count
\gset east_ecommerce_data_
SELECT COUNT(*) as sales_transaction_line_count from sales_transaction_line;
-- sets the variable east_ecommerce_data_sales_transaction_line_count
\gset east_ecommerce_data_


\c west_ecommerce_data

\echo 'West data counts'

SELECT COUNT(*) as product_count from product;
-- sets the variable west_ecommerce_data_product_count
\gset west_ecommerce_data_
SELECT COUNT(*) as active_product_price_count from product_variant_price where current=true;
-- sets the variable west_ecommerce_data_active_product_price_count
\gset west_ecommerce_data_
SELECT COUNT(*) as customer_count from customer;
-- sets the variable west_ecommerce_data_customer_count
\gset west_ecommerce_data_
SELECT COUNT(*) as sales_transaction_count from sales_transaction;
-- sets the variable west_ecommerce_data_sales_transaction_count
\gset west_ecommerce_data_
SELECT COUNT(*) as sales_transaction_line_count from sales_transaction_line;
-- sets the variable west_ecommerce_data_sales_transaction_line_count
\gset west_ecommerce_data_

\c central_analytics
\echo 'Central Analytivs data counts'

SELECT COUNT(*) as product_count from product;
-- sets the variable central_analytics_product_count
\gset central_analytics_ 
SELECT COUNT(*) as active_product_price_count from product_variant_price where current=true;
-- sets the variable central_analytics_active_product_price_count
\gset central_analytics_ 

SELECT COUNT(*) as east_customer_count from east_customer.customer;
-- sets the variable central_analytics_east_customer_count
\gset central_analytics_ 
SELECT COUNT(*) as west_customer_count from west_customer.customer;
-- sets the variable central_analytics_west_customer_count
\gset central_analytics_ 
SELECT COUNT(*) as customer_count from merged_customer.customer;
-- sets the variable central_analytics_customer_count
\gset central_analytics_ 

SELECT COUNT(*) as sales_transaction_count from merged_sales.sales_transaction;
-- sets the variable central_analytics_sales_transaction_count
\gset central_analytics_
SELECT COUNT(*) as sales_transaction_line_count from merged_sales.sales_transaction_line;
-- sets the variable central_analytics_sales_transaction_line_count
\gset central_analytics_


\c aidb
\echo 'AIDB data counts'

SELECT COUNT(*) as product_count from product;
-- sets the variable aidb_product_count
\gset aidb_ 
SELECT COUNT(*) as active_product_price_count from product_variant_price where current=true;
-- sets the variable aidb_active_product_price_count
\gset aidb_ 

\echo 'Done with setup'

\echo '--------------------------------------------------------------------'
\echo 'Checking product replication results'
\echo 'ecommerce_product_count:' :ecommerce_product_count
\echo 'ecommerce_active_product_price_count:' :ecommerce_active_product_price_count
\echo 'east_ecommerce_data_product_count:' :east_ecommerce_data_product_count
\echo 'east_ecommerce_data_active_product_price_count:' :east_ecommerce_data_active_product_price_count
\echo 'west_ecommerce_data_product_count:' :west_ecommerce_data_product_count
\echo 'west_ecommerce_data_active_product_price_count:' :west_ecommerce_data_active_product_price_count
\echo 'central_analytics_product_count:' :central_analytics_product_count
\echo 'central_analytics_active_product_price_count:' :central_analytics_active_product_price_count
\echo 'aidb_product_count:' :aidb_product_count
\echo 'aidb_active_product_price_count:' :aidb_active_product_price_count
\echo '--------------------------------------------------------------------'
\echo 'Checking customer and sales replication results'
\echo 'east_ecommerce_data_customer_count:' :east_ecommerce_data_customer_count
\echo 'east_ecommerce_data_sales_transaction_count:' :east_ecommerce_data_sales_transaction_count
\echo 'east_ecommerce_data_sales_transaction_line_count:' :east_ecommerce_data_sales_transaction_line_count
\echo 'west_ecommerce_data_customer_count:' :west_ecommerce_data_customer_count
\echo 'west_ecommerce_data_sales_transaction_count:' :west_ecommerce_data_sales_transaction_count
\echo 'west_ecommerce_data_sales_transaction_line_count:' :west_ecommerce_data_sales_transaction_line_count
\echo 'central_analytics_east_customer_count:' :central_analytics_east_customer_count
\echo 'central_analytics_west_customer_count:' :central_analytics_west_customer_count
\echo 'central_analytics_customer_count:' :central_analytics_customer_count
\echo 'central_analytics_sales_transaction_count:' :central_analytics_sales_transaction_count
\echo 'central_analytics_sales_transaction_line_count:' :central_analytics_sales_transaction_line_count
\echo '--------------------------------------------------------------------'

\c postgres

\l
