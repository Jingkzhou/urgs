#!/bin/bash
set -e

echo "Loading docker images from urgs-images.tar..."
docker load -i urgs-images.tar

echo "Updating services: sql-lineage-engine..."
docker-compose up -d sql-lineage-engine

echo "URGS components [sql-lineage-engine] updated successfully!"
