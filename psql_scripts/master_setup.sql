/*
 Master script to set up the eCommerce structure with multiple databases on the same server

 Sequence:
 1) reference_data.sql (creates ecommerce_reference_data)
 2) us_ecommerce_data.sql (creates us_ecommerce_data)
 3) replication_setup.sql (sets up product reference replication from ecommerce_reference_data to us_ecommerce_data)
 4) reference_data_set.sql (populates ecommerce_reference_data)



*/

\c postgres

\echo '.... executing reference_data.sql'
\i reference_data.sql

\echo '.... executing us_ecommerce_data.sql'
\i us_ecommerce_data.sql

\echo '.... executing replication_setup.sql'
\i replication_setup.sql

\echo '.... loading product reference data'

\c ecommerce_reference_data

\i data_set/ecommerce_reference_data/product_reference/product_brand.sql
\i data_set/ecommerce_reference_data/product_reference/product_category.sql
\i data_set/ecommerce_reference_data/product_reference/product.sql
\i data_set/ecommerce_reference_data/product_reference/product_price.sql

--- this resets the sequences so that the API calls don't conflict

\i data_set/ecommerce_reference_data/product_reference/alter_product_reference_sequences.sql

\echo '... loading US ecommerce data for customers and sales'

\c us_ecommerce_data

\i data_set/us_ecommerce_data/us_customer/customer.sql
\i data_set/us_ecommerce_data/us_sales/sales_transaction.sql
\i data_set/us_ecommerce_data/us_sales/sales_transaction_lines.sql
\i data_set/us_ecommerce_data/inventory/product_inventory.sql


\echo 'Done with setup'

\l
