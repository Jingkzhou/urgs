#!/bin/bash

# Configuration
IMAGE_NAME="urgs-platform"
PACKAGE_NAME="urgs-deploy-package"
OUTPUT_DIR="temp_package"

echo "📦 Starting packaging process for $IMAGE_NAME..."

# 1. Build Docker Image
echo "   Building Docker image..."
docker build --build-arg VITE_DASHBOARD_URL="http://25.18.17.139:3000" -t $IMAGE_NAME .
if [ $? -ne 0 ]; then
    echo "❌ Docker build failed."
    exit 1
fi

# 2. Prepare Output Directory
rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

# 3. Export Docker Image
echo "   Saving Docker image (this may take a moment)..."
docker save -o $OUTPUT_DIR/urgs-platform-image.tar $IMAGE_NAME

if [ $? -ne 0 ]; then
    echo "❌ Failed to save Docker image."
    exit 1
fi

# 4. Generate Setup Script
echo "   Generating setup.sh..."
cat << 'EOF' > $OUTPUT_DIR/setup.sh
#!/bin/bash
IMAGE_FILE="urgs-platform-image.tar"
IMAGE_NAME="urgs-platform"
CONTAINER_NAME="urgs-platform-container"
PORT=3001

echo "🚀 Deploying URGS+ Platform..."

# Check if image file exists
if [ ! -f "$IMAGE_FILE" ]; then
    echo "❌ Error: $IMAGE_FILE not found in current directory."
    exit 1
fi

# Load Docker Image
echo "   Loading Docker image..."
docker load -i $IMAGE_FILE

# Stop and Remove Existing Container
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo "   Stopping existing container..."
    docker stop $CONTAINER_NAME > /dev/null 2>&1
    docker rm $CONTAINER_NAME > /dev/null 2>&1
fi

# Run New Container
echo "   Starting container on port $PORT..."
docker run -d --restart unless-stopped --name $CONTAINER_NAME -p $PORT:80 $IMAGE_NAME

echo "✅ App deployed successfully!"
echo "🌍 Access at: http://localhost:$PORT"
EOF

chmod +x $OUTPUT_DIR/setup.sh

# 5. Create Final Archive
echo "   Compressing package..."
tar -czf $PACKAGE_NAME.tar.gz -C $OUTPUT_DIR .

# 6. Cleanup
rm -rf $OUTPUT_DIR

echo "🎉 Package created successfully: $PACKAGE_NAME.tar.gz"
echo "   To deploy: Copy this file to target server, extract, and run ./setup.sh"
