# design-action

Turn scattered context into actionable design prototypes and artifacts — with grounded source citations.

Pulls context from everywhere you work -  Meeting discussions, Jira tickets, Slack threads, Figma designs, and Notion docs. Synthesizes the context, and turns that into grounded prototypes, journey maps, wireframes, or research docs that help you get work done.

## Get Started (2 minutes)

### Option 1: Skill only (works in Claude Code, Cursor, Copilot, Cline)

```bash
npx skills add lolasalehu-rgb/design-action-plugin
```

Then run `/setup` — it auto-detects your MCP servers (Google Meet, Jira, Slack, Figma, etc.).

### Option 2: Full plugin (Claude Code — recommended)

```bash
git clone git@github.com:akeneo/design-action.git
cd design-action
claude --plugin-dir .
```

The full plugin adds `/scan`, `/briefing` commands, automated daily briefings, and heartbeat scanning on top of the core skill.

| | Skill only | Full plugin |
|---|---|---|
| `/design-action --topic "..."` | Yes | Yes |
| `/setup` wizard | Yes | Yes |
| `/scan`, `/briefing`, `/priorities` | No | Yes |
| Automated daily briefings | No | Yes |
| launchd scheduling templates | No | Yes |

## What It Does

1. **Gathers** evidence from Meeting recordings, Jira (AS8 + ADS), Slack, Figma, Notion
2. **Synthesizes** pain points by frequency, confirmed decisions, open questions, verbatim quotes
3. **Suggests** the right artifact type based on what the evidence supports
4. **Creates** the artifact with every element citing its source
5. **Tracks** design decisions and keeps your backlog updated across sessions

## Quick Start

```bash
# Transform meeting discussions into artifacts
/design-action --topic "error management"

# Cross-stream synthesis (pulls from meetings + Jira + Slack)
/design-action --topic "product model navigation" --multi-source

# Scan for new design-relevant items across all sources
/design-action --scan

# Weekly priority synthesis
/design-action --priorities
```

## Real Examples at Akeneo

Here's what design-action has produced from real meeting evidence:

| Topic | Stream | What It Created | Evidence Sources |
|-------|--------|----------------|-----------------|
| Error management | Activation | Interactive prototype — 6-category error taxonomy, KPI tiles, By Error/By Catalog tabs | 25+ meetings, AS8 Jira tickets, Slack threads |
| Product model navigation | Digital Showroom | Variant display redesign prototype — inline variants, mobile-first wireframes | 12 meetings, ADS Jira, customer data (Allergosan) |
| PIM navigation | Cross-stream | Interactive pitch prototype — 3-state toggle, Export Hub concept | Activation + DS meetings, nav analytics |
| Search experience | Digital Showroom | 3-state search prototype — empty, partial, full results | Customer interviews, ADS tickets |
| Onboarding walkthrough | Activation | 6-step Jimo tour deployed to prod | Sprint retros, user feedback, AS8 tickets |

## How It Works

The plugin uses **dispatch tables** — markdown lookup tables that map your tool config to the right MCP calls. No code adapters. Adding a new provider = adding a table row.

```
Your config (YAML) → dispatch table → MCP tool call → normalized output → synthesis → artifact
```

### Evidence Grounding

Every element in the artifact cites its source:

```
Pain Point: "Users can't find where to start mapping"
Sources: Activation Retro (Mar 7), AS8-2971 (Jira), #activation-core-team (Slack)
Frequency: 4 mentions across 3 source types
Evidence Level: STRONG
```

No hallucinated rationale. No "I think someone mentioned this." Actual citations.

## Value Tiers

Start simple, add capabilities over time.

| Tier | What You Get | You Need |
|------|-------------|----------|
| **Core** | `/design-action --topic "..."` → synthesis + artifacts | Google Meet recordings (or any meeting notes) |
| **+ Tracking** | Backlog, DDRs, task sync, `/scan` | + Jira MCP (AS8/ADS projects) |
| **Full Auto** | Daily briefings, heartbeat, auto-triage | + launchd schedule (macOS) |

## Connected Tools 

| Category | What We Use | Status |
|----------|------------|--------|
| Meetings | **Google Meet recordings** | Connected — primary evidence source |
| Tasks | **Jira** (AS8 + ADS projects) | Connected via Atlassian MCP |
| Communication | **Slack** (Chrome DevTools scraping) | Connected — enterprise blocks API, uses browser |
| Design | **Figma** | Connected via Figma MCP |
| Docs | **Notion** | Connected via Notion MCP |

## Connection to PIM Playground

design-action feeds into the **dual-playground model**:

```
Meetings & evidence → design-action synthesis → stack-matched prototypes → pim-playground visibility
```

- **Activation prototypes** (Next.js + React 19 + DSM) → absorbable into AS8 cockpit
- **DS prototypes** (Next.js + Tailwind + shadcn) → absorbable into Digital Showroom
- **PIM Playground** → central visibility hub, links out to stack-matched prototypes

This means prototypes are both demo-ready (via pim-playground) AND engineering-absorbable (matching production stacks).

## Troubleshooting

### /setup says "no MCP servers detected"

design-action works with any MCP server you already have. If none are detected, use `manual` mode — point it at a folder of meeting notes as markdown files.

### Missing reference files

The skill self-repairs on first run. If files are still missing:

```bash
SKILL_DIR=$(find ~/.claude/skills -name "SKILL.md" -path "*/design-action/*" -exec dirname {} \; 2>/dev/null | head -1)
# Re-download from GitHub
curl -sL "https://raw.githubusercontent.com/akeneo/design-action/main/skills/design-action/reference/{FILENAME}" -o "$SKILL_DIR/reference/{FILENAME}"
```

## Documentation

- [Provider Setup](docs/providers.md) — MCP server setup for each provider
- [Architecture](docs/architecture.md) — System design and data flow
- [Customization](docs/customization.md) — Scoring, templates, workflows

## Author

Built by [Lola Salehu](https://www.linkedin.com/in/lola-salehu/?originalSubdomain=uk) — Product Designer, Activation & Digital Showroom.

**Landing page:** [design-action-site.vercel.app](https://design-action-site.vercel.app)
