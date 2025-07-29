# PostgreSQL E-commerce Sample Data

This repository contains a set of SQL scripts to demonstrate a reference architecture for an e-commerce platform using PostgreSQL. The setup includes a central "reference" database and a regional "subscriber" database, showcasing features like logical replication, advanced data types, and data maintenance procedures.

## Key Features Demonstrated
*   **Logical Replication**: Setting up a publisher/subscriber model.
*   **Row-Filtered Publication**: Replicating only a subset of data (e.g., prices for a specific geography).
*   **Advanced Data Types**: `DATERANGE` for price validity, `JSONB` for product attributes, and custom `ENUM` types.
*   **Exclusion Constraints**: Using `GIST` to prevent overlapping price validity periods.
*   **Stored Procedures**: Efficient data maintenance (`update_current_price_flags`) and sample data generation (`create_sales_transactions`).
*   **`psql` Scripting**: Use of `psql` meta-commands and variables for automated setup and teardown.
*   **🤖 AI-Powered Recommendations**: Vector similarity search, collaborative filtering, and hybrid recommendation system using `pgvector`.

## File Structure
*   `reference_data.sql`: Master script to create the `ecommerce_reference_data` (publisher) database, schema, and sample data.
*   `us_ecommerce_data.sql`: Master script to create the `us_ecommerce_data` (subscriber) database and its local schema.
*   `enhanced_sample_data.sql`: **NEW** - Extended product catalog with diverse brands, categories, and detailed product information.
*   `ai_recommendations.sql`: **NEW** - AI-powered recommendation system using PostgreSQL's `pgvector` extension.
*   `ai_examples.sql`: **NEW** - Comprehensive examples demonstrating AI recommendation features.
*   `replication_setup.sql`: Script to configure logical replication between the two databases.
*   `remove_replication.sql`: Script to tear down the replication configuration.
*   `cleanup_databases.sql`: Script to drop both databases and clean up the environment.
*   `pgAdmin4_sqls/`: Contains versions of the scripts adapted for use with the pgAdmin 4 query tool, which does not support certain `psql` meta-commands.
*   `AI_RECOMMENDATIONS.md`: **NEW** - Detailed documentation for the AI recommendation system.

## Prerequisites
*   PostgreSQL server installed.
*   Superuser access to the PostgreSQL instance.
*   `psql` command-line client.
*   **For AI features**: `pgvector` extension (`sudo dnf install postgresql-18-pgvector -y` on Rocky Linux.

---

## Instructions (using `psql`)
This is the recommended method for a fully automated setup.

### 1. One-Time Server Configuration
Before you begin, you must configure your PostgreSQL server for logical replication. This only needs to be done once per server instance.

Edit your `postgresql.conf` file to set:
```ini
wal_level = logical
```
Alternatively, you can run the following SQL as a superuser:
```sql
ALTER SYSTEM SET wal_level = logical;
```
**You must restart your PostgreSQL server for this change to take effect.**

### 2. Create Databases and Schema
The setup scripts handle database creation and connection switching automatically. Run them from your terminal using `psql`.

```bash
# Create the publisher database, schema, and data
psql -U your_superuser -f reference_data.sql

# Create the subscriber database and schema
psql -U your_superuser -f us_ecommerce_data.sql
```

### 3. Set Up Logical Replication
This script creates the publications on the publisher and subscriptions on the subscriber.

```bash
# Configure and start replication
psql -U your_superuser -f replication_setup.sql
```
After this step, the `product*` tables in `us_ecommerce_data` should be populated with data from `ecommerce_reference_data`. The `product_variant_price` table will only contain rows where `geography = 'US'` and `current = true`.

### 4. (Optional) Populate Local Data
The `us_ecommerce_data.sql` script contains commented-out sections for populating local tables (like `customer` and `product_variant_inventory`) and creating a procedure to generate sales.

To use them:
1.  Connect to the `us_ecommerce_data` database: `psql -U your_superuser -d us_ecommerce_data`
2.  Uncomment the `INSERT` statements and the `create_sales_transactions` procedure in `us_ecommerce_data.sql`.
3.  Execute the uncommented code in your `psql` session.
4.  You can then generate sample sales data by running: `CALL create_sales_transactions(10);`

### 5. (Optional) Set Up AI-Powered Recommendations

To enable AI-powered product recommendations:

```bash
# Install pgvector extension (Rocky Linux)
sudo dnf install postgresql-18-pgvector -y

# Add enhanced sample data with diverse product catalog
psql -U your_superuser -d ecommerce_reference_data -f enhanced_sample_data.sql

# Set up AI recommendation system on US database
psql -U your_superuser -d us_ecommerce_data -f ai_recommendations.sql

# Run comprehensive AI examples and demonstrations
psql -U your_superuser -d us_ecommerce_data -f ai_examples.sql
```

**AI Features Available:**
- **Content-based similarity**: Find products similar to a given product using vector embeddings
- **Text-based search**: Search products using natural language queries ("athletic shirt", "formal business attire")
- **Collaborative filtering**: Recommend products based on similar customer purchase patterns
- **Hybrid recommendations**: Combine multiple recommendation approaches for better results

**Example AI Queries:**
```sql
-- Find products similar to product ID 1
SELECT * FROM find_similar_products(1, 0.3, 10);

-- Search for products using natural language
SELECT * FROM search_similar_products_by_text('running shoes', 0.2, 5);

-- Get personalized recommendations for customer ID 1
SELECT * FROM get_hybrid_recommendations(1, NULL, 10);
```

For detailed AI documentation, see [`AI_RECOMMENDATIONS.md`](AI_RECOMMENDATIONS.md).

### Cleanup
To remove the setup, run the scripts in the following order:

```bash
# 1. Remove publications, subscriptions, and replication slots
psql -U your_superuser -f remove_replication.sql

# 2. Drop both databases
psql -U your_superuser -f cleanup_databases.sql
```

---

## Instructions (using pgAdmin 4)

The scripts in the `pgAdmin4_sqls` directory are split into multiple parts because pgAdmin's query tool does not support `psql` commands like `\c` to switch database connections within a single script.

### 1. Create the Reference Database
1.  Connect to the default `postgres` database.
2.  Open and run `/pgAdmin4_sqls/create_reference_database.sql`.
3.  **Disconnect** from the `postgres` database.
4.  **Connect** to the newly created `ecommerce_reference_data` database.
5.  Open and run `/pgAdmin4_sqls/ecommerce_reference_data.sql` to create tables and insert data.

### 2. Create the US Subscriber Database
1.  Connect to the default `postgres` database.
2.  Open and run `/pgAdmin4_sqls/create_us_commerce_data_database.sql`.
3.  **Disconnect** from the `postgres` database.
4.  **Connect** to the newly created `us_ecommerce_data` database.
5.  Open and run `/pgAdmin4_sqls/us_commerce_data.sql` to create the table schemas.

### 3. Setup Replication & Cleanup
The `replication_setup.sql`, `remove_replication.sql`, and `cleanup_databases.sql` scripts from the root directory can be run, but you will need to manually handle the `\c` commands by switching connections in pgAdmin between steps. For cleanup, `/pgAdmin4_sqls/cleanup_database.sql` can be run from a connection to the `postgres` database.
