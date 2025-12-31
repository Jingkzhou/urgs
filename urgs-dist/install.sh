#!/bin/bash
set -e

echo "Loading docker images from urgs-images.tar..."
docker load -i urgs-images.tar

echo "Updating services: urgs-api urgs-web urgs-executor sql-lineage-engine neo4j..."
docker-compose up -d urgs-api urgs-web urgs-executor sql-lineage-engine neo4j

echo "URGS components [urgs-api urgs-web urgs-executor sql-lineage-engine neo4j] updated successfully!"
