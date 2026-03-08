#!/bin/bash
# Daily Design Briefing Script (config-driven, provider-agnostic)
# Produces a full briefing: meetings, tasks, communication, triage.
# Reads all settings from ~/.design-action/config.yaml via yq.
#
# Scheduled trigger: e.g., 8 AM weekdays via launchd/systemd/cron
# Manual run: bash daily-briefing.sh
# Force (bypass all gates): bash daily-briefing.sh --force
# Dry run (test gates, no Claude): bash daily-briefing.sh --dry-run

set -euo pipefail
unset CLAUDECODE 2>/dev/null || true

# ─── Config ──────────────────────────────────────────────────────
CONFIG_FILE="${DESIGN_ACTION_CONFIG:-$HOME/.design-action/config.yaml}"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Config not found at $CONFIG_FILE"
    echo "Run 'design-action setup' or copy templates/config.example.yaml to $CONFIG_FILE"
    exit 1
fi

if ! command -v yq &>/dev/null; then
    echo "ERROR: yq not found. Install with: brew install yq (macOS) or apt install yq (Linux)"
    exit 1
fi

# Read paths (with defaults)
DATA_DIR=$(yq -r '.paths.data_dir // "~/.design-action"' "$CONFIG_FILE" | sed "s|^~|$HOME|")
LOG_DIR="$DATA_DIR/logs"
BRIEFING_DIR=$(yq -r '.paths.briefings // "~/.design-action/briefings"' "$CONFIG_FILE" | sed "s|^~|$HOME|")
DECISIONS_DIR=$(yq -r '.paths.decisions // "~/.design-action/decisions"' "$CONFIG_FILE" | sed "s|^~|$HOME|")
EXTRACTIONS_DIR=$(yq -r '.paths.extractions // "~/.design-action/extractions"' "$CONFIG_FILE" | sed "s|^~|$HOME|")
INBOX_FILE=$(yq -r '.paths.inbox // "~/.design-action/inbox.md"' "$CONFIG_FILE" | sed "s|^~|$HOME|")
BACKLOG_FILE=$(yq -r '.paths.backlog // "~/.design-action/backlog.md"' "$CONFIG_FILE" | sed "s|^~|$HOME|")

mkdir -p "$LOG_DIR" "$BRIEFING_DIR" "$DECISIONS_DIR/pending" "$DECISIONS_DIR/accepted" "$EXTRACTIONS_DIR"

TODAY=$(date +"%Y-%m-%d")
TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S")
LOG_FILE="$LOG_DIR/briefing-$TODAY.log"

echo "[$TIMESTAMP] Daily briefing starting..." > "$LOG_FILE"

# Read identity
USER_NAME=$(yq -r '.user.name // "User"' "$CONFIG_FILE")
USER_ROLE=$(yq -r '.user.role // "Designer"' "$CONFIG_FILE")

# Read provider types
MEETING_TYPE=$(yq -r '.providers.meetings.type // "manual"' "$CONFIG_FILE")
TASK_TYPE=$(yq -r '.providers.tasks.type // "none"' "$CONFIG_FILE")
COMM_TYPE=$(yq -r '.providers.communication.type // "none"' "$CONFIG_FILE")
NOTIFICATION_TYPE=$(yq -r '.providers.notifications.type // "none"' "$CONFIG_FILE")

# Read automation settings
WEEKDAYS_ONLY=$(yq -r '.automation.work_hours.weekdays_only // true' "$CONFIG_FILE")
WORK_START=$(yq -r '.automation.work_hours.start // 7' "$CONFIG_FILE")
WORK_END=$(yq -r '.automation.work_hours.end // 19' "$CONFIG_FILE")

