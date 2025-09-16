-- =================================================================
--  DEMO SCRIPT FOR AI DATABASE (aidb)
-- =================================================================
--  Demonstrates the AI database functionality
--  NOTE: Requires OpenAI API key to be set for full functionality
-- =================================================================

\c aidb

\echo '========================================'
\echo '  AI Database Demo'
\echo '========================================'

-- Show database overview
\echo '--> Database Overview:'
SELECT 'Categories' as data_type, count(*) as count FROM public.product_category
UNION ALL
SELECT 'Brands', count(*) FROM public.product_brand
UNION ALL  
SELECT 'Products', count(*) FROM public.product
UNION ALL
SELECT 'Variants', count(*) FROM public.product_variant
UNION ALL
SELECT 'Prices', count(*) FROM public.product_variant_price;

\echo ''
\echo '--> Sample Products with Details:'
SELECT 
    p.name as product_name,
    c.name as category,
    b.name as brand,
    pv.color,
    pv.size,
    pvp.amount as price,
    pvp.currency
FROM public.product p
JOIN public.product_category c ON c.id = p.category_id
JOIN public.product_brand b ON b.id = p.brand_id
JOIN public.product_variant pv ON pv.product_id = p.id
JOIN public.product_variant_price pvp ON pvp.product_variant_id = pv.id
ORDER BY p.name, pv.color, pv.size
LIMIT 10;

\echo ''
\echo '--> Category Complements (Product Pairing Rules):'
SELECT 
    category_name,
    array_to_string(complements, ', ') as pairs_with
FROM api.category_complements 
WHERE category_name IN ('Jeans', 'Shirt', 'Footwear')
ORDER BY category_name;

\echo ''
\echo '--> Product Search by Category and Price:'
SELECT 
    p.name as product_name,
    c.name as category,
    pv.color,
    pvp.amount as price
FROM public.product p
JOIN public.product_category c ON c.id = p.category_id
JOIN public.product_variant pv ON pv.product_id = p.id
JOIN public.product_variant_price pvp ON pvp.product_variant_id = pv.id
WHERE c.name = 'Jeans' AND pvp.amount < 50
ORDER BY pvp.amount;

\echo ''
\echo '========================================'
\echo '  AI Features Demo (Requires API Key)'
\echo '========================================'

-- Check if OpenAI API key is set
DO $$
DECLARE
    api_key text;
BEGIN
    SELECT current_setting('api.openai_api_key', true) INTO api_key;
    
    IF api_key IS NULL OR api_key = '' THEN
        RAISE NOTICE '';
        RAISE NOTICE 'OpenAI API key not set. To use AI features:';
        RAISE NOTICE '1) Set your API key:';
        RAISE NOTICE '   SELECT set_config(''api.openai_api_key'',''sk-...YOUR_KEY...'', false);';
        RAISE NOTICE '';
        RAISE NOTICE '2) Generate embeddings:';
        RAISE NOTICE '   SELECT api.embed_products(25);';
        RAISE NOTICE '';
        RAISE NOTICE '3) Test similarity search:';
        RAISE NOTICE '   SELECT * FROM api.similar_items(''blue casual summer shirt'', 3);';
        RAISE NOTICE '';
        RAISE NOTICE '4) Try the chat interface:';
        RAISE NOTICE '   SELECT * FROM api.chat(''Tell me about women''''s jeans under $50'', 5);';
        RAISE NOTICE '';
    ELSE
        RAISE NOTICE 'OpenAI API key is set. You can now use AI features!';
        RAISE NOTICE '';
        RAISE NOTICE 'Try these commands:';
        RAISE NOTICE '- SELECT api.embed_products(25);';
        RAISE NOTICE '- SELECT * FROM api.similar_items(''comfortable jeans'', 3);';
        RAISE NOTICE '- SELECT * FROM api.chat(''Show me casual shirts'', 5);';
    END IF;
END $$;

\echo ''
\echo '--> Example: Product Pairs View (works without API key):'
\echo 'This view would show complementary products once embeddings are generated:'

SELECT 
    'Product pairing example:' as note,
    'Jeans + Shirt combinations' as description
UNION ALL
SELECT 
    'After running api.embed_products()', 
    'This view will show actual similarity scores'
UNION ALL
SELECT 
    'Query: SELECT * FROM api.product_pairs_demo LIMIT 5;',
    'Shows products that complement each other';

\echo ''
\echo '========================================'
\echo '  Demo Completed!'
\echo '========================================'
\echo ''
\echo 'The AI database is ready for use. Set your OpenAI API key to enable'
\echo 'semantic search and natural language chat features.'