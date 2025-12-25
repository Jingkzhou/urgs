#!/bin/bash
set -e

echo "Loading docker images..."
docker load -i urgs-images.tar

echo "Starting services..."
docker-compose up -d

echo "URGS deployed successfully!"
