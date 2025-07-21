/*
 Master script to set up the eCommerce structure with multiple databases on the same server

 Sequence:
 1) remove_replication.sql
 2) cleanup_databases.sql

*/

--- make sure psql stops after the first error
\set ON_ERROR_STOP on

\c postgres

\echo '.... running remove_replication.sql'
\i replication/remove_replication.sql

\echo '.... running cleanup_databases.sql'
\i cleanup_databases.sql

