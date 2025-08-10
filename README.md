# PostgreSQL E-commerce Sample Data

This repository contains a comprehensive setup for demonstrating PostgreSQL's advanced features using an e-commerce platform. The setup includes logical replication, advanced data types, AI-powered recommendations using pgvector, and a complete Docker environment for easy deployment.

## 🌟 Key Features Demonstrated
*   **Logical Replication**: Setting up a publisher/subscriber model
*   **Row-Filtered Publication**: Replicating only specific data subsets
*   **Advanced Data Types**: `DATERANGE`, `JSONB`, and custom `ENUM` types
*   **Exclusion Constraints**: Using `GIST` to prevent overlapping price validity periods
*   **Stored Procedures**: Efficient data maintenance and sample data generation
*   **🤖 AI-Powered Recommendations**: Vector similarity search, collaborative filtering, and hybrid recommendations using `pgvector`
*   **🐳 Docker Environment**: Complete containerized setup with multiple configurations

## 🚀 Quick Start with Docker (Recommended)

### Prerequisites
- Docker and Docker Compose installed
- 8GB+ RAM recommended for AI features
- 50GB+ free disk space

### Interactive Setup
```bash
# Clone the repository
git clone <repository-url>
cd pg18book

# Run the interactive setup script
./docker/quick-start.sh
```

The interactive script will guide you through:
1. Building the PostgreSQL 18 + pgvector image
2. Starting the AI demo environment (includes pgAdmin)
3. Setting up sample data and AI system
4. Running the AI demonstration

### Manual Docker Setup
```bash
# Build the PostgreSQL image
cd docker/postgresql
docker build -t pg18book:latest .

# Start the AI demo environment
cd ../compose
docker-compose -f docker-compose.ai-demo.yml up -d

# Setup the database and AI system
docker exec -i pg18book psql -U postgres < ../../psql_scripts/master_setup.sql
docker exec -i pg18book psql -U postgres -d west_ecommerce_data < ../../psql_scripts/ai_recommendations.sql

# Run the AI demo
docker exec -it pg18book psql -U postgres -d west_ecommerce_data -f /docker-entrypoint-initdb.d/scripts/ai_demo.sql
```

### Access Your Environment
- **PostgreSQL**: localhost:5432 (postgres/postgres)
- **pgAdmin**: http://localhost:8080 (admin@pg18book.com/admin)
- **AI Database**: west_ecommerce_data

## 📁 File Structure
## 📁 File Structure

### Core SQL Scripts
*   `psql_scripts/master_setup.sql`: Complete database setup with replication
*   `psql_scripts/ai_recommendations.sql`: AI-powered recommendation system using pgvector
*   `psql_scripts/ai_demo.sql`: Interactive AI demonstration script
*   `psql_scripts/ai_examples.sql`: Comprehensive AI usage examples
*   `psql_scripts/ai_validation.sql`: System validation and testing
*   `psql_scripts/enhanced_sample_data.sql`: Extended product catalog with diverse data

### Docker Environment
*   `docker/postgresql/Dockerfile`: PostgreSQL 18 + pgvector + extensions
*   `docker/compose/docker-compose.yml`: Standard configuration
*   `docker/compose/docker-compose.dev.yml`: Development environment
*   `docker/compose/docker-compose.prod.yml`: Production environment  
*   `docker/compose/docker-compose.ai-demo.yml`: AI demo with pgAdmin
*   `docker/quick-start.sh`: Interactive setup script
*   `docker/README.md`: Comprehensive Docker documentation

### Legacy Scripts (psql method)
*   `reference_data.sql`: Master script for reference database
*   `us_ecommerce_data.sql`: Master script for subscriber database
*   `replication_setup.sql`: Logical replication configuration
*   `pgAdmin4_sqls/`: Scripts adapted for pgAdmin 4

### Documentation
*   `AI_RECOMMENDATIONS.md`: Detailed AI system documentation
*   `QUICK_START.md`: Quick setup guide
*   `README.md`: This comprehensive guide

## 🐳 Docker Configurations

### Available Environments

