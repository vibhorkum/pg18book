-- =================================================================
--  AI RECOMMENDATION SYSTEM EXAMPLES
--  PURPOSE: Demonstrates how to use the AI-powered recommendation
--           features for e-commerce applications
--  DATABASE: Should be run on west_ecommerce_data or east_ecommerce_data 
--            (databases with replicated product data)
-- =================================================================

-- Connect to the appropriate database
\c west_ecommerce_data

\echo '[AI EXAMPLES] ==> AI Recommendation System Usage Examples'
\echo '================================================================='

-- =================================================================
--  SECTION 1: SETUP AND INITIALIZATION
-- =================================================================

\echo '--> Step 1: Generate product embeddings...'
SELECT update_product_embeddings() as embeddings_created;

\echo '--> Step 2: Check available products...'
SELECT p.id, p.label, pc.label as category, pb.label as brand
FROM product p
JOIN product_category pc ON p.product_category_id = pc.id
JOIN product_brand pb ON p.product_brand_id = pb.id
ORDER BY p.id;

-- =================================================================
--  SECTION 2: CONTENT-BASED SIMILARITY EXAMPLES
-- =================================================================

\echo ''
\echo '================================================================='
\echo 'CONTENT-BASED PRODUCT SIMILARITY EXAMPLES'
\echo '================================================================='

\echo '--> Example 1: Find products similar to "Mens Classic Oxford Shirt" (product_id=1)...'
SELECT * FROM find_similar_products(1, 0.2, 5);

\echo '--> Example 2: Find products similar to "501 Original Fit Jeans" (product_id=3)...'
SELECT * FROM find_similar_products(3, 0.2, 5);

\echo '--> Example 3: Find products similar to "Calvin Klein Cotton Shirt" (product_id=4)...'
SELECT * FROM find_similar_products(4, 0.2, 5);

\echo '--> Example 4: Search for products similar to "athletic shirt for running"...'
SELECT * FROM search_similar_products_by_text('athletic shirt for running', 0.15, 5);

\echo '--> Example 5: Search for products similar to "formal business attire"...'
SELECT * FROM search_similar_products_by_text('formal business attire', 0.15, 5);

\echo '--> Example 6: Search for products similar to "casual weekend outfit"...'
SELECT * FROM search_similar_products_by_text('casual weekend outfit', 0.15, 5);

-- =================================================================
--  SECTION 3: SAMPLE CUSTOMER DATA FOR COLLABORATIVE FILTERING
-- =================================================================

\echo ''
\echo '================================================================='
\echo 'CREATING SAMPLE CUSTOMER AND PURCHASE DATA'
\echo '================================================================='

-- Check if customer table exists and what type of ID it uses
DO $$
DECLARE
    customer_table_exists BOOLEAN;
    id_column_type TEXT;
    current_db TEXT;
BEGIN
    SELECT current_database() INTO current_db;
    
    -- Check if customer table exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'customer' 
        AND table_schema IN ('public', 'west_customer', 'east_customer')
    ) INTO customer_table_exists;
    
    IF customer_table_exists THEN
        -- Check ID column type
        SELECT data_type INTO id_column_type
        FROM information_schema.columns 
        WHERE table_name = 'customer' 
        AND column_name = 'id'
        AND table_schema IN ('public', 'west_customer', 'east_customer')
        LIMIT 1;
        
        RAISE NOTICE 'Customer table found in % with ID type: %', current_db, id_column_type;
    ELSE
        RAISE NOTICE 'Customer table not found in %. Collaborative filtering examples will be skipped.', current_db;
    END IF;
END;
$$;

\echo '--> Adding sample customers (if customer table exists)...'
-- Try to insert sample customers - this may fail gracefully on some database configurations
INSERT INTO customer (first_name, last_name, phone_numbers, street_address, city, postal_code, country)
    VALUES
        ('Sarah', 'Johnson', '{"mobile": "+1-555-0102"}', '123 Fashion Ave', 'New York', 'NY 10001', 'USA'),
        ('Michael', 'Chen', '{"mobile": "+1-555-0103"}', '456 Style St', 'Los Angeles', 'CA 90210', 'USA'),
        ('Emma', 'Rodriguez', '{"mobile": "+1-555-0104"}', '789 Trend Blvd', 'Chicago', 'IL 60601', 'USA'),
        ('James', 'Wilson', '{"mobile": "+1-555-0105"}', '321 Modern Rd', 'Austin', 'TX 78701', 'USA'),
        ('Olivia', 'Davis', '{"mobile": "+1-555-0106"}', '654 Chic Lane', 'Seattle', 'WA 98101', 'USA')
    ON CONFLICT DO NOTHING;

\echo '--> Adding sample sales transactions (simplified for demo)...'
-- Note: This sample data is simplified and may not work in all database configurations
-- In production, you would have real customer IDs from your application
-- For demo purposes, we'll use existing customers or create minimal test data

-- Only proceed if we have customers
DO $$
DECLARE
    customer_count INTEGER;
    sample_customer_id TEXT;
