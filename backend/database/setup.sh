#!/bin/bash

# Quick Talk Tales Database Setup Script
# This script sets up PostgreSQL database for the Quick Talk Tales application

set -e

# Configuration
DB_NAME="quick_talk_tales"
DB_USER="quick_talk_tales_user"
DB_PASSWORD="your_secure_password_here"
DB_HOST="localhost"
DB_PORT="5432"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_postgresql() {
    if ! command -v psql &> /dev/null; then
        echo_error "PostgreSQL is not installed. Please install PostgreSQL first."
        exit 1
    fi
    echo_info "PostgreSQL found"
}

check_database_exists() {
    if psql -h $DB_HOST -p $DB_PORT -U postgres -lqt | cut -d \| -f 1 | grep -qw $DB_NAME; then
        return 0
    else
        return 1
    fi
}

check_user_exists() {
    if psql -h $DB_HOST -p $DB_PORT -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
        return 0
    else
        return 1
    fi
}

create_user() {
    echo_info "Creating database user: $DB_USER"
    psql -h $DB_HOST -p $DB_PORT -U postgres -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
    psql -h $DB_HOST -p $DB_PORT -U postgres -c "ALTER USER $DB_USER CREATEDB;"
}

create_database() {
    echo_info "Creating database: $DB_NAME"
    psql -h $DB_HOST -p $DB_PORT -U postgres -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;"
}

run_schema() {
    echo_info "Running database schema..."
    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$(dirname "$0")/schema.sql"
}

run_seeds() {
    if [ -f "$(dirname "$0")/seeds/initial_data.sql" ]; then
        echo_info "Running seed data..."
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$(dirname "$0")/seeds/initial_data.sql"
    else
        echo_warning "No seed data found. Skipping..."
    fi
}

create_env_file() {
    local env_file="$(dirname "$0")/../.env"
    if [ ! -f "$env_file" ]; then
        echo_info "Creating .env file with database configuration..."
        cat > "$env_file" << EOF
# Database Configuration
DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_NAME=${DB_NAME}
DB_USERNAME=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}

# Application Configuration
NODE_ENV=development
PORT=3000
JWT_SECRET=your_jwt_secret_key_change_in_production
JWT_EXPIRES_IN=1d
JWT_REFRESH_SECRET=your_jwt_refresh_secret_key_change_in_production
JWT_REFRESH_EXPIRES_IN=7d

# Redis Configuration (optional)
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# File Upload Configuration
MAX_FILE_SIZE=10485760
UPLOAD_PATH=uploads/
EOF
        echo_warning "Please update the JWT secrets and other sensitive information in .env file"
    else
        echo_info ".env file already exists. Skipping creation."
    fi
}

main() {
    echo_info "Starting Quick Talk Tales database setup..."
    
    # Check if PostgreSQL is installed
    check_postgresql
    
    # Create user if doesn't exist
    if check_user_exists; then
        echo_info "Database user $DB_USER already exists"
    else
        create_user
    fi
    
    # Create database if doesn't exist
    if check_database_exists; then
        echo_warning "Database $DB_NAME already exists"
        read -p "Do you want to recreate it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo_info "Dropping existing database..."
            psql -h $DB_HOST -p $DB_PORT -U postgres -c "DROP DATABASE $DB_NAME;"
            create_database
            run_schema
            run_seeds
        else
            echo_info "Keeping existing database"
        fi
    else
        create_database
        run_schema
        run_seeds
    fi
    
    # Create environment file
    create_env_file
    
    echo_info "Database setup completed successfully!"
    echo_info "Database URL: postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
    echo_warning "Don't forget to:"
    echo_warning "1. Update .env file with production-ready secrets"
    echo_warning "2. Configure your application to use the database connection"
    echo_warning "3. Install required Node.js dependencies: npm install @nestjs/typeorm typeorm pg"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --db-name)
            DB_NAME="$2"
            shift 2
            ;;
        --db-user)
            DB_USER="$2"
            shift 2
            ;;
        --db-password)
            DB_PASSWORD="$2"
            shift 2
            ;;
        --db-host)
            DB_HOST="$2"
            shift 2
            ;;
        --db-port)
            DB_PORT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --db-name      Database name (default: quick_talk_tales)"
            echo "  --db-user      Database user (default: quick_talk_tales_user)"
            echo "  --db-password  Database password (default: your_secure_password_here)"
            echo "  --db-host      Database host (default: localhost)"
            echo "  --db-port      Database port (default: 5432)"
            echo "  -h, --help     Show this help message"
            exit 0
            ;;
        *)
            echo_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main function
main