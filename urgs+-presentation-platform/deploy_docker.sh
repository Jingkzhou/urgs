#!/bin/bash

# Configuration
IMAGE_NAME="urgs-platform"
CONTAINER_NAME="urgs-platform-container"
PORT=3001

echo "🚀 Starting Docker deployment for $IMAGE_NAME..."

# Build the Docker image
echo "📦 Building Docker image..."
docker build -t $IMAGE_NAME .

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed."
    exit 1
fi

# Check if a container with the same name exists
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo "🛑 Stopping and removing existing container..."
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
fi

# Run the new container
echo "▶️  Running container on port $PORT..."
docker run -d --name $CONTAINER_NAME -p $PORT:80 $IMAGE_NAME

if [ $? -eq 0 ]; then
    echo "✅ Deployment successful!"
    echo "🌍 App is running at: http://localhost:$PORT"
else
    echo "❌ Docker run failed."
    exit 1
fi
