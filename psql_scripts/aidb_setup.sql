-- =================================================================
--  MASTER SETUP SCRIPT FOR AI DATABASE (aidb)
-- =================================================================
--  This script creates and sets up the AI database with embeddings
--  for e-commerce product search and recommendation
-- =================================================================

-- Enable error stopping
\set ON_ERROR_STOP on
SET client_min_messages TO NOTICE;

\echo '========================================'
\echo '  AI Database Setup Starting...'
\echo '========================================'

-- Step 1: Create the database
\echo '--> Step 1: Creating aidb database...'
\i psql_scripts/database_definitions/create_aidb.sql

-- Step 2: Set up schema, tables, and functions
\echo '--> Step 2: Setting up AI database schema...'
\i psql_scripts/database_definitions/aidb.sql

\echo '========================================'
\echo '  AI Database Setup Completed!'
\echo '========================================'
\echo ''
\echo 'Next steps:'
\echo '1) Set your OpenAI API key:'
\echo '   \\c aidb'
\echo '   SELECT set_config(''api.openai_api_key'',''sk-...YOUR_KEY...'', false);'
\echo ''
\echo '2) Generate embeddings:'
\echo '   SELECT api.embed_products(25);'
\echo ''
\echo '3) Test similarity search:'
\echo '   SELECT * FROM api.similar_items(''blue casual summer shirt for men'', 2);'
\echo ''
\echo '4) Try the chat interface:'
\echo '   SELECT * FROM api.chat(''Tell me about women''''s black jeans'', 3);'