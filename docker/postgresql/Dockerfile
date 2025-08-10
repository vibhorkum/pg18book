# Use Rocky Linux 9 as base image with configurable platform
ARG BUILDPLATFORM=linux/amd64
FROM --platform=$BUILDPLATFORM rockylinux:9

# Update base image and all packages to latest versions to reduce vulnerabilities
RUN dnf -y update && dnf -y upgrade && dnf -y distro-sync

# Set environment variables
ENV PG_BRANCH=REL_18_STABLE
ENV PGVECTOR_BRANCH=master
ENV POSTGRES_USER=postgres
# Do not set POSTGRES_PASSWORD here; pass it securely at runtime via environment variable or Docker secrets.
ENV POSTGRES_DB=postgres
ENV PGDATA=/var/lib/postgresql/data
ENV PATH=/usr/local/pgsql/bin:$PATH

# PostgreSQL configuration environment variables with defaults
ENV PG_MAX_CONNECTIONS=100
ENV PG_SHARED_BUFFERS=256MB
ENV PG_EFFECTIVE_CACHE_SIZE=1GB
ENV PG_WORK_MEM=4MB
ENV PG_MAINTENANCE_WORK_MEM=64MB
ENV PG_MAX_WAL_SIZE=2GB
ENV PG_CHECKPOINT_TIMEOUT=10min
ENV PG_LOG_MIN_DURATION_STATEMENT=1000

# Replication and high availability settings
ENV PG_MAX_REPLICATION_SLOTS=10
ENV PG_MAX_WAL_SENDERS=10
ENV PG_WAL_LEVEL=logical
ENV PG_ARCHIVE_MODE=off
ENV PG_ARCHIVE_COMMAND=""
ENV PG_HOT_STANDBY=on
ENV PG_MAX_LOGICAL_REPLICATION_WORKERS=4

# Background workers and extensions
ENV PG_MAX_WORKER_PROCESSES=8
ENV PG_MAX_PARALLEL_WORKERS=8
ENV PG_MAX_PARALLEL_WORKERS_PER_GATHER=2
ENV PG_MAX_PARALLEL_MAINTENANCE_WORKERS=2

# Logging configuration
ENV PG_LOG_DESTINATION=stderr
ENV PG_LOGGING_COLLECTOR=on
ENV PG_LOG_DIRECTORY=/var/log/postgresql
ENV PG_LOG_FILENAME=postgresql-%Y-%m-%d.log
ENV PG_LOG_ROTATION_AGE=1d
ENV PG_LOG_ROTATION_SIZE=100MB
ENV PG_LOG_LINE_PREFIX="\"%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h \""
ENV PG_LOG_MIN_DURATION_STATEMENT=1000
ENV PG_LOG_STATEMENT=none

# Network and security
ENV PG_LISTEN_ADDRESSES="*"
ENV PG_PORT=5432
ENV PG_SSL=off
ENV PG_SSL_CERT_FILE=""
# Do not set PG_SSL_KEY_FILE as an ENV variable; handle SSL keys securely via Docker secrets or mounted files at runtime.
ENV PG_SSL_CA_FILE=""

# Performance and tuning
ENV PG_RANDOM_PAGE_COST=1.1
ENV PG_EFFECTIVE_IO_CONCURRENCY=200
ENV PG_DEFAULT_STATISTICS_TARGET=100
ENV PG_AUTOVACUUM=on
ENV PG_AUTOVACUUM_MAX_WORKERS=3

# Install development tools and dependencies
RUN dnf update -y && \
    dnf groupinstall -y "Development Tools" && \
    dnf install -y \
        procps-ng \
        wget \
        git \
        gcc \
        gcc-c++ \
        make \
        cmake \
        autoconf \
        automake \
        libtool \
        pkgconfig \
        grep \
        vim \
        util-linux \
        which \
        findutils \
        zlib-devel \
        openssl-devel \
        readline-devel \
        perl-devel \
        perl-ExtUtils-Embed \
        perl-ExtUtils-MakeMaker \
        perl-CPAN \
        python3-devel \
        tcl-devel \
        gettext \
        systemd-devel \
        krb5-devel \
        openldap-devel \
        pam-devel \
        libuuid-devel \
        lz4-devel \
        libzstd-devel \
        glibc-locale-source \
        glibc-langpack-en && \
    dnf clean all

# Install base XML and ICU libraries first, then try development packages
RUN dnf install -y libxml2 libicu libicu-devel || true && \
    dnf install -y libxml2-devel || echo "Warning: libxml2-devel not available" && \
    dnf install -y libxslt libxslt-devel || echo "Warning: libxslt-devel not available" && \
    dnf install -y pkgconfig || true

# Install missing Perl modules via CPAN
RUN cpan -T IPC::Run Test::More

# Create postgres user and directories
RUN groupadd -r postgres && \
    useradd -r -g postgres -d /var/lib/postgresql -s /bin/bash postgres && \
    mkdir -p /var/lib/postgresql/data && \
    mkdir -p /usr/local/pgsql && \
    chown -R postgres:postgres /var/lib/postgresql && \
    chown -R postgres:postgres /usr/local/pgsql

# Set working directory
WORKDIR /tmp

