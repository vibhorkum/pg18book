-- =================================================================
--  SECTION 1: SYSTEM AND DATABASE PREPARATION
-- =================================================================
-- Note: These initial commands should be run by a superuser connected
-- to a maintenance database (like 'postgres').

-- Terminate all active connections to the target database before dropping it.
-- This is a more controlled approach than using WITH (FORCE).
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'ecommerce_reference_data' AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS ecommerce_reference_data;

-- \echo '[DATABASE PREP] ==> Creating the database...'
CREATE DATABASE ecommerce_reference_data;

-- The original psql script had a "\c ecommerce_reference_data" command here.
-- In pgAdmin, you must manually close this query tool and open a new one
-- connected to the 'ecommerce_reference_data' database to run Part 2.
