"""Tests for study_buddy_mode.py.  Run from the repo root:  python3 functions/test_study_buddy_mode.py"""
import asyncio, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from study_buddy_mode import Filter

f = Filter()
events = []
async def emit(e): events.append(e)
def inlet(body, user=None): return asyncio.run(f.inlet(body, user or {"id": "u", "name": "Anne-Marie", "email": "am@example.com"}, emit))

def check(name, cond):
    print(("PASS " if cond else "FAIL ") + name)
    if not cond: sys.exit(1)

body = {"model": "qwen3:8b", "messages": [{"role": "user", "content": "hi"}]}
out = inlet(body)
check("shows as a switch", f.toggle is True)
check("adult gets the adult version, addressed by name", out["messages"][0]["role"] == "system" and "named Anne-Marie" in out["messages"][0]["content"] and "13-year-old" not in out["messages"][0]["content"] and "Grace" not in out["messages"][0]["content"])
g = inlet(body, {"id": "g", "name": "Grace", "email": "KeithMiller1975+Grace@gmail.com"})
check("Grace gets the student version", "13-year-old student named Grace" in g["messages"][0]["content"])
check("user message kept, original body untouched", out["messages"][1]["content"] == "hi" and len(body["messages"]) == 1)
check("model is left alone", out["model"] == "qwen3:8b")
withsys = {"model": "m", "messages": [{"role": "system", "content": "CONTEXT: notes"}, {"role": "user", "content": "q"}]}
out = inlet(withsys)
check("existing system message merged", out["messages"][0]["content"].endswith("CONTEXT: notes") and len(out["messages"]) == 2)
twice = inlet(out)
check("not added twice", twice["messages"][0]["content"].count("Study Buddy") == out["messages"][0]["content"].count("Study Buddy"))
check("status shown", events and "Study Buddy mode" in events[-1]["data"]["description"])
master = (Path(__file__).resolve().parent.parent / "assistants" / "study-buddy.txt").read_text().strip()
check("embedded prompt equals assistants/study-buddy.txt", Filter().valves.system_prompt == master)
adult = (Path(__file__).resolve().parent.parent / "assistants" / "study-buddy-adult.txt").read_text().strip()
check("embedded adult prompt equals assistants/study-buddy-adult.txt", Filter().valves.adult_prompt == adult)
print("All checks passed")
