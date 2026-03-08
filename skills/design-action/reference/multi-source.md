# Multi-Source Mode & Priority Synthesis

## Multi-Source Search (`--multi-source`)

After all meeting context is loaded (Phase 1 complete), search across configured secondary sources.

### Secondary Source Dispatch

Search each configured provider for supplementary context on the current topic.

**Task Tracker:**

| If `providers.tasks.type` = | Search Method |
|------------------------------|---------------|
| `jira` | `searchJiraIssuesUsingJql(jql="text ~ '{topic}' AND project IN ({stream.task_project_key}) ORDER BY updated DESC")` via Atlassian MCP |
| `linear` | Search issues in `{team_ids}` matching topic keywords |
| `github-issues` | `gh issue list --repo {repo} --search "{topic}" --json number,title,body,labels` |
| `notion` | `notion-search(query="{topic}")` scoped to task database |
| `none` | Skip |

**Communication:**

| If `providers.communication.type` = | Search Method |
|---------------------------------------|---------------|
| `slack-mcp` | Search messages matching topic in configured channels |
| `slack-browser` | Navigate to channels via Chrome DevTools, search for topic |
| `discord` | Search channels matching topic |
| `teams` | Search channels matching topic |
| `none` | Skip |

**Additional Sources** (always attempt if available):
- Notion connected sources: `notion-search(query="{topic} {stream keywords}", query_type="internal")` — returns Slack, Jira, Notion, Drive results in one response
- Google Drive: search for documents matching topic

### Present Supplementary Results

```
## Supplementary Context (Async Communications)

**Tasks** (N items from {tasks.type}):
| Key | Summary | Status |
|-----|---------|--------|

**Messages** (N from {communication.type}):
- #channel: "[message preview]" - [Author], [Date]

**Documents** (N docs):
- [Doc title]: "[excerpt]"

Commands: "load task {KEY}", "load message [url]", "load doc [id]", or "continue"
```

### On-Demand Deep Dives

| Command | Action |
|---------|--------|
| `load task [KEY]` | Fetch specific task via configured task MCP |
| `load message [url]` | Fetch message thread via communication MCP |
| `load doc [id]` | Fetch document via Notion/Drive MCP |

### Token Budget (Multi-Source)

| Source | Typical Load | Tokens |
|--------|--------------|--------|
| Meetings (primary) | 5-8 transcripts + 30 summaries | ~70,000-90,000 |
| Secondary sources | 10-20 results | ~2,000-4,000 |
| On-demand deep dives | User-requested only | ~3,000-8,000 |
| **Total** | | **~75,000-100,000** |

Multi-source adds ~10% overhead but keeps meetings as the authoritative source.

---

## Priority Synthesis (`--priorities`)

Synthesize weekly design priorities from all configured sources.

### Execution Order (Meetings First)

1. **Meetings**: Get meetings from last 7 days → extract action items, decisions
2. **Tasks**: Get items assigned to user in current sprint/iteration
3. **Documents**: Search for weekly plan / sprint planning docs
4. **Communication**: Search for "this week" + "priorities" + "design" in channels
5. **Synthesize** into prioritized list with cross-references

### Meeting Provider for Priorities

| If `providers.meetings.type` = | Weekly Query |
|--------------------------------|--------------|
| `granola` | `search_meetings(query="design priorities week", limit=20)` filtered to last 7 days |
| `otter` | `search_transcripts(query="priorities this week")` filtered to last 7 days |
| `fireflies` | `search_meetings(query="priorities week")` filtered to last 7 days |
| `google-meet` | Calendar events from last 7 days → load transcripts |
| `notion` | Query meeting DB sorted by date, last 7 days |
| `manual` | Recent files in notes_dir from last 7 days |

### Task Provider for Priorities

| If `providers.tasks.type` = | Sprint/Iteration Query |
|------------------------------|------------------------|
| `jira` | `assignee = currentUser() AND sprint in openSprints() ORDER BY priority DESC` |
| `linear` | Active cycle issues assigned to user |
| `github-issues` | `gh issue list --assignee @me --state open` across configured repos |
| `notion` | Query task DB filtered by assignee and status != Done |
| `none` | Skip task context |

### Output Format

```
## This Week's Design Priorities ([date range])

### Committed
1. **[TASK-KEY]**: [Title] (Status: [status], due [date])
   - Mentioned in: [sources]

### Under Discussion
2. **[Topic]**
   - [Source]: [context]
   - No task created yet

### Blocked
3. **[Topic]**
   - Waiting on: [dependency]
```
