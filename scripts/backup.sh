#!/usr/bin/env bash
# Nightly backup of everything Open WebUI stores (chats, accounts, uploads, vector index) plus config.
# Output: $BACKUP_DIR/family-ai-YYYY-MM-DD.tar.gz, retention 14 daily + 8 weekly (Sundays).
# The SQLite database is copied with sqlite3 ".backup" so the copy is consistent while the app runs.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
load_env

: "${DATA_DIR:?}" "${BACKUP_DIR:?}" "${FAMILY_AI_HOME:?}"
if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "Backup destination $BACKUP_DIR is not available (is the external drive plugged in?)." >&2
  exit 1
fi

STAMP="$(date +%Y-%m-%d)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
STAGE="$WORK/family-ai-$STAMP"
mkdir -p "$STAGE/data"

# Everything except the live database, then a consistent copy of the database.
tar -C "$DATA_DIR" --exclude='./webui.db' --exclude='./webui.db-*' -cf - . | tar -C "$STAGE/data" -xf -
if [[ -f "$DATA_DIR/webui.db" ]]; then
  sqlite3 "$DATA_DIR/webui.db" ".backup '$STAGE/data/webui.db'"
fi
cp "$FAMILY_AI_HOME/family-ai.env" "$STAGE/family-ai.env"

OUT="$BACKUP_DIR/family-ai-$STAMP.tar.gz"
umask 077
tar -C "$WORK" -czf "$OUT.partial" "family-ai-$STAMP"
mv "$OUT.partial" "$OUT"
echo "Wrote $OUT"

# Retention: keep the 14 newest daily files, plus any Sunday backup from the last 8 weeks.
# (while-read instead of mapfile: launchd runs this under macOS's bash 3.2.)
keep_days=14
i=0
while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  i=$((i + 1))
  (( i <= keep_days )) && continue
  d="$(basename "$f" .tar.gz)"; d="${d#family-ai-}"
  if date -j -f %Y-%m-%d "$d" +%u >/dev/null 2>&1; then
    dow="$(date -j -f %Y-%m-%d "$d" +%u)"                 # macOS
    age=$(( ( $(date +%s) - $(date -j -f %Y-%m-%d "$d" +%s) ) / 86400 ))
  else
    dow="$(date -d "$d" +%u)"                             # GNU date, used when testing on Linux
    age=$(( ( $(date +%s) - $(date -d "$d" +%s) ) / 86400 ))
  fi
  if [[ "$dow" == "7" && "$age" -le 56 ]]; then continue; fi
  rm -f "$f"
done < <(ls -1 "$BACKUP_DIR"/family-ai-????-??-??.tar.gz 2>/dev/null | sort -r)
