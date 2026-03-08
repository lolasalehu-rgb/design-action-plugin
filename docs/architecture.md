# Architecture

## Design Philosophy

design-action uses **Claude as the universal adapter**. Instead of writing code adapters for each provider, the SKILL.md contains **dispatch tables** in markdown — lookup tables that tell Claude which MCP tool to call based on the user's config.

```
Config (YAML) → SKILL.md dispatch table → MCP tool call → Normalized output
```

This means:
- **Zero code to maintain** per provider — just markdown
- **New providers** are added by extending dispatch tables
- **Claude handles the normalization** between different API response formats
- **Graceful degradation** — if a provider isn't configured, the skill skips it

## System Components

```
┌─────────────────────────────────────────────────┐
│                   User                           │
│                                                  │
│  /design-action --topic "..."                    │
│  /scan                                           │
│  /briefing                                       │
└──────────┬──────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────┐
│              SKILL.md (Methodology)               │
│                                                   │
│  Phase 1: Context Gathering                       │
│    └─ Meeting Provider Dispatch Table             │
│  Phase 2: Synthesis                               │
│    └─ Extraction Patterns                         │
│  Phase 3: Artifact Suggestion                     │
│  Phase 4: Creation                                │
│    └─ Design Tool Dispatch Table                  │
│  Phase 5: Automation                              │
│                                                   │
│  Scan Mode ──── Task Tracker Dispatch Table       │
│  Multi-Source ── Communication Dispatch Table      │
└──────────┬──────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────┐
│            config.yaml (User Config)              │
│                                                   │
│  providers:                                       │
│    meetings: { type: "granola" }                  │
│    tasks: { type: "jira", config: {...} }         │
│    communication: { type: "slack-browser" }       │
│    design_tool: { type: "figma" }                 │
│                                                   │
│  streams: [{ name: "...", ... }]                  │
│  scoring: { dimensions: [...] }                   │
└──────────┬──────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────┐
│              MCP Servers (External)               │
│                                                   │
│  Granola MCP ──── Meeting transcripts             │
│  Atlassian MCP ── Jira tickets                    │
│  Figma MCP ────── Design artifacts                │
│  Chrome DevTools ─ Slack scanning                 │
│  Notion MCP ────── Docs, databases                │
│  (etc.)                                           │
└──────────────────────────────────────────────────┘
```

## Data Flow

### Standard Invocation (`/design-action --topic "..."`)

```
User query
  → Phase 1: Search meetings (dispatch to configured provider)
    → Cache extraction to {data_dir}/extractions/
  → Phase 2: Synthesize across meetings
    → Cache synthesis to {data_dir}/extractions/
  → Phase 3: Suggest artifact type
    → User selects
  → Phase 4: Create artifact (dispatch to configured design tool)
    → Evidence-grounded output
  → Phase 5: Suggest automation, create DDR if needed
```

### Scan (`/scan`)

```
Load baseline (briefing + last-checks.json)
  → Search meetings since last scan
  → Check task tracker delta
  → Check communication channels
  → Compare against backlog
  → Score new items
  → Present findings
  → Update last-checks.json
```

### Briefing (`/briefing`)

```
Query all configured providers
  → Compile meeting summary
  → Compile task status
  → Compile communication highlights
  → Read inbox + backlog
  → Generate triage for new items
  → Save to {data_dir}/briefings/
```

## Value Tiers

| Tier | What You Get | Requirements |
|------|-------------|--------------|
| **1: Core** | Manual `/design-action --topic "..."` → synthesis + artifacts | Any meeting source + Claude Code |
| **2: + Tracking** | Backlog management, DDRs, task sync, `/scan` | + task tracker MCP |
| **3: Full Auto** | Heartbeat, daily briefing, auto-triage, notifications | + scheduler setup |

Each tier builds on the previous. Users get value at any level.

## File Layout

```
~/.design-action/              # User data (created by /setup)
├── config.yaml                # Provider configuration
├── inbox.md                   # Untriaged incoming items
├── backlog.md                 # Scored design backlog
├── extractions/               # Cache files
│   ├── {stream}-{topic}.json           # Phase 1 cache
│   ├── {stream}-{topic}-synthesis.json # Phase 2 cache
│   ├── triage-{date}.json             # Daily triage output
│   └── last-checks.json               # Timestamp tracking
├── briefings/                 # Daily briefings
│   └── YYYY-MM-DD.md
└── decisions/                 # Design Decision Records
    ├── pending/
    └── accepted/
```

## Reference File Loading

Reference files are loaded **on-demand** to minimize token usage:

| File | Loaded When | ~Tokens |
|------|------------|---------|
| SKILL.md | Always (skill invocation) | ~3,000 |
| tiered-loading.md | Phase 1 | ~2,000 |
| synthesis-patterns.md | Phase 2 | ~3,000 |
| evidence-grounding.md | Phase 4 | ~3,000 |
| artifact-templates.md | Phase 4 | ~3,500 |
| production-extraction.md | Prototype selected | ~1,500 |
| scan-workflow.md | `--scan` mode | ~2,500 |
| multi-source.md | `--multi-source` or `--priorities` | ~1,500 |

Total if all loaded: ~20,000 tokens. Typical invocation loads 2-3 files: ~8,000 tokens.