| Configuration | Purpose | Memory | Features | Command |
|---------------|---------|--------|----------|---------|
| **Standard** | General use | 256MB/1GB | Basic setup | `docker-compose up -d` |
| **Development** | Dev/Testing | 128MB/512MB | Enhanced logging | `docker-compose -f docker-compose.dev.yml up -d` |
| **Production** | High performance | 2GB/8GB | Optimized performance | `docker-compose -f docker-compose.prod.yml up -d` |
| **AI Demo** | Complete demo | 512MB/2GB | AI + pgAdmin | `docker-compose -f docker-compose.ai-demo.yml up -d` |

### Docker Benefits
- **Pre-configured PostgreSQL 18** with all extensions
- **Automated setup** with sample data
- **Multiple environments** for different use cases
- **Persistent data** with Docker volumes
- **Easy cleanup** and reproducible builds
- **pgAdmin included** for graphical management

See [`docker/README.md`](docker/README.md) for complete Docker documentation.

## 🔧 Prerequisites

### For Docker Setup (Recommended)
*   Docker and Docker Compose installed
*   8GB+ RAM (recommended for AI features)
*   50GB+ free disk space
*   Modern CPU with 4+ cores (recommended)

### For Manual psql Setup
*   PostgreSQL server installed (version 15+)
*   Superuser access to the PostgreSQL instance
*   `psql` command-line client
*   **For AI features**: `pgvector` extension ([installation guide](https://github.com/pgvector/pgvector))

---

## 🚀 Setup Methods

Choose the method that best fits your needs:

### Method 1: Docker Setup (Recommended for Demos)

**Advantages:**
- Complete environment in minutes
- No PostgreSQL installation required
- Includes pgAdmin for graphical management
- Multiple pre-configured environments
- Easy cleanup and reproducibility

**Quick Start:**
```bash
./docker/quick-start.sh
```

See the [Docker Quick Start section](#-quick-start-with-docker-recommended) above or [`docker/README.md`](docker/README.md) for detailed instructions.

### Method 2: Manual psql Setup (For Existing PostgreSQL)

**Advantages:**
- Use existing PostgreSQL installation
- Full control over configuration
- Integration with existing infrastructure
- Custom extension installations

**Prerequisites Configuration:**
Before you begin, configure your PostgreSQL server for logical replication (one-time setup):

```ini
# In postgresql.conf
wal_level = logical
```

Or via SQL:
```sql
ALTER SYSTEM SET wal_level = logical;
-- Restart PostgreSQL server
```
**Setup Steps:**

#### 1. Create Databases and Schema
The setup scripts handle database creation and connection switching automatically:

```bash
# Complete setup with all databases and replication
psql -U your_superuser -f psql_scripts/master_setup.sql

# OR individual setup:
# Create the publisher database, schema, and data
psql -U your_superuser -f reference_data.sql

# Create the subscriber database and schema  
psql -U your_superuser -f us_ecommerce_data.sql
```

#### 2. Set Up Logical Replication (if using individual scripts)
```bash
# Configure and start replication (only if not using master_setup.sql)
psql -U your_superuser -f replication_setup.sql
```

#### 3. Set Up AI-Powered Recommendations
```bash
# Install AI system on subscriber database (contains replicated product data)
psql -U your_superuser -d west_ecommerce_data -f psql_scripts/ai_recommendations.sql

# Validate installation
psql -U your_superuser -d west_ecommerce_data -f psql_scripts/ai_validation.sql

# Run AI demo
psql -U your_superuser -d west_ecommerce_data -f psql_scripts/ai_demo.sql
```

### Method 3: pgAdmin 4 Setup

**For users who prefer graphical interfaces:**

The scripts in the `pgAdmin4_sqls` directory are split for pgAdmin compatibility:

1. **Create Reference Database**: Run `pgAdmin4_sqls/create_reference_database.sql`
2. **Switch to Reference DB**: Connect to `ecommerce_reference_data`
3. **Setup Reference Data**: Run `pgAdmin4_sqls/ecommerce_reference_data.sql`
4. **Create Subscriber Database**: Run `pgAdmin4_sqls/create_us_commerce_data_database.sql`
5. **Switch to Subscriber DB**: Connect to `us_ecommerce_data`
6. **Setup Subscriber Schema**: Run `pgAdmin4_sqls/us_commerce_data.sql`

---

## 🤖 AI Features Overview

The AI recommendation system provides:

### Core Capabilities
- **Content-based Similarity**: Find products similar to a given product using vector embeddings
- **Text-based Search**: Natural language product search ("athletic shirt", "business casual")
- **Collaborative Filtering**: Recommendations based on customer behavior patterns
- **Hybrid Recommendations**: Combined approach for enhanced accuracy

### Available Databases for AI
- **west_ecommerce_data**: Western region subscriber database
- **east_ecommerce_data**: Eastern region subscriber database
- **us_ecommerce_data**: Legacy US subscriber database

**Important**: Install AI functions only on subscriber databases with replicated product data.

### Example AI Queries
```sql
-- Find similar products
SELECT * FROM find_similar_products(1, 0.3, 10);

-- Natural language search
SELECT * FROM search_similar_products_by_text('running shoes for beginners', 0.2, 5);

-- Personalized recommendations
SELECT * FROM get_hybrid_recommendations(customer_id, NULL, 10);

-- Update product embeddings
SELECT update_product_embeddings();
```

For comprehensive AI documentation, see [`AI_RECOMMENDATIONS.md`](AI_RECOMMENDATIONS.md).

---

## 🧹 Cleanup and Maintenance

### Docker Cleanup
```bash
# Stop services
cd docker/compose
docker-compose -f docker-compose.ai-demo.yml down

# Remove all data (DESTRUCTIVE!)
docker-compose -f docker-compose.ai-demo.yml down -v

# Remove image
docker rmi pg18book:latest
```

### Manual psql Cleanup
To remove the manual setup, run these scripts in order:

```bash
# 1. Remove publications, subscriptions, and replication slots
psql -U your_superuser -f remove_replication.sql

# 2. Drop both databases
psql -U your_superuser -f cleanup_databases.sql
```

---

## 🔗 Connection Information

### Docker Environment
- **PostgreSQL**: localhost:5432
- **Username/Password**: postgres/postgres
- **AI Demo Database**: west_ecommerce_data
- **pgAdmin**: http://localhost:8080 (admin@pg18book.com/admin)

### Connection Examples
```bash
# Docker psql
docker exec -it pg18book psql -U postgres -d west_ecommerce_data

# External connection string
postgresql://postgres:postgres@localhost:5432/west_ecommerce_data
```

---

## 📚 Documentation

- **[Docker Setup Guide](docker/README.md)**: Comprehensive Docker documentation
- **[AI Recommendations Guide](AI_RECOMMENDATIONS.md)**: Complete AI system documentation
- **[Quick Start Guide](QUICK_START.md)**: Condensed setup instructions
- **[PostgreSQL 18 Docs](https://www.postgresql.org/docs/18/)**: Official PostgreSQL documentation
- **[pgvector Extension](https://github.com/pgvector/pgvector)**: Vector similarity search extension

---

## 🚨 Troubleshooting

### Common Issues

#### Docker Issues
```bash
# Check if containers are running
docker ps

# View container logs
docker logs pg18book

# Restart services
docker-compose -f docker/compose/docker-compose.ai-demo.yml restart
```

#### Database Connection Issues
```bash
# Test connection
docker exec pg18book pg_isready -U postgres

# Check PostgreSQL status
docker exec pg18book ps aux | grep postgres
```

#### AI System Issues
```bash
# Verify pgvector extension
docker exec pg18book psql -U postgres -c "SELECT * FROM pg_extension WHERE extname = 'vector';"

# Check AI functions
docker exec pg18book psql -U postgres -d west_ecommerce_data -c "\df *embedding*"

# Regenerate embeddings
docker exec pg18book psql -U postgres -d west_ecommerce_data -c "SELECT update_product_embeddings();"
```

For more troubleshooting help, see the [Docker README](docker/README.md#-troubleshooting).

---

## 🤝 Contributing

We welcome contributions! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with clear description

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

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
