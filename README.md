# Family AI Hub

A private AI server for the household, running on a MacBook (M5, 48 GB) and reached over Tailscale.
Built on Open WebUI, with local models by default and a trust-tier gateway that decides which
data may reach which provider (Infomaniak is the first approved external provider).

See `docs/family-ai-hub-prd.docx` for the product requirements and phased plan.

## Status

Phase 0: planning. Next up is phase 1 (Open WebUI + Ollama in production mode, Tailscale HTTPS,
accounts for the family, backups).

## Ground rules

- Never commit secrets, API keys, databases, chat data, or uploaded documents.
- The service is for the private tailnet only. Do not expose it publicly.
