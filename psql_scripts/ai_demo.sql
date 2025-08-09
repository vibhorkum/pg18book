-- =================================================================
--  AI RECOMMENDATION SYSTEM DEMO
--  PURPOSE: Simple demonstration of AI-powered e-commerce recommendations
--  DATABASE: Should be run on west_ecommerce_data or east_ecommerce_data 
--            (databases with replicated product data)
-- =================================================================

-- Connect to the appropriate database
\c west_ecommerce_data

\echo '================================================================='
\echo '🤖 AI-POWERED E-COMMERCE RECOMMENDATION SYSTEM DEMO'
\echo '================================================================='

-- Validation check
DO $$
DECLARE
    table_count INTEGER;
    current_db TEXT;
BEGIN
    SELECT current_database() INTO current_db;
    
    -- Check if required tables exist
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables 
    WHERE table_name IN ('product', 'product_brand', 'product_category')
    AND table_schema IN ('public', 'product_reference');
    
    IF table_count < 3 THEN
        RAISE EXCEPTION 'Required product tables not found. Please ensure you are connected to a database with replicated product data (us_ecommerce_data, west_ecommerce_data, or east_ecommerce_data).';
    END IF;
    
    RAISE NOTICE 'Database validation successful: % has required product tables', current_db;
END;
$$;

-- Setup: Generate embeddings for all products
\echo ''
\echo '📊 Step 1: Generating AI embeddings for products...'
SELECT update_product_embeddings() as embeddings_generated;

-- Show available products
\echo ''
\echo '🏪 Step 2: Available products in catalog:'
SELECT 
    p.id,
    p.label as product_name,
    pb.label as brand,
    pc.label as category
FROM product p
JOIN product_brand pb ON p.product_brand_id = pb.id
JOIN product_category pc ON p.product_category_id = pc.id
ORDER BY p.id;

-- Demonstrate content-based similarity
\echo ''
\echo '🔍 Step 3: Content-Based Similarity Search'
\echo '-------------------------------------------'
\echo 'Finding products similar to "Mens Classic Oxford Shirt" (ID: 1):'

SELECT 
    product_id,
    product_label,
    brand_label,
    similarity_score,
    CASE 
        WHEN similarity_score > 0.5 THEN '🔥 Highly Similar'
        WHEN similarity_score > 0.3 THEN '✅ Similar' 
        ELSE '📝 Somewhat Related'
    END as similarity_level
FROM find_similar_products(1, 0.1, 10)
ORDER BY similarity_score DESC;

-- Demonstrate text-based search
\echo ''
\echo '🔎 Step 4: AI-Powered Text Search'
\echo '----------------------------------'
\echo 'Searching for: "shirt for business meetings"'

SELECT 
    product_label,
    brand_label,
    category_label,
    similarity_score,
    CASE 
        WHEN similarity_score > 0.15 THEN '🎯 Perfect Match'
        WHEN similarity_score > 0.05 THEN '✅ Good Match'
        ELSE '📋 Related'
    END as match_quality
FROM search_similar_products_by_text('shirt for business meetings', 0.01, 5)
ORDER BY similarity_score DESC;

\echo ''
\echo 'Searching for: "casual denim jeans"'

SELECT 
    product_label,
    brand_label,
    category_label,
    similarity_score,
    CASE 
        WHEN similarity_score > 0.15 THEN '🎯 Perfect Match'
        WHEN similarity_score > 0.05 THEN '✅ Good Match'
        ELSE '📋 Related'
    END as match_quality
FROM search_similar_products_by_text('casual denim jeans', 0.01, 5)
ORDER BY similarity_score DESC;

-- Show embedding details
\echo ''
\echo '🧠 Step 5: AI Embedding Information'
\echo '------------------------------------'
SELECT 
    p.label as product_name,
    pe.embedding_type,
    pe.created_at as embedding_generated_at
FROM product_embeddings pe
JOIN product p ON pe.product_id = p.id
ORDER BY pe.created_at DESC;

-- Real-world use case examples
\echo ''
\echo '================================================================='
\echo '🛒 REAL-WORLD E-COMMERCE USE CASES'
\echo '================================================================='

\echo ''
\echo '📱 Use Case 1: Product Page "Customers Also Viewed"'
\echo '----------------------------------------------------'
\echo 'Customer viewing Oxford Shirt - Show similar products:'

SELECT 
    '👔 ' || product_label as recommended_product,
    brand_label,
    ROUND((similarity_score * 100)::NUMERIC, 1) || '%' as similarity_percentage,
    COALESCE(price::text, 'Price varies') as price_info
FROM find_similar_products(1, 0.05, 3)
ORDER BY similarity_score DESC;

\echo ''
\echo '🔍 Use Case 2: Smart Search with Natural Language'
\echo '--------------------------------------------------'
\echo 'Customer searches for "professional work clothes":'

SELECT 
    '👔 ' || product_label as search_result,
    brand_label,
    category_label,
    ROUND((similarity_score * 100)::NUMERIC, 1) || '% match' as relevance
FROM search_similar_products_by_text('professional work clothes', 0.01, 4)
ORDER BY similarity_score DESC;

\echo ''
\echo '🎯 Use Case 3: Cross-Selling Recommendations'
\echo '----------------------------------------------'
\echo 'Customer added jeans to cart - Suggest complementary items:'

SELECT 
    '👕 ' || product_label as complement_suggestion,
    brand_label,
    CASE 
        WHEN similarity_score > 0.2 THEN '🔥 Perfect Combo'
        WHEN similarity_score > 0.05 THEN '✅ Good Pairing'
        ELSE '📝 Consider This'
    END as pairing_strength
FROM find_similar_products(3, 0.01, 5)  -- Product ID 3 is jeans
WHERE product_id != 3
ORDER BY similarity_score DESC;

\echo ''
\echo '================================================================='
\echo '✅ AI RECOMMENDATION SYSTEM DEMO COMPLETED!'
\echo '================================================================='
\echo ''
\echo '🚀 Key Capabilities Demonstrated:'
\echo '   ✓ Vector-based product similarity using pgvector'
\echo '   ✓ Natural language product search'
\echo '   ✓ Content-based recommendations'
\echo '   ✓ Real-world e-commerce use cases'
\echo ''
\echo '📚 Next Steps:'
\echo '   • Add customer purchase data for collaborative filtering'
\echo '   • Implement real embedding models (OpenAI, Hugging Face)'
\echo '   • Set up recommendation caching for performance'
\echo '   • Integrate with your e-commerce application'
\echo ''
\echo '📖 Full Documentation: See AI_RECOMMENDATIONS.md'
\echo '================================================================='