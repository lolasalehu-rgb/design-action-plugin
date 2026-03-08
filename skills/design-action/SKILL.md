---
name: design-action
description: Transform scattered design evidence into grounded artifacts. Aggregates context from meetings, video recordings, task trackers, chat threads, and documents — then synthesizes into prototypes, journey maps, wireframes, research docs, or FigJam boards with full source citations. Use when the user mentions design synthesis, meeting notes, design tasks, cross-source analysis, evidence gathering, or wants to turn discussions and research into deliverables. Also use for proactive source scanning (--scan), weekly priority synthesis (--priorities), or working triaged items (--execute).
---

# Design Action: Evidence to Artifacts

Transform scattered design evidence — from meetings, videos, tasks, chat, and docs — into grounded design artifacts through cross-source synthesis and interactive creation.

## Configuration

This skill reads `~/.design-action/config.yaml` for provider configuration. Run `/setup` if config doesn't exist.

**Config structure** (see `templates/config.example.yaml` for full schema):
- `providers.meetings.type` — which meeting tool to query
- `providers.tasks.type` — which task tracker to sync
- `providers.communication.type` — which chat tool to scan
- `providers.design_tool.type` — which design tool for artifacts
- `streams[]` — work streams with project keys and channels
- `scoring.dimensions[]` — customizable priority scoring

## Core Principles

1. **Context-Aware**: Match approach to context — known artifacts use established patterns; novel artifacts get research first; user references get matched exactly.
2. **Notice-But-Ask**: If you discover a better approach, mention it as an option rather than switching automatically.
3. **Automation for Repeatable Work**: If a workflow will repeat, propose automation after completing it once.
4. **Design System First**: For UI/UX artifacts, always adhere to existing design system. For prototypes, run Production Pattern Extraction first (see `reference/production-extraction.md`).

## Invocation

```
/design-action --topic "onboarding"                         # Default meeting source
/design-action --topic "error handling" --multi-source      # Add tasks, chat, docs
/design-action --topic "analytics" --deep --multi-source    # Full transcripts + secondary
/design-action --topic "customer feedback" --broad --limit 200
/design-action --folder "Research Notes"
/design-action --topic "mobile preview" --video "https://..."
/design-action --scan                                       # Scan for new items
/design-action --execute                                    # Work triaged items
/design-action --priorities                                 # Weekly synthesis
```

**Arguments:**
| Flag | Effect |
|------|--------|
| `--topic <query>` | Semantic search across meetings (required unless --folder/--scan/--execute/--priorities) |
| `--multi-source` | After meetings, search secondary sources (tasks, chat, docs) |
| `--deep` | Fewer meetings (5-8) with full transcripts |
| `--broad` | Many meetings (30-50) with summaries only |
| `--scan` | Proactive scan for NEW design-relevant items |
| `--execute` | Work pre-triaged items from morning briefing |
| `--priorities` | Weekly priority synthesis from all sources |
| `--folder <name>` | Search within specific folder/collection |
| `--video <url>` | Include video recording context |
| `--limit <N>` | Override discovery limit (default: 100) |
| `--parallel` | Spawn Agent Team for parallel execution |
| `--since <dur>` | Time range for --scan (default: "1 day") |

---

## Phase 1: Context Gathering

The skill uses a **tiered loading system**: discover all matches (unlimited), load summaries (broad context), then load full transcripts (deep context). This maximizes coverage while respecting token limits.

**Read `reference/tiered-loading.md` when entering Phase 1 for detailed procedures.**

### Mandatory Pre-Steps (always run these first)

**1. Load Config**
Read `~/.design-action/config.yaml`. If missing, tell user to run `/setup` and stop.

**2. Extraction Cache Check**
Before querying meetings, check `{paths.extractions}/` for existing extraction files matching the topic.
- If found and < 48 hours: ask "Reuse, refresh, or start fresh?"
- If found and > 48 hours: "Stale cache. Fresh extract recommended. Reuse anyway?"
- If not found: proceed to fresh extraction.

**3. Daily Briefing Pre-Context**
Check `{paths.briefings}/YYYY-MM-DD.md` (today, fallback to yesterday). If found:
- Read it (~2-4K tokens) — contains meetings, task status, chat highlights, inbox.
- Note items matching the topic. Use meeting names to supplement search queries.
- Do NOT separately read inbox or last-checks — briefing includes both.
If not found: continue normally (briefing is additive, not a dependency).

### Meeting Provider Dispatch

