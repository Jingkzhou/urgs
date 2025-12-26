#!/bin/bash
set -e

echo "Loading docker images from urgs-images.tar..."
docker load -i urgs-images.tar

echo "Updating services: urgs-web sql-lineage-engine..."
docker-compose up -d urgs-web sql-lineage-engine

echo "URGS components [urgs-web sql-lineage-engine] updated successfully!"
