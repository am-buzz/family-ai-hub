#!/usr/bin/env bash
# Adds a stub entry to theme/static/models.json for every model in `ollama list` that is not in the guide yet,
# so you only have to write the description. Then run scripts/apply-theme.sh and reload the guide page.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PY="${PYTHON:-$HOME/.family-ai/venv/bin/python}"; [[ -x "$PY" ]] || PY="$(command -v python3)"
command -v ollama >/dev/null || { echo "ollama not found" >&2; exit 1; }
OLLAMA_LIST="$(ollama list)" "$PY" - "$REPO_DIR/theme/static/models.json" <<'PYEOF'
import json, os, re, sys
path = sys.argv[1]
data = json.load(open(path))
known = {m['id'] for m in data['models']}
added = []
for line in os.environ['OLLAMA_LIST'].splitlines()[1:]:
    parts = line.split()
    if len(parts) < 3: continue
    name = parts[0]
    if name in known: continue
    size = None
    m = re.search(r'([\d.]+)\s*(GB|MB)', line)
    if m: size = round(float(m.group(1)) / (1000 if m.group(2) == 'MB' else 1), 2)
    cloud = ':cloud' in name or name.endswith('-cloud') or ' - ' in line
    data['models'].append({'id': name, 'name': name, 'runs': 'cloud' if cloud else 'local', 'size_gb': size, 'speed': 'Medium',
        'kind': 'Everyday', 'good_for': 'TODO: what is it good for?', 'notes': 'TODO: describe this model.', 'audience': 'Admin only'})
    added.append(name)
json.dump(data, open(path, 'w'), indent=2, ensure_ascii=False)
print('Added %d stub(s): %s' % (len(added), ', '.join(added) or 'none'))
PYEOF
echo "Edit theme/static/models.json to fill in the TODO lines, then run scripts/apply-theme.sh."
