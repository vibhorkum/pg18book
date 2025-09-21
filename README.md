# PostgreSQL E-commerce and AI Sample Database

This repository contains a set of SQL scripts to demonstrate a reference architecture for an e-commerce platform using PostgreSQL, now enhanced with an AI database (`aidb`) for advanced search and analytics.

The architecture includes:
*   **`ecommerce_reference_data`**: A central publisher for master product information.
*   **`west_ecommerce_data` & `east_ecommerce_data`**: Regional databases that subscribe to product data and manage local customers and sales.
*   **`central_analytics`**: A data warehouse that aggregates data from all regional databases.
*   **`aidb`**: An AI database that subscribes to `central_analytics` and `ecommerce_reference_data` to build a semantic search engine using `pgvector` and OpenAI embeddings.

This project showcases a multi-layered logical replication setup, data aggregation, and the integration of vector search for AI-powered applications.

## Key Features Demonstrated
*   **Multi-Layer Logical Replication**: A sophisticated publisher/subscriber model across four database types.
*   **AI-Powered Semantic Search**: Using `pgvector` and OpenAI embeddings to find products based on natural language queries.
*   **Retrieval-Augmented Generation (RAG)**: A function that uses database content to provide context to an LLM for answering questions.
*   **Advanced Data Types**: `DATERANGE` for price validity, `JSONB` for product attributes, and `vector` for embeddings.
*   **Exclusion Constraints**: Using `GIST` to prevent overlapping price validity periods.
*   **`psql` Scripting**: Comprehensive use of `psql` meta-commands and variables for fully automated setup and teardown.

## File Structure
The project is primarily organized within the `psql_scripts/` directory:
*   `master_setup.sql`: The main script to create all databases, schemas, and set up the entire replication topology.
*   `master_teardown.sql`: The main script to remove all replication slots, subscriptions, and drop all databases.
*   `database_definitions/`: Contains the individual SQL files to define the schema for each database (`ecommerce_reference_data`, `west_ecommerce_data`, `east_ecommerce_data`, `central_analytics`, and `aidb`).
*   `data_sets/`: Contains scripts to populate the databases with sample data.
*   `replication/`: Contains scripts that define the replication relationships between the databases (`product_replication_setup.sql` and `customer_sales_replication_setup.sql`).
*   `product_pictures/`: Contains product images and prompts used for generating embeddings.

## Prerequisites
*   PostgreSQL 16 or higher installed.
*   Superuser access to the PostgreSQL instance.
*   `psql` command-line client.
*   An OpenAI API key for generating embeddings and using the RAG function.

---

## Instructions (using `psql`)
This is the recommended method for a fully automated setup.

### 1. One-Time Server Configuration
Your PostgreSQL server must be configured for logical replication. This only needs to be done once.

Edit your `postgresql.conf` file to set:
```ini
wal_level = logical
```
Alternatively, run the following SQL as a superuser:
```sql
ALTER SYSTEM SET wal_level = logical;
```
**You must restart your PostgreSQL server for this change to take effect.**

### 2. Set Your OpenAI API Key
The `aidb` database requires an OpenAI API key to generate vector embeddings. Connect to `psql` and set the key in the database configuration. **This key is stored as a server-level parameter and will persist until reset.**

```bash
# Connect to any database as a superuser
psql -U your_superuser -d postgres

-- Set the API key (replace with your actual key)
ALTER SYSTEM SET api.openai_api_key = 'your_openai_api_key_here';

-- Reload the configuration to apply the change
SELECT pg_reload_conf();
```

### 3. Create Databases and Set Up Replication
The master setup script handles everything: creating databases, defining schemas, populating data, and configuring all replication publications and subscriptions in the correct order.

```bash
# Run the master setup script from the root of the repository
psql -U your_superuser -f psql_scripts/master_setup.sql
```
After the script finishes, all databases will be created, and data will be flowing from the reference and regional databases into `central_analytics` and finally into `aidb`.

### 4. Query the AI Database
You can now test the semantic search functionality in the `aidb`.

1.  Connect to the `aidb` database:
    ```bash
    psql -U your_superuser -d aidb
    ```

2.  Run a semantic search for a product. The function `api.similar_items` takes a natural language query and returns the top matching products from the catalog.
    ```sql
    -- Find products similar to "a blue shirt for summer"
    SELECT * FROM api.similar_items('a blue shirt for summer', 5);
    ```

3.  Ask a question using the RAG function. This function finds relevant items and passes them to an OpenAI model to generate a human-like answer.
    ```sql
    -- Ask for recommendations
    SELECT api.answer_question('What are some good options for a formal event?');
    ```

### Cleanup
To completely remove the databases and all replication artifacts, run the master teardown script.

```bash
# Run the master teardown script
psql -U your_superuser -f psql_scripts/master_teardown.sql
```

---

## Instructions (using pgAdmin 4)

Due to pgAdmin's lack of support for `psql` meta-commands like `\c`, running the automated scripts is not feasible. It is highly recommended to use `psql` for this project. If you must use pgAdmin, you will need to manually execute the contents of the SQL files in the `database_definitions`, `data_sets`, and `replication` directories, ensuring you are connected to the correct database for each step. The `master_setup.sql` script can serve as a guide for the correct order of execution.
