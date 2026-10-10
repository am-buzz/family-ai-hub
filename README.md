# Family AI Hub

A private AI server for the household, running on a MacBook (M5, 48 GB) and reached over Tailscale.
Built on Open WebUI, with local models by default and a trust-tier gateway that decides which
data may reach which provider (Infomaniak is the first approved external provider).

Docs (Word):
- `docs/family-ai-hub-prd.docx`: product requirements and phased plan.
- `docs/family-ai-hub-setup-guide.docx`: step-by-step Mac setup, groups, Tailscale and backups.

## Status

Phase 1 scaffolding is written but not yet run on the Mac. It has been syntax-checked, and the backup
and retention logic was tested with fake data. The installer, launchd jobs and Tailscale script have not
been exercised on macOS yet.

## Layout

- `scripts/install.sh`: installs Ollama and Open WebUI, creates `~/.family-ai`, sets up launchd
- `scripts/pull-models.sh`, `scripts/tailscale-serve.sh`
- `scripts/backup.sh`, `scripts/restore.sh`, `scripts/install-backup-job.sh`
- `config/family-ai.env.example`: settings (copied to `~/.family-ai/family-ai.env`, never committed)
- `config/providers.yaml`: provider registry seed for the phase 2 trust gateway
- `launchd/`: job templates

## Ground rules

- Never commit secrets, API keys, databases, chat data, or uploaded documents.
- The service is for the private tailnet only. Do not expose it publicly.
