# Docker Setup for PostgreSQL 18 with AI Extensions

This directory contains Docker configurations for running PostgreSQL 18 with pgvector and other extensions for the AI-powered e-commerce demonstration.

## 🏗️ Directory Structure

```
docker/
├── postgresql/
│   └── Dockerfile              # PostgreSQL 18 + pgvector build
├── compose/
│   ├── docker-compose.yml      # Standard configuration
│   ├── docker-compose.dev.yml  # Development environment
│   ├── docker-compose.prod.yml # Production environment
│   └── docker-compose.ai-demo.yml # AI demo with pgAdmin
├── quick-start.sh              # Interactive setup script
└── README.md                   # This file
```

## 🚀 Quick Start

### Option 1: Interactive Script (Recommended)
```bash
./docker/quick-start.sh
```

### Option 2: Manual Setup
```bash
# 1. Build the image
cd docker/postgresql
docker build -t pg18book:latest .

# 2. Start the AI demo environment
cd ../compose
docker-compose -f docker-compose.ai-demo.yml up -d

# 3. Setup demo data
docker exec -i pg18book psql -U postgres < ../../psql_scripts/master_setup.sql
docker exec -i pg18book psql -U postgres -d west_ecommerce_data < ../../psql_scripts/ai_recommendations.sql

# 4. Run the AI demo
docker exec -it pg18book psql -U postgres -d west_ecommerce_data -f /docker-entrypoint-initdb.d/scripts/ai_demo.sql
```

## 📋 Available Configurations

### Standard Configuration (`docker-compose.yml`)
- **Purpose**: General purpose PostgreSQL with AI extensions
- **Container**: `pg18book`
- **Memory**: 256MB shared_buffers, 1GB effective_cache_size
- **Features**: Logical replication, basic logging

```bash
cd docker/compose
docker-compose up -d
```

### Development Configuration (`docker-compose.dev.yml`)
- **Purpose**: Development and testing environment
- **Container**: `pg18book-dev`
- **Memory**: 128MB shared_buffers, 512MB effective_cache_size
- **Features**: Enhanced logging, lower resource usage
- **Special**: Logs all statements for debugging

```bash
cd docker/compose
docker-compose -f docker-compose.dev.yml up -d
```

### Production Configuration (`docker-compose.prod.yml`)
- **Purpose**: High-performance production workload
- **Container**: `pg18book-prod`
- **Memory**: 2GB shared_buffers, 8GB effective_cache_size
- **Features**: Optimized for performance, minimal logging
- **Special**: Resource limits and health checks

```bash
cd docker/compose
docker-compose -f docker-compose.prod.yml up -d
```

### AI Demo Configuration (`docker-compose.ai-demo.yml`)
- **Purpose**: Complete AI demonstration environment
- **Containers**: `pg18book` + `pgadmin-ai`
- **Memory**: 512MB shared_buffers, 2GB effective_cache_size
- **Features**: Optimized for vector operations, includes pgAdmin
- **Access**: PostgreSQL (5432), pgAdmin (8080)

```bash
cd docker/compose
docker-compose -f docker-compose.ai-demo.yml up -d
```

## 🔧 Configuration Details

### Environment Variables

#### Performance Tuning
| Variable | Default | Description |
|----------|---------|-------------|
| `PG_SHARED_BUFFERS` | 256MB | Memory for shared buffers |
| `PG_EFFECTIVE_CACHE_SIZE` | 1GB | Optimizer's assumption of cache size |
| `PG_WORK_MEM` | 4MB | Memory for sort operations |
| `PG_MAINTENANCE_WORK_MEM` | 64MB | Memory for maintenance operations |
| `PG_MAX_CONNECTIONS` | 100 | Maximum concurrent connections |

#### Replication Settings
| Variable | Default | Description |
|----------|---------|-------------|
| `PG_WAL_LEVEL` | logical | Write-ahead log level |
| `PG_MAX_REPLICATION_SLOTS` | 10 | Maximum replication slots |
| `PG_MAX_WAL_SENDERS` | 10 | Maximum WAL sender processes |
| `PG_MAX_LOGICAL_REPLICATION_WORKERS` | 4 | Logical replication workers |

#### AI Optimization
| Variable | Default | Description |
|----------|---------|-------------|
| `PG_RANDOM_PAGE_COST` | 1.1 | Cost of random page access (SSD optimized) |
| `PG_EFFECTIVE_IO_CONCURRENCY` | 200 | Concurrent I/O operations |
| `PG_MAX_PARALLEL_WORKERS` | 4 | Maximum parallel workers |
| `PG_MAX_PARALLEL_WORKERS_PER_GATHER` | 2 | Parallel workers per gather node |

### Volume Mounts

#### Data Persistence
- `postgres_data:/var/lib/postgresql/data` - Database data files
- `postgres_logs:/var/log/postgresql` - PostgreSQL log files
- `postgres_backup:/var/backups/postgresql` - Backup files (prod only)

#### Script Access
- `../../psql_scripts:/docker-entrypoint-initdb.d/scripts:ro` - Read-only access to SQL scripts

## 🌐 Network Configuration

Each configuration uses its own Docker network:
- Standard: `pg18book`
- Development: `pg18book-dev`
- Production: `pg18book-prod`
- AI Demo: `pg18book-ai`

