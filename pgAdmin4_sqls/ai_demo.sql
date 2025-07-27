-- =================================================================
--  AI RECOMMENDATION SYSTEM DEMO (pgAdmin4 Version)
--  PURPOSE: Simple demonstration for pgAdmin4 Query Tool
--  NOTE: Run these queries one section at a time in pgAdmin4
-- =================================================================

-- ============================================================
-- 🤖 AI-POWERED E-COMMERCE RECOMMENDATION SYSTEM DEMO
-- ============================================================

-- Setup: Generate embeddings for all products
-- Section 1: Generate AI embeddings
SELECT update_product_embeddings() as embeddings_generated;

-- Section 2: Show available products
SELECT 
    p.id,
    p.label as product_name,
    pb.label as brand,
    pc.label as category
FROM product p
JOIN product_brand pb ON p.product_brand_id = pb.id
JOIN product_category pc ON p.product_category_id = pc.id
ORDER BY p.id;

-- Section 3: Content-Based Similarity Search
-- Finding products similar to "Mens Classic Oxford Shirt" (ID: 1)
SELECT 
    product_id,
    product_label,
    brand_label,
    similarity_score,
    CASE 
        WHEN similarity_score > 0.5 THEN 'Highly Similar'
        WHEN similarity_score > 0.3 THEN 'Similar' 
        ELSE 'Somewhat Related'
    END as similarity_level
FROM find_similar_products(1, 0.1, 10)
ORDER BY similarity_score DESC;

-- Section 4: AI-Powered Text Search
-- Searching for: "shirt for business meetings"
SELECT 
    product_label,
    brand_label,
    category_label,
    similarity_score,
    CASE 
        WHEN similarity_score > 0.3 THEN 'Perfect Match'
        WHEN similarity_score > 0.2 THEN 'Good Match'
        ELSE 'Related'
    END as match_quality
FROM search_similar_products_by_text('shirt for business meetings', 0.1, 5)
ORDER BY similarity_score DESC;

-- Searching for: "casual denim jeans"
SELECT 
    product_label,
    brand_label,
    category_label,
    similarity_score,
    CASE 
        WHEN similarity_score > 0.3 THEN 'Perfect Match'
        WHEN similarity_score > 0.2 THEN 'Good Match'
        ELSE 'Related'
    END as match_quality
FROM search_similar_products_by_text('casual denim jeans', 0.1, 5)
ORDER BY similarity_score DESC;

-- Section 5: AI Embedding Information
SELECT 
    p.label as product_name,
    pe.embedding_type,
    pe.created_at as embedding_generated_at
FROM product_embeddings pe
JOIN product p ON pe.product_id = p.id
ORDER BY pe.created_at DESC;

-- ============================================================
-- 🛒 REAL-WORLD E-COMMERCE USE CASES
-- ============================================================

-- Use Case 1: Product Page "Customers Also Viewed"
-- Customer viewing Oxford Shirt - Show similar products:
SELECT 
    'Recommended: ' || product_label as recommended_product,
    brand_label,
    ROUND((similarity_score * 100)::NUMERIC, 1) || '%' as similarity_percentage,
    COALESCE(price::text, 'Price varies') as price_info
FROM find_similar_products(1, 0.3, 3)
ORDER BY similarity_score DESC;

-- Use Case 2: Smart Search with Natural Language
-- Customer searches for "professional work clothes":
SELECT 
    'Found: ' || product_label as search_result,
    brand_label,
    category_label,
    ROUND((similarity_score * 100)::NUMERIC, 1) || '% match' as relevance
FROM search_similar_products_by_text('professional work clothes', 0.15, 4)
ORDER BY similarity_score DESC;

-- Use Case 3: Cross-Selling Recommendations
-- Customer added jeans to cart - Suggest complementary items:
SELECT 
    'Suggest: ' || product_label as complement_suggestion,
    brand_label,
    CASE 
        WHEN similarity_score > 0.4 THEN 'Perfect Combo'
        WHEN similarity_score > 0.2 THEN 'Good Pairing'
        ELSE 'Consider This'
    END as pairing_strength
FROM find_similar_products(3, 0.15, 5)  -- Product ID 3 is jeans
WHERE product_id != 3
ORDER BY similarity_score DESC;

-- Section 6: System Performance Check
-- Check embedding coverage
SELECT 
    COUNT(*) as total_products,
    COUNT(pe.product_id) as products_with_embeddings,
    ROUND(COUNT(pe.product_id)::NUMERIC / COUNT(*)::NUMERIC * 100, 2) as coverage_percentage
FROM product p
LEFT JOIN product_embeddings pe ON p.id = pe.product_id;

-- Check vector index status
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes 
WHERE indexname LIKE '%vector%';

-- ============================================================
-- 🔬 ADVANCED EXPERIMENTS
-- ============================================================

-- Experiment 1: Test different similarity thresholds
SELECT 
    'Threshold 0.5' as test_name,
    COUNT(*) as results_count
FROM find_similar_products(1, 0.5, 10)
UNION ALL
SELECT 
    'Threshold 0.3' as test_name,
    COUNT(*) as results_count
FROM find_similar_products(1, 0.3, 10)
UNION ALL
SELECT 
    'Threshold 0.1' as test_name,
    COUNT(*) as results_count
FROM find_similar_products(1, 0.1, 10);

-- Experiment 2: Compare search approaches
SELECT 
    'Vector Search' as approach,
    product_label,
    similarity_score
FROM search_similar_products_by_text('shirt', 0.1, 3)
UNION ALL
SELECT 
    'Traditional LIKE' as approach,
    label as product_label,
    1.0 as similarity_score
FROM product 
WHERE LOWER(label) LIKE '%shirt%'
ORDER BY approach, similarity_score DESC;

-- Experiment 3: Raw vector similarity
SELECT 
    p1.label as product_1,
    p2.label as product_2,
    ROUND((1 - (pe1.embedding <=> pe2.embedding))::NUMERIC, 4) as raw_similarity
FROM product_embeddings pe1
JOIN product_embeddings pe2 ON pe2.embedding_type = pe1.embedding_type
JOIN product p1 ON pe1.product_id = p1.id
JOIN product p2 ON pe2.product_id = p2.id
WHERE pe1.product_id < pe2.product_id  -- Avoid duplicates
ORDER BY raw_similarity DESC;

-- ============================================================
-- ✅ DEMO COMPLETED - READY FOR PRODUCTION!
-- ============================================================

/*
Key Capabilities Demonstrated:
✓ Vector-based product similarity using pgvector
✓ Natural language product search
✓ Content-based recommendations
✓ Real-world e-commerce use cases

Next Steps:
• Add customer purchase data for collaborative filtering
• Implement real embedding models (OpenAI, Hugging Face)
• Set up recommendation caching for performance
• Integrate with your e-commerce application

Full Documentation: See AI_RECOMMENDATIONS.md
*/