| If `providers.meetings.type` = | Then |
|--------------------------------|------|
| `granola` | `search_meetings(query, limit)` via Granola MCP → `get_meeting_details(id)` → `get_meeting_transcript(id)` |
| `otter` | `search_transcripts(query)` via Otter MCP → `get_transcript(id)` |
| `fireflies` | `search_meetings(query)` via Fireflies MCP → `get_transcript(id)` |
| `google-meet` | Search Google Calendar for meetings → check Drive for auto-transcripts |
| `notion` | `notion-search(query)` scoped to `config.meetings.config.notion_meeting_db` |
| `manual` | `Glob` + `Grep` on `config.meetings.config.notes_dir` for topic matches |

**Normalize** all output to standard discovery format regardless of provider:
```json
{
  "id": "provider-specific-id",
  "title": "Meeting Title",
  "date": "ISO 8601",
  "participants": ["Name"],
  "duration_minutes": 60,
  "has_transcript": true,
  "relevance": "high|medium|low"
}
```

### Tiered Loading Overview

| Tier | What | Token Budget | Detail |
|------|------|-------------|--------|
| 1. Discovery | Search meetings (limit from config or flag) | ~5K | Meeting index only |
| 2. Summaries | Load details for ranked meetings 6-50 | ~15-25K | Key decisions, participants |
| 3. Full Transcripts | Load transcripts for top 5-10 | ~50-80K | Verbatim quotes, full context |

After loading, present discovery table and offer interactive refinement: "load more", "swap N for M", "focus on [person]", "focus on [date range]", "continue".

### ⛔ GATE: Write Extraction Cache

**Phase 1 is NOT complete until this cache file is written. Do not proceed to Phase 2.**

Write to `{paths.extractions}/{stream}-{topic}.json`:
```json
{
  "topic": "[topic]", "stream": "[stream name from config]",
  "created": "[ISO 8601]",
  "meetings_discovered": 0, "meetings_summarized": 0, "meetings_full_loaded": 0,
  "meeting_ids": [], "meeting_titles": [], "key_participants": [],
  "token_cost_estimate": 0,
  "context_summary": "Brief 2-3 sentence narrative"
}
```
Confirm to user: "Extraction cache saved. Next session can skip Phase 1."

---

## Phase 2: Context Synthesis

Analyze loaded context and extract into categories:

| Category | What to Extract |
|----------|-----------------|
| **Decisions** | Confirmed choices with rationale |
| **Pain Points** | User frustrations — track frequency across meetings |
| **Feature Proposals** | Suggested solutions and status |
| **Open Questions** | Unresolved issues |
| **Quotes** | Verbatim customer/stakeholder quotes |

**Read `reference/synthesis-patterns.md` for detailed extraction patterns and aggregation templates.**

Present cross-meeting synthesis with: meetings analyzed table, pain points by frequency (with evidence), decisions made, proposed solutions, open questions.

### ⛔ GATE: Write Synthesis Cache

**Phase 2 is NOT complete until this file is written. Do not proceed to Phase 3.**

Write to `{paths.extractions}/{stream}-{topic}-synthesis.json`:
```json
{
  "topic": "[topic]", "stream": "[stream]", "created": "[ISO 8601]",
  "based_on_extraction": "{stream}-{topic}.json",
  "pain_points": [{"issue": "...", "frequency": 0, "meetings": [], "quotes": [], "severity": "high|medium|low"}],
  "decisions": [{"decision": "...", "date": "...", "meeting": "...", "rationale": "...", "status": "confirmed|proposed|rejected"}],
  "open_questions": [], "feature_proposals": [],
  "cross_meeting_themes": [],
  "recommended_artifact": "...", "artifact_reasoning": "..."
}
```
Confirm to user: "Synthesis cache saved. Next session can skip Phase 2."

---

## Phase 3: Artifact Suggestion

Based on the synthesis, suggest appropriate artifacts:

| Discussion Type | Suggested Artifacts |
|-----------------|---------------------|
| User research | Journey Map (FigJam), Research Synthesis, Persona Updates |
| Feature discussions | Interactive Prototype, Wireframes, Flow Diagrams |
| UI patterns | Component Library Updates, Wireframes |
| Brainstorming | FigJam Board, Mind Map, Prioritization Matrix |
| Stakeholder comm | Presentation Deck, Executive Summary |

Present primary recommendation with rationale + 2-3 alternatives. Wait for user selection.

**If user selects Interactive Prototype**: Read `reference/production-extraction.md` and run Production Pattern Extraction before building.

