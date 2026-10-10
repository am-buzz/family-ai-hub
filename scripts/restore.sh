#!/usr/bin/env bash
# Restores a backup into DATA_DIR. Stops Open WebUI first and keeps the old data aside, never deleting it.
# Usage: scripts/restore.sh /path/to/family-ai-YYYY-MM-DD.tar.gz
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
load_env
ARCHIVE="${1:?usage: restore.sh <backup.tar.gz>}"
[[ -f "$ARCHIVE" ]] || { echo "No such file: $ARCHIVE" >&2; exit 1; }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
tar -C "$WORK" -xzf "$ARCHIVE"
SRC="$(find "$WORK" -maxdepth 1 -type d -name 'family-ai-*' | head -1)"
[[ -d "$SRC/data" ]] || { echo "Archive does not look like a Family AI backup." >&2; exit 1; }

launchctl bootout "gui/$(id -u)/com.familyai.openwebui" 2>/dev/null || true
if [[ -d "$DATA_DIR" ]]; then
  ASIDE="$DATA_DIR.before-restore-$(date +%Y%m%d-%H%M%S)"
  mv "$DATA_DIR" "$ASIDE"
  echo "Previous data kept at $ASIDE"
fi
mkdir -p "$DATA_DIR"
cp -R "$SRC/data/." "$DATA_DIR/"
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.familyai.openwebui.plist"
echo "Restored from $ARCHIVE. The env file in the archive is at $SRC/family-ai.env if you also need the secret key."
