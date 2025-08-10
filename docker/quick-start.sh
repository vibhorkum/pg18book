#!/bin/bash

# PostgreSQL 18 with pgvector - Quick Start Script
# This script helps you get started with the PostgreSQL 18 AI demo environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
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

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_status "Docker is running ✓"
}

# Function to build the PostgreSQL image
build_image() {
    print_header "Building PostgreSQL 18 with pgvector"
    cd docker/postgresql
    docker build --no-cache -t pg18book:latest .
    cd ../..
    print_status "Image built successfully ✓"
}

# Function to start the AI demo environment
start_ai_demo() {
    print_header "Starting AI Demo Environment"
    cd docker/compose
    docker-compose -f docker-compose.ai-demo.yml up -d
    cd ../..
    
    print_status "Waiting for PostgreSQL to be ready..."
    sleep 10
    
    # Check if PostgreSQL is ready
    if docker exec pg18book pg_isready -U postgres > /dev/null 2>&1; then
        print_status "PostgreSQL is ready ✓"
    else
        print_warning "PostgreSQL might still be starting up. Please wait a moment."
    fi
}

# Function to setup the AI demo data
setup_ai_demo() {
    print_header "Setting up AI Demo Data"
    
    print_status "Running master setup script..."
    docker exec -i pg18book psql -U postgres < psql_scripts/master_setup.sql
    
    print_status "Installing AI recommendation system..."
    docker exec -i pg18book psql -U postgres -d west_ecommerce_data < psql_scripts/ai_recommendations.sql
    
    print_status "AI demo setup complete ✓"
}

# Function to run the AI demo
run_ai_demo() {
    print_header "Running AI Demo"
    print_status "Executing AI demo script..."
    docker exec -it pg18book psql -U postgres -d west_ecommerce_data -f /docker-entrypoint-initdb.d/scripts/ai_demo.sql
}

# Function to show connection information
show_connection_info() {
    print_header "Connection Information"
    echo -e "${GREEN}PostgreSQL Database:${NC}"
    echo "  Host: localhost"
    echo "  Port: 5432"
    echo "  User: postgres"
    echo "  Password: postgres"
    echo "  Database: west_ecommerce_data (for AI features)"
    echo ""
    echo -e "${GREEN}pgAdmin (if started with AI demo):${NC}"
    echo "  URL: http://localhost:8080"
    echo "  Email: admin@pg18book.com"
    echo "  Password: admin"
    echo ""
    echo -e "${GREEN}Connect via psql:${NC}"
    echo "  docker exec -it pg18book psql -U postgres -d west_ecommerce_data"
}

# Main menu
show_menu() {
    print_header "PostgreSQL 18 AI Demo - Quick Start"
    echo "1. Build Docker image"
    echo "2. Start AI demo environment"
    echo "3. Setup AI demo data"
    echo "4. Run AI demo"
    echo "5. Show connection info"
    echo "6. Complete setup (1+2+3)"
    echo "7. Stop environment"
    echo "8. Clean up everything"
    echo "9. Exit"
    echo ""
    read -p "Choose an option (1-9): " choice
}

# Execute choice
execute_choice() {
    case $choice in
        1)
            check_docker
            build_image
            ;;
        2)
            check_docker
            start_ai_demo
            show_connection_info
            ;;
        3)
            setup_ai_demo
            ;;
        4)
            run_ai_demo
            ;;
        5)
            show_connection_info
            ;;
        6)
            check_docker
            build_image
            start_ai_demo
            setup_ai_demo
            show_connection_info
            ;;
        7)
            print_status "Stopping environment..."
            cd docker/compose
            docker-compose -f docker-compose.ai-demo.yml down
            cd ../..
            print_status "Environment stopped ✓"
            ;;
        8)
            print_warning "This will remove all containers, volumes, and data!"
            read -p "Are you sure? (y/N): " confirm
            if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
                cd docker/compose
                docker-compose -f docker-compose.ai-demo.yml down -v
                cd ../..
                docker rmi pg18book:latest 2>/dev/null || true
                print_status "Cleanup complete ✓"
            fi
            ;;
        9)
            print_status "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid option. Please choose 1-9."
            ;;
    esac
}

# Main loop
while true; do
    show_menu
    execute_choice
    echo ""
    read -p "Press Enter to continue..."
    clear
done