BEGIN
    -- Count existing customers
    SELECT COUNT(*) INTO customer_count FROM customer LIMIT 1;
    
    IF customer_count > 0 THEN
        -- Get a sample customer ID for demo purposes
        SELECT id INTO sample_customer_id FROM customer LIMIT 1;
        
        RAISE NOTICE 'Found % customers. Using customer ID % for sample data.', customer_count, sample_customer_id;
        
        -- Insert a few sample transactions using the existing customer
        INSERT INTO sales_transaction (transaction_date, customer_id)
        VALUES 
            (CURRENT_DATE - INTERVAL '1 day', sample_customer_id),
            (CURRENT_DATE - INTERVAL '2 days', sample_customer_id)
        ON CONFLICT DO NOTHING;
        
    ELSE
        RAISE NOTICE 'No customers found. Skipping sales transaction sample data.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Could not create sample sales data: %', SQLERRM;
END;
$$;

\echo '--> Adding sample sales transaction lines (simplified)...'
-- Create some sample transaction lines for demonstration
-- This uses existing sales transactions and product variants

DO $$
DECLARE
    transaction_record RECORD;
    variant_record RECORD;
    line_count INTEGER := 0;
BEGIN
    -- Create sample transaction lines using existing data
    FOR transaction_record IN 
        SELECT id as transaction_id FROM sales_transaction LIMIT 3
    LOOP
        -- Add a few product variants to each transaction
        FOR variant_record IN 
            SELECT id as variant_id FROM product_variant LIMIT 2
        LOOP
            BEGIN
                INSERT INTO sales_transaction_line (sales_transaction_id, product_variant_id, qty, price_at_sale)
                VALUES (transaction_record.transaction_id, variant_record.variant_id, 1, 29.99);
                line_count := line_count + 1;
            EXCEPTION
                WHEN OTHERS THEN
                    -- Ignore conflicts or errors
                    NULL;
            END;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Created % sample transaction lines', line_count;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Could not create sample transaction lines: %', SQLERRM;
END;
$$;

\echo '--> Adding sample product ratings...'
-- Create some sample product ratings for demonstration
DO $$
DECLARE
    customer_record RECORD;
    product_record RECORD;
    rating_count INTEGER := 0;
BEGIN
    -- Create some sample ratings using existing customers and products
    FOR customer_record IN 
        SELECT id as customer_id FROM customer LIMIT 3
    LOOP
        FOR product_record IN 
            SELECT id as product_id FROM product LIMIT 2
        LOOP
            BEGIN
                INSERT INTO product_ratings (customer_id, product_id, rating, review_text)
                VALUES (
                    customer_record.customer_id, 
                    product_record.product_id, 
                    4 + ROUND(RANDOM())::INTEGER, -- Random rating 4 or 5
                    'Great product, would recommend!'
                );
                rating_count := rating_count + 1;
            EXCEPTION
                WHEN OTHERS THEN
                    -- Ignore conflicts or errors
                    NULL;
            END;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Created % sample product ratings', rating_count;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Could not create sample product ratings: %', SQLERRM;
END;
$$;

-- =================================================================
--  SECTION 4: COLLABORATIVE FILTERING EXAMPLES
-- =================================================================

\echo ''
\echo '================================================================='
\echo 'COLLABORATIVE FILTERING EXAMPLES'
\echo '================================================================='

\echo '--> Step 1: Update customer purchase profiles...'
SELECT update_customer_purchase_profiles() as profiles_updated;

\echo '--> Step 2: View customer purchase profiles...'
SELECT 
    c.first_name || ' ' || c.last_name as customer_name,
    pc.label as category,
    cpp.purchase_frequency,
    cpp.total_spent,
    cpp.avg_rating,
    cpp.preference_score
FROM customer_purchase_profile cpp
JOIN customer c ON cpp.customer_id = c.id
JOIN product_category pc ON cpp.product_category_id = pc.id
ORDER BY cpp.customer_id, cpp.preference_score DESC;

\echo '--> Example 1: Find customers similar to Marc (customer_id=1)...'
SELECT 
    sc.customer_id,
    c.first_name || ' ' || c.last_name as similar_customer,
    sc.similarity_score,
    sc.shared_categories
FROM find_similar_customers(1, 5) sc
JOIN customer c ON sc.customer_id = c.id;

\echo '--> Example 2: Get collaborative recommendations for Marc (customer_id=1)...'
SELECT * FROM get_collaborative_recommendations(1, 5);

\echo '--> Example 3: Get collaborative recommendations for Sarah (customer_id=2)...'
SELECT * FROM get_collaborative_recommendations(2, 5);

\echo '--> Example 4: Get collaborative recommendations for Michael (customer_id=3)...'
SELECT * FROM get_collaborative_recommendations(3, 5);

-- =================================================================
--  SECTION 5: HYBRID RECOMMENDATION EXAMPLES
-- =================================================================

\echo ''
\echo '================================================================='
\echo 'HYBRID RECOMMENDATION SYSTEM EXAMPLES'
\echo '================================================================='

\echo '--> Example 1: Get hybrid recommendations for Marc (customer_id=1) based on Oxford shirt (product_id=1)...'
SELECT * FROM get_hybrid_recommendations(1, 1, 8);

