-- =================================================================
--  VALIDATION SCRIPT FOR AI DATABASE (aidb)
-- =================================================================
--  Tests the basic functionality of the AI database
-- =================================================================

\c aidb

\echo '========================================'
\echo '  AI Database Validation Tests'
\echo '========================================'

-- Test 1: Check database connection and extensions
\echo '--> Test 1: Checking extensions...'
SELECT name, default_version, installed_version 
FROM pg_available_extensions 
WHERE name IN ('vector', 'plpython3u') 
ORDER BY name;

-- Test 2: Check tables exist and have data
\echo '--> Test 2: Checking table structure and sample data...'
SELECT 'product_category' as table_name, count(*) as row_count FROM public.product_category
UNION ALL
SELECT 'product_brand', count(*) FROM public.product_brand
UNION ALL  
SELECT 'product', count(*) FROM public.product
UNION ALL
SELECT 'product_variant', count(*) FROM public.product_variant
UNION ALL
SELECT 'product_variant_price', count(*) FROM public.product_variant_price
UNION ALL
SELECT 'category_complements', count(*) FROM api.category_complements;

-- Test 3: Check embedding column structure
\echo '--> Test 3: Checking embedding column...'
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'product' 
  AND column_name = 'embedding';

-- Test 4: Show sample product data
\echo '--> Test 4: Sample product data...'
SELECT p.id, p.name, c.name as category, b.name as brand,
       CASE WHEN p.embedding IS NULL THEN 'No' ELSE 'Yes' END as has_embedding
FROM public.product p
JOIN public.product_category c ON c.id = p.category_id
JOIN public.product_brand b ON b.id = p.brand_id
ORDER BY p.id;

-- Test 5: Check functions exist
\echo '--> Test 5: Checking API functions...'
SELECT routine_name, routine_type
FROM information_schema.routines 
WHERE routine_schema = 'api' 
  AND routine_name IN ('openai_embed', 'embed_products', 'similar_items', 'chat')
ORDER BY routine_name;

-- Test 6: Check views exist
\echo '--> Test 6: Checking views...'
SELECT table_name
FROM information_schema.views 
WHERE table_schema = 'api'
ORDER BY table_name;

\echo '========================================'
\echo '  Validation Tests Completed!'
\echo '========================================'
\echo ''
\echo 'If all tests passed, the AI database is ready for use.'
\echo 'Remember to set your OpenAI API key before using embedding functions:'
\echo 'SELECT set_config(''api.openai_api_key'',''sk-...YOUR_KEY...'', false);'