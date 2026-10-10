#!/usr/bin/env bash
# Phase 1 installer for macOS. Safe to re-run; it never overwrites an existing env file or data.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAMILY_AI_HOME="${FAMILY_AI_HOME:-$HOME/.family-ai}"
ENV_FILE="$FAMILY_AI_HOME/family-ai.env"
VENV="$FAMILY_AI_HOME/venv"

[[ "$(uname -s)" == "Darwin" ]] || { echo "This installer is for macOS." >&2; exit 1; }
command -v brew >/dev/null || { echo "Install Homebrew first: https://brew.sh" >&2; exit 1; }

echo "==> Installing Ollama, Python 3.11 and Tailscale tooling via Homebrew"
brew list ollama >/dev/null 2>&1 || brew install ollama
brew list python@3.11 >/dev/null 2>&1 || brew install python@3.11
# Tailscale: the App Store / standalone app is fine; the CLI must be on PATH for tailscale-serve.sh.

mkdir -p "$FAMILY_AI_HOME/data" "$FAMILY_AI_HOME/backups" "$FAMILY_AI_HOME/logs"
chmod 700 "$FAMILY_AI_HOME"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "==> Creating $ENV_FILE"
  cp "$REPO_DIR/config/family-ai.env.example" "$ENV_FILE"
  SECRET="$(openssl rand -hex 32)"
  sed -i '' "s|^WEBUI_SECRET_KEY=.*|WEBUI_SECRET_KEY=\"$SECRET\"|" "$ENV_FILE"
  chmod 600 "$ENV_FILE"
else
  echo "==> Keeping existing $ENV_FILE"
fi

if [[ ! -d "$VENV" ]]; then
  echo "==> Creating Python environment"
  "$(brew --prefix python@3.11)/bin/python3.11" -m venv "$VENV"
fi
echo "==> Installing Open WebUI"
"$VENV/bin/pip" install --upgrade pip
if [[ -f "$REPO_DIR/requirements.lock" ]]; then
  "$VENV/bin/pip" install -r "$REPO_DIR/requirements.lock"
else
  "$VENV/bin/pip" install open-webui
  "$VENV/bin/pip" freeze > "$REPO_DIR/requirements.lock"
  echo "    Wrote requirements.lock. Commit it so upgrades are deliberate."
fi

echo "==> Installing launchd job for Open WebUI"
PLIST="$HOME/Library/LaunchAgents/com.familyai.openwebui.plist"
mkdir -p "$HOME/Library/LaunchAgents"
sed -e "s|__REPO_DIR__|$REPO_DIR|g" -e "s|__HOME__|$HOME|g" \
  "$REPO_DIR/launchd/com.familyai.openwebui.plist" > "$PLIST"
launchctl bootout "gui/$(id -u)/com.familyai.openwebui" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"

echo "==> Starting Ollama as a background service"
brew services start ollama

cat <<MSG

Done. Next:
  1. scripts/pull-models.sh          (downloads local models; large)
  2. Open http://127.0.0.1:8080 on this Mac and create the FIRST account: that becomes the admin (you).
  3. scripts/tailscale-serve.sh      (HTTPS for phones over your tailnet)
  4. scripts/install-backup-job.sh   (nightly backups)
See docs/ for the setup guide.
MSG
