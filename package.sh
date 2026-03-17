#!/bin/bash
set -e

# Define helper function to get image for a module
get_image() {
    case $1 in
        api) echo "urgs-api:latest" ;;
        web) echo "urgs-web:latest" ;;
        executor) echo "urgs-executor:latest" ;;
        lineage) echo "sql-lineage-engine:latest" ;;
        neo4j) echo "neo4j:5.15.0" ;;
        presentation) echo "urgs-presentation:latest" ;;
        dify-api) echo "urgs-dify-api:latest" ;;
        dify-web) echo "urgs-dify-web:latest" ;;
        *) echo "" ;;
    esac
}

# Define helper function to get service name in docker-compose.yml
get_service_name() {
    case $1 in
        api) echo "urgs-api" ;;
        web) echo "urgs-web" ;;
        executor) echo "urgs-executor" ;;
        lineage) echo "sql-lineage-engine" ;;
        neo4j) echo "neo4j" ;;
        presentation) echo "urgs-presentation" ;;
        dify-api) echo "urgs-dify-api" ;;
        dify-web) echo "urgs-dify-web" ;;
        dify-worker) echo "urgs-dify-worker" ;;
        *) echo "" ;;
    esac
}

ALL_MODULES=("api" "web" "executor" "lineage" "neo4j" "presentation" "dify-api" "dify-web" "dify-worker")

# Parse requested modules
SELECTED_MODULES=()
if [ $# -eq 0 ]; then
    echo "No modules specified. Starting URGS Full Production Packaging..."
    SELECTED_MODULES=("${ALL_MODULES[@]}")
else
    for arg in "$@"; do
        IMG=$(get_image "$arg")
        if [ -n "$IMG" ]; then
            SELECTED_MODULES+=("$arg")
        else
            echo "Error: Unknown module '$arg'"
            echo "Available modules: ${ALL_MODULES[*]}"
            exit 1
        fi
    done
    echo "Starting URGS Partial Packaging for: ${SELECTED_MODULES[*]}"
fi
 
# 0. Sync Submodules
echo "Syncing submodules (Dify)..."
git submodule update --init --recursive

# 1. Build selected images
echo "Building Docker images..."
for mod in "${SELECTED_MODULES[@]}"; do
    SERVICE_NAME=$(get_service_name "$mod")
    if [ -n "$SERVICE_NAME" ]; then
        docker-compose build "$SERVICE_NAME"
    fi
done

# 2. Prepare output directory
DIST_DIR="urgs-dist"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# 3. Save selected images
IMAGES_TO_SAVE=()
for mod in "${SELECTED_MODULES[@]}"; do
    IMAGES_TO_SAVE+=($(get_image "$mod"))
done

TAR_NAME="urgs-images.tar"
echo "Saving selected Docker images to $TAR_NAME..."
docker save -o "$DIST_DIR/$TAR_NAME" "${IMAGES_TO_SAVE[@]}"

# 4. Copy configuration files
echo "Copying configuration files..."
cp docker-compose.yml "$DIST_DIR/"
if [ -f .env.prod ]; then
    cp .env.prod "$DIST_DIR/.env"
else
    touch "$DIST_DIR/.env"
fi

# 5. Create a dynamic install script
SELECTED_SERVICES=()
for mod in "${SELECTED_MODULES[@]}"; do
    SELECTED_SERVICES+=($(get_service_name "$mod"))
done

cat > "$DIST_DIR/install.sh" << EOF
#!/bin/bash
set -e

echo "Loading docker images from $TAR_NAME..."
docker load -i $TAR_NAME

echo "Updating services: ${SELECTED_SERVICES[*]}..."
docker-compose up -d ${SELECTED_SERVICES[*]}

echo "URGS components [${SELECTED_SERVICES[*]}] updated successfully!"
EOF

chmod +x "$DIST_DIR/install.sh"
chmod +x package.sh

echo "Packaging complete! Artifacts are in $DIST_DIR/"
echo "To deploy, copy $DIST_DIR to target server and run ./install.sh"
