#!/bin/bash
set -e

echo "Loading docker images from urgs-images.tar..."
docker load -i urgs-images.tar

echo "Updating services: urgs-web..."
docker-compose up -d urgs-web

echo "URGS components [urgs-web] updated successfully!"