# ─── Flags ───────────────────────────────────────────────────────
FORCE=false
DRY_RUN=false
for arg in "$@"; do
    [[ "$arg" == "--force" ]] && FORCE=true
    [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done

# ─── Gate: Weekend check ─────────────────────────────────────────
if [[ "$FORCE" != "true" ]] && [[ "$WEEKDAYS_ONLY" == "true" ]]; then
    DOW=$(date +%u)
    if (( DOW >= 6 )); then
        echo "[$TIMESTAMP] SKIP: Weekend (day $DOW)" >> "$LOG_FILE"
        exit 0
    fi
fi

# ─── Gate: Work hours check ──────────────────────────────────────
if [[ "$FORCE" != "true" ]]; then
    HOUR=$(date +%H)
    if (( HOUR >= WORK_END || HOUR < WORK_START )); then
        echo "[$TIMESTAMP] SKIP: Outside work hours ($HOUR:00, window: $WORK_START-$WORK_END)" >> "$LOG_FILE"
        exit 0
    fi
fi

# ─── Gate: Idempotency (skip if briefing already exists today) ───
if [[ "$FORCE" != "true" ]] && [[ -f "$BRIEFING_DIR/$TODAY.md" ]]; then
    echo "[$TIMESTAMP] SKIP: Briefing already exists for $TODAY" >> "$LOG_FILE"
    exit 0
fi

if [[ "$DRY_RUN" == "true" ]]; then
    echo "[$TIMESTAMP] DRY RUN: All gates passed. Would invoke Claude for daily briefing." >> "$LOG_FILE"
    echo "[$TIMESTAMP] Config: meetings=$MEETING_TYPE, tasks=$TASK_TYPE, comms=$COMM_TYPE" >> "$LOG_FILE"
    echo "DRY RUN complete. See $LOG_FILE"
    cat "$LOG_FILE"
    exit 0
fi

# ─── Prerequisite: Claude CLI ────────────────────────────────────
if ! command -v claude &>/dev/null; then
    echo "[$TIMESTAMP] ERROR: claude CLI not found in PATH" >> "$LOG_FILE"
    exit 1
fi

# ─── Build provider-specific instructions ────────────────────────

# --- Meetings ---
MEETING_INSTRUCTIONS=""
case "$MEETING_TYPE" in
    granola)
        MEETING_INSTRUCTIONS="Search Granola for meetings from yesterday using search_meetings. For each meeting: title, participants, duration, and whether it's design-relevant."
        ;;
    otter)
        MEETING_INSTRUCTIONS="Search Otter for transcripts from yesterday. For each: title, participants, duration, and whether it's design-relevant."
        ;;
    fireflies)
        MEETING_INSTRUCTIONS="Search Fireflies for meetings from yesterday. For each: title, participants, duration, and whether it's design-relevant."
        ;;
    google-meet)
        MEETING_INSTRUCTIONS="Search Google Calendar for yesterday's meetings, check Google Drive for any auto-generated transcripts. For each: title, participants, duration, and whether it's design-relevant."
        ;;
    notion)
        MEETING_DB=$(yq -r '.providers.meetings.config.notion_meeting_db // ""' "$CONFIG_FILE")
        MEETING_INSTRUCTIONS="Query the Notion meeting database (ID: $MEETING_DB) for yesterday's entries. For each: title, participants, and whether it's design-relevant."
        ;;
    manual)
        NOTES_DIR=$(yq -r '.providers.meetings.config.notes_dir // "~/meeting-notes"' "$CONFIG_FILE" | sed "s|^~|$HOME|")
        MEETING_INSTRUCTIONS="Search $NOTES_DIR for markdown files modified yesterday. For each: filename, content summary, and whether it's design-relevant."
        ;;
    *)
        MEETING_INSTRUCTIONS="No meeting provider configured (type: $MEETING_TYPE). Skip meeting summary."
        ;;
esac

# --- Tasks ---
TASK_INSTRUCTIONS=""
case "$TASK_TYPE" in
    jira)
        TASK_PROJECTS=$(yq -r '.providers.tasks.config.projects // [] | join(", ")' "$CONFIG_FILE")
        TASK_DESIGN_LABEL=$(yq -r '.providers.tasks.config.labels.design_work // "design-work"' "$CONFIG_FILE")
        TASK_INSTRUCTIONS="Using Atlassian MCP tools:
