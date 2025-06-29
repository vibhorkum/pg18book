-- =================================================================
--  pgAdmin 4 Script for Terminating Connections and Dropping Databases
--  WARNING: THIS IS A DESTRUCTIVE OPERATION AND CANNOT BE UNDONE.
-- =================================================================

-- Display a startup warning in the messages tab
-- *** Database Cleanup Script Started ***'
-- WARNING: This script will permanently delete databases: ecommerce_reference_data and us_ecommerce_data

-- =================================================================
--  Step 1: Terminate connections and drop the first database
-- =================================================================

--> Terminating all connections to database: ecommerce_reference_data
-- Use pg_stat_activity to find and terminate connections to the target database.
-- We exclude our own connection's process ID (pid).
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'ecommerce_reference_data'
  AND pid <> pg_backend_pid();

--> Dropping database: ecommerce_reference_data'
DROP DATABASE IF EXISTS ecommerce_reference_data;
--> Database ecommerce_reference_data has been dropped.


-- =================================================================
--  Step 2: Terminate connections and drop the second database
-- =================================================================

--> Terminating all connections to database: us_ecommerce_data
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'us_ecommerce_data'
  AND pid <> pg_backend_pid();

--> Dropping database: us_ecommerce_data'
DROP DATABASE IF EXISTS us_ecommerce_data;
--> Database us_ecommerce_data has been dropped.
-- *** Cleanup Script Finished Successfully ***
--> Please refresh your database list in the browser tree to verify.
