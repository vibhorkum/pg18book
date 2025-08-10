#!/bin/bash

# Migration script for existing users
# This script helps migrate from the old Docker setup to the new organized structure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to backup existing data
backup_existing_data() {
    print_header "Backing Up Existing Data"
    
    if docker ps -a | grep -q pg18book; then
        print_status "Found existing pg18book container"
        
        # Create backup directory
        mkdir -p backups
        
        # Backup databases
        if docker exec pg18book pg_isready -U postgres > /dev/null 2>&1; then
            print_status "Creating database backups..."
            
            # List of databases to backup
            databases=("ecommerce_reference_data" "west_ecommerce_data" "east_ecommerce_data" "us_ecommerce_data")
            
            for db in "${databases[@]}"; do
                if docker exec pg18book psql -U postgres -lqt | cut -d \| -f 1 | grep -qw "$db"; then
                    print_status "Backing up $db..."
                    docker exec pg18book pg_dump -U postgres "$db" > "backups/${db}_$(date +%Y%m%d_%H%M%S).sql"
                fi
            done
            
            print_status "Backups created in ./backups/ directory"
        else
            print_warning "Container exists but PostgreSQL is not responding"
        fi
    else
        print_status "No existing pg18book container found - fresh installation"
    fi
}

# Function to stop old containers
stop_old_containers() {
    print_header "Stopping Old Containers"
    
    # Stop using old docker-compose.yml in root
    if [ -f docker-compose.yml ]; then
        print_status "Stopping services using root docker-compose.yml..."
        docker-compose down || true
    fi
    
    # Stop any containers from pgsql18-docker directory
    if [ -d pgsql18-docker ]; then
        cd pgsql18-docker
        if [ -f docker-compose.yml ]; then
            print_status "Stopping services from pgsql18-docker directory..."
            docker-compose down || true
        fi
        cd ..
    fi
    
    # Force stop any remaining pg18book containers
    if docker ps -a | grep -q pg18book; then
        print_status "Force stopping any remaining pg18book containers..."
        docker stop pg18book 2>/dev/null || true
        docker rm pg18book 2>/dev/null || true
    fi
}

# Function to migrate to new structure
migrate_to_new_structure() {
    print_header "Migrating to New Docker Structure"
    
    # Build new image
    print_status "Building new PostgreSQL image..."
    cd docker/postgresql
    docker build -t pg18book:latest .
    cd ../..
    
    # Start new environment
    print_status "Starting new AI demo environment..."
    cd docker/compose
    docker-compose -f docker-compose.ai-demo.yml up -d
    cd ../..
    
    print_status "Waiting for PostgreSQL to be ready..."
    sleep 15
    
    # Check if PostgreSQL is ready
    if docker exec pg18book pg_isready -U postgres > /dev/null 2>&1; then
        print_status "PostgreSQL is ready ✓"
    else
        print_warning "PostgreSQL might still be starting up. Please wait a moment."
    fi
}

# Function to restore data
restore_data() {
    print_header "Restoring Data"
    
    if [ -d backups ] && [ "$(ls -A backups)" ]; then
        print_status "Found backup files. Setting up fresh environment with master_setup.sql..."
        
        # Run master setup to create databases
        docker exec -i pg18book psql -U postgres < psql_scripts/master_setup.sql
        
        # Install AI system
        print_status "Installing AI recommendation system..."
        docker exec -i pg18book psql -U postgres -d west_ecommerce_data < psql_scripts/ai_recommendations.sql
        
        print_status "Migration completed! Your data is backed up in ./backups/"
        print_warning "If you had custom data, you may need to restore it manually from the backup files."
    else
        print_status "No backups found. Setting up fresh environment..."
        
        # Run master setup
        docker exec -i pg18book psql -U postgres < psql_scripts/master_setup.sql
        
        # Install AI system
        docker exec -i pg18book psql -U postgres -d west_ecommerce_data < psql_scripts/ai_recommendations.sql
    fi
}

# Function to show new access information
show_access_info() {
    print_header "New Access Information"
    echo -e "${GREEN}PostgreSQL Database:${NC}"
    echo "  Host: localhost"
    echo "  Port: 5432"
    echo "  User: postgres"
    echo "  Password: postgres"
    echo "  AI Database: west_ecommerce_data"
    echo ""
    echo -e "${GREEN}pgAdmin Web Interface:${NC}"
    echo "  URL: http://localhost:8080"
    echo "  Email: admin@pg18book.com"
    echo "  Password: admin"
    echo ""
    echo -e "${GREEN}Quick Start Commands:${NC}"
    echo "  Connect via psql: docker exec -it pg18book psql -U postgres -d west_ecommerce_data"
    echo "  Run AI demo: docker exec -it pg18book psql -U postgres -d west_ecommerce_data -f /docker-entrypoint-initdb.d/scripts/ai_demo.sql"
    echo "  Use quick-start script: ./docker/quick-start.sh"
    echo ""
    echo -e "${GREEN}New Docker Commands:${NC}"
    echo "  Start: cd docker/compose && docker-compose -f docker-compose.ai-demo.yml up -d"
    echo "  Stop: cd docker/compose && docker-compose -f docker-compose.ai-demo.yml down"
    echo "  Logs: docker logs -f pg18book"
}

# Main migration function
main() {
    print_header "PostgreSQL 18 AI Demo - Migration Script"
    echo "This script will migrate your existing setup to the new organized Docker structure."
    echo ""
    
    read -p "Do you want to proceed with the migration? (y/N): " confirm
    if [[ ! $confirm == [yY] || ! $confirm == [yY][eE][sS] ]]; then
        if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
            :  # Continue
        else
            print_status "Migration cancelled."
            exit 0
        fi
    fi
    
    backup_existing_data
    stop_old_containers
    migrate_to_new_structure
    restore_data
    show_access_info
    
    print_header "Migration Complete!"
    print_status "Your PostgreSQL 18 AI demo environment is now running with the new organized structure."
    print_status "The old docker-compose.yml file is still available but should be replaced with the new structure."
    print_warning "Consider removing the old pgsql18-docker directory after verifying everything works correctly."
}

# Check if we're in the right directory
if [ ! -f README.md ] || [ ! -d docker ]; then
    print_error "Please run this script from the pg18book repository root directory."
    exit 1
fi

# Run main migration
main
