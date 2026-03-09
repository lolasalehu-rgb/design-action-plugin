---
name: setup
description: Interactive setup wizard — validates installation, auto-detects MCP servers, creates config
---

# Setup Wizard

Configure design-action for your environment. This wizard validates your installation, auto-detects your MCP servers, and creates `~/.design-action/config.yaml`.

## Step 0: Validate Installation

**Run this FIRST before anything else.**

Find the skill directory:
```bash
SKILL_DIR=$(find ~/.claude/skills ~/.agents/skills -name "SKILL.md" -path "*/design-action/*" -exec dirname {} \; 2>/dev/null | head -1)
echo "Skill installed at: $SKILL_DIR"
```

Check that required reference files exist:
```bash
ls "$SKILL_DIR/reference/"
```

**Required files in `reference/`:**
- `config-template.yaml`
- `ddr-template.md`
- `tiered-loading.md`
- `synthesis-patterns.md`
- `artifact-templates.md`
- `evidence-grounding.md`
- `scan-workflow.md`
- `multi-source.md`
- `production-extraction.md`

**If ANY are missing**, download them from GitHub:
```bash
mkdir -p "$SKILL_DIR/reference"
for file in config-template.yaml ddr-template.md scoring-framework.md tiered-loading.md synthesis-patterns.md artifact-templates.md evidence-grounding.md scan-workflow.md multi-source.md production-extraction.md; do
  if [ ! -f "$SKILL_DIR/reference/$file" ]; then
    echo "Downloading missing: $file"
    curl -sL "https://raw.githubusercontent.com/lolasalehu-rgb/design-action-plugin/main/skills/design-action/reference/$file" -o "$SKILL_DIR/reference/$file"
  fi
done
```

Report result:
```
## Installation Check

✓ Skill directory found at: [path]
✓ All reference files present (or downloaded)

Proceeding to configuration...
```

If curl fails (no internet), the skill can still work — SKILL.md contains inline fallbacks for the config template and DDR template. Tell the user and continue.

---

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

Write `~/.design-action/config.yaml` based on answers. Use `reference/config-template.yaml` as the base if available, otherwise use the inline config template from SKILL.md.

Create starter files (inline — do NOT depend on templates/ directory):

**`~/.design-action/inbox.md`:**
```markdown
# Design Inbox

Items discovered by scanning that need triage.

| Date | Source | Item | Stream | Action |
|------|--------|------|--------|--------|
```

**`~/.design-action/backlog.md`:**
```markdown
# Design Backlog

Scored and prioritized design work items.

## Active (In Progress)

| Priority | Item | Stream | Score | Status | Phase |
|----------|------|--------|-------|--------|-------|

## Queued (Ready to Start)

| Priority | Item | Stream | Score | Status | Phase |
|----------|------|--------|-------|--------|-------|

## Completed

| Item | Stream | Completed |
|------|--------|-----------|
```

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

✓ Installation validated — all reference files present
✓ Config written to ~/.design-action/config.yaml
✓ Directory structure created
✓ Meeting provider validated (found X meetings)
✓ Starter files created (inbox, backlog)

Next steps:
1. Try: /design-action --topic "any topic from a recent meeting"
2. Try: /design-action --scan (if task tracker configured)
```

## Step 5: Help Install Missing Servers

If the user wants capabilities that need MCP servers they don't have, offer to help set them up. Read their `.mcp.json` to understand the existing format, then:

1. **Explain what the server enables** and what credentials/access are needed
2. **Offer to add the server config** to `.mcp.json` if the user provides the required tokens/keys
3. **For servers with no auth required** (like Chrome DevTools), offer to install them directly

Common MCP servers for design-action:

| Server | Auth Needed | Install Help |
|--------|-------------|-------------|
| Granola | No (local app) | Add to `.mcp.json`, user needs Granola desktop app installed |
| Atlassian/Jira | Yes (API token) | Guide user to create token, then add to `.mcp.json` |
| Figma | Yes (access token) | Guide user to Figma settings → Personal Access Tokens |
| Slack | Yes (app token) | Most complex — guide to Slack app creation or use `slack-browser` mode instead |
| Chrome DevTools | No | Can install directly — just needs Chrome running with `--remote-debugging-port` |

Be helpful and proactive, but always confirm with the user before modifying their `.mcp.json`.