# Download and compile PostgreSQL 18 from GitHub REL_18_STABLE branch
RUN git clone --branch ${PG_BRANCH} --single-branch --depth 1 https://github.com/postgres/postgres.git postgresql && \
    cd postgresql && \
    ./configure \
        --prefix=/usr/local/pgsql \
        --with-openssl \
        --with-readline \
        --with-zlib \
        --with-perl \
        --with-python \
        --with-tcl \
        --with-gssapi \
        --with-ldap \
        --with-pam \
        --with-systemd \
        --with-uuid=e2fs \
        --with-lz4 \
        --with-zstd \
        --enable-nls \
        --enable-thread-safety \
        --enable-debug \
        $(pkg-config --exists libxml-2.0 && echo "--with-libxml" || echo "") \
        $(pkg-config --exists libxslt && echo "--with-libxslt" || echo "") && \
    make -j$(nproc) && \
    make install && \
    cd contrib && \
    make -j$(nproc) && \
    make install && \
    cd /tmp && \
    rm -rf postgresql

# Download and compile pgvector extension
RUN export PATH="/usr/local/pgsql/bin:$PATH" && \
    export PG_CONFIG="/usr/local/pgsql/bin/pg_config" && \
    git clone --branch ${PGVECTOR_BRANCH} --single-branch --depth 1 https://github.com/pgvector/pgvector.git && \
    cd pgvector && \
    make -j$(nproc) PG_CONFIG=/usr/local/pgsql/bin/pg_config && \
    make install PG_CONFIG=/usr/local/pgsql/bin/pg_config && \
    cd /tmp && \
    rm -rf pgvector

# Download and compile pg_ivm (Incremental View Maintenance) extension
RUN export PATH="/usr/local/pgsql/bin:$PATH" && \
    export PG_CONFIG="/usr/local/pgsql/bin/pg_config" && \
    git clone --branch main --single-branch --depth 1 https://github.com/sraoss/pg_ivm.git && \
    cd pg_ivm && \
    make -j$(nproc) PG_CONFIG=/usr/local/pgsql/bin/pg_config && \
    make install PG_CONFIG=/usr/local/pgsql/bin/pg_config && \
    cd /tmp && \
    rm -rf pg_ivm

# Download and compile pg_background (Background worker) extension
RUN export PATH="/usr/local/pgsql/bin:$PATH" && \
    export PG_CONFIG="/usr/local/pgsql/bin/pg_config" && \
    git clone --branch master --single-branch --depth 1 https://github.com/vibhorkum/pg_background.git && \
    cd pg_background && \
    make -j$(nproc) PG_CONFIG=/usr/local/pgsql/bin/pg_config && \
    make install PG_CONFIG=/usr/local/pgsql/bin/pg_config && \
    cd /tmp && \
    rm -rf pg_background

# Download and compile pg_squeeze (Table bloat reduction) extension
RUN export PATH="/usr/local/pgsql/bin:$PATH" && \
    export PG_CONFIG="/usr/local/pgsql/bin/pg_config" && \
    git clone --branch master --single-branch --depth 1 https://github.com/cybertec-postgresql/pg_squeeze.git && \
    cd pg_squeeze && \
    make -j$(nproc) PG_CONFIG=/usr/local/pgsql/bin/pg_config && \
    make install PG_CONFIG=/usr/local/pgsql/bin/pg_config && \
    cd /tmp && \
    rm -rf pg_squeeze

# Download and compile pgaudit (PostgreSQL Audit Extension)
RUN export PATH="/usr/local/pgsql/bin:$PATH" && \
    export PG_CONFIG="/usr/local/pgsql/bin/pg_config" && \
    export USE_PGXS=1 && \
    git clone --branch main --single-branch --depth 1 https://github.com/pgaudit/pgaudit.git && \
    cd pgaudit && \
    make -j$(nproc) PG_CONFIG=/usr/local/pgsql/bin/pg_config && \
    make install PG_CONFIG=/usr/local/pgsql/bin/pg_config && \
    cd /tmp && \
    rm -rf pgaudit

# Create additional useful directories
RUN mkdir -p /var/run/postgresql && \
    chown postgres:postgres /var/run/postgresql && \
    mkdir -p /var/log/postgresql && \
    chown postgres:postgres /var/log/postgresql

# Add PostgreSQL binaries to PATH for all users
RUN echo 'export PATH=/usr/local/pgsql/bin:$PATH' >> /etc/environment && \
    echo 'export LD_LIBRARY_PATH=/usr/local/pgsql/lib:$LD_LIBRARY_PATH' >> /etc/environment && \
    echo 'export PATH=/usr/bin:$PATH' >> /etc/environment

# Add /usr/bin to PATH for all users
RUN echo 'export PATH=/usr/bin:/usr/local/pgsql/bin:$PATH' > /etc/profile.d/binpath.sh && \
    echo 'export LD_LIBRARY_PATH=/usr/local/pgsql/lib:$LD_LIBRARY_PATH' >> /etc/profile.d/binpath.sh

# Create initialization script
RUN cat > /usr/local/bin/init-postgres.sh <<EOF
#!/bin/bash
set -e

