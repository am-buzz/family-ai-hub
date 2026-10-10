#!/usr/bin/env bash
# Downloads the starter local models. These are candidates to benchmark on real family tasks,
# not final choices. Override with: MODELS="a b c" scripts/pull-models.sh
set -euo pipefail
MODELS="${MODELS:-qwen3:30b-a3b qwen3:8b gemma3:12b nomic-embed-text}"
for m in $MODELS; do
  echo "==> ollama pull $m"
  ollama pull "$m"
done
ollama list
