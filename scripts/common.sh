#!/usr/bin/env bash
# Shared helpers. Source this; do not run it.
set -euo pipefail

ENV_FILE="${FAMILY_AI_ENV:-$HOME/.family-ai/family-ai.env}"

load_env() {
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "Missing $ENV_FILE. Run scripts/install.sh first." >&2
    exit 1
  fi
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
}
