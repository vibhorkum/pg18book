# AI-Powered E-commerce Recommendations

This document explains the AI-powered product recommendation system implemented for the PostgreSQL e-commerce sample application.

## Overview

The AI recommendation system uses PostgreSQL's `pgvector` extension to provide:

1. **Content-based similarity search** - Find products similar to a given product using vector embeddings
2. **Text-based product search** - Search products using natural language queries
3. **Collaborative filtering** - Recommend products based on similar customer purchase patterns
4. **Hybrid recommendations** - Combine content-based and collaborative filtering for better results

## Prerequisites

- PostgreSQL 16+ with `pgvector` extension installed
- Existing e-commerce database with product catalog
- Customer and sales transaction data

## Installation

### 1. Install pgvector Extension

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql-16-pgvector

# Or compile from source
git clone https://github.com/pgvector/pgvector.git
cd pgvector
make
sudo make install
```

### 2. Set Up AI Recommendation System

For **psql** users:
```bash
# Set up the main database with enhanced sample data
psql -U your_superuser -f psql_scripts/reference_data.sql
psql -U your_superuser -d ecommerce_reference_data -f psql_scripts/enhanced_sample_data.sql

# Set up US subscriber database  
psql -U your_superuser -f psql_scripts/us_ecommerce_data.sql

# Install AI recommendation system
psql -U your_superuser -d us_ecommerce_data -f psql_scripts/ai_recommendations.sql

# Run example demonstrations
psql -U your_superuser -d us_ecommerce_data -f psql_scripts/ai_examples.sql
```

For **pgAdmin4** users:
1. Connect to your database
2. Run `/pgAdmin4_sqls/ai_recommendations.sql`
3. Use individual functions as needed

## AI Features

### Content-Based Similarity Search

#### Find Similar Products
```sql
-- Find products similar to product ID 1
SELECT * FROM find_similar_products(1, 0.3, 10);
```

Returns products with similarity scores based on:
- Product descriptions
- Brand and category information
- Product attributes (color, size, material, etc.)

#### Text-Based Search
```sql
-- Search for products using natural language
SELECT * FROM search_similar_products_by_text('athletic shirt for running', 0.2, 5);
SELECT * FROM search_similar_products_by_text('formal business attire', 0.2, 5);
```

### Vector Embeddings

The system generates 384-dimensional embeddings for each product by combining:
- Product name and descriptions
- Brand and category labels  
- Product variant attributes (JSON)

```sql
-- Generate/update embeddings for all products
SELECT update_product_embeddings();

-- View embeddings
SELECT product_id, embedding_type, created_at 
FROM product_embeddings 
LIMIT 5;
```

### Collaborative Filtering

#### Customer Purchase Profiles
```sql
-- Update customer behavior profiles
SELECT update_customer_purchase_profiles();

-- View customer preferences by category
SELECT 
    c.first_name || ' ' || c.last_name as customer_name,
    pc.label as category,
    cpp.preference_score,
    cpp.purchase_frequency,
    cpp.total_spent
FROM customer_purchase_profile cpp
JOIN customer c ON cpp.customer_id = c.id
JOIN product_category pc ON cpp.product_category_id = pc.id
ORDER BY cpp.preference_score DESC;
```

#### Find Similar Customers
```sql
-- Find customers with similar purchase patterns
SELECT * FROM find_similar_customers(1, 5);
```

#### Collaborative Recommendations
```sql
-- Get recommendations based on similar customers
SELECT * FROM get_collaborative_recommendations(1, 10);
```

### Hybrid Recommendation System

Combines content-based and collaborative filtering:

```sql
-- Hybrid recommendations with product context
SELECT * FROM get_hybrid_recommendations(
    customer_id := 1, 
    product_id := 1,  -- Optional: base recommendations on this product
    max_results := 10
);