- Search: assignee = currentUser() AND status != Done — list active tickets
- Search: project in ($TASK_PROJECTS) AND labels = $TASK_DESIGN_LABEL AND updated >= -1d — recent design tickets
- Save results to $EXTRACTIONS_DIR/last-checks.json.
  Read the file first if it exists, then UPDATE only the 'task_morning' and 'briefing' keys:
  {
    ...existing keys preserved...,
    \"task_morning\": {\"timestamp\": \"$TIMESTAMP\", \"tickets\": [{\"key\": \"...\", \"summary\": \"...\", \"status\": \"...\", \"priority\": \"...\"}]},
    \"briefing\": {\"timestamp\": \"$TIMESTAMP\", \"source\": \"daily-briefing.sh\"}
  }
  IMPORTANT: Preserve all other keys (heartbeat, task_midday, full_scan)."
        ;;
    linear)
        TASK_TEAMS=$(yq -r '.providers.tasks.config.team_ids // [] | join(", ")' "$CONFIG_FILE")
        TASK_LABEL_GROUP=$(yq -r '.providers.tasks.config.label_group // "Design"' "$CONFIG_FILE")
        TASK_INSTRUCTIONS="Using Linear MCP: search active issues in teams: $TASK_TEAMS with label group $TASK_LABEL_GROUP. List key, title, status, priority.
Save results to $EXTRACTIONS_DIR/last-checks.json (read first, update 'task_morning' and 'briefing' keys, preserve others)."
        ;;
    github-issues)
        TASK_REPOS=$(yq -r '.providers.tasks.config.repos // [] | join(", ")' "$CONFIG_FILE")
        TASK_LABELS=$(yq -r '.providers.tasks.config.labels // [] | join(", ")' "$CONFIG_FILE")
        TASK_INSTRUCTIONS="Using gh CLI: list open issues in repos: $TASK_REPOS with labels: $TASK_LABELS assigned to current user. List number, title, status, labels.
Save results to $EXTRACTIONS_DIR/last-checks.json (read first, update 'task_morning' and 'briefing' keys, preserve others)."
        ;;
    notion)
        TASK_DB=$(yq -r '.providers.tasks.config.task_db // ""' "$CONFIG_FILE")
        TASK_INSTRUCTIONS="Query Notion task database (ID: $TASK_DB) for active items assigned to the user. List ID, title, status, priority.
Save results to $EXTRACTIONS_DIR/last-checks.json (read first, update 'task_morning' and 'briefing' keys, preserve others)."
        ;;
    none)
        TASK_INSTRUCTIONS="No task tracker configured. Skip task status section."
        ;;
    *)
        TASK_INSTRUCTIONS="Unknown task provider: $TASK_TYPE. Skip task status."
        ;;
esac

# --- Communication ---
COMM_INSTRUCTIONS=""
case "$COMM_TYPE" in
    slack-mcp)
        COMM_CHANNELS=$(yq -r '[.streams[].channels // [] | .[]] | unique | join(", ")' "$CONFIG_FILE" 2>/dev/null)
        COMM_INSTRUCTIONS="Using Slack MCP, check these channels: $COMM_CHANNELS
Look for: design tasks, requests, feedback, decisions, mentions of $USER_NAME."
        ;;
    slack-browser)
        COMM_CHANNELS=$(yq -r '[.streams[].channels // [] | .[]] | unique | join(", ")' "$CONFIG_FILE" 2>/dev/null)
        COMM_INSTRUCTIONS="Using Chrome DevTools MCP (chrome-devtools), check Slack if Chrome is running.
Channels to check: $COMM_CHANNELS
Look for: design tasks, requests, feedback, decisions, mentions of $USER_NAME.
If Chrome or Slack is not available, note 'Slack check skipped -- Chrome not available' and continue."
        ;;
    discord)
        COMM_CHANNELS=$(yq -r '[.streams[].channels // [] | .[]] | unique | join(", ")' "$CONFIG_FILE" 2>/dev/null)
        COMM_INSTRUCTIONS="Using Discord MCP, check channels: $COMM_CHANNELS
