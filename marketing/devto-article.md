---
title: "I Built a Plugin That Turns Meeting Chaos Into Cited Design Artifacts"
published: false
description: "How design-action synthesizes evidence from meetings, Jira, Slack, and Figma into grounded artifacts with full source citations."
tags: design, productivity, ai, claude
---

# I Built a Plugin That Turns Meeting Chaos Into Cited Design Artifacts

I'm a product designer working across multiple product streams. On any given week, I'm in 6+ meetings with PMs, engineers, QA, and stakeholders — each generating decisions, pain points, and feature ideas that scatter across Jira, Slack, Figma comments, and meeting transcripts.

By Friday, I'm spending an hour reconstructing what happened Monday.

So I built **design-action** — a plugin that synthesizes evidence from all those sources into grounded design artifacts with full source citations.

## The Problem: Evidence Scatter

Design evidence lives in at least 5 different places:

| Source | What's There |
|--------|-------------|
| Meeting transcripts | Decisions, pain points, stakeholder quotes |
| Task trackers | Requirements, acceptance criteria, linked discussions |
| Chat threads | Quick decisions, feedback, requests |
| Design tools | Review comments, annotations |
| Video recordings | User interviews, usability test observations |

The problem isn't access — most of us have MCP servers or APIs for these tools. The problem is **synthesis**. Connecting the dots across sources to see that the same pain point came up in 3 meetings, 2 Jira tickets, and a Slack thread.

## The Solution: Evidence-Grounded Artifacts

design-action runs a 5-phase pipeline:

### Phase 1: Gather
Searches your meeting tool, task tracker, and chat for evidence related to your topic. Uses tiered loading (discover → summarize → deep-dive) to stay within token budgets.

```
/design-action --topic "onboarding"
```

It finds 12 relevant meetings, 8 matching Jira tickets, and 3 Slack threads.

### Phase 2: Synthesize
Extracts structured insights:
- **Pain points** with frequency counts across sources
- **Decisions** with who agreed and when
- **Verbatim quotes** with attribution
- **Open questions** that need resolution

### Phase 3: Suggest
Based on the evidence pattern, recommends an artifact type:
- Journey maps for user flow pain points
- Wireframes for UI-specific discussions
- Research synthesis for broad discovery
- Design Decision Records for resolved debates

### Phase 4: Create
Builds the artifact with **every element citing its source**:

```
Pain Point: "I spent 20 minutes just trying to find where to start"
Sources: Customer Call (Mar 7), PROJ-456 (Jira), #product-feedback (Slack)
Frequency: 4 mentions across 3 source types
Evidence Level: STRONG
```

No hallucinated design rationale. Every element traces back to where it was discussed.

### Phase 5: Track
Creates a Design Decision Record, updates your backlog, and suggests automation for repeatable workflows.

## Provider Agnostic

design-action works with whatever your team uses. One YAML config file maps to the right MCP tool calls:

```yaml
providers:
  meetings:
    type: "granola"  # or otter, fireflies, google-meet, manual
  tasks:
    type: "jira"     # or linear, github-issues, notion
  communication:
    type: "slack-mcp" # or discord, teams
  design_tool:
    type: "figma"     # or penpot
```

Supported providers:
- **Meetings**: Granola, Otter.ai, Fireflies.ai, Google Meet, Notion, manual markdown
- **Tasks**: Jira, Linear, GitHub Issues, Notion
- **Chat**: Slack, Discord, Microsoft Teams
- **Design**: Figma, Penpot

## Three Value Tiers

You don't need the full stack to get value:

| Tier | What You Get | You Need |
|------|-------------|----------|
| **Core** | Synthesis + artifacts from `/design-action --topic` | Any meeting source |
| **+ Tracking** | Backlog sync, DDRs, `/scan` for discovery | + task tracker |
| **Full Auto** | Daily briefings, heartbeat scanning, auto-triage | + scheduler |

## Install

Works with Claude Code, Cursor, Copilot, Cline, and more:

```bash
npx skills add lolasalehu-rgb/design-action-plugin
```

For the full Claude Code plugin experience (with commands and automation):

```bash
claude --plugin-dir ./design-action-plugin
```

Then run `/setup` to connect your tools.

## Who It's For

- **In-house product designers** juggling multiple streams with cross-functional stakeholders
- **Design consultants** managing multiple client contexts
- **Design leads** needing cross-stream visibility

The common thread: you work across people and tools, and context gets lost between meetings.

## License

Free for personal use. Commercial license (with revenue share) required for teams selling services with it. See the LICENSE file for details.

---

Built by [Lola Salehu](https://www.linkedin.com/in/lola-salehu/) — a product designer who got tired of losing decisions between meetings.

[GitHub](https://github.com/lolasalehu-rgb/design-action-plugin) · [Landing Page](#)
