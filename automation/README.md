# Automation (Tier 3)

Automated scanning and briefing for design-action. Requires Tier 1 + 2 to be configured first.

## Overview

| Script | Trigger | Purpose |
|--------|---------|---------|
| `daily-briefing.sh` | Scheduled (e.g., 8 AM weekdays) | Full briefing: meetings, tasks, chat, triage |
| `heartbeat.sh` | Event-driven (meeting tool file changes) | Fast scan for new meetings → inbox |
| `task-check.sh` | Scheduled (e.g., 12 PM weekdays) | Delta detection from morning task baseline |

## Setup

```bash
# Run the installer (auto-detects platform)
./install-automation.sh

# Or manually configure:
# macOS: Copy .plist templates to ~/Library/LaunchAgents/
# Linux: Copy .service templates to ~/.config/systemd/user/
# Other: Add crontab entries from cron/crontab.template
```

## Requirements

- `claude` CLI in PATH
- `yq` for YAML parsing (`brew install yq` / `apt install yq`)
- `python3` (for decision-log generation and cache parsing)
- `~/.design-action/config.yaml` configured (run `/setup` first)

## Configuration

All scripts read from `~/.design-action/config.yaml`:
- `automation.work_hours` — when scripts are allowed to run
- `automation.briefing_time` / `automation.task_check_time` — scheduled times
- `automation.heartbeat.throttle_minutes` — minimum interval between heartbeat runs
- `providers.*` — which tools to query

## Flags

All scripts support:
- `--force` — bypass all gate checks (time, weekend, idempotency)
- `--dry-run` — test gate checks without invoking Claude

## Logs

Logs are written to `~/.design-action/logs/`:
- `briefing-YYYY-MM-DD.log`
- `heartbeat-TIMESTAMP.log`
- `task-check-TIMESTAMP.log`

Auto-cleaned after 7 days (briefing, task-check) or 2 days (heartbeat).