\echo '--> Example 2: Get hybrid recommendations for Sarah (customer_id=2) based on her purchase history...'
SELECT * FROM get_hybrid_recommendations(2, NULL, 8);

\echo '--> Example 3: Get hybrid recommendations for Michael (customer_id=3) based on athletic t-shirt (product_id=9)...'
SELECT * FROM get_hybrid_recommendations(3, 9, 8);

\echo '--> Example 4: Get hybrid recommendations for Emma (customer_id=4) based on polo shirt (product_id=6)...'
SELECT * FROM get_hybrid_recommendations(4, 6, 8);

-- =================================================================
--  SECTION 6: ADVANCED ANALYTICS EXAMPLES
-- =================================================================

\echo ''
\echo '================================================================='
\echo 'ADVANCED ANALYTICS AND INSIGHTS'
\echo '================================================================='

\echo '--> Analysis 1: Most popular products by purchase frequency...'
SELECT 
    p.label as product_name,
    pb.label as brand,
    pc.label as category,
    COUNT(stl.id) as times_purchased,
    SUM(stl.qty) as total_quantity,
    SUM(stl.price_at_sale * stl.qty) as total_revenue,
    AVG(pr.rating) as avg_rating
FROM product p
JOIN product_brand pb ON p.product_brand_id = pb.id
JOIN product_category pc ON p.product_category_id = pc.id
JOIN product_variant pv ON p.id = pv.product_id
JOIN sales_transaction_line stl ON pv.id = stl.product_variant_id
LEFT JOIN product_ratings pr ON p.id = pr.product_id
GROUP BY p.id, p.label, pb.label, pc.label
ORDER BY times_purchased DESC;

\echo '--> Analysis 2: Customer spending patterns by category...'
SELECT 
    c.first_name || ' ' || c.last_name as customer_name,
    pc.label as category,
    SUM(stl.price_at_sale * stl.qty) as total_spent,
    COUNT(stl.id) as purchases,
    AVG(stl.price_at_sale) as avg_item_price
FROM customer c
JOIN sales_transaction st ON c.id = st.customer_id
JOIN sales_transaction_line stl ON st.id = stl.sales_transaction_id
JOIN product_variant pv ON stl.product_variant_id = pv.id
JOIN product p ON pv.product_id = p.id
JOIN product_category pc ON p.product_category_id = pc.id
GROUP BY c.id, c.first_name, c.last_name, pc.id, pc.label
ORDER BY c.id, total_spent DESC;

\echo '--> Analysis 3: Product similarity matrix (top similarities)...'
SELECT 
    p1.label as product_1,
    p2.label as product_2,
    ROUND((1 - (pe1.embedding <=> pe2.embedding))::NUMERIC, 4) as similarity_score
FROM product_embeddings pe1
JOIN product_embeddings pe2 ON pe2.embedding_type = pe1.embedding_type
JOIN product p1 ON pe1.product_id = p1.id
JOIN product p2 ON pe2.product_id = p2.id
WHERE pe1.product_id < pe2.product_id  -- Avoid duplicates
AND (1 - (pe1.embedding <=> pe2.embedding)) > 0.3  -- Only high similarities
ORDER BY similarity_score DESC
LIMIT 20;

\echo '--> Analysis 4: Cross-selling opportunities (frequently bought together)...'
WITH purchase_pairs AS (
    SELECT 
        stl1.product_variant_id as variant_1,
        stl2.product_variant_id as variant_2,
        COUNT(*) as frequency
    FROM sales_transaction_line stl1
    JOIN sales_transaction_line stl2 ON stl1.sales_transaction_id = stl2.sales_transaction_id
    WHERE stl1.product_variant_id < stl2.product_variant_id
    GROUP BY stl1.product_variant_id, stl2.product_variant_id
    HAVING COUNT(*) > 1
)
SELECT 
    p1.label as product_1,
    p2.label as product_2,
    pp.frequency as bought_together_count,
    ROUND((pp.frequency::FLOAT / total_orders.total * 100), 2) as percentage
FROM purchase_pairs pp
JOIN product_variant pv1 ON pp.variant_1 = pv1.id
JOIN product_variant pv2 ON pp.variant_2 = pv2.id
JOIN product p1 ON pv1.product_id = p1.id
JOIN product p2 ON pv2.product_id = p2.id
CROSS JOIN (SELECT COUNT(DISTINCT sales_transaction_id) as total FROM sales_transaction_line) total_orders
ORDER BY pp.frequency DESC;

\echo ''
\echo '================================================================='
\echo 'AI RECOMMENDATION SYSTEM EXAMPLES COMPLETED'
\echo '================================================================='
\echo 'The AI recommendation system is now ready for use!'
\echo 'Key functions available:'
\echo '  - find_similar_products(product_id): Content-based similarity'
\echo '  - search_similar_products_by_text(query): Text-based search'
\echo '  - get_collaborative_recommendations(customer_id): Collaborative filtering'
\echo '  - get_hybrid_recommendations(customer_id, [product_id]): Combined approach'
\echo '================================================================='