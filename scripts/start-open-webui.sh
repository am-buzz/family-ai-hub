#!/usr/bin/env bash
# Entry point used by launchd. Loads settings, then runs Open WebUI in the foreground.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
load_env
exec "$FAMILY_AI_HOME/venv/bin/open-webui" serve --host "$HOST" --port "$PORT"
