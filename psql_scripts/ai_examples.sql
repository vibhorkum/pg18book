-- =================================================================
--  AI RECOMMENDATION SYSTEM EXAMPLES
--  PURPOSE: Demonstrates how to use the AI-powered recommendation
--           features for e-commerce applications
-- =================================================================

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

\echo '--> Adding sample customers...'
INSERT INTO customer (id, first_name, last_name, phone_numbers, street_address, city, postal_code, country)
    VALUES
        (2, 'Sarah', 'Johnson', '{"mobile": "+1-555-0102"}', '123 Fashion Ave', 'New York', 'NY 10001', 'USA'),
        (3, 'Michael', 'Chen', '{"mobile": "+1-555-0103"}', '456 Style St', 'Los Angeles', 'CA 90210', 'USA'),
        (4, 'Emma', 'Rodriguez', '{"mobile": "+1-555-0104"}', '789 Trend Blvd', 'Chicago', 'IL 60601', 'USA'),
        (5, 'James', 'Wilson', '{"mobile": "+1-555-0105"}', '321 Modern Rd', 'Austin', 'TX 78701', 'USA'),
        (6, 'Olivia', 'Davis', '{"mobile": "+1-555-0106"}', '654 Chic Lane', 'Seattle', 'WA 98101', 'USA')
    ON CONFLICT (id) DO NOTHING;

\echo '--> Adding sample sales transactions...'
INSERT INTO sales_transaction (id, transaction_date, customer_id)
    VALUES
        ('550e8400-e29b-41d4-a716-446655440001', '2024-12-01', 1),
        ('550e8400-e29b-41d4-a716-446655440002', '2024-12-02', 2),
        ('550e8400-e29b-41d4-a716-446655440003', '2024-12-03', 2),
        ('550e8400-e29b-41d4-a716-446655440004', '2024-12-04', 3),
        ('550e8400-e29b-41d4-a716-446655440005', '2024-12-05', 3),
        ('550e8400-e29b-41d4-a716-446655440006', '2024-12-06', 4),
        ('550e8400-e29b-41d4-a716-446655440007', '2024-12-07', 4),
        ('550e8400-e29b-41d4-a716-446655440008', '2024-12-08', 5),
        ('550e8400-e29b-41d4-a716-446655440009', '2024-12-09', 5),
        ('550e8400-e29b-41d4-a716-446655440010', '2024-12-10', 6),
        ('550e8400-e29b-41d4-a716-446655440011', '2024-12-11', 6),
        ('550e8400-e29b-41d4-a716-446655440012', '2024-12-12', 1),
        ('550e8400-e29b-41d4-a716-446655440013', '2024-12-13', 2),
        ('550e8400-e29b-41d4-a716-446655440014', '2024-12-14', 3)
    ON CONFLICT (id) DO NOTHING;

