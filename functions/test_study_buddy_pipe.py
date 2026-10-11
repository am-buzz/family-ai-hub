"""Tests for study_buddy_pipe.py using stand-ins for Open WebUI's internals.
Run from the repo root:  python3 functions/test_study_buddy_pipe.py
"""
import asyncio, json, sys, types
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
calls = []

# --- stand-ins for the two Open WebUI modules the pipe imports ---
chat = types.ModuleType("open_webui.utils.chat")
users = types.ModuleType("open_webui.models.users")
class _User:  # minimal user object
    def __init__(self, id): self.id, self.role = id, "user"
class _Users:
    @staticmethod
    async def get_user_by_id(uid): return _User(uid)
users.Users = _Users
class _JSONResponse:  # looks like starlette's JSONResponse (has .body, no .body_iterator)
    def __init__(self, d, status=400): self.body, self.status_code = json.dumps(d).encode(), status
class _Stream:  # looks like a StreamingResponse
    body_iterator = iter(())
mode = {"result": "dict"}
async def generate_chat_completion(request, form_data, user, **kw):
    calls.append({"form_data": form_data, "user": user.id})
    return {"dict": {"choices": [{"message": {"content": "hi"}}]}, "error": _JSONResponse({"detail": "Model not found"}), "stream": _Stream()}[mode["result"]]
chat.generate_chat_completion = generate_chat_completion
for name, mod in [("open_webui", types.ModuleType("open_webui")), ("open_webui.utils", types.ModuleType("open_webui.utils")), ("open_webui.models", types.ModuleType("open_webui.models")),
                  ("open_webui.utils.chat", chat), ("open_webui.models.users", users)]:
    sys.modules[name] = mod

from study_buddy_pipe import Pipe

events = []
async def emit(e): events.append(e)

def run(body, user, task=None, result="dict"):
    calls.clear(); events.clear(); mode["result"] = result
    p = Pipe()
    uv = Pipe.UserValves(**user.pop("_valves", {}))
    user = {"id": "u1", "email": "adult@example.com", **user, "valves": uv}
    out = asyncio.run(p.pipe(body, user, object(), emit, task))
    return out, calls[0]["form_data"]

base = {"model": "study_buddy", "stream": False, "messages": [{"role": "user", "content": "hello"}]}
ok = 0
def check(name, cond):
    global ok
    print(("PASS " if cond else "FAIL ") + name); ok += bool(cond)
    if not cond: sys.exit(1)

# 1 default brain is Standard, persona injected, original body untouched
out, fd = run(base, {})
check("default uses Standard model", fd["model"] == "gemma4:26b")
check("system prompt added first", fd["messages"][0]["role"] == "system" and "Study Buddy" in fd["messages"][0]["content"])
check("user message kept after it", fd["messages"][1]["content"] == "hello" and base["messages"] == [{"role": "user", "content": "hello"}])
# 2 each choice maps to the right model
for label, model in [("Fast", "qwen3:8b"), ("Thoughtful", "qwen3.8:27b-mlx"), ("Apertus 8B", "apertus1.5-8b-text:f16"), ("Cloud: Apertus 70B", "swiss-ai/Apertus-v1.5-70B"), ("Cloud: Mistral 119B", "mistralai/Mistral-Small-4-119B-2603")]:
    _, fd = run(base, {"_valves": {"brain": label}})
    check(f"{label} -> {model}", fd["model"] == model)
# 3 restricted account cannot reach the cloud, falls back, tells the user
_, fd = run(base, {"email": "KeithMiller1975+Grace@gmail.com", "_valves": {"brain": "Cloud: Apertus 70B"}})
check("restricted account falls back to default local model", fd["model"] == "gemma4:26b")
check("user is told about the fallback", "not available for this account" in events[0]["data"]["description"])
_, fd = run(base, {"email": "keithmiller1975+grace@gmail.com", "_valves": {"brain": "Thoughtful"}})
check("restricted account may still pick local models", fd["model"] == "qwen3.8:27b-mlx")
_, fd = run(base, {"email": "keithmiller1975+grace@gmail.com", "_valves": {"brain": "Apertus 8B"}})
check("restricted account may use Apertus 8B (local)", fd["model"] == "apertus1.5-8b-text:f16")
# 4 existing system message (memory/RAG context) is kept, persona goes in front
withsys = {**base, "messages": [{"role": "system", "content": "CONTEXT: notes"}, {"role": "user", "content": "q"}]}
_, fd = run(withsys, {})
check("existing system message merged, not replaced", fd["messages"][0]["content"].endswith("CONTEXT: notes") and "Study Buddy" in fd["messages"][0]["content"] and len(fd["messages"]) == 2)
# 5 background tasks use the fast local model without the persona
_, fd = run({**base, "messages": [{"role": "user", "content": "### Task: write a title"}]}, {"_valves": {"brain": "Cloud: Apertus 70B"}}, task="title_generation")
check("task uses Fast model", fd["model"] == "qwen3:8b")
check("task gets no persona", fd["messages"][0]["role"] == "user")
check("task emits no status", events == [])
# 6 status line says where the answer comes from
run(base, {"_valves": {"brain": "Cloud: Mistral 119B"}})
check("cloud status says Infomaniak", "at Infomaniak" in events[0]["data"]["description"])
run(base, {"_valves": {"brain": "Fast"}})
check("local status says this Mac", "on this Mac" in events[0]["data"]["description"])
# 7 error objects become plain dicts, streams pass through
out, _ = run(base, {}, result="error")
check("JSONResponse error converted to dict", isinstance(out, dict) and out["detail"] == "Model not found")
out, _ = run(base, {}, result="stream")
check("streaming response passed through untouched", hasattr(out, "body_iterator"))
# 8 the form shows dropdowns, and the embedded prompt matches the master copy
schema = Pipe.UserValves.model_json_schema()
check("brain is a dropdown with 6 choices", len(schema["properties"]["brain"]["enum"]) == 6)
master = (Path(__file__).resolve().parent.parent / "assistants" / "study-buddy.txt").read_text().strip()
check("embedded prompt equals assistants/study-buddy.txt", Pipe().valves.system_prompt == master)
print(f"\nAll {ok} checks passed")
