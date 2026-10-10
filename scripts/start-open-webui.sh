#!/usr/bin/env bash
# Entry point used by launchd. Loads settings, runs Open WebUI, and lays the family theme over its
# static files once the server is up (Open WebUI rewrites that folder on every start).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/common.sh"
load_env
export STATIC_DIR="${STATIC_DIR:-$FAMILY_AI_HOME/static}"
mkdir -p "$STATIC_DIR"

"$FAMILY_AI_HOME/venv/bin/open-webui" serve --host "$HOST" --port "$PORT" &
SERVER_PID=$!
trap 'kill -TERM "$SERVER_PID" 2>/dev/null || true' TERM INT

(
  for _ in $(seq 1 150); do
    if curl -sf -o /dev/null "http://127.0.0.1:$PORT/health"; then
      "$HERE/apply-theme.sh" || true
      exit 0
    fi
    sleep 2
  done
) &

wait "$SERVER_PID"
wait "$SERVER_PID" 2>/dev/null
exit $?