Look for: design tasks, requests, feedback, decisions."
        ;;
    teams)
        COMM_CHANNELS=$(yq -r '[.streams[].channels // [] | .[]] | unique | join(", ")' "$CONFIG_FILE" 2>/dev/null)
        COMM_INSTRUCTIONS="Using Teams MCP, check channels: $COMM_CHANNELS
Look for: design tasks, requests, feedback, decisions."
        ;;
    none)
        COMM_INSTRUCTIONS="No communication provider configured. Skip communication check."
        ;;
    *)
        COMM_INSTRUCTIONS="Unknown communication provider: $COMM_TYPE. Skip communication check."
        ;;
esac

# --- Streams ---
STREAM_LIST=$(yq -r '.streams[] | "- " + .display_name + " (project: " + .task_project_key + ")"' "$CONFIG_FILE" 2>/dev/null || echo "- No streams configured")

# --- Scoring dimensions ---
SCORING_DIMS=$(yq -r '.scoring.dimensions[] | "- " + .name + " (1-5, weight: " + (.weight | tostring) + (.description // "" | if . != "" then ", " + . else "" end) + ")" + (if .invert == true then " [INVERTED: higher = lower priority]" else "" end)' "$CONFIG_FILE" 2>/dev/null || echo "- No scoring dimensions configured")
SCORING_FORMULA=$(yq -r '
  [.scoring.dimensions[] | select(.invert != true) | .name + "*" + (.weight | tostring)] | join(" + ") | . as $pos |
  [.scoring.dimensions[] | select(.invert == true) | .name + "*" + (.weight | tostring)] | join(" + ") | . as $neg |
  if $neg != "" then "(" + $pos + ") - (" + $neg + ")" else $pos end
' "$CONFIG_FILE" 2>/dev/null || echo "weighted sum of dimensions")

# ─── Build the Claude prompt ─────────────────────────────────────

PROMPT="You are a daily design briefing agent for $USER_NAME ($USER_ROLE).

Produce a daily design briefing for $TODAY. Save it to $BRIEFING_DIR/$TODAY.md.

Work streams being tracked:
$STREAM_LIST

### 1. Yesterday's Meetings
$MEETING_INSTRUCTIONS

### 2. Task Status
$TASK_INSTRUCTIONS

### 3. Communication Highlights
$COMM_INSTRUCTIONS

### 4. Current Priorities
Read $BACKLOG_FILE for current design priorities (if it exists).
Read $DECISIONS_DIR/decision-log.md for recent decisions (if it exists).

### 5. Inbox Check
Read $INBOX_FILE — summarize any unprocessed items (if it exists).

### 6. Produce Briefing
Save to $BRIEFING_DIR/$TODAY.md with this format:

# Design Briefing — $TODAY

## Yesterday's Design-Relevant Meetings
| # | Meeting | Participants | Key Design Items |
|---|---------|-------------|-----------------|

## Task Status
- [Active tasks by stream, status, priority]

## Communication Highlights
- [Design-relevant messages from configured channels]

## Unprocessed Inbox Items
- [Items from inbox]

## Current Backlog Priorities
- [Top 3-5 items from backlog]

## Recommended Focus Today
- [What to work on based on urgency and priorities]

Be concise. Focus on actionable items."

echo "[$TIMESTAMP] Running Claude agent (briefing phase)..." >> "$LOG_FILE"

perl -e 'alarm 300; exec @ARGV' claude --print --dangerously-skip-permissions "$PROMPT" >> "$LOG_FILE" 2>&1 || {
    echo "[$TIMESTAMP] Briefing agent timed out or errored" >> "$LOG_FILE"
}

echo "[$TIMESTAMP] Briefing phase complete" >> "$LOG_FILE"

# ─── Auto-generate decision-log.md from DDR files ────────────────
echo "[$TIMESTAMP] Regenerating decision-log.md from DDR files..." >> "$LOG_FILE"

python3 << PYEOF 2>> "$LOG_FILE" || echo "[$TIMESTAMP] WARNING: decision-log generation failed" >> "$LOG_FILE"
import os, re, glob

decisions_dir = os.path.expanduser("$DECISIONS_DIR")
pending = glob.glob(os.path.join(decisions_dir, "pending", "*.md"))
accepted = glob.glob(os.path.join(decisions_dir, "accepted", "*.md"))
all_ddrs = pending + accepted

rows = []
for path in sorted(all_ddrs):
    filename = os.path.basename(path)
    # Extract number from DDR-NNN-title.md pattern
    num_match = re.match(r"(?:ddr-?)?(\d+)", filename, re.IGNORECASE)
    if not num_match:
        continue
    num = num_match.group(1)

    with open(path) as f:
        content = f.read()

    # Parse frontmatter-style fields from the DDR body
    title = filename.replace(".md", "").split("-", 2)[-1].replace("-", " ").title() if len(filename.split("-")) > 2 else filename
    title_match = re.search(r"^# DDR-\d+:\s*(.+)", content, re.MULTILINE)
    if title_match:
        title = title_match.group(1).strip()

    date = "---"
    date_match = re.search(r"\*\*Date\*\*:\s*(\S+)", content)
    if date_match:
        date = date_match.group(1)

    status = "Proposed"
    status_match = re.search(r"\*\*Status\*\*:\s*(\S+)", content)
    if status_match:
        status = status_match.group(1)

    stream = "---"
    stream_match = re.search(r"\*\*Stream\*\*:\s*(.+?)(?:\n|\*)", content)
    if stream_match:
        stream = stream_match.group(1).strip()

    # Determine folder as fallback for status
    if "/accepted/" in path and status == "Proposed":
        status = "Accepted"

    rows.append((int(num), num, title, status, date, stream))

rows.sort(key=lambda r: r[0])

# Read stream names from config for the header
stream_names = "configured work streams"

lines = [
    "# Design Decision Log\n",
    "",
    "Track all design decisions across " + stream_names + ".",
    "Auto-generated from DDR files in pending/ and accepted/. Do not edit manually.",
    "",
    "| # | Decision | Status | Date | Stream | Impact | Source Meetings |",
    "|---|----------|--------|------|--------|--------|-----------------|",
]

if rows:
    for _, num, title, status, date, stream in rows:
        lines.append(f"| {num} | {title} | {status} | {date} | {stream} | --- | --- |")
else:
    lines.append("| --- | No decisions recorded yet | --- | --- | --- | --- | --- |")

lines.append("")
lines.append("<!--")
lines.append("Auto-generated by daily-briefing.sh from DDR files.")
lines.append("Status values: Proposed | Accepted | Rejected | Superseded")
lines.append("-->")

log_path = os.path.join(decisions_dir, "decision-log.md")
with open(log_path, "w") as f:
    f.write("\n".join(lines) + "\n")

print(f"decision-log.md regenerated with {len(rows)} entries")
PYEOF

echo "[$TIMESTAMP] Decision-log regeneration complete" >> "$LOG_FILE"

# ─── Triage Phase: Score and classify briefing items ─────────────
echo "[$TIMESTAMP] Starting triage phase..." >> "$LOG_FILE"

TRIAGE_FILE="$EXTRACTIONS_DIR/triage-$TODAY.json"

# Only run triage if briefing was actually produced
if [[ -f "$BRIEFING_DIR/$TODAY.md" ]]; then

    # Build task sync instructions based on provider
    TASK_SYNC_INSTRUCTIONS=""
    case "$TASK_TYPE" in
        jira)
            TASK_PHASE_PREFIX=$(yq -r '.providers.tasks.config.labels.phase_prefix // "design-"' "$CONFIG_FILE")
            TASK_STREAM_PREFIX=$(yq -r '.providers.tasks.config.labels.stream_prefix // "design-stream-"' "$CONFIG_FILE")
            TASK_DESIGN_LABEL=$(yq -r '.providers.tasks.config.labels.design_work // "design-work"' "$CONFIG_FILE")
            TASK_SYNC_INSTRUCTIONS="TASK SYNC (after triage):
