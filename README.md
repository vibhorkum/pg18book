# eComerce sample database to accompany the book 'PostgreSQL 18 for the developer: transactions, analytics, and AI'

This repository contains a set of scripts to accomapny the book 'PostgreSQL 18 for the developer: transactions, analytics, and AI' (draft title).

The scripts create a reference architecture for an e-commerce platform using PostgreSQL,  enhanced with an AI database (`aidb`) for advanced search and analytics.

The architecture includes:
*   **`ecommerce_reference_data`**: A central publisher for master product information.
*   **`west_ecommerce_data` & `east_ecommerce_data`**: Regional databases that subscribe to product data and manage local customers and sales.
*   **`central_analytics`**: A data warehouse that aggregates data from all regional databases.
*   **`aidb`**: An AI database that subscribes to `central_analytics` and `ecommerce_reference_data` to build a semantic search engine using `pgvector` and OpenAI embeddings.

This project showcases a multi-layered logical replication setup, data aggregation, and the integration of vector search for AI-powered applications.

## Key Features Demonstrated
*   **Multi-Layer Logical Replication**: A sophisticated publisher/subscriber model across four databases using logical replication or the COPY command.
*   **Data Modeling for Transactions**: A normalized data model to support high-volume transactions.
*   **Data Modeling for Analytics**: A star schema to support analytics queries with groups, aggregates, window functions and CTEs.
*   **Text Searching**: Three PostgreSQL text-serach techniques: LIKE, tsvector, and trigrams.
*   **AI-Powered Semantic Search**: Using `pgvector` and OpenAI embeddings to find products based on natural language queries.
*   **Retrieval-Augmented Generation (RAG)**: A function that uses database content to provide context to an LLM for answering questions.
*   **Advanced Data Types**: `DATERANGE` for price validity, `JSONB` for product attributes, and `vector` for embeddings.
*   **Exclusion Constraints**: Using `GIST` to prevent overlapping price validity periods.
*   **PostgreSQL extensions**: 
    * `pg_background` for background processing using independant processes.
    * `pg_squeeze` to reorganize tables and remove unused space.
    * `pg_stat_statements` to collect performance information
    * `pg_trgm` for fuzzy text search and string matching
    * `pgaudit` to get collect audit information about DML and DDL commands
    * `plpgsql_check` to show the value of a plpgsql linter
    * `plpgsql` to develop stored procedures and functions in PostgreSQL native procedural language
    * `plpython3u`to devlop stored procedures in Python and to connect to LLMs
    * `vector` to run approximate nearest neighbor AI calculations in PostgreSQL
    * `btree_gist` to combine B-tree and GiST indexes to identify overlaps in ranges


*   **`psql` Scripting**: Comprehensive use of `psql` meta-commands and variables for fully automated setup and teardown.

## File Structure
The project is primarily organized within the `psql_scripts/` directory:
*   `master_setup.sql`: The main script to create all databases, schemas, and set up
     the entire replication topology. The script checks for the prerequisites and will abort if they are not met.
*   `master_teardown.sql`: The main script to remove all replication slots, 
     subscriptions, and drop all databases.
*   `database_definitions/`: Contains the individual SQL files to define the schema
    for each database (`ecommerce_reference_data`, `west_ecommerce_data`, `east_ecommerce_data`, `central_analytics`, and `aidb`).
*   `data_sets/`: Contains scripts to populate the databases with sample data.
*   `replication/`: Contains scripts that define the replication relationships between the databases (`product_replication_setup.sql` and `customer_sales_replication_setup.sql`).
*   `product_pictures/`: Contains product images and prompts used for generating embeddings.
* `Example for each chapter of the book`: The directory /psql_scripts/sample_scripts contains sample scripts to illustrate the concepts explained in the book.

## Prerequisites
*   PostgreSQL 18 or higher installed, with 
    * wal_level = logical
    * logging_collector=on 
    * max_logical_replication_workers>=10 
    * log_statement=ddl
*    The extensions listed above need to be installed
*    Superuser access to the PostgreSQL instance.
*   `psql` command-line client.
*   An OpenAI API key for generating embeddings and using the RAG function.

---
## Supported Environments
The scripts have been tested with Docker Desktop 4.53.

The file docker-compose.yml can be used to generate a Docker container that includes all the required extensions.

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

Alternatively, run the master_setup.sql script from from psql /psql_scripts with
```
\i master_setup.sql
```
After the script finishes, all databases will be created, and data will be flowing from the reference and regional databases into `central_analytics` and into `aidb`.

The databases will be populated with 5,000 customers and approximately 23,000 sales transaction lines.

In the final step of the setup, the script prints out a report showing the counts for customers, products, and sales orders in the different databases.

### 3. Cleanup
To completely remove the databases and all replication artifacts, run the master teardown script.

```bash
# Run the master teardown script
psql -U your_superuser -f psql_scripts/master_teardown.sql
```