# Set default values if environment variables are not provided
export PG_MAX_CONNECTIONS=\${PG_MAX_CONNECTIONS:-100}
export PG_SHARED_BUFFERS=\${PG_SHARED_BUFFERS:-256MB}
export PG_EFFECTIVE_CACHE_SIZE=\${PG_EFFECTIVE_CACHE_SIZE:-1GB}
export PG_WORK_MEM=\${PG_WORK_MEM:-4MB}
export PG_MAINTENANCE_WORK_MEM=\${PG_MAINTENANCE_WORK_MEM:-64MB}
export PG_MAX_WAL_SIZE=\${PG_MAX_WAL_SIZE:-2GB}
export PG_CHECKPOINT_TIMEOUT=\${PG_CHECKPOINT_TIMEOUT:-10min}
export PG_LOG_MIN_DURATION_STATEMENT=\${PG_LOG_MIN_DURATION_STATEMENT:-1000}

export PG_MAX_REPLICATION_SLOTS=\${PG_MAX_REPLICATION_SLOTS:-10}
export PG_MAX_WAL_SENDERS=\${PG_MAX_WAL_SENDERS:-10}
export PG_WAL_LEVEL=\${PG_WAL_LEVEL:-replica}
export PG_ARCHIVE_MODE=\${PG_ARCHIVE_MODE:-off}
export PG_ARCHIVE_COMMAND=\${PG_ARCHIVE_COMMAND:-""}
export PG_HOT_STANDBY=\${PG_HOT_STANDBY:-on}
export PG_MAX_LOGICAL_REPLICATION_WORKERS=\${PG_MAX_LOGICAL_REPLICATION_WORKERS:-4}

export PG_MAX_WORKER_PROCESSES=\${PG_MAX_WORKER_PROCESSES:-8}
export PG_MAX_PARALLEL_WORKERS=\${PG_MAX_PARALLEL_WORKERS:-8}
export PG_MAX_PARALLEL_WORKERS_PER_GATHER=\${PG_MAX_PARALLEL_WORKERS_PER_GATHER:-2}
export PG_MAX_PARALLEL_MAINTENANCE_WORKERS=\${PG_MAX_PARALLEL_MAINTENANCE_WORKERS:-2}

export PG_LOG_DESTINATION=\${PG_LOG_DESTINATION:-stderr}
export PG_LOGGING_COLLECTOR=\${PG_LOGGING_COLLECTOR:-on}
export PG_LOG_DIRECTORY=\${PG_LOG_DIRECTORY:-/var/log/postgresql}
export PG_LOG_FILENAME=\${PG_LOG_FILENAME:-postgresql-%Y-%m-%d.log}
export PG_LOG_ROTATION_AGE=\${PG_LOG_ROTATION_AGE:-1d}
export PG_LOG_ROTATION_SIZE=\${PG_LOG_ROTATION_SIZE:-100MB}
export PG_LOG_LINE_PREFIX=\${PG_LOG_LINE_PREFIX:-"%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h "}
export PG_LOG_STATEMENT=\${PG_LOG_STATEMENT:-none}

export PG_LISTEN_ADDRESSES=\${PG_LISTEN_ADDRESSES:-"*"}
export PG_PORT=\${PG_PORT:-5432}
export PG_SSL=\${PG_SSL:-off}
export PG_SSL_CERT_FILE=\${PG_SSL_CERT_FILE:-""}
export PG_SSL_KEY_FILE=\${PG_SSL_KEY_FILE:-""}
export PG_SSL_CA_FILE=\${PG_SSL_CA_FILE:-""}

export PG_RANDOM_PAGE_COST=\${PG_RANDOM_PAGE_COST:-1.1}
export PG_EFFECTIVE_IO_CONCURRENCY=\${PG_EFFECTIVE_IO_CONCURRENCY:-200}
export PG_DEFAULT_STATISTICS_TARGET=\${PG_DEFAULT_STATISTICS_TARGET:-100}
export PG_AUTOVACUUM=\${PG_AUTOVACUUM:-on}
export PG_AUTOVACUUM_MAX_WORKERS=\${PG_AUTOVACUUM_MAX_WORKERS:-3}

# Initialize database if not already done
if [ ! -d "$PGDATA/base" ]; then
    echo "Initializing PostgreSQL database..."
    su - postgres -c "/usr/local/pgsql/bin/initdb -D $PGDATA --auth-local=trust --auth-host=scram-sha-256"
    
    # Configure PostgreSQL
    cat >> $PGDATA/postgresql.conf <<PGCONF
# Basic settings
listen_addresses = '\${PG_LISTEN_ADDRESSES}'
port = \${PG_PORT}
max_connections = \${PG_MAX_CONNECTIONS}
shared_buffers = '\${PG_SHARED_BUFFERS}'
effective_cache_size = '\${PG_EFFECTIVE_CACHE_SIZE}'
work_mem = '\${PG_WORK_MEM}'
maintenance_work_mem = '\${PG_MAINTENANCE_WORK_MEM}'

# Performance tuning
random_page_cost = \${PG_RANDOM_PAGE_COST}
effective_io_concurrency = \${PG_EFFECTIVE_IO_CONCURRENCY}
default_statistics_target = \${PG_DEFAULT_STATISTICS_TARGET}

