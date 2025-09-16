-- =================================================================
--  CREATE AI DATABASE FOR E-COMMERCE EMBEDDINGS
-- =================================================================
--  OWNER: Superuser
--  PURPOSE: Creates the aidb database for AI/ML with embeddings
-- =================================================================

\echo '--> Creating aidb database...'

-- Connect to postgres database to create the new database
\c postgres

-- Drop database if exists (for clean setup)
DROP DATABASE IF EXISTS aidb;

-- Create the new AI database
CREATE DATABASE aidb
  WITH 
  OWNER = postgres
  ENCODING = 'UTF8'
  LC_COLLATE = 'C.UTF-8'
  LC_CTYPE = 'C.UTF-8'
  TABLESPACE = pg_default
  CONNECTION LIMIT = -1
  TEMPLATE = template0;

\echo '--> aidb database created successfully!'