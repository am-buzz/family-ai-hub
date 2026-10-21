# Family AI Hub

A private AI server for the household, running on a MacBook (M5, 48 GB) and reached over Tailscale.
Built on Open WebUI, with local models by default and a trust-tier gateway that decides which
data may reach which provider (Infomaniak is the first approved external provider).

Docs (Word):
- `docs/family-ai-hub-prd.docx`: product requirements and phased plan.
- `docs/family-ai-hub-setup-guide.docx`: step-by-step Mac setup, groups, Tailscale and backups.

## Status

Phase 1 is running on the owner's Mac: Open WebUI 0.12.0 (migrated from Docker, upgraded from 0.11.4), Ollama, Tailscale HTTPS
on port 10000, family accounts, Adults and Grace groups, Study Buddy. Still to do: backup drive and
backup job, retire the old Docker instance, then phase 2 (trust gateway and Infomaniak).

## Layout

- `functions/`: the Study Buddy pipe (one assistant, each person picks the model) with tests and INSTALL.txt
- `tools/`: the Office Export tool (a model makes Word, Excel and PowerPoint files and returns a download link) with tests and INSTALL.txt; `requirements-extras.txt` lists its Python packages
- `scripts/upgrade.sh`: backup, then upgrade Open WebUI to a chosen version and restart
- `assistants/study-buddy.txt`: system prompt for Grace's Study Buddy assistant
- `scripts/migrate-from-docker.sh`: copies an existing Docker Open WebUI's data across, non-destructively
- `scripts/install.sh`: installs Ollama and Open WebUI, creates `~/.family-ai`, sets up launchd
- `scripts/pull-models.sh`, `scripts/tailscale-serve.sh`
- `scripts/backup.sh`, `scripts/restore.sh`, `scripts/install-backup-job.sh`
- `config/family-ai.env.example`: settings (copied to `~/.family-ai/family-ai.env`, never committed)
- `config/providers.yaml`: provider registry seed for the phase 2 trust gateway
- `theme/`: "Lakeside & Blue Ridge" look (custom.css, emblem and app icons); applied at startup by `scripts/apply-theme.sh`
- `theme/static/model-guide.html` + `models.json`: the "Which model should I pick?" page (served at /static/model-guide.html); `scripts/model-guide-sync.sh` adds stubs for newly downloaded models
- `scripts/set-name.sh`: sets the hub's name (tab/phone label and the name plate at the top)
- `launchd/`: job templates

## Ground rules

- Never commit secrets, API keys, databases, chat data, or uploaded documents.
- The service is for the private tailnet only. Do not expose it publicly.
