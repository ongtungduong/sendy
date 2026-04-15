#!/bin/bash

# Sendy Docker Quick Start Script
# This script helps you quickly set up and run Sendy with Docker

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BOLD}═══════════════════════════════════════════════════${NC}"
echo -e "${BOLD}   Sendy Docker Setup${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose (v2) is available
if ! docker compose version &> /dev/null 2>&1; then
    echo -e "${RED}✗ Docker Compose is not available. Please install Docker with Compose plugin.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker is installed${NC}"

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠ .env file not found. Creating from .env.example...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}⚠ Please edit .env file with your settings before continuing.${NC}"
    echo ""
    echo -e "${BOLD}Required settings:${NC}"
    echo "  - MySQL passwords"
    echo "  - APP_PATH (your domain)"
    echo "  - AWS SES credentials"
    echo ""
    read -p "Press Enter after editing .env file..."
fi

echo ""
echo -e "${BOLD}Building and starting containers...${NC}"
echo -e "${YELLOW}(MySQL healthcheck will ensure database is ready before starting app)${NC}"
echo ""

# Build and start containers
# MySQL healthcheck + depends_on condition ensures proper startup order
docker compose up -d --build

echo ""

# Wait for all services to be healthy
echo -e "${BOLD}Waiting for all services to be healthy...${NC}"

MAX_ATTEMPTS=60
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    HEALTHY=$(docker compose ps --format json 2>/dev/null | grep -c '"healthy"' || true)
    TOTAL=$(docker compose ps --format json 2>/dev/null | wc -l | tr -d ' ')

    if [ "$HEALTHY" -ge 1 ] && docker compose ps | grep -q "sendy-app.*Up"; then
        echo -e "${GREEN}✓ All services are healthy!${NC}"
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    echo -n "."
    sleep 2
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo -e "${RED}✗ Services failed to become healthy. Check logs:${NC}"
    echo "  docker compose logs"
    exit 1
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Sendy is now running!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo ""
echo "1. Open your browser and go to: ${BOLD}http://localhost${NC}"
echo "   (or the APP_PATH you configured in .env)"
echo ""
echo "2. Follow the Sendy installation wizard"
echo ""
echo "3. Use these database settings:"
echo "   - Host: ${BOLD}mysql${NC}"
echo "   - Port: ${BOLD}3306${NC}"
echo "   - Database: Check your .env file"
echo "   - User: Check your .env file"
echo "   - Password: Check your .env file"
echo ""
echo -e "${BOLD}Useful commands:${NC}"
echo "  View logs:           docker compose logs -f"
echo "  Stop containers:     docker compose down"
echo "  Restart containers:  docker compose restart"
echo "  Access database:     docker compose exec mysql mysql -u sendy_user -p"
echo ""