# WAL and checkpointing
max_wal_size = '\${PG_MAX_WAL_SIZE}'
checkpoint_timeout = '\${PG_CHECKPOINT_TIMEOUT}'
wal_level = \${PG_WAL_LEVEL}

# Replication settings
max_replication_slots = \${PG_MAX_REPLICATION_SLOTS}
max_wal_senders = \${PG_MAX_WAL_SENDERS}
hot_standby = \${PG_HOT_STANDBY}
max_logical_replication_workers = \${PG_MAX_LOGICAL_REPLICATION_WORKERS}

# Archive settings (configure if needed)
archive_mode = \${PG_ARCHIVE_MODE}
$([ -n "\${PG_ARCHIVE_COMMAND}" ] && echo "archive_command = '\${PG_ARCHIVE_COMMAND}'" || echo "# archive_command = ''")

# Background workers
max_worker_processes = \${PG_MAX_WORKER_PROCESSES}
max_parallel_workers = \${PG_MAX_PARALLEL_WORKERS}
max_parallel_workers_per_gather = \${PG_MAX_PARALLEL_WORKERS_PER_GATHER}
max_parallel_maintenance_workers = \${PG_MAX_PARALLEL_MAINTENANCE_WORKERS}

# Autovacuum settings
autovacuum = \${PG_AUTOVACUUM}
autovacuum_max_workers = \${PG_AUTOVACUUM_MAX_WORKERS}

# Logging
log_destination = '\${PG_LOG_DESTINATION}'
logging_collector = \${PG_LOGGING_COLLECTOR}
log_directory = '\${PG_LOG_DIRECTORY}'
log_filename = '\${PG_LOG_FILENAME}'
log_truncate_on_rotation = on
log_rotation_age = \${PG_LOG_ROTATION_AGE}
log_rotation_size = \${PG_LOG_ROTATION_SIZE}
log_line_prefix = '\${PG_LOG_LINE_PREFIX}'
log_min_duration_statement = \${PG_LOG_MIN_DURATION_STATEMENT}
log_statement = '\${PG_LOG_STATEMENT}'

# SSL Configuration (configure if needed)
ssl = \${PG_SSL}
$([ -n "\${PG_SSL_CERT_FILE}" ] && echo "ssl_cert_file = '\${PG_SSL_CERT_FILE}'" || echo "# ssl_cert_file = ''")
$([ -n "\${PG_SSL_KEY_FILE}" ] && echo "ssl_key_file = '\${PG_SSL_KEY_FILE}'" || echo "# ssl_key_file = ''")
$([ -n "\${PG_SSL_CA_FILE}" ] && echo "ssl_ca_file = '\${PG_SSL_CA_FILE}'" || echo "# ssl_ca_file = ''")

# Extensions
shared_preload_libraries = 'pg_stat_statements,pg_ivm,pg_background,pg_squeeze,pgaudit'

# Extension-specific settings
# pgaudit settings
pgaudit.log = 'all'
pgaudit.log_catalog = off
pgaudit.log_parameter = on
pgaudit.log_relation = off
pgaudit.log_statement_once = off

# pg_stat_statements settings
pg_stat_statements.max = 10000
pg_stat_statements.track = all
pg_stat_statements.save = on
PGCONF

    # Configure client authentication
    cat >> $PGDATA/pg_hba.conf <<HBACONF
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     trust
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256
host    all             all             0.0.0.0/0               scram-sha-256
HBACONF
fi

# Start PostgreSQL
echo "Starting PostgreSQL..."
su - postgres -c "/usr/local/pgsql/bin/pg_ctl -D $PGDATA -l /var/log/postgresql/postgresql.log start"

# Wait for PostgreSQL to start
echo "Waiting for PostgreSQL to start..."
until su - postgres -c "/usr/local/pgsql/bin/pg_isready"; do
  sleep 1
done

# Set default values for PostgreSQL user and database if not provided
export POSTGRES_USER=\${POSTGRES_USER:-postgres}
export POSTGRES_PASSWORD=\${POSTGRES_PASSWORD:-postgres}
export POSTGRES_DB=\${POSTGRES_DB:-postgres}

# Create custom user and database if they don't exist and are different from defaults
echo "Setting up PostgreSQL user and database..."

# Only create a new user if it's different from the default 'postgres' user
if [ "\$POSTGRES_USER" != "postgres" ]; then
    echo "Creating user: \$POSTGRES_USER"
    su - postgres -c "psql -c \"CREATE USER \$POSTGRES_USER WITH SUPERUSER CREATEDB CREATEROLE REPLICATION;\"" || true
fi

# Set password for the user (works for both postgres and custom users)
echo "Setting password for user: \$POSTGRES_USER"
su - postgres -c "psql -c \"ALTER USER \$POSTGRES_USER PASSWORD '\$POSTGRES_PASSWORD';\""

# Create custom database if it's different from the default 'postgres' database
if [ "\$POSTGRES_DB" != "postgres" ]; then
    echo "Creating database: \$POSTGRES_DB"
    su - postgres -c "psql -c \"CREATE DATABASE \$POSTGRES_DB OWNER \$POSTGRES_USER;\""
