# Provider Catalog & MCP Setup

design-action works with any combination of meeting, task, communication, and design tools. This guide covers setup for each supported provider.

## Meeting Providers

### Granola (`type: "granola"`)

**What it provides:** AI meeting notes with transcripts, summaries, participants, and Q&A history.

**MCP Server:** [granola-mcp](https://github.com/granola-ai/granola-mcp) (community)

**Setup:**
```json
// Add to ~/.claude/.mcp.json
{
  "mcpServers": {
    "granola": {
      "command": "npx",
      "args": ["-y", "granola-mcp"]
    }
  }
}
```

**Available tools:** `search_meetings`, `get_meeting_details`, `get_meeting_transcript`

**Best for:** Teams already using Granola for meeting notes. Provides the richest meeting data.

---

### Otter.ai (`type: "otter"`)

**What it provides:** Real-time transcription, automated summaries, action items.

**MCP Server:** Check [Otter.ai integrations](https://otter.ai/integrations) for MCP availability, or use their API.

**Setup:**
```json
{
  "mcpServers": {
    "otter": {
      "command": "npx",
      "args": ["-y", "otter-mcp"],
      "env": {
        "OTTER_API_KEY": "your-api-key"
      }
    }
  }
}
```

**Available tools:** `search_transcripts`, `get_transcript_summary`, `get_full_transcript`

**Best for:** Teams using Otter for automated transcription across meeting platforms.

---

### Fireflies.ai (`type: "fireflies"`)

**What it provides:** Meeting transcription, summaries, action items, topic detection.

**MCP Server:** Check [Fireflies integrations](https://fireflies.ai/integrations) for MCP availability.

**Setup:**
```json
{
  "mcpServers": {
    "fireflies": {
      "command": "npx",
      "args": ["-y", "fireflies-mcp"],
      "env": {
        "FIREFLIES_API_KEY": "your-api-key"
      }
    }
  }
}
```

**Available tools:** `search_meetings`, `get_meeting_summary`, `get_transcript`

**Best for:** Teams using Fireflies for meeting intelligence and CRM integration.

---

### Google Meet (`type: "google-meet"`)

**What it provides:** Calendar events + auto-generated transcripts (saved to Google Drive).

**MCP Server:** Requires Google Calendar + Google Drive MCP servers.

**Setup:** Configure Google Workspace MCP servers with appropriate OAuth scopes:
- `calendar.readonly` — for meeting discovery
- `drive.readonly` — for transcript access

**How it works:**
1. Searches Google Calendar for meetings matching the topic
2. Checks Google Drive for auto-generated transcript files
3. Falls back to meeting event description if no transcript exists

**Best for:** Teams using Google Workspace without a dedicated meeting note tool.

---

### Notion (`type: "notion"` for meetings)

**What it provides:** Meeting notes stored as Notion pages in a dedicated database.

**MCP Server:** [Notion MCP](https://github.com/makenotion/notion-mcp)

**Setup:**
```json
{
  "mcpServers": {
    "notion": {
      "command": "npx",
      "args": ["-y", "@notionhq/notion-mcp-server"],
      "env": {
        "OPENAPI_MCP_HEADERS": "{\"Authorization\": \"Bearer ntn_xxx\", \"Notion-Version\": \"2022-06-28\"}"
      }
    }
  }
}
```

**Config:** Set `notion_meeting_db` to the database ID containing your meeting notes:
```yaml
providers:
  meetings:
    type: "notion"
    config:
      notion_meeting_db: "your-database-id"
```

**Best for:** Teams that manually write meeting notes in Notion.

---

### Manual (`type: "manual"`)

**What it provides:** Local markdown files as meeting notes.

**No MCP Server needed.** Uses built-in file tools (Glob, Grep, Read).

**Config:**
```yaml
providers:
  meetings:
    type: "manual"
    config:
      notes_dir: "~/meeting-notes"  # Directory containing .md files
```

**File naming convention** (recommended):
```
YYYY-MM-DD-meeting-title.md
```

**Best for:** Anyone who takes meeting notes in markdown. Zero setup required.

---

## Task Tracker Providers

### Jira (`type: "jira"`)

**MCP Server:** [Atlassian MCP](https://github.com/atlassian/mcp-server-atlassian)

**Setup:**
```json
{
  "mcpServers": {
    "atlassian": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-atlassian"],
      "env": {
        "ATLASSIAN_SITE": "your-site.atlassian.net",
        "ATLASSIAN_EMAIL": "you@company.com",
        "ATLASSIAN_API_TOKEN": "your-api-token"
      }
    }
  }
}
```

**Config:**
```yaml
providers:
  tasks:
    type: "jira"
    config:
      projects: ["PROJ", "MOB"]
      labels:
        design_work: "design-work"
        phase_prefix: "design-"
        stream_prefix: "design-stream-"
```

**Label taxonomy:** design-action uses labels to track design phase and stream:
- `design-work` — marks a ticket as design-relevant
- `design-research`, `design-build`, `design-review` — phase labels
- `design-stream-{name}` — stream labels

---

### Linear (`type: "linear"`)

**MCP Server:** Check [Linear integrations](https://linear.app/integrations) for MCP availability.

**Config:**
```yaml
providers:
  tasks:
    type: "linear"
    config:
      team_ids: ["team-abc"]
      label_group: "Design"
```

---

### GitHub Issues (`type: "github-issues"`)

**No MCP Server needed.** Uses the `gh` CLI (must be installed and authenticated).

**Config:**
```yaml
providers:
  tasks:
    type: "github-issues"
    config:
      repos: ["org/repo", "org/other-repo"]
      labels: ["design", "ux"]
```

---

### Notion (`type: "notion"` for tasks)

Uses the same Notion MCP server as the meetings provider.

**Config:**
```yaml
providers:
  tasks:
    type: "notion"
    config:
      task_db: "your-task-database-id"
```

---

## Communication Providers

### Slack MCP (`type: "slack-mcp"`)

**MCP Server:** Check Slack marketplace for MCP server availability.

**Config:**
```yaml
providers:
  communication:
    type: "slack-mcp"
    config:
      channels: ["#design-team", "#product-feedback"]
```

### Slack via Browser (`type: "slack-browser"`)

**MCP Server:** Requires Chrome DevTools MCP + Slack open in Chrome.

Uses browser automation to read Slack channels when a native Slack MCP isn't available (common in enterprise environments that restrict API access).

**Setup:**
1. Install Chrome DevTools MCP
2. Open Slack in Chrome
3. Launch Chrome with remote debugging enabled

**Config:**
```yaml
providers:
  communication:
    type: "slack-browser"
    config:
      channels: ["#design-team", "#product-feedback"]
```

### Discord (`type: "discord"`)

**MCP Server:** Check Discord developer tools for MCP availability.

### Microsoft Teams (`type: "teams"`)

**MCP Server:** Check Microsoft Graph API integrations for MCP availability.

---

## Design Tool Providers

### Figma (`type: "figma"`)

**MCP Server:** [Figma MCP](https://github.com/figma/figma-mcp) (official)

**Capabilities:**
- Create FigJam boards for journey maps and workshops
- Read existing designs for reference
- Generate diagrams

### Penpot (`type: "penpot"`)

**MCP Server:** Check [Penpot](https://penpot.app/) for MCP availability.

---

## Notification Providers

### macOS (`type: "macos"`)
Uses `osascript` to send native macOS notifications. No setup needed on macOS.

### Linux (`type: "notify-send"`)
Uses `notify-send` command. Install with your package manager if not present:
```bash
# Debian/Ubuntu
sudo apt install libnotify-bin

# Fedora
sudo dnf install libnotify
```

---

## Provider Compatibility Matrix

| Feature | Granola | Otter | Fireflies | Google Meet | Notion | Manual |
|---------|---------|-------|-----------|-------------|--------|--------|
| Semantic search | ✓ | ✓ | ✓ | ✗ | ✓ | ✓ (grep) |
| Full transcripts | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |
| Summaries | ✓ | ✓ | ✓ | ✗ | ✓ | ✗ |
| Participants | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ |
| Action items | ✓ | ✓ | ✓ | ✗ | ✗ | ✗ |
| Zero config | ✓ | ✗ | ✗ | ✗ | ✗ | ✓ |
