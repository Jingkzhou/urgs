#!/bin/sh

# Ensure generated files are world-readable (avoid 640 umask)
umask 022

# Generate config.js from environment variables
# This allows "Build Once, Run Anywhere" strategy
# Variables started with VITE_ are picked up

cat <<EOF > /usr/share/nginx/html/config.js
window.__RUNTIME_CONFIG__ = {
  VITE_WS_URL: "${VITE_WS_URL:-ws://localhost:8080/ws/im}",
  VITE_API_URL: "${VITE_API_URL:-http://localhost:8080}",
  VITE_RAG_URL: "${VITE_RAG_URL:-http://localhost:8001}"
};
EOF

chmod 644 /usr/share/nginx/html/config.js

# Handle Nginx dynamic proxy targets
# We use /etc/nginx/conf.d/default.conf.template as the source
export API_TARGET="${API_PROXY_TARGET:-http://urgs-api:8080}"
export RAG_TARGET="${VITE_RAG_URL:-http://urgs-rag:8001}"

envsubst '${API_TARGET} ${RAG_TARGET}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

# Execute default CMD
exec "$@"
