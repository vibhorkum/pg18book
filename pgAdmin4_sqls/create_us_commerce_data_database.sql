-- =================================================================
--  PART 1: DATABASE PREPARATION
--  PURPOSE: Creates the us_ecommerce_data database.
--  INSTRUCTIONS: Run this script while connected to a neutral
--                database like 'postgres'.
-- =================================================================

-- \echo '[DATABASE PREP] ==> Preparing to drop and recreate the database.'

-- Terminate active connections before dropping the database for a safe teardown.
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'us_ecommerce_data' AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS us_ecommerce_data;

-- \echo '[DATABASE PREP] ==> Creating the database...'
CREATE DATABASE us_ecommerce_data;

-- The following psql commands are not valid in pgAdmin and are commented out.
-- The user must manually connect to the new database for the next part.
-- \c us_ecommerce_data
-- \echo '--> Successfully connected to database: us_ecommerce_data'
