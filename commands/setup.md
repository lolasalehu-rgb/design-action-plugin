---
name: setup
description: Interactive setup wizard — auto-detects MCP servers and creates config
---

# Setup Wizard

Configure design-action for your environment. This wizard auto-detects your installed MCP servers and creates `~/.design-action/config.yaml`.

## Step 1: Auto-Detect MCP Servers

Read the user's MCP configuration (typically `~/.claude/.mcp.json` or project-level `.mcp.json`) and identify available servers:

| Server Pattern | Provider Type | Category |
|----------------|--------------|----------|
| `granola` | `granola` | meetings |
| `otter` | `otter` | meetings |
| `fireflies` | `fireflies` | meetings |
| `atlassian`, `jira` | `jira` | tasks |
| `linear` | `linear` | tasks |
| `slack` | `slack-mcp` | communication |
| `discord` | `discord` | communication |
| `figma` | `figma` | design_tool |
| `penpot` | `penpot` | design_tool |
| `notion` | `notion` | multiple |
| `chrome-devtools` | `slack-browser` (potential) | communication |

Present detected servers:
```
## Detected MCP Servers

✓ Granola MCP — can be used for meeting transcripts
✓ Atlassian MCP — can be used for Jira task tracking
✓ Figma MCP — can be used for design artifacts
✓ Chrome DevTools — can be used for Slack scanning (browser-based)

✗ No Slack MCP detected
✗ No Linear MCP detected
```

## Step 2: Ask 5 Configuration Questions

### Q1: Meeting Source
"Where do your meeting notes/transcripts live?"
- Options based on detected servers, plus `manual` (markdown files in a directory)
- If manual: ask for directory path (default: `~/meeting-notes`)

### Q2: Task Tracker
"What task tracker do you use for design work?"
- Options based on detected servers, plus `none`
- If jira: ask for project key(s) (e.g., "PROJ" or "PROJ, MOB")
- If linear: ask for team ID(s)
- If github-issues: ask for repo(s) (e.g., "org/repo")

### Q3: Communication Tool
"How does your team communicate async?"
- Options based on detected servers, plus `none`
- If any: ask for channel names to monitor

### Q4: Design Tool
"What design tool do you use?"
- Options based on detected servers, plus `none`

### Q5: Work Streams
"Do you work across multiple products/streams, or just one?"
- If one: ask for name, display name, project key
- If multiple: collect name, display name, project key for each

## Step 3: Write Configuration

Create directory structure:
```bash
mkdir -p ~/.design-action/{extractions,briefings,decisions/pending,decisions/accepted}
```

Write `~/.design-action/config.yaml` based on answers.
Copy starter templates:
- `templates/inbox.md` → `~/.design-action/inbox.md`
- `templates/backlog.md` → `~/.design-action/backlog.md`

## Step 4: Validate

Run a simple test against the meeting provider to verify connectivity:

| Provider | Validation Test |
|----------|----------------|
| `granola` | `search_meetings(query="test", limit=1)` — should return at least 1 result |
| `otter` | `search_transcripts(query="test", limit=1)` |
| `fireflies` | `search_meetings(query="test", limit=1)` |
| `google-meet` | Check Calendar API access |
| `notion` | `notion-search(query="test")` scoped to meeting DB |
| `manual` | Verify notes_dir exists and contains .md files |

Report result:
```
## Setup Complete!

✓ Config written to ~/.design-action/config.yaml
✓ Directory structure created
✓ Meeting provider validated (found X meetings)
✓ Templates installed

Next steps:
1. Try: /design-action --topic "any topic from a recent meeting"
2. Try: /design-action --scan (if task tracker configured)
3. See docs/providers.md for additional MCP server setup
4. See docs/customization.md for scoring and template customization
```

## Step 5: Guide for Missing Servers

If the user needs MCP servers they don't have:
```
## Optional: Install Additional MCP Servers

For the best experience, consider adding:
- [Provider name]: [One-line description of what it enables]
  See docs/providers.md for setup instructions.
```

Do NOT attempt to install MCP servers automatically. Only guide the user.
