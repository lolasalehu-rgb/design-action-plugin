# Scan Mode — Full Procedure

When invoked with `--scan`, skip normal Phases 1-5 and run a proactive source scan.

## Step 1: Load Scan Baseline

### 1a. Daily Briefing

Read `{paths.briefings}/YYYY-MM-DD.md` (today's date, fallback to yesterday):
- If < 4 hours old: treat as **current** — only scan for items NEWER than the briefing
- If > 4 hours old: treat as **stale base** — use for context but do a full re-scan
- If missing: skip, no error

Content from briefing (~2-4K tokens): meetings, active tasks, chat highlights, inbox items, backlog priorities.

**Skip re-fetching** categories already covered by briefing unless scanning for newer items.

### 1b. Last Scan Timestamps

Read `{paths.extractions}/last-checks.json`:
- `full_scan.timestamp` — precise scan cutoff (if empty, default to "1 day" lookback)
- `heartbeat.timestamp` — check if heartbeat found anything since last scan
- `briefing.timestamp` — when morning briefing ran

**Combined logic**: Briefing provides _context_ (what's known), `last-checks.json` provides _cutoff_ timestamps. Together they avoid redundant reads and missed items.

## Step 2: Decide Execution Mode

Check `{paths.extractions}/triage-{date}.json`:
- If exists with `ready_for_parallel` items: offer to skip scan and go to team execution
- If 2+ independent items found: spawn Agent Team
- If 1 item or dependent items: proceed single-threaded

## Step 3: Check Meetings for New Items

### Meeting Scan Dispatch

| If `providers.meetings.type` = | Scan Calls |
|--------------------------------|------------|
| `granola` | `search_meetings(query="design", limit=50)` + `search_meetings(query="UX prototype wireframe", limit=50)` + stream-specific queries |
| `otter` | `search_transcripts(query="design")` + topic variations |
| `fireflies` | `search_meetings(query="design")` + topic variations |
| `google-meet` | Search Calendar for recent meetings → check Drive for transcripts |
| `notion` | Query meeting database sorted by date desc |
| `manual` | `Glob` recent files in notes_dir, sorted by modification time |

- Date filter: only items since last scan timestamp
- Deduplicate by ID
- Classify each: design-relevant? Which stream?
- Design signals: "UX", "design", "wireframe", "prototype", "user journey", "error handling", "onboarding", "flow", participant names from config

## Step 4: Check Task Tracker (Freshness + Delta)

### 4a. Evaluate timestamp freshness
- Task check timestamp fresh (< 2h)? Use cached data
- Stale? Warn user "Task data may be outdated"
- If task MCP available and data stale: direct scan as backup

### 4b. Read inbox for items already captured
From `{paths.inbox}` — note existing items to avoid duplicates.

### 4c. Task Tracker Scan Dispatch

| If `providers.tasks.type` = | Scan Method |
|------------------------------|-------------|
| `jira` | JQL: `project = {stream.task_project_key} AND labels = "{labels.design_work}" AND updated >= "{cutoff_date}" ORDER BY updated DESC` per stream. Also: `assignee = currentUser() AND updated >= "{cutoff_date}"` |
| `linear` | Query issues in `{team_ids}` with `{label_group}` label, updated since cutoff |
| `github-issues` | `gh issue list --repo {repo} --label {labels} --state open --json number,title,updatedAt` per repo |
| `notion` | Query task database filtered by last_edited_time > cutoff |
| `none` | Skip task check |

Track: new items, status transitions, new comments with design implications.

## Step 5: Check Communication Channels

### Communication Scan Dispatch

| If `providers.communication.type` = | Scan Method |
|---------------------------------------|-------------|
| `slack-mcp` | Search channels from config for design keywords |
| `slack-browser` | `list_pages()` → find Slack tabs → `select_page` → `take_snapshot` per channel |
| `discord` | Search configured channels via Discord MCP |
| `teams` | Search configured channels via Teams MCP |
| `none` | Skip communication check |

- Target channels: from `{streams[].channels}` config
- Signals: design decisions, feature requests, blockers, @mentions of user
- If tool unavailable: skip gracefully, log gap in findings

## Step 6: Compare Against Existing Backlog

Read `{paths.backlog}`:
- Identify genuinely NEW items (not in backlog or inbox)
- Identify existing items with status changes
- Items in inbox but not backlog: note for triage

## Step 7: Score New Items

Use the scoring framework from config (`scoring.dimensions[]`):

For each new item, score on each dimension (1-5 scale), then compute weighted priority:
```
priority = sum(score[i] * weight[i] * (invert[i] ? -1 : 1))
```

Ground scoring in: codebase knowledge, meeting context, task details, historical patterns.

**Default dimensions** (if not customized):
| Dimension | Weight | Question |
|-----------|--------|----------|
| User Impact | 0.4 | How much does this help users accomplish their goals? |
| Business Value | 0.3 | How much does this drive business outcomes? |
| Effort | 0.2 (inverted) | Engineering and design complexity |
| Strategic Alignment | 0.1 | How well does this align with current strategy? |

## Step 8: Present Findings

```
## Scan Results (since [last scan date])

### Sources Scanned
| Source | Status | Items Checked | New Items |
|--------|--------|---------------|-----------|
| Meetings ({type}) | [Scanned/Skipped] | [N] | [N] new |
| Tasks ({type}) | [Fresh/Stale] | [N] | [N] changes |
| Communication ({type}) | [Scanned/Skipped - reason] | [N] channels | [N] new |

### New Design-Relevant Items
| # | Item | Source | Stream | Score | Priority |
|---|------|--------|--------|-------|----------|

### Existing Backlog Updates
| Item | Change | Source |
|------|--------|--------|

### Design Decisions Detected
| Decision | Meeting/Source | Needs DDR? |
|----------|---------------|------------|

### Gaps & Warnings
- [e.g., "Communication not scanned — no Slack MCP configured"]
- [e.g., "No meetings found in last 8 days"]

Add [N] items to backlog? Create DDRs for detected decisions?
```

## Step 9: Update Scan Timestamp

Read `{paths.extractions}/last-checks.json`, then UPDATE only the `full_scan` key (preserve all others):

```json
{
  "...existing keys preserved...",
  "full_scan": {
    "timestamp": "[ISO 8601]",
    "items_found": 0,
    "items_added_to_backlog": 0,
    "ddrs_created": 0,
    "sources": {
      "meetings": "scanned|skipped",
      "tasks": "scanned|skipped",
      "communication": "scanned|skipped"
    }
  }
}
```

## Parallelization Opportunities

- Steps 1a, 1b, 2 can run in parallel (independent file reads)
- Meeting searches can run in parallel with each other
- Task queries can run in parallel with each other
- Steps 3, 4, and 5 can all run in parallel with each other
