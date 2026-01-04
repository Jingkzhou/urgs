#!/bin/bash
set -e

echo "Loading docker images from urgs-images.tar..."
docker load -i urgs-images.tar

echo "Updating services: urgs-api..."
docker-compose up -d urgs-api

echo "URGS components [urgs-api] updated successfully!"