## 📊 Resource Requirements

### Minimum Requirements
- **CPU**: 2 cores
- **Memory**: 2GB RAM
- **Storage**: 10GB free space

### Recommended for AI Demo
- **CPU**: 4 cores
- **Memory**: 8GB RAM
- **Storage**: 50GB free space

### Production Requirements
- **CPU**: 8+ cores
- **Memory**: 16GB+ RAM
- **Storage**: 100GB+ SSD

## 🔌 Connection Information

### PostgreSQL Database
- **Host**: localhost
- **Port**: 5432
- **User**: postgres
- **Password**: postgres
- **AI Database**: west_ecommerce_data

### pgAdmin (AI Demo only)
- **URL**: http://localhost:8080
- **Email**: admin@pg18book.com
- **Password**: admin

### Connection Examples

#### psql (Command Line)
```bash
# Connect to AI database
docker exec -it pg18book psql -U postgres -d west_ecommerce_data

# Connect to default database
docker exec -it pg18book psql -U postgres
```

#### pgAdmin
1. Open http://localhost:8080
2. Login with credentials above
3. Add server with:
   - Name: pg18book
   - Host: postgres
   - Port: 5432
   - Username: postgres
   - Password: postgres

#### External Applications
```bash
# Connection string
postgresql://postgres:postgres@localhost:5432/west_ecommerce_data

# JDBC URL
jdbc:postgresql://localhost:5432/west_ecommerce_data
```

## 🏥 Health Checks

All configurations include health checks:
- **Test**: `pg_isready -U postgres`
- **Interval**: 10-30s (depending on environment)
- **Timeout**: 3-10s
- **Retries**: 3-5

## 📝 Logging

### Log Locations (inside container)
- **Log Directory**: `/var/log/postgresql`
- **Log Files**: `postgresql-<env>-YYYY-MM-DD.log`
- **Rotation**: Daily or 100MB-500MB (depending on environment)

### Access Logs
```bash
# View current logs
docker logs pg18book

# Follow logs in real-time
docker logs -f pg18book

# Access PostgreSQL log files
docker exec -it pg18book tail -f /var/log/postgresql/postgresql-$(date +%Y-%m-%d).log
```

## 🛠️ Maintenance Commands

### Start/Stop Services
```bash
# Start
docker-compose -f docker-compose.ai-demo.yml up -d

# Stop
docker-compose -f docker-compose.ai-demo.yml down

# Restart
docker-compose -f docker-compose.ai-demo.yml restart
```

### Data Management
```bash
# Backup database
docker exec pg18book pg_dump -U postgres west_ecommerce_data > backup.sql

# Restore database
docker exec -i pg18book psql -U postgres west_ecommerce_data < backup.sql

# Access container shell
docker exec -it pg18book bash
```

### Volume Management
```bash
# List volumes
docker volume ls | grep postgres

# Remove all data (DESTRUCTIVE!)
docker-compose -f docker-compose.ai-demo.yml down -v

# Backup volume
docker run --rm -v postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres_data.tar.gz -C /data .
```

## 🚨 Troubleshooting

### Common Issues

#### Container Won't Start
```bash
# Check logs
docker logs pg18book

# Check if port is in use
lsof -i :5432

# Remove conflicting containers
docker ps -a | grep postgres
docker rm -f <container_id>
```

#### Database Connection Issues
```bash
# Verify PostgreSQL is ready
docker exec pg18book pg_isready -U postgres

# Check configuration
docker exec pg18book cat /var/lib/postgresql/data/postgresql.conf

# Restart container
docker restart pg18book
```

#### Performance Issues
```bash
# Check resource usage
docker stats pg18book

# Review configuration
docker exec pg18book psql -U postgres -c "SHOW shared_buffers;"

# Check for long-running queries
docker exec pg18book psql -U postgres -c "SELECT * FROM pg_stat_activity WHERE state = 'active';"
```

#### AI Demo Issues
```bash
# Verify pgvector extension
docker exec pg18book psql -U postgres -c "SELECT * FROM pg_extension WHERE extname = 'vector';"

# Check AI functions
docker exec pg18book psql -U postgres -d west_ecommerce_data -c "\df *embedding*"

# Regenerate embeddings
docker exec pg18book psql -U postgres -d west_ecommerce_data -c "SELECT update_product_embeddings();"
```

## 🔐 Security Considerations

### Production Deployment
1. **Change default passwords**
2. **Use Docker secrets for sensitive data**
3. **Configure SSL/TLS certificates**
4. **Restrict network access**
5. **Enable audit logging**
6. **Regular security updates**

### Example with secrets:
```yaml
services:
  postgres:
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
    secrets:
      - postgres_password

secrets:
  postgres_password:
    file: ./secrets/postgres_password.txt
```

## 📚 Additional Resources

- [PostgreSQL 18 Documentation](https://www.postgresql.org/docs/18/)
- [pgvector Extension](https://github.com/pgvector/pgvector)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [AI Recommendations Documentation](../AI_RECOMMENDATIONS.md)

## 🤝 Support

For issues and questions:
1. Check the [troubleshooting section](#-troubleshooting)
2. Review container logs: `docker logs pg18book`
3. Check the main [README](../README.md) for general setup
4. Open an issue in the repository
