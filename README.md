# design-action

Turn scattered design evidence into grounded artifacts with full source citations. Aggregates context from meetings, task trackers, chat, videos, and docs — then synthesizes it into prototypes, journey maps, wireframes, and more.

## Install

### Core skill (any AI agent)

Works with Claude Code, Cursor, Copilot, Cline, and more. Gives you the core `/design-action` skill with evidence synthesis and artifact creation.

```bash
npx skills add lolasalehu-rgb/design-action-plugin
```

Then run `/setup` to connect your tools.

### Full experience (Claude Code)

Includes everything above plus: `/scan`, `/briefing` commands, automated daily briefings, heartbeat scanning, launchd/systemd/cron scheduling, and config validation scripts.

```bash
git clone https://github.com/lolasalehu-rgb/design-action-plugin.git
claude --plugin-dir ./design-action-plugin
```

| | `npx skills add` | `git clone` + `--plugin-dir` |
|---|---|---|
| Core `/design-action` skill | Yes | Yes |
| `/setup` wizard | Yes | Yes |
| `/scan`, `/briefing` commands | No | Yes |
| Automated daily briefings | No | Yes |
| Heartbeat + task-check scripts | No | Yes |
| launchd/systemd/cron templates | No | Yes |
| Full docs + examples | No | Yes |

## What It Does

1. **Gathers** evidence from multiple sources (meetings, tasks, chat, videos, docs)
2. **Synthesizes** cross-source insights — pain points by frequency, decisions, open questions
3. **Suggests** the right artifact type based on what was discussed
4. **Creates** the artifact with every element citing its source
5. **Tracks** design decisions, backlog items, and priorities across sessions

## Quick Start

```bash
# Run interactive setup (auto-detects your MCP servers)
/setup

# Transform meeting discussions into artifacts
/design-action --topic "onboarding"

# Add tasks, chat, and docs to the search
/design-action --topic "error handling" --multi-source

# Scan for new design-relevant items
/design-action --scan

# Weekly priority synthesis
/design-action --priorities
```

## Value Tiers

Start simple, add capabilities over time.

| Tier | What You Get | You Need |
|------|-------------|----------|
| **Core** | `/design-action --topic "..."` → synthesis + artifacts | Any meeting source |
| **+ Tracking** | Backlog, DDRs, task sync, `/scan` | + task tracker (Jira/Linear/GH Issues) |
| **Full Auto** | Daily briefings, heartbeat, auto-triage | + scheduler (launchd/systemd/cron) |

## Supported Providers

| Category | Providers |
|----------|----------|
| **Meetings** | Granola, Otter.ai, Fireflies.ai, Google Meet, Notion, Manual (markdown) |
| **Tasks** | Jira, Linear, GitHub Issues, Notion |
| **Communication** | Slack (MCP or browser), Discord, Microsoft Teams |
| **Design Tools** | Figma, Penpot |

## How It Works

The skill contains **dispatch tables** — markdown lookup tables that map your config to the right MCP tool calls. No code adapters needed.

```
Config (YAML) → SKILL.md dispatch table → MCP tool call → Normalized output
```

### Evidence Grounding

Every design element cites its source:
```
Pain Point: "I spent 20 minutes just trying to find where to start"
Sources: Customer Call (Mar 7), PROJ-456 (Jira), #product-feedback (Slack)
Frequency: 4 mentions across 3 source types
Evidence Level: STRONG
```

## Troubleshooting

### Missing reference files after install

`npx skills add` only installs the `skills/design-action/` subtree. If reference files are missing, the skill self-repairs on first run — or you can fix manually:

```bash
# Find your skill directory
SKILL_DIR=$(find ~/.claude/skills ~/.agents/skills -name "SKILL.md" -path "*/design-action/*" -exec dirname {} \; 2>/dev/null | head -1)

# Download missing reference files
for file in config-template.yaml ddr-template.md scoring-framework.md tiered-loading.md synthesis-patterns.md artifact-templates.md evidence-grounding.md scan-workflow.md multi-source.md production-extraction.md; do
  if [ ! -f "$SKILL_DIR/reference/$file" ]; then
    curl -sL "https://raw.githubusercontent.com/lolasalehu-rgb/design-action-plugin/main/skills/design-action/reference/$file" -o "$SKILL_DIR/reference/$file"
  fi
done
```

### Stale cache from npx skills

If you're getting an old version:

```bash
npx skills update        # Update to latest
# OR force reinstall:
npx skills remove design-action
npx skills add lolasalehu-rgb/design-action-plugin
```

### /setup says "no MCP servers detected"

design-action works with any MCP server you already have installed. If none are detected, you can still use `manual` mode — just point it at a folder of meeting notes as markdown files.

## Documentation

- [Provider Setup](docs/providers.md) — MCP server setup for each provider
- [Architecture](docs/architecture.md) — System design and data flow
- [Customization](docs/customization.md) — Scoring, templates, workflows
- [Troubleshooting](docs/troubleshooting.md) — Common issues and fixes

## License

**Personal and non-commercial use:** Free.
**Commercial use:** Requires a commercial license with revenue sharing. See [LICENSE](LICENSE) for details.

## Author

Created by [Lola Salehu](https://www.linkedin.com/in/lola-salehu/?originalSubdomain=uk).

**Landing page:** [design-action-site.vercel.app](https://design-action-site.vercel.app)
