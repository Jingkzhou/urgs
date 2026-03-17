#!/bin/bash

# Navigate to the script's directory
cd "$(dirname "$0")"

echo "Checking Dify Status..."

# 0. Check for .env file
if [ ! -f .env ]; then
  echo "⚠️  .env file not found!"
  echo "Creating .env from .env.example..."
  cp .env.example .env
  echo "✅  .env created."
fi

# 1. Check if docker is running
if ! docker info > /dev/null 2>&1; then
  echo "❌  Error: Docker is not running. Please start Docker Desktop App first."
  exit 1
fi

# 2. Check and start services
echo "Starting services..."
docker compose up -d

if [ $? -ne 0 ]; then
  echo "❌  Failed to run 'docker compose up -d'."
  echo "Please check if you have permissions or if docker is configured correctly."
  exit 1
fi

echo "Wait for 5 seconds for services to initialize..."
sleep 5

# 3. Validation
# Check if nginx is running
RUNNING_CONTAINERS=$(docker ps --format "{{.LoclaNames}}")
echo "$RUNNING_CONTAINERS" | grep -q "nginx"
IS_NGINX_UP=$?

echo "---------------------------------------------------"
echo "Container Status Check:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -n 10
echo "---------------------------------------------------"

if [ $IS_NGINX_UP -eq 0 ]; then
    echo "✅  Dify seems to be running!"
    echo "Access URL: http://localhost"
    echo ""
    echo "If you still see 'Connection Refused':"
    echo "1. Wait another 10-20 seconds."
    echo "2. Run 'docker compose logs -f nginx' to see errors."
else
    echo "⚠️  Services started but Nginx container is NOT running."
    echo "Showing last 20 lines of logs for ALL containers:"
    docker compose logs --tail=20
fi
