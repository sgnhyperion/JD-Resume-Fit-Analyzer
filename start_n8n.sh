#!/usr/bin/env bash
# Starts n8n locally on http://localhost:5678
# Usage:  bash start_n8n.sh      (leave this terminal open; Ctrl+C to stop)
set -e
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use 22 >/dev/null 2>&1 || true

# Allow login over plain http://localhost and quiet telemetry
export N8N_SECURE_COOKIE=false
export N8N_DIAGNOSTICS_ENABLED=false
export N8N_RUNNERS_ENABLED=true

echo "Starting n8n... open http://localhost:5678 in your browser once it says 'Editor is now accessible'."
exec n8n start