-- Hybrid recommendations based only on customer history
SELECT * FROM get_hybrid_recommendations(1, NULL, 10);
```

## Database Schema

### New AI Tables

- **`product_embeddings`** - Stores vector embeddings for products
- **`customer_purchase_profile`** - Customer behavior and preferences by category
- **`product_ratings`** - Customer ratings and reviews
- **`product_similarity_cache`** - Cached similarity scores for performance
- **`recommendation_cache`** - Cached recommendation results

### Key Indexes

- Vector similarity index: `idx_product_embeddings_vector` using IVFFlat
- Customer behavior indexes for fast collaborative filtering
- Similarity cache indexes for performance optimization

## Example Use Cases

### E-commerce Product Pages

**"Customers who viewed this item also viewed"**
```sql
SELECT product_label, brand_label, similarity_score, price
FROM find_similar_products($product_id, 0.3, 5);
```

### Search Results

**Smart product search with typos and synonyms**
```sql
SELECT product_label, brand_label, category_label, similarity_score
FROM search_similar_products_by_text($user_query, 0.2, 20);
```

### Personalized Recommendations

**"Recommended for you" based on purchase history**
```sql
SELECT product_label, recommendation_score, reason
FROM get_hybrid_recommendations($customer_id, NULL, 10);
```

### Shopping Cart Suggestions

**"Frequently bought together"**
```sql
WITH recent_purchases AS (
    SELECT DISTINCT pv.product_id
    FROM sales_transaction st
    JOIN sales_transaction_line stl ON st.id = stl.sales_transaction_id
    JOIN product_variant pv ON stl.product_variant_id = pv.id
    WHERE st.customer_id = $customer_id
    AND st.transaction_date >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT DISTINCT r.*
FROM recent_purchases rp
CROSS JOIN LATERAL (
    SELECT * FROM find_similar_products(rp.product_id, 0.4, 3)
) r;
```

## Performance Considerations

### Vector Index Optimization

```sql
-- Create vector index with appropriate lists parameter
-- Rules: lists = rows / 1000 for up to 1M rows
DROP INDEX IF EXISTS idx_product_embeddings_vector;
CREATE INDEX idx_product_embeddings_vector ON product_embeddings 
USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- For larger datasets, use HNSW index
CREATE INDEX idx_product_embeddings_hnsw ON product_embeddings 
USING hnsw (embedding vector_cosine_ops);
```

### Caching Strategy

- **Recommendation Cache**: Pre-compute recommendations for active customers
- **Similarity Cache**: Store frequently accessed product similarities
- **TTL Management**: Set appropriate expiration times for cached results

```sql
-- Clean up expired cache entries
DELETE FROM recommendation_cache 
WHERE expires_at < CURRENT_TIMESTAMP;
```

## Integration with Real ML Models

The current implementation uses a mock embedding generator. For production:

### Option 1: External ML Service
```sql
-- Replace generate_simple_embedding() with external API call
CREATE OR REPLACE FUNCTION generate_embedding_api(text_input TEXT)
RETURNS vector(384) AS $$
    # Python function to call OpenAI, Hugging Face, or custom ML service
    # Return proper 384-dimensional embeddings
$$ LANGUAGE plpython3u;
```

### Option 2: Sentence Transformers (PostgreSQL + Python)
```sql
-- Use sentence-transformers library
CREATE OR REPLACE FUNCTION generate_embedding_transformer(text_input TEXT)
RETURNS vector(384) AS $$
    from sentence_transformers import SentenceTransformer
    import numpy as np
    
    model = SentenceTransformer('all-MiniLM-L6-v2')
    embedding = model.encode(text_input)
    return embedding.tolist()
$$ LANGUAGE plpython3u;
```

### Option 3: pgml Extension
```sql
-- Use PostgresML for in-database ML
SELECT pgml.embed('sentence-transformers/all-MiniLM-L6-v2', product_description)
FROM product;
```

## Analytics and Insights

### Recommendation Performance
```sql
-- Track recommendation click-through rates
SELECT 
    recommendation_type,
    AVG(score) as avg_recommendation_score,
    COUNT(*) as recommendations_given
FROM recommendation_cache 
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY recommendation_type;
```

### Product Similarity Analysis
```sql
-- Find products that are similar to many others (versatile products)
SELECT 
    p.label,
    COUNT(*) as similar_product_count,
    AVG(psc.similarity_score) as avg_similarity
FROM product_similarity_cache psc
JOIN product p ON psc.product_id_1 = p.id
WHERE psc.similarity_score > 0.5
GROUP BY p.id, p.label
ORDER BY similar_product_count DESC;
```

### Customer Behavior Insights
```sql
-- Customer diversity score (how varied their purchases are)
SELECT 
    c.first_name || ' ' || c.last_name as customer,
    COUNT(DISTINCT cpp.product_category_id) as categories_purchased,
    AVG(cpp.preference_score) as avg_preference_strength
FROM customer c
JOIN customer_purchase_profile cpp ON c.id = cpp.customer_id
GROUP BY c.id, c.first_name, c.last_name
ORDER BY categories_purchased DESC;
```

## Troubleshooting

### Common Issues

1. **Low similarity scores**: Adjust threshold values or improve text preprocessing
2. **Slow vector queries**: Ensure proper indexing and consider HNSW for large datasets
3. **Empty recommendations**: Verify sufficient training data and customer purchase history

### Monitoring Queries

```sql
-- Check embedding generation status
SELECT 
    COUNT(*) as total_products,
    COUNT(pe.product_id) as products_with_embeddings,
    ROUND(COUNT(pe.product_id)::NUMERIC / COUNT(*)::NUMERIC * 100, 2) as coverage_percentage
FROM product p
LEFT JOIN product_embeddings pe ON p.id = pe.product_id;

-- Monitor vector index usage
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes 
WHERE indexname LIKE '%vector%';
```

## Next Steps

1. **A/B Testing**: Compare recommendation performance against baseline
2. **Real-time Updates**: Implement triggers for automatic embedding updates
3. **Cross-domain Recommendations**: Extend to related product categories
4. **Seasonal Adjustments**: Factor in seasonal trends and promotions
5. **Cold Start Problem**: Handle new products and customers without history

## Support

For questions about the AI recommendation system:
- Review the example queries in `psql_scripts/ai_examples.sql`
- Check function documentation in `psql_scripts/ai_recommendations.sql`
- Monitor PostgreSQL logs for performance issues
- Consider upgrading to PostgreSQL 17+ for enhanced vector capabilities