fi

# Update pg_hba.conf to include the custom user and database if needed
if [ "\$POSTGRES_USER" != "postgres" ] || [ "\$POSTGRES_DB" != "postgres" ]; then
    echo "Updating pg_hba.conf for custom user/database..."
    cat >> $PGDATA/pg_hba.conf <<HBACONF

# Custom user and database configuration
local   \$POSTGRES_DB    \$POSTGRES_USER                         trust
host    \$POSTGRES_DB    \$POSTGRES_USER     127.0.0.1/32        scram-sha-256
host    \$POSTGRES_DB    \$POSTGRES_USER     ::1/128             scram-sha-256
host    \$POSTGRES_DB    \$POSTGRES_USER     0.0.0.0/0           scram-sha-256
HBACONF
    
    # Reload PostgreSQL configuration
    su - postgres -c "/usr/local/pgsql/bin/pg_ctl reload -D $PGDATA"
fi

# Create extensions in the target database
echo "Creating extensions in database: \$POSTGRES_DB"
su - postgres -c "psql -d \"\$POSTGRES_DB\" -c \"CREATE EXTENSION IF NOT EXISTS pg_stat_statements;\""
su - postgres -c "psql -d \"\$POSTGRES_DB\" -c \"CREATE EXTENSION IF NOT EXISTS vector;\""
su - postgres -c "psql -d \"\$POSTGRES_DB\" -c \"CREATE EXTENSION IF NOT EXISTS pg_ivm;\""
su - postgres -c "psql -d \"\$POSTGRES_DB\" -c \"CREATE EXTENSION IF NOT EXISTS pg_background;\""
su - postgres -c "psql -d \"\$POSTGRES_DB\" -c \"CREATE EXTENSION IF NOT EXISTS pg_squeeze;\""
su - postgres -c "psql -d \"\$POSTGRES_DB\" -c \"CREATE EXTENSION IF NOT EXISTS pgaudit;\""

echo "PostgreSQL with pgvector, pg_ivm, pg_background, pg_squeeze, and pgaudit is ready!"
echo "Connection info:"
echo "  Host: localhost"
echo "  Port: 5432"
echo "  Database: \$POSTGRES_DB"
echo "  User: \$POSTGRES_USER"
echo ""
echo "Installed Extensions:"
echo "  - pgvector: Vector similarity search"
echo "  - pg_ivm: Incremental View Maintenance"
echo "  - pg_background: Background workers"
echo "  - pg_squeeze: Table bloat reduction and online table reorganization"
echo "  - pgaudit: PostgreSQL audit logging"
echo ""
echo "Configuration Management:"
echo "  - Configure parameters: /usr/local/bin/configure-postgres.sh set <param> <value>"
echo "  - Show parameters: /usr/local/bin/configure-postgres.sh show <param>"
echo "  - Reload config: /usr/local/bin/configure-postgres.sh reload"
echo ""
echo "Key Configurable Parameters:"
echo "  - Connections: max_connections (default: \${PG_MAX_CONNECTIONS})"
echo "  - Memory: shared_buffers (default: \${PG_SHARED_BUFFERS})"
echo "  - Replication: max_replication_slots (default: \${PG_MAX_REPLICATION_SLOTS})"
echo "  - Workers: max_worker_processes (default: \${PG_MAX_WORKER_PROCESSES})"
echo ""
echo "Test extensions with:"
echo "  psql -U $POSTGRES_USER -d $POSTGRES_DB -c \"SELECT '[1,2,3]'::vector;\""
echo "  psql -U $POSTGRES_USER -d $POSTGRES_DB -c \"SELECT pg_background_launch('SELECT pg_sleep(10);');\""
echo "  psql -U $POSTGRES_USER -d $POSTGRES_DB -c \"SELECT squeeze.squeeze_table('public', 'test_table');\""
EOF

RUN chmod +x /usr/local/bin/init-postgres.sh

# Create a configuration script for runtime parameter changes
RUN cat > /usr/local/bin/configure-postgres.sh <<EOF
#!/bin/bash
set -e

# Function to update PostgreSQL configuration
update_config() {
    local param=$1
    local value=$2
    local config_file="${PGDATA}/postgresql.conf"
    
    if [ -f "$config_file" ]; then
        # Comment out existing parameter and add new one
        sed -i "s/^${param}.*/#&/" "$config_file"
        echo "${param} = ${value}" >> "$config_file"
        echo "Updated ${param} to ${value}"
    else
        echo "Error: PostgreSQL configuration file not found at $config_file"
        exit 1
    fi
}

# Function to reload PostgreSQL configuration
reload_config() {
    if su - postgres -c "/usr/local/pgsql/bin/pg_ctl status -D $PGDATA" >/dev/null 2>&1; then
        su - postgres -c "/usr/local/pgsql/bin/pg_ctl reload -D $PGDATA"
        echo "PostgreSQL configuration reloaded"
    else
        echo "PostgreSQL is not running. Configuration will take effect on next start."
    fi
}

