---
name: scan
description: Proactive scan for new design-relevant items across all configured sources
---

# Scan Command

Shortcut for `/design-action --scan`. Scans all configured sources for new design-relevant items since the last scan.

## Execution

1. Load config from `~/.design-action/config.yaml`
2. Execute the full scan workflow defined in `skills/design-action/SKILL.md` → Scan Mode section
3. Reference `skills/design-action/reference/scan-workflow.md` for detailed procedures

## Arguments

```
/scan                     # Default: scan since last check
/scan --since "3 days"    # Custom lookback period
/scan --stream "mobile"   # Scan specific stream only
```

## What It Does

1. Checks daily briefing for pre-existing context
2. Searches meeting source for new design-relevant meetings
3. Checks task tracker for status changes and new items
4. Scans communication channels for design discussions
5. Compares findings against existing backlog
6. Scores new items using configured scoring framework
7. Presents findings table with recommended actions
