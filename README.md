# design-action

A Claude Code plugin that turns scattered design evidence into grounded artifacts. Aggregates context from meetings, videos, task trackers, chat, and docs — then synthesizes it into prototypes, journey maps, wireframes, and more with full source citations.

## What It Does

Design evidence lives everywhere — meeting transcripts, Jira tickets, Slack threads, video recordings, research docs. design-action pulls it all together:

1. **Gathers** evidence from multiple sources (meetings, tasks, chat, videos, docs)
2. **Synthesizes** cross-source insights — pain points by frequency, decisions, open questions
3. **Suggests** the right artifact type based on what was discussed
4. **Creates** the artifact with every element citing its source
5. **Tracks** design decisions, backlog items, and priorities across sessions

## Quick Start

```bash
# Install the plugin
claude plugin add ./design-action

# Run interactive setup (auto-detects your MCP servers)
/setup

# Transform meeting discussions into artifacts
/design-action --topic "onboarding"

# Scan for new design-relevant items
/scan

# Generate a daily briefing
/briefing
```

## Value Tiers

You get value at every level — start simple, add capabilities over time.

| Tier | What You Get | You Need |
|------|-------------|----------|
| **Core** | `/design-action --topic "..."` → synthesis + artifacts | Any meeting source + Claude Code |
| **+ Tracking** | Backlog, DDRs, task sync, `/scan` | + task tracker (Jira/Linear/GH Issues) |
| **Full Auto** | Daily briefings, heartbeat, auto-triage | + scheduler (launchd/systemd/cron) |

## Supported Providers

| Category | Providers |
|----------|----------|
| **Meetings** | Granola, Otter.ai, Fireflies.ai, Google Meet, Notion, Manual (markdown) |
| **Tasks** | Jira, Linear, GitHub Issues, Notion |
| **Communication** | Slack (MCP or browser), Discord, Microsoft Teams |
| **Design Tools** | Figma, Penpot |
| **Notifications** | macOS, Linux (notify-send) |

## Commands

| Command | Description |
|---------|-------------|
| `/design-action --topic "..."` | Full pipeline: gather → synthesize → suggest → create |
| `/design-action --scan` | Scan all sources for new design-relevant items |
| `/design-action --multi-source` | Include task tracker and communication in search |
| `/design-action --priorities` | Weekly priority synthesis |
| `/design-action --execute` | Work pre-triaged items from morning briefing |
| `/setup` | Interactive configuration wizard |
| `/scan` | Shortcut for `--scan` |
| `/briefing` | Generate daily design briefing |

## How It Works

### Architecture

Claude itself is the universal adapter. The skill contains **dispatch tables** — markdown lookup tables that map your config to the right MCP tool calls. No code adapters needed.

```
Config (YAML) → SKILL.md dispatch table → MCP tool call → Normalized output
```

### The 5-Phase Pipeline

**Phase 1: Context Gathering** — Searches your primary source (meetings) with a tiered loading system (discover → summarize → deep-dive), then optionally pulls in secondary sources (tasks, chat, docs, videos). Maximizes coverage within token budgets.

**Phase 2: Synthesis** — Extracts decisions, pain points, feature proposals, open questions, and verbatim quotes. Tracks frequency across sources.

**Phase 3: Artifact Suggestion** — Recommends the best artifact type based on what was discussed (journey map, prototype, wireframes, research synthesis, etc).

**Phase 4: Creation** — Builds the artifact with every element citing its source. Uses your design tool if configured, or creates markdown/HTML artifacts.

**Phase 5: Wrap-up** — Creates Design Decision Records, updates backlog, suggests automation for repeatable workflows.

### Evidence Grounding

Every design element cites its source — whether from a meeting, task, chat thread, or video:
```
Pain Point: "I spent 20 minutes just trying to find where to start"
Sources: Customer Call (Mar 7), PROJ-456 (Jira), #product-feedback (Slack)
Frequency: 4 mentions across 3 source types
Evidence Level: STRONG
```

## Configuration

Config lives at `~/.design-action/config.yaml`. Run `/setup` for interactive creation, or copy `templates/config.example.yaml`.

Key sections:
- `providers` — which tools to use for meetings, tasks, communication, design
- `streams` — your work streams (product areas, teams)
- `scoring` — customizable priority scoring dimensions and weights

See [docs/customization.md](docs/customization.md) for full customization guide.

## Project Structure

```
design-action/
├── .claude-plugin/plugin.json    # Plugin manifest
├── skills/design-action/
│   ├── SKILL.md                  # Core methodology
│   └── reference/                # On-demand reference files
├── commands/                     # User-invocable commands
├── templates/                    # Config + starter templates
├── automation/                   # Scheduler scripts + templates
├── docs/                         # Documentation + examples
└── scripts/                      # Utility scripts
```

## Documentation

- [Provider Setup](docs/providers.md) — MCP server setup for each provider
- [Architecture](docs/architecture.md) — System design and data flow
- [Customization](docs/customization.md) — Scoring, templates, workflows
- [Troubleshooting](docs/troubleshooting.md) — Common issues and fixes
- [Examples](docs/examples/) — Sanitized real-world examples

## License

**Personal and non-commercial use:** Free.
**Commercial use:** Requires a commercial license with revenue sharing. See [LICENSE](LICENSE) for details.

## Author

Created by Lola Salehu.