**If `--parallel` or 2+ independent items**: Read `reference/team-execution.md` for Agent Team dispatch.

---

## Phase 4: Interactive Creation

### Design Tool Dispatch

| If `providers.design_tool.type` = | Capabilities |
|------------------------------------|-------------|
| `figma` | FigJam boards via `generate_diagram`, screenshots via `get_screenshot` |
| `penpot` | Board creation via Penpot MCP |
| `none` | Markdown-only artifacts, Mermaid diagrams, HTML prototypes |

### Artifact Tool Selection

| Artifact Type | Tool/Skill |
|---------------|-----------|
| Interactive Prototype | `frontend-design` / `impeccable:frontend-design` |
| Journey Map (FigJam) | Figma/Penpot MCP |
| Demo Video | `remotion` skill |
| Wireframes | `frontend-design` (lo-fi HTML/CSS) |
| Research Synthesis | Local markdown |
| UI Images | `image-gen` skill |
| Flow Diagrams | Mermaid (no external tool needed) |

**Read `reference/artifact-templates.md` for templates for each artifact type.**
**Read `reference/evidence-grounding.md` for citation format standards.**

**Every design element must cite its source meeting** — include pain point, source meeting name/date, verbatim quote, and mention frequency.

Build iteratively: announce approach, show progress, get feedback on sections, offer refinements.

---

## Phase 5: Automation & Wrap-up

If the workflow appears repeatable, suggest: manual only, hook/agent, or scheduled automation.

**DDR Prompt**: After artifact creation, ask: "Did this session produce a design decision? If yes, I'll create a DDR."
If confirmed: create DDR in `{paths.decisions}/pending/` using template (see `templates/ddr-template.md`), update backlog if needed.

**Backlog Update**: If new items were discovered or existing items changed status, update `{paths.backlog}`.

---

## Scan Mode (`--scan`)

Skip normal Phases 1-5. Run a proactive source scan for NEW design-relevant items.

**Read `reference/scan-workflow.md` for the full scan procedure.**

Quick overview:
1. Load scan baseline (daily briefing + last-checks timestamps)
2. Check triage output — if pre-triaged items exist, offer to skip scan
3. Search meetings for new items since last scan
4. Check task tracker freshness and delta
5. Check communication channels (if available)
6. Compare against backlog
7. Score new items with configured scoring framework
8. Present findings table with new items, backlog updates, design decisions, gaps
9. Update scan timestamp

---

## Multi-Source Mode (`--multi-source`)

After meeting context loads, search secondary sources based on configured providers.

### Secondary Source Dispatch

| If `providers.tasks.type` = | Then |
|------------------------------|------|
| `jira` | Search via Atlassian MCP with project keys from config |
| `linear` | Search via Linear MCP with team IDs from config |
| `github-issues` | Search via `gh` CLI with repos from config |
| `notion` | Search task database via Notion MCP |
| `none` | Skip task search |

| If `providers.communication.type` = | Then |
|---------------------------------------|------|
| `slack-mcp` | Search via Slack MCP with channels from config |
| `slack-browser` | Scan via Chrome DevTools MCP (Slack open in browser) |
| `discord` | Search via Discord MCP |
| `teams` | Search via Teams MCP |
| `none` | Skip communication search |

Present supplementary results with on-demand deep dives.

**Read `reference/multi-source.md` for full multi-source procedures including --priorities mode.**

---

## Reference Files

Read these on-demand when entering the relevant phase:

| File | When to Read |
|------|-------------|
| `reference/tiered-loading.md` | Entering Phase 1 — detailed loading procedures, context commands, video processing |
| `reference/scan-workflow.md` | Using `--scan` — full scan procedure with provider dispatch |
| `reference/multi-source.md` | Using `--multi-source` or `--priorities` — secondary source search, priority synthesis |
| `reference/production-extraction.md` | Building prototypes — codebase pattern extraction, team execution |
| `reference/artifact-templates.md` | Phase 4 — templates for common artifacts |
| `reference/synthesis-patterns.md` | Phase 2 — cross-meeting analysis patterns |
| `reference/evidence-grounding.md` | Phase 4 — citation format standards |

## Dependencies

**Required:** A meeting source (any provider) + Claude Code
**Optional MCP servers** (detected by `/setup`): Granola, Otter, Fireflies, Notion, Figma, Penpot, Atlassian (Jira), Linear, Slack, Discord, Chrome DevTools
**Optional skills:** `frontend-design`, `impeccable:frontend-design`, `remotion`, `image-gen`
