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

\echo '.... executing reference_data_set.sql'

\i reference_data_set.sql

\ech 'Done with setup'

\l
