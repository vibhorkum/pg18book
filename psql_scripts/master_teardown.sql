

\set ON_ERROR_STOP off 

\c postgres

\echo '.... running remove_product_replication.sql'
\i replication/remove_product_replication.sql

\echo '.... running remove_replication.sql'
\i replication/remove_customer_sales_replication.sql

\echo '.... running cleanup_databases.sql'
\i cleanup_databases.sql

\echo '.... running remove_roles.sql'
\i database_definitions/remove_roles.sql

