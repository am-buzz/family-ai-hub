#!/usr/bin/env bash
# Sets the hub's name in both places: WEBUI_NAME (browser tab, sign-in page, phone home-screen label)
# and the name plate at the top of the screen (theme/static/custom.css).
# Usage: scripts/set-name.sh "Lake & Ridge" "Buzatu · Miller"
# After running: restart Open WebUI for the tab/phone name (launchctl kickstart -k gui/$(id -u)/com.familyai.openwebui).
set -euo pipefail
TITLE="${1:?usage: set-name.sh \"Title\" [\"Subtitle\"]}"
SUBTITLE="${2:-}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAMILY_AI_HOME="${FAMILY_AI_HOME:-$HOME/.family-ai}"
ENV_FILE="${FAMILY_AI_ENV:-$FAMILY_AI_HOME/family-ai.env}"
PY="${PYTHON:-$FAMILY_AI_HOME/venv/bin/python}"
[[ -x "$PY" ]] || PY="$(command -v python3)"
"$PY" - "$TITLE" "$SUBTITLE" "$ENV_FILE" "$REPO_DIR/theme/static/custom.css" <<'PYEOF'
import re, sys
title, subtitle, env_path, css_path = sys.argv[1:5]
for v in (title, subtitle):
    if '"' in v or '\\' in v or '\n' in v:
        sys.exit('Please avoid double quotes and backslashes in the name.')
def css_str(v):  # escape non-ASCII for CSS content strings
    return ''.join(c if ord(c) < 128 else '\\%X ' % ord(c) for c in v)
env = open(env_path).read()
if re.search(r'^WEBUI_NAME=.*$', env, re.M):
    env = re.sub(r'^WEBUI_NAME=.*$', lambda m: 'WEBUI_NAME="%s"' % title, env, count=1, flags=re.M)
else:
    env += '\nWEBUI_NAME="%s"\n' % title
open(env_path, 'w').write(env)
css = open(css_path).read()
css = re.sub(r'--hub-title: "[^"]*";', lambda m: '--hub-title: "%s";' % css_str(title), css, count=1)
css = re.sub(r'--hub-subtitle: "[^"]*";', lambda m: '--hub-subtitle: "%s";' % css_str(subtitle), css, count=1)
open(css_path, 'w').write(css)
print('Name set to: %s%s' % (title, ' | ' + subtitle if subtitle else ''))
PYEOF
echo "Next: scripts/apply-theme.sh, then restart Open WebUI so the tab and phone names update."
