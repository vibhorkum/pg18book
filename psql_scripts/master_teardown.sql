/*
 Master script to set up the eCommerce structure with multiple databases on the same server

 Sequence:
 1) remove_replication.sql
 2) cleanup_databases.sql

*/


\c postgres

\echo '.... running remove_replication.sql'
\i remove_replication.sql

\echo '.... running cleanup_databases.sql'
\i cleanup_databases.sql

