"""Embeds assistants/study-buddy.txt into functions/study_buddy_pipe.py and functions/study_buddy_mode.py
(between the DEFAULT_PROMPT quotes).
Run from the repo root:  python3 functions/build_study_buddy.py
"""
import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
prompt = (root / "assistants" / "study-buddy.txt").read_text().strip()
assert '"""' not in prompt and "\\" not in prompt, "prompt must not contain triple quotes or backslashes"
for name in ("study_buddy_pipe.py", "study_buddy_mode.py"):
    path = root / "functions" / name
    src = path.read_text()
    new = re.sub(r'DEFAULT_PROMPT = """.*?"""', lambda m: 'DEFAULT_PROMPT = """' + prompt + '"""', src, count=1, flags=re.S)
    path.write_text(new)
    print("Embedded", len(prompt), "characters of prompt into", path.relative_to(root))