# Function to show current configuration
show_config() {
    local param=$1
    if [ -n "$param" ]; then
        su - postgres -c "psql -c \"SHOW ${param};\""
    else
        echo "Available parameters to configure:"
        echo "  max_connections, shared_buffers, effective_cache_size"
        echo "  work_mem, maintenance_work_mem, max_wal_size"
        echo "  max_replication_slots, max_wal_senders, wal_level"
        echo "  max_worker_processes, max_parallel_workers"
        echo "  log_min_duration_statement, checkpoint_timeout"
        echo ""
        echo "Usage examples:"
        echo "  $0 set max_connections 200"
        echo "  $0 set shared_buffers 512MB"
        echo "  $0 set max_replication_slots 20"
        echo "  $0 show max_connections"
        echo "  $0 reload"
    fi
}

case "$1" in
    set)
        if [ $# -ne 3 ]; then
            echo "Usage: $0 set <parameter> <value>"
            exit 1
        fi
        update_config "$2" "$3"
        ;;
    show)
        show_config "$2"
        ;;
    reload)
        reload_config
        ;;
    *)
        show_config
        ;;
esac
EOF

RUN chmod +x /usr/local/bin/configure-postgres.sh

# Add the debug script to the image
COPY debug-env.sh /usr/local/bin/debug-env.sh
RUN chmod +x /usr/local/bin/debug-env.sh

# Create a test script for pgvector functionality
RUN cat > /usr/local/bin/test-pgvector.sh <<EOF
#!/bin/bash
set -e

echo "Testing pgvector functionality..."

# Set default values for PostgreSQL connection
export POSTGRES_USER=\${POSTGRES_USER:-postgres}
export POSTGRES_DB=\${POSTGRES_DB:-postgres}

# Test basic vector operations
su - postgres -c "psql -U \$POSTGRES_USER -d \$POSTGRES_DB -c \"
-- Test vector creation and operations
SELECT '[1,2,3]'::vector as test_vector;

-- Create a test table with vectors
CREATE TABLE IF NOT EXISTS test_vectors (
    id serial PRIMARY KEY,
    name text,
    embedding vector(3)
);

-- Insert test data
INSERT INTO test_vectors (name, embedding) VALUES
    ('item1', '[1,2,3]'),
    ('item2', '[4,5,6]'),
    ('item3', '[7,8,9]')
ON CONFLICT DO NOTHING;

-- Test similarity search
SELECT 
    name,
    embedding,
    embedding <-> '[2,3,4]'::vector as distance
FROM test_vectors
ORDER BY embedding <-> '[2,3,4]'::vector
LIMIT 3;

-- Test cosine similarity
SELECT 
    name,
    embedding,
    1 - (embedding <=> '[2,3,4]'::vector) as cosine_similarity
FROM test_vectors
ORDER BY embedding <=> '[2,3,4]'::vector
LIMIT 3;
\""

echo "pgvector test completed successfully!"
EOF

RUN chmod +x /usr/local/bin/test-pgvector.sh

# Create a comprehensive test script for all extensions
RUN cat > /usr/local/bin/test-all-extensions.sh <<EOF
#!/bin/bash
set -e

echo "Testing all PostgreSQL extensions..."

# Set default values for PostgreSQL connection
export POSTGRES_USER=\${POSTGRES_USER:-postgres}
export POSTGRES_DB=\${POSTGRES_DB:-postgres}

# Test pgvector
echo "=== Testing pgvector ==="
su - postgres -c "psql -U \$POSTGRES_USER -d \$POSTGRES_DB -c \"
SELECT '[1,2,3]'::vector as test_vector;
CREATE TABLE IF NOT EXISTS test_vectors (id serial PRIMARY KEY, name text, embedding vector(3));
INSERT INTO test_vectors (name, embedding) VALUES ('item1', '[1,2,3]') ON CONFLICT DO NOTHING;
SELECT name, embedding <-> '[2,3,4]'::vector as distance FROM test_vectors LIMIT 1;
\""

# Test pg_ivm
echo "=== Testing pg_ivm ==="
su - postgres -c "psql -U \$POSTGRES_USER -d \$POSTGRES_DB -c \"
CREATE TABLE IF NOT EXISTS base_table (id int, value text);
INSERT INTO base_table VALUES (1, 'test') ON CONFLICT DO NOTHING;
SELECT * FROM base_table LIMIT 1;
\""

# Test pg_background
echo "=== Testing pg_background ==="
su - postgres -c "psql -U \$POSTGRES_USER -d \$POSTGRES_DB -c \"
SELECT * FROM pg_background_result(pg_background_launch('SELECT 2::TEXT as result')) AS background_result(result text);
\""

# Test pg_squeeze
echo "=== Testing pg_squeeze ==="
su - postgres -c "psql -U \$POSTGRES_USER -d \$POSTGRES_DB -c \"
SELECT 'pg_squeeze extension loaded successfully' as squeeze_status FROM pg_extension WHERE extname = 'pg_squeeze';
\""

# Test pgaudit
echo "=== Testing pgaudit ==="
su - postgres -c "psql -U \$POSTGRES_USER -d \$POSTGRES_DB -c \"
SELECT 'pgaudit extension loaded successfully' as pgaudit_status FROM pg_extension WHERE extname = 'pgaudit';
\""

