#!/usr/bin/env bash
# Upgrades Open WebUI in place: backup first, install the version, refresh requirements.lock, restart, check health.
# Usage:  scripts/upgrade.sh 0.12.3      (a specific version, recommended)
#         scripts/upgrade.sh             (the newest release)
# Rollback: scripts/restore.sh (restores the pre-upgrade backup), then reinstall the old version, see the end of this script's output.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
load_env
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${DATA_DIR:?}" "${FAMILY_AI_HOME:?}" "${PORT:?}"
VENV="$FAMILY_AI_HOME/venv"
TARGET="${1:-}"
OLD="$("$VENV/bin/pip" show open-webui 2>/dev/null | awk '/^Version:/ {print $2}')"
echo "==> Open WebUI is currently $OLD; upgrading to ${TARGET:-the newest release}"

echo "==> Backing up first"
if ! "$REPO_DIR/scripts/backup.sh"; then
  FALLBACK="$FAMILY_AI_HOME/pre-upgrade-$(date +%Y-%m-%d-%H%M).tar.gz"
  echo "    The normal backup is not available. Making a copy at $FALLBACK instead."
  WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
  mkdir -p "$WORK/data"
  tar -C "$DATA_DIR" --exclude='./webui.db' --exclude='./webui.db-*' -cf - . | tar -C "$WORK/data" -xf -
  [[ -f "$DATA_DIR/webui.db" ]] && sqlite3 "$DATA_DIR/webui.db" ".backup '$WORK/data/webui.db'"
  umask 077
  tar -C "$WORK" -czf "$FALLBACK" data
  echo "    Wrote $FALLBACK"
fi

echo "==> Installing"
PKG="open-webui${TARGET:+==$TARGET}"
"$VENV/bin/pip" install --upgrade "$PKG"
"$VENV/bin/pip" install -r "$REPO_DIR/requirements-extras.txt"
NEW="$("$VENV/bin/pip" show open-webui | awk '/^Version:/ {print $2}')"
"$VENV/bin/pip" freeze > "$REPO_DIR/requirements.lock"
echo "    Installed $NEW and refreshed requirements.lock (commit it when you are happy)."

echo "==> Restarting Open WebUI"
launchctl kickstart -k "gui/$(id -u)/com.familyai.openwebui"
for _ in $(seq 1 90); do
  if curl -sf -o /dev/null "http://127.0.0.1:$PORT/health"; then
    echo "==> Up. Version reported by the server:"
    curl -s "http://127.0.0.1:$PORT/api/version"; echo
    echo "The theme is re-applied automatically a moment after start. Reload the browser (Cmd+Shift+R)."
    echo "If something is wrong: scripts/restore.sh, then: $VENV/bin/pip install open-webui==$OLD && launchctl kickstart -k gui/$(id -u)/com.familyai.openwebui"
    exit 0
  fi
  sleep 2
done
echo "Open WebUI did not answer within 3 minutes. See ~/.family-ai/logs/openwebui.err.log, or roll back as above." >&2
exit 1
