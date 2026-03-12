#!/bin/bash
set -e

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting Nicotine+ configuration..."

# Ensure directories exist with correct permissions
mkdir -p "${NICOTINE_CONFIG_DIR}" \
         "${NICOTINE_DATA_DIR}/plugins" \
         "${NICOTINE_DATA_DIR}/downloads" \
         "${NICOTINE_DATA_DIR}/incomplete" \
         "${NICOTINE_DATA_DIR}/received"

# Create placeholder for custom plugins
touch "${NICOTINE_DATA_DIR}/plugins/README.txt"
cat > "${NICOTINE_DATA_DIR}/plugins/README.txt" << 'EOF'
Place custom Nicotine+ plugins in this directory.
They will be automatically loaded by Nicotine+ on startup.

For more information about Nicotine+ plugins:
https://nicotine-plus.org/doc/PLUGINS.html
EOF

# Configure Nicotine+ settings
configure-nicotine.sh

log "Configuration complete. Starting application..."

# Execute the original entrypoint (from gui-web-base)
exec "$@"
