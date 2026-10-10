#!/usr/bin/env bash
# Copies the data of an existing Docker-based Open WebUI (accounts, assistants, knowledge/documents,
# uploads, settings) into DATA_DIR for the new install. Non-destructive:
#   - the Docker container and its volume are left exactly as they were (it is only stopped for ~a minute
#     so the database copy is consistent, then started again)
#   - a full safety copy is kept in ~/openwebui-old-backup-<timestamp>
#   - any data already in DATA_DIR is moved aside, never deleted
# Usage: scripts/migrate-from-docker.sh [container-name]     (default: open-webui)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
load_env

CONTAINER="${1:-open-webui}"
command -v docker >/dev/null || { echo "docker not found" >&2; exit 1; }
docker inspect "$CONTAINER" >/dev/null 2>&1 || { echo "No container named $CONTAINER (see: docker ps -a)" >&2; exit 1; }

STAMP="$(date +%Y%m%d-%H%M%S)"
SAFE="$HOME/openwebui-old-backup-$STAMP"
mkdir -p "$SAFE"

WAS_RUNNING="$(docker inspect -f '{{.State.Running}}' "$CONTAINER")"
restart_old() {
  if [[ "$WAS_RUNNING" == "true" ]]; then
    echo "==> Starting $CONTAINER again"
    docker start "$CONTAINER" >/dev/null || echo "WARNING: could not restart $CONTAINER; run: docker start $CONTAINER" >&2
  fi
}
trap restart_old EXIT

if [[ "$WAS_RUNNING" == "true" ]]; then
  echo "==> Stopping $CONTAINER briefly for a consistent copy"
  docker stop "$CONTAINER" >/dev/null
fi

echo "==> Copying data out of the container to $SAFE"
docker cp "$CONTAINER:/app/backend/data" "$SAFE/"
DB="$SAFE/data/webui.db"
[[ -s "$DB" ]] || { echo "No webui.db found in the copied data; aborting. Nothing was changed." >&2; exit 1; }
echo "    webui.db: $(du -h "$DB" | cut -f1); total: $(du -sh "$SAFE/data" | cut -f1)"

restart_old
trap - EXIT

echo "==> Stopping the new Open WebUI"
launchctl bootout "gui/$(id -u)/com.familyai.openwebui" 2>/dev/null || true

if [[ -e "$DATA_DIR" ]]; then
  ASIDE="$DATA_DIR.before-migrate-$STAMP"
  mv "$DATA_DIR" "$ASIDE"
  echo "    Previous (empty/new) data kept at $ASIDE"
fi
cp -R "$SAFE/data" "$DATA_DIR"

echo "==> Starting the new Open WebUI"
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.familyai.openwebui.plist"

cat <<MSG

Migrated. Safety copy of the original data: $SAFE   (keep it until you are happy)
Open http://127.0.0.1:8080 and sign in with your OLD admin account. Then check:
  - your assistants (Workspace > Models) and the cookbook (Workspace > Knowledge)
  - Admin Panel > Settings: admin chat access off, signups off (migrated settings override the env file)
The old Open WebUI is still running on port 3000, untouched.
MSG
