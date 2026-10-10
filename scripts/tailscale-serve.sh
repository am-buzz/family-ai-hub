#!/usr/bin/env bash
# Puts Open WebUI on the tailnet over HTTPS. Never uses Funnel (public internet).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
load_env
tailscale serve --bg --https="$TAILSCALE_HTTPS_PORT" "http://127.0.0.1:$PORT"
tailscale serve status
echo "Reachable only from devices on your tailnet."