For each new item added to the backlog during triage:
1. If no task key exists: create a Jira issue using createJiraIssue via Atlassian MCP in the correct project.
   - Set summary (prefix with [Design]), description from triage context
   - Set labels: [$TASK_DESIGN_LABEL, ${TASK_PHASE_PREFIX}{phase}, ${TASK_STREAM_PREFIX}{stream}]
   - Phase mapping: RESEARCH->${TASK_PHASE_PREFIX}research, BUILD->${TASK_PHASE_PREFIX}build, REVIEW->${TASK_PHASE_PREFIX}review, DESIGN->${TASK_PHASE_PREFIX}design, DISCUSS->${TASK_PHASE_PREFIX}research
   - Write the returned key back into the backlog and triage JSON
2. If task key already exists: ensure the $TASK_DESIGN_LABEL label is present. Update the phase label if changed.
3. Always preserve existing labels on tickets when adding new ones."
            ;;
        linear)
            TASK_SYNC_INSTRUCTIONS="TASK SYNC (after triage):
For each new item: create a Linear issue in the appropriate team. Set labels from config label_group. Write the returned ID back to backlog and triage JSON."
            ;;
        github-issues)
            TASK_SYNC_INSTRUCTIONS="TASK SYNC (after triage):
For each new item: create a GitHub issue in the appropriate repo using gh CLI. Apply configured labels. Write the returned issue number back to backlog and triage JSON."
            ;;
        notion)
            TASK_DB=$(yq -r '.providers.tasks.config.task_db // ""' "$CONFIG_FILE")
            TASK_SYNC_INSTRUCTIONS="TASK SYNC (after triage):