\echo '--> Adding sample sales transaction lines...'
INSERT INTO sales_transaction_line (id, sales_transaction_id, product_variant_id, qty, price_at_sale)
    VALUES
        -- Customer 1 (Marc) purchases - business professional
        ('650e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440001', 1, 1, 31.00), -- Oxford shirt
        ('650e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440001', 13, 1, 125.00), -- Ralph Lauren chinos
        ('650e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440012', 4, 1, 89.99), -- Calvin Klein shirt
        ('650e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440012', 40, 1, 59.99), -- Calvin Klein belt
        
        -- Customer 2 (Sarah) purchases - fashion-forward professional
        ('650e8400-e29b-41d4-a716-446655440005', '550e8400-e29b-41d4-a716-446655440002', 7, 1, 159.99), -- Zara silk blouse
        ('650e8400-e29b-41d4-a716-446655440006', '550e8400-e29b-41d4-a716-446655440002', 16, 1, 79.99), -- Zara midi dress
        ('650e8400-e29b-41d4-a716-446655440007', '550e8400-e29b-41d4-a716-446655440003', 37, 1, 89.99), -- Adidas sneakers
        ('650e8400-e29b-41d4-a716-446655440008', '550e8400-e29b-41d4-a716-446655440013', 43, 1, 149.99), -- Tommy Hilfiger watch
        
        -- Customer 3 (Michael) purchases - athletic/casual
        ('650e8400-e29b-41d4-a716-446655440009', '550e8400-e29b-41d4-a716-446655440004', 19, 2, 34.99), -- Nike athletic t-shirt
        ('650e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440004', 22, 1, 59.99), -- Adidas track pants
        ('650e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440005', 34, 1, 129.99), -- Nike running shoes
        ('650e8400-e29b-41d4-a716-446655440012', '550e8400-e29b-41d4-a716-446655440014', 28, 1, 99.90), -- Uniqlo down jacket
        
        -- Customer 4 (Emma) purchases - mixed style
        ('650e8400-e29b-41d4-a716-446655440013', '550e8400-e29b-41d4-a716-446655440006', 10, 1, 69.99), -- Tommy Hilfiger polo
        ('650e8400-e29b-41d4-a716-446655440014', '550e8400-e29b-41d4-a716-446655440006', 3, 1, 33.50), -- 501 jeans
        ('650e8400-e29b-41d4-a716-446655440015', '550e8400-e29b-41d4-a716-446655440007', 31, 1, 149.99), -- Lacoste windbreaker
        
        -- Customer 5 (James) purchases - business casual
        ('650e8400-e29b-41d4-a716-446655440016', '550e8400-e29b-41d4-a716-446655440008', 5, 1, 89.99), -- Calvin Klein shirt (blue)
        ('650e8400-e29b-41d4-a716-446655440017', '550e8400-e29b-41d4-a716-446655440008', 14, 1, 125.00), -- Ralph Lauren chinos (navy)
        ('650e8400-e29b-41d4-a716-446655440018', '550e8400-e29b-41d4-a716-446655440009', 44, 1, 149.99), -- Tommy Hilfiger watch (brown)
        
        -- Customer 6 (Olivia) purchases - athletic/fitness focused
        ('650e8400-e29b-41d4-a716-446655440019', '550e8400-e29b-41d4-a716-446655440010', 25, 2, 49.99), -- Under Armour sports bra
        ('650e8400-e29b-41d4-a716-446655440020', '550e8400-e29b-41d4-a716-446655440010', 20, 1, 34.99), -- Nike athletic t-shirt (grey)
        ('650e8400-e29b-41d4-a716-446655440021', '550e8400-e29b-41d4-a716-446655440011', 35, 1, 129.99), -- Nike running shoes (white)
        ('650e8400-e29b-41d4-a716-446655440022', '550e8400-e29b-41d4-a716-446655440011', 23, 1, 59.99) -- Adidas track pants (navy)
    ON CONFLICT (id) DO NOTHING;

\echo '--> Adding sample product ratings...'
INSERT INTO product_ratings (customer_id, product_id, rating, review_text)
    VALUES
        (1, 1, 5, 'Excellent quality Oxford shirt, perfect for business meetings.'),
        (1, 4, 4, 'Great fit and quality, slightly expensive but worth it.'),
        (1, 7, 5, 'These chinos are my go-to for business casual events.'),
        (2, 5, 5, 'Beautiful silk blouse, love the professional look.'),
        (2, 8, 4, 'Elegant dress, great for work and evening events.'),
        (2, 15, 4, 'Comfortable sneakers for casual wear.'),
        (3, 9, 5, 'Perfect athletic shirt, keeps me dry during workouts.'),
        (3, 10, 4, 'Classic Adidas style, very comfortable.'),
        (3, 14, 5, 'Amazing running shoes, great for long distance.'),
        (4, 6, 4, 'Nice polo shirt, good quality and fit.'),
        (4, 3, 5, 'Love these 501 jeans, classic and durable.'),
        (4, 13, 4, 'Good windbreaker for unpredictable weather.'),
        (5, 4, 5, 'Excellent business shirt, highly recommended.'),
        (5, 7, 4, 'Good quality chinos, professional appearance.'),
        (6, 11, 5, 'Best sports bra I''ve owned, great support.'),
        (6, 9, 4, 'Good athletic shirt, comfortable for workouts.'),
        (6, 14, 5, 'Excellent running shoes, very comfortable.')
    ON CONFLICT (customer_id, product_id) DO NOTHING;

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