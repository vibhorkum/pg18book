-- =================================================================
--  PSQL SCRIPT FOR TERMINATING CONNECTIONS AND DROPPING DATABASES
--  WARNING: THIS IS A DESTRUCTIVE OPERATION AND CANNOT BE UNDONE.
--  Run this script while connected to a maintenance database (e.g., 'postgres').
-- =================================================================

\c postgres

-- Step 0: Define variables for the databases to be dropped
\set db_to_drop_1 'ecommerce_reference_data'
\set db_to_drop_2 'us_ecommerce_data'
\set db_to_drop_3 'eu_ecommerce_data'
\set db_to_drop_4 'central_analytics'

\echo '*** Database Cleanup Script Started ***'
\echo 'WARNING: This script will permanently delete databases:' :'db_to_drop_1' 'and' :'db_to_drop_2'

-- It is assumed you are running this from a neutral database like 'postgres'.
-- We can verify the current database.
\echo 'Current database is:' :'DBNAME'
\echo ' '

-- =================================================================
--  Step 1: Terminate connections and drop the first database
-- =================================================================

\echo '--> Terminating all connections to database:' :'db_to_drop_1'
-- Use pg_stat_activity to find and terminate connections to the target database.
-- We exclude our own connection's process ID (pid).
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = :'db_to_drop_1'
  AND pid <> pg_backend_pid();

\echo '--> Dropping database:' :'db_to_drop_1'
-- The WITH (FORCE) option is available in PostgreSQL 13+ as an alternative.
-- The manual termination above is more broadly compatible.
DROP DATABASE IF EXISTS :db_to_drop_1 WITH (FORCE);

\echo '--> Database' :'db_to_drop_1' 'has been dropped.'
\echo ' '

-- =================================================================
--  Step 2: Terminate connections and drop the second database
-- =================================================================

\echo '--> Terminating all connections to database:' :'db_to_drop_2'
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = :'db_to_drop_2'
  AND pid <> pg_backend_pid();

\echo '--> Dropping database:' :'db_to_drop_2'
DROP DATABASE IF EXISTS :db_to_drop_2 WITH (FORCE);

\echo '--> Database' :'db_to_drop_2' 'has been dropped.'
\echo ' '

-- =================================================================
--  Step 3: Terminate connections and drop the third database
-- =================================================================

\echo '--> Terminating all connections to database:' :'db_to_drop_3'
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = :'db_to_drop_3'
  AND pid <> pg_backend_pid();

\echo '--> Dropping database:' :'db_to_drop_3'
DROP DATABASE IF EXISTS :db_to_drop_3 WITH (FORCE);

\echo '--> Database' :'db_to_drop_3' 'has been dropped.'
\echo ' '

-- =================================================================
--  Step 4: Terminate connections and drop the fourth database
-- =================================================================

\echo '--> Terminating all connections to database:' :'db_to_drop_4'
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = :'db_to_drop_4'
  AND pid <> pg_backend_pid();

\echo '--> Dropping database:' :'db_to_drop_4'
DROP DATABASE IF EXISTS :db_to_drop_4 WITH (FORCE);

\echo '--> Database' :'db_to_drop_4' 'has been dropped.'
\echo ' '

-- =================================================================
--  Step 4: Verification
-- =================================================================
\echo '--> Verifying that databases are gone. The following list should not contain the dropped databases:'
\l

\echo '*** Cleanup Script Finished Successfully ***'
