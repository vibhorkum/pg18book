/*
 Master script to set up the eCommerce structure with multiple databases on the same server

 Sequence:
 1) reference_data.sql (creates ecommerce_reference_data)
 2) us_ecommerce_data.sql (creates us_ecommerce_data)
 3) replication_setup.sql (sets up product reference replication from ecommerce_reference_data to us_ecommerce_data)
 4) reference_data_set.sql (populates ecommerce_reference_data)



*/

--- make sure psql stops after the first error
\set ON_ERROR_STOP on

\c postgres

\echo '.... database_definitions/ecommerce_reference_data.sql'
\i database_definitions/ecommerce_reference_data.sql

\echo '.... executing database_definitions/us_ecommerce_data.sql'
\i database_definitions/us_ecommerce_data.sql

\echo '.... executing database_definitions/eu_ecommerce_data.sql'
\i database_definitions/eu_ecommerce_data.sql

\echo '.... executing database_definitions/central_analytics.sql'
\i database_definitions/central_analytics.sql

\echo '.... executing replication/product_replication_setup.sql'
\i replication/product_replication_setup.sql

\echo '.... executing replication/customer_sales_replication_setup.sql'
\i replication/customer_sales_replication_setup.sql


\echo '.... loading product reference data'

\c ecommerce_reference_data

\i data_sets/ecommerce_reference_data/product_reference/product_brand.sql
\i data_sets/ecommerce_reference_data/product_reference/product_category.sql
\echo '.... wait for reference data replication to complete'
SELECT pg_sleep(5);
\i data_sets/ecommerce_reference_data/product_reference/product.sql

\echo '.... wait for reference data replication to complete'
SELECT pg_sleep(5);
\i data_sets/ecommerce_reference_data/product_reference/product_price.sql

\echo '.... wait for reference data replication to complete'
SELECT pg_sleep(10);

--- this resets the sequences so that the API calls don't conflict

\i data_sets/ecommerce_reference_data/product_reference/alter_product_reference_sequences.sql

\echo '... loading US ecommerce data for customers and sales'

\c us_ecommerce_data

\i data_sets/us_ecommerce_data/us_customer/customer.sql
\i data_sets/us_ecommerce_data/us_sales/sales_transaction.sql
\i data_sets/us_ecommerce_data/us_sales/sales_transaction_line.sql
\i data_sets/us_ecommerce_data/inventory/product_inventory.sql

\echo '... loading EU ecommerce data for customers and sales'

\c eu_ecommerce_data
\i data_sets/eu_ecommerce_data/eu_customer/customer.sql
\i data_sets/eu_ecommerce_data/eu_sales/sales_transaction.sql
\i data_sets/eu_ecommerce_data/eu_sales/sales_transaction_line.sql
\i data_sets/eu_ecommerce_data/inventory/product_inventory.sql


\echo 'Done with setup'

\l
