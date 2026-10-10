#!/usr/bin/env bash
# Installs the nightly 03:17 backup launchd job.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLIST="$HOME/Library/LaunchAgents/com.familyai.backup.plist"
sed -e "s|__REPO_DIR__|$REPO_DIR|g" -e "s|__HOME__|$HOME|g" \
  "$REPO_DIR/launchd/com.familyai.backup.plist" > "$PLIST"
launchctl bootout "gui/$(id -u)/com.familyai.backup" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "Nightly backup scheduled. Test it now with: scripts/backup.sh"