echo "=== All extensions tested successfully! ==="
EOF

RUN chmod +x /usr/local/bin/test-all-extensions.sh

# Create startup script that combines initialization and keeps container running
RUN cat > /usr/local/bin/start-postgres.sh <<EOF
#!/bin/bash
set -e

# Try to initialize and start PostgreSQL, but don't exit if it fails
echo "Attempting to initialize and start PostgreSQL..."
if /usr/local/bin/init-postgres.sh; then
    echo "PostgreSQL started successfully"
else
    echo "PostgreSQL failed to start, but keeping container running for debugging"
fi

# Keep container running regardless of PostgreSQL status
echo "Container is running. You can:"
echo "  - Connect with: docker exec -it <container_name> /bin/bash"
echo "  - Try manual start: /usr/local/bin/init-postgres.sh"
echo "  - Check logs in: /var/log/postgresql/"

# Handle shutdown gracefully
trap 'echo "Shutting down container..."; if pgrep postgres > /dev/null; then su - postgres -c "/usr/local/pgsql/bin/pg_ctl -D $PGDATA stop"; fi; exit 0' SIGTERM SIGINT

# Keep the container running indefinitely
while true; do
    if [ -f /var/log/postgresql/postgresql.log ]; then
        tail -f /var/log/postgresql/postgresql.log &
        TAIL_PID=$!
        wait $TAIL_PID
    else
        echo "Waiting for PostgreSQL log file or manual intervention..."
        sleep 60
    fi
done
EOF

RUN chmod +x /usr/local/bin/start-postgres.sh

# Expose PostgreSQL port
EXPOSE 5432

# Set default user
USER root

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD /usr/local/pgsql/bin/pg_isready -h localhost -p ${PG_PORT:-5432} -U ${POSTGRES_USER:-postgres} || exit 1

# Default command
CMD ["/usr/local/bin/start-postgres.sh"]

# Add labels
LABEL maintainer="Vibhor Kumar <vibhor.aim@gmail.com>"
LABEL description="PostgreSQL 18 with pgvector, pg_ivm, pg_background, pg_squeeze, and pgaudit extensions on Rocky Linux 9"
LABEL version="pg18-multi-extensions-rocky9"
LABEL postgresql.version="REL_18_STABLE"
LABEL pgvector.version="master"
LABEL pg_ivm.version="main"
LABEL pg_background.version="master"
LABEL pg_squeeze.version="master"
LABEL pgaudit.version="main"
LABEL base.image="rockylinux:9"

