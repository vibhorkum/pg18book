# AI Database (aidb) for E-commerce Embeddings

This directory contains the implementation of an AI-powered database for e-commerce product search and recommendations using PostgreSQL with pgvector and OpenAI embeddings.

## Overview

The AI database (`aidb`) provides:
- **Vector embeddings** for product search using pgvector
- **OpenAI integration** for natural language queries
- **Semantic similarity search** across products
- **Product recommendation** based on complementary categories
- **Chat interface** for natural language product queries

## Files

### Core Setup Scripts
- `aidb_setup.sql` - Master setup script that creates and configures the entire AI database
- `database_definitions/create_aidb.sql` - Creates the aidb database
- `database_definitions/aidb.sql` - Core schema, tables, functions and sample data

### Data and Validation
- `aidb_data_integration.sql` - Populates database with extended sample data
- `aidb_validation.sql` - Tests database setup and functionality
- `aidb_cleanup.sql` - Drops the aidb database completely

## Quick Start

### 1. Prerequisites
- PostgreSQL 18+ with pgvector extension
- plpython3u extension (requires superuser privileges)
- OpenAI API key

### 2. Setup Database
```bash
# Run the master setup script
psql -U postgres -f psql_scripts/aidb_setup.sql

# Optional: Add more sample data
psql -U postgres -f psql_scripts/aidb_data_integration.sql

# Validate the setup
psql -U postgres -f psql_scripts/aidb_validation.sql
```

### 3. Configure OpenAI API Key
```sql
\c aidb
SELECT set_config('api.openai_api_key','sk-...YOUR_KEY...', false);
```

### 4. Generate Embeddings
```sql
-- Generate embeddings for all products
SELECT api.embed_products(25);
```

### 5. Test the System
```sql
-- Search for similar products
SELECT * FROM api.similar_items('blue casual summer shirt for men', 5);

-- Chat interface
SELECT * FROM api.chat('Tell me about women''s black jeans under $50', 3);

-- View product pairs
SELECT * FROM api.product_pairs_demo LIMIT 10;
```

## Database Schema

### Core Tables
- `public.product_category` - Product categories (Shirt, Jeans, etc.)
- `public.product_brand` - Brand information  
- `public.product` - Products with embedding vectors
- `public.product_variant` - Product variants (SKU, color, size)
- `public.product_variant_price` - Pricing information

### AI/API Schema
- `api.category_complements` - Category pairing rules
- `api.openai_embed()` - Single text embedding function
- `api.embed_products()` - Batch embedding generation
- `api.similar_items()` - Semantic similarity search
- `api.chat()` - Natural language chat interface
- `api.product_pairs_demo` - View of complementary products

## Key Features

### Vector Search
Uses pgvector with cosine similarity for semantic product search:
```sql
SELECT * FROM api.similar_items('comfortable running shoes', 5);
```

### Product Recommendations
Finds complementary products based on category relationships:
```sql
SELECT * FROM api.product_pairs_demo 
WHERE base_name LIKE '%jeans%' 
ORDER BY cosine_distance 
LIMIT 5;
```

### Natural Language Interface
Chat-based product search with OpenAI:
```sql
SELECT * FROM api.chat('I need a formal shirt for work meetings', 3);
```

## Configuration

### OpenAI Settings
The system uses OpenAI's `text-embedding-3-small` model for embeddings and `gpt-4o-mini` for chat responses. Configure your API key:

```sql
-- Session-scoped (temporary)
SELECT set_config('api.openai_api_key','sk-...', false);

-- Optional: Set organization
SELECT set_config('api.openai_organization','org-...', false);
```

### Vector Index
The system creates an IVFFlat index for efficient similarity search:
```sql
CREATE INDEX product_embedding_ivfflat_idx
  ON public.product USING ivfflat (embedding vector_cosine_ops) 
  WITH (lists = 100);
```

## Sample Data

The database includes realistic e-commerce sample data:
- 8 product categories (Shirt, Jeans, T-Shirt, etc.)
- 8 brands (Urban Style, Nike, Adidas, etc.) 
- 13+ products with variants and pricing
- Category complement mapping for recommendations

## Cleanup

To completely remove the AI database:
```bash
psql -U postgres -f psql_scripts/aidb_cleanup.sql
```

## Integration with Existing E-commerce Data

The AI database can be extended to work with existing e-commerce reference data from this repository. The schema is designed to be compatible with the existing `ecommerce_reference_data` structure while adding AI/ML capabilities.

## Security Notes

- The system uses `plpython3u` (untrusted Python) which requires superuser privileges
- OpenAI API keys are stored as session variables (not persistent)
- In production, consider using more secure credential management
- The chat interface sends data to OpenAI - ensure compliance with privacy policies