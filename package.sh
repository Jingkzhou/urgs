#!/bin/bash
set -e

echo "Starting URGS Production Packaging..."

# 1. Build all images
echo "Building Docker images..."
docker-compose build

# 2. Prepare output directory
DIST_DIR="urgs-dist"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# 3. Save images
echo "Saving Docker images to tarball (this may take a while)..."
docker save -o "$DIST_DIR/urgs-images.tar" \
    urgs-api:latest \
    urgs-web:latest \
    urgs-executor:latest \
    sql-lineage-engine:latest \
    neo4j:5.15.0

# 4. Copy configuration files
echo "Copying configuration files..."
cp docker-compose.yml "$DIST_DIR/"
cp .env.prod "$DIST_DIR/.env"

# 5. Create a load/start script for the user
cat > "$DIST_DIR/install.sh" << 'EOF'
#!/bin/bash
set -e

echo "Loading docker images..."
docker load -i urgs-images.tar

echo "Starting services..."
docker-compose up -d

echo "URGS deployed successfully!"
EOF

chmod +x "$DIST_DIR/install.sh"
chmod +x package.sh

echo "Packaging complete! Artifacts are in $DIST_DIR/"
echo "You can archive it with: tar -czf urgs-dist.tar.gz $DIST_DIR"