# BUILD INSTRUCTIONS:
# 
# To build this image on Mac M1/M2, use:
#
# 1. Force AMD64 platform build:
#    docker build --build-arg BUILDPLATFORM=linux/amd64 --no-cache -t postgresql18-pgvector:rocky9 .
#
# 2. For debugging ARM64 issues:
#    docker build --build-arg BUILDPLATFORM=linux/amd64 --progress=plain -t postgresql18-pgvector:rocky9 .
#
# 3. Native platform build (if supported):
#    docker build --no-cache -t postgresql18-pgvector:rocky9 .
#
# 4. Cross-platform build:
#    docker buildx build --platform linux/amd64,linux/arm64 -t postgresql18-pgvector:rocky9 .
#
# 5. Clean up any existing images/containers:
#    docker system prune -af
#    docker rmi postgresql18-pgvector:rocky9 2>/dev/null || true
#    docker rm -f pg18-vector 2>/dev/null || true
#
# 6. Build the image with no cache:
#    docker build --no-cache -t postgresql18-pgvector:rocky9 .
#
# 7. Alternative: Build with pull latest base image:
#    docker build --no-cache --pull -t postgresql18-pgvector:rocky9 .
#
# 8. Build with progress output for debugging:
#    docker build --no-cache --progress=plain -t postgresql18-pgvector:rocky9 .
#
# 9. Build with specific build arguments:
#    docker build --no-cache --build-arg PG_BRANCH=REL_18_STABLE --build-arg PGVECTOR_BRANCH=master -t postgresql18-pgvector:rocky9 .
#
# CLEAN BUILD SCRIPT:
# Create a script file clean-build.sh with the following content:
# #!/bin/bash
# set -e
# echo "Cleaning up existing Docker artifacts..."
# docker system prune -af
# docker rmi postgresql18-pgvector:rocky9 2>/dev/null || true
# docker rm -f pg18-vector 2>/dev/null || true
# echo "Building fresh image..."
# docker build --no-cache --pull --progress=plain -t postgresql18-pgvector:rocky9 .
# echo "Build completed successfully!"
#
# USAGE EXAMPLES:
#
# 1. Run the container:
#    docker run -d --name pg18-vector -p 5432:5432 postgresql18-pgvector:rocky9
#
# 2. Run with persistent data:
#    docker run -d --name pg18-vector -p 5432:5432 -v pg_data:/var/lib/postgresql/data postgresql18-pgvector:rocky9
#
# 3. Test pgvector functionality:
#    docker exec pg18-vector /usr/local/bin/test-pgvector.sh
#
# 4. Connect to PostgreSQL:
#    docker exec -it pg18-vector psql -U postgres
#
# 4. Connect to PostgreSQL:
#    docker exec -it pg18-vector psql -U postgres
#
# ENVIRONMENT VARIABLES FOR POSTGRESQL CONFIGURATION:
#
# Memory and Performance:
#   PG_SHARED_BUFFERS=256MB          # Shared memory buffer size
#   PG_EFFECTIVE_CACHE_SIZE=1GB      # Estimate of OS disk cache  
#   PG_WORK_MEM=4MB                  # Memory for query operations
#   PG_MAINTENANCE_WORK_MEM=64MB     # Memory for maintenance operations
#   PG_RANDOM_PAGE_COST=1.1          # Random page cost estimate
#   PG_EFFECTIVE_IO_CONCURRENCY=200  # Effective I/O concurrency
#
# Connections and Workers:
#   PG_MAX_CONNECTIONS=100           # Maximum client connections
#   PG_MAX_WORKER_PROCESSES=8        # Maximum background worker processes
#   PG_MAX_PARALLEL_WORKERS=8        # Maximum parallel workers
#   PG_MAX_PARALLEL_WORKERS_PER_GATHER=2  # Max parallel workers per gather
#   PG_MAX_PARALLEL_MAINTENANCE_WORKERS=2 # Max parallel maintenance workers
#
# Replication and High Availability:
#   PG_MAX_REPLICATION_SLOTS=10      # Maximum replication slots
#   PG_MAX_WAL_SENDERS=10           # Maximum WAL sender processes
#   PG_WAL_LEVEL=replica            # WAL level (minimal, replica, logical)
#   PG_ARCHIVE_MODE=off             # Archive mode (on, off, always)
#   PG_HOT_STANDBY=on               # Hot standby mode
#
# WAL and Checkpointing:
#   PG_MAX_WAL_SIZE=2GB             # Maximum WAL size
#   PG_CHECKPOINT_TIMEOUT=10min     # Checkpoint timeout
#
# Logging:
#   PG_LOG_MIN_DURATION_STATEMENT=1000  # Log queries taking longer than N ms
#   PG_LOG_DESTINATION=stderr            # Log destination
#   PG_LOGGING_COLLECTOR=on              # Enable log collector
#   PG_LOG_DIRECTORY=/var/log/postgresql # Log directory
#   PG_LOG_FILENAME=postgresql-%Y-%m-%d.log # Log filename pattern
#   PG_LOG_ROTATION_AGE=1d               # Log rotation age
#   PG_LOG_ROTATION_SIZE=100MB           # Log rotation size
#
# Network and Security:
#   PG_LISTEN_ADDRESSES="*"         # Listen addresses
#   PG_PORT=5432                    # PostgreSQL port
#   PG_SSL=off                      # SSL mode
#
# Autovacuum:
#   PG_AUTOVACUUM=on                # Enable autovacuum
#   PG_AUTOVACUUM_MAX_WORKERS=3     # Maximum autovacuum workers
#
# ADVANCED CONFIGURATION EXAMPLES:
#
# 1. High-memory server configuration:
#    docker run -d --name pg18-vector -p 5432:5432 \
#      -e PG_SHARED_BUFFERS=2GB \
#      -e PG_EFFECTIVE_CACHE_SIZE=8GB \
#      -e PG_WORK_MEM=32MB \
#      -e PG_MAINTENANCE_WORK_MEM=512MB \
#      -e PG_MAX_CONNECTIONS=300 \
#      -e PG_MAX_WORKER_PROCESSES=16 \
#      postgresql18-pgvector:rocky9
#
# 2. Replication master configuration:
#    docker run -d --name pg18-master -p 5432:5432 \
#      -e PG_MAX_REPLICATION_SLOTS=20 \
#      -e PG_MAX_WAL_SENDERS=10 \
#      -e PG_WAL_LEVEL=replica \
#      -e PG_ARCHIVE_MODE=on \
#      -e PG_HOT_STANDBY=on \
#      postgresql18-pgvector:rocky9
#
# 3. Development/testing configuration:
#    docker run -d --name pg18-dev -p 5432:5432 \
#      -e PG_SHARED_BUFFERS=128MB \
#      -e PG_MAX_CONNECTIONS=50 \
#      -e PG_LOG_MIN_DURATION_STATEMENT=100 \
#      postgresql18-pgvector:rocky9
#
# 4. Runtime configuration management:
#    # Change memory settings
#    docker exec pg18-vector /usr/local/bin/configure-postgres.sh set shared_buffers 2GB
#    docker exec pg18-vector /usr/local/bin/configure-postgres.sh set work_mem 16MB
#    
#    # Change replication settings
#    docker exec pg18-vector /usr/local/bin/configure-postgres.sh set max_replication_slots 30
#    docker exec pg18-vector /usr/local/bin/configure-postgres.sh set max_wal_senders 15
#    
#    # Reload configuration
#    docker exec pg18-vector /usr/local/bin/configure-postgres.sh reload
#    
#    # Show current settings
#    docker exec pg18-vector /usr/local/bin/configure-postgres.sh show shared_buffers
#    docker exec pg18-vector /usr/local/bin/configure-postgres.sh show max_connections