For each new item: create a page in Notion task database (ID: $TASK_DB). Set status, priority, and stream properties. Write the returned page ID back to backlog and triage JSON."
            ;;
        none)
            TASK_SYNC_INSTRUCTIONS="No task tracker configured. Skip task sync."
            ;;
    esac

    TRIAGE_PROMPT="Read the briefing at $BRIEFING_DIR/$TODAY.md.
Read $BACKLOG_FILE (if it exists).

For each actionable item in the briefing that isn't already in the backlog:
1. Score it using these dimensions:
$SCORING_DIMS

   Priority formula: $SCORING_FORMULA

2. Add it to $BACKLOG_FILE in the Queued section (include Phase column)
3. Classify it: RESEARCH | BUILD | REVIEW | DISCUSS | DEFER
4. Mark whether it can be worked independently (no dependencies on other items)

Write triage results to $TRIAGE_FILE:
{
  \"date\": \"$TODAY\",
  \"items_scored\": N,
  \"items_added_to_backlog\": N,
  \"ready_for_parallel\": [
    {\"item\": \"...\", \"stream\": \"...\", \"type\": \"RESEARCH|BUILD|REVIEW|DISCUSS|DEFER\", \"priority\": N, \"independent\": true, \"task_key\": \"...\" or null}
  ]
}

$TASK_SYNC_INSTRUCTIONS

Be concise. Only add genuinely new items. If no new items found, write the JSON with items_scored: 0."

    perl -e 'alarm 300; exec @ARGV' claude --print --dangerously-skip-permissions "$TRIAGE_PROMPT" >> "$LOG_FILE" 2>&1 || {
        echo "[$TIMESTAMP] Triage phase timed out or errored" >> "$LOG_FILE"
    }

    echo "[$TIMESTAMP] Triage phase complete" >> "$LOG_FILE"
else
    echo "[$TIMESTAMP] SKIP triage: No briefing file produced for $TODAY" >> "$LOG_FILE"
fi

# ─── Clean up old logs ───────────────────────────────────────────
find "$LOG_DIR" -name "briefing-*.log" -mtime +7 -delete 2>/dev/null || true

echo "[$TIMESTAMP] Daily briefing script finished" >> "$LOG_FILE"
