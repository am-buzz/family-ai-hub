#!/usr/bin/env bash
# Copies the Family AI Hub theme (custom.css and icons) into Open WebUI's static folder.
# Open WebUI wipes and refills that folder every time it starts, so start-open-webui.sh runs this
# once the server is up. You can also run it by hand; reload the browser afterwards.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_DIR/scripts/common.sh"
load_env
STATIC_DIR="${STATIC_DIR:-$FAMILY_AI_HOME/static}"
[[ -d "$STATIC_DIR" ]] || { echo "No static folder at $STATIC_DIR yet (has Open WebUI started?)" >&2; exit 1; }
cp -f "$REPO_DIR"/theme/static/* "$STATIC_DIR/"
echo "Theme applied to $STATIC_DIR"
