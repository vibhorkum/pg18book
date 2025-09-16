-- =================================================================
--  CLEANUP SCRIPT FOR AI DATABASE (aidb)
-- =================================================================
--  Drops the aidb database completely
-- =================================================================

\echo '========================================'
\echo '  AI Database Cleanup'
\echo '========================================'

-- Connect to postgres database to drop the aidb database
\c postgres

\echo '--> Terminating active connections to aidb...'
-- Terminate any active connections to the database
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'aidb' AND pid <> pg_backend_pid();

\echo '--> Dropping aidb database...'
DROP DATABASE IF EXISTS aidb;

\echo '========================================'
\echo '  AI Database Cleanup Completed!'
\echo '========================================'