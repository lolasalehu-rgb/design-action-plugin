#!/bin/bash
# Mid-Day Task Check Script (config-driven, provider-agnostic)
# Checks task tracker for changes since the morning briefing baseline.
# Reads all settings from ~/.design-action/config.yaml via yq.
#
# Scheduled trigger: e.g., 12 PM weekdays via launchd/systemd/cron
# Manual run: bash task-check.sh
# Force (bypass all gates): bash task-check.sh --force
# Dry run (test gates, no Claude): bash task-check.sh --dry-run

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
EXTRACTIONS_DIR=$(yq -r '.paths.extractions // "~/.design-action/extractions"' "$CONFIG_FILE" | sed "s|^~|$HOME|")
BACKLOG_FILE=$(yq -r '.paths.backlog // "~/.design-action/backlog.md"' "$CONFIG_FILE" | sed "s|^~|$HOME|")
INBOX_FILE=$(yq -r '.paths.inbox // "~/.design-action/inbox.md"' "$CONFIG_FILE" | sed "s|^~|$HOME|")

mkdir -p "$LOG_DIR" "$EXTRACTIONS_DIR"

TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S")
LOG_FILE="$LOG_DIR/task-check-$TIMESTAMP.log"
CHECKS_FILE="$EXTRACTIONS_DIR/last-checks.json"

echo "[$TIMESTAMP] Task check starting..." > "$LOG_FILE"

# Read identity
USER_NAME=$(yq -r '.user.name // "User"' "$CONFIG_FILE")
USER_ROLE=$(yq -r '.user.role // "Designer"' "$CONFIG_FILE")

# Read provider types
TASK_TYPE=$(yq -r '.providers.tasks.type // "none"' "$CONFIG_FILE")
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

# ─── Gate: No task tracker ────────────────────────────────────────
if [[ "$TASK_TYPE" == "none" ]]; then
    echo "[$TIMESTAMP] SKIP: No task tracker configured (providers.tasks.type = none)" >> "$LOG_FILE"
    echo "No task tracker configured. Set providers.tasks.type in $CONFIG_FILE"
    exit 0
fi

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

if [[ "$DRY_RUN" == "true" ]]; then
    echo "[$TIMESTAMP] DRY RUN: All gates passed. Would invoke Claude for task check (provider: $TASK_TYPE)." >> "$LOG_FILE"
    echo "DRY RUN complete. See $LOG_FILE"
    cat "$LOG_FILE"
    exit 0
fi

# ─── Prerequisite: Claude CLI ────────────────────────────────────
if ! command -v claude &>/dev/null; then
    echo "[$TIMESTAMP] ERROR: claude CLI not found in PATH" >> "$LOG_FILE"
    exit 1
fi

# ─── Build notification instructions ─────────────────────────────
NOTIFY_INSTRUCTIONS=""
case "$NOTIFICATION_TYPE" in
    macos)
        NOTIFY_INSTRUCTIONS="If any high-priority items found (P1/P2, blockers, or newly assigned), append to $INBOX_FILE and send macOS notification:
osascript -e 'display notification \"MESSAGE\" with title \"Task Check\" subtitle \"STREAM\" sound name \"Submarine\"'"
        ;;
    notify-send)
        NOTIFY_INSTRUCTIONS="If any high-priority items found (P1/P2, blockers, or newly assigned), append to $INBOX_FILE and send desktop notification:
notify-send -u critical 'Task Check' 'MESSAGE'"
        ;;
    none)
        NOTIFY_INSTRUCTIONS="If any high-priority items found (P1/P2, blockers, or newly assigned), append to $INBOX_FILE."
        ;;
esac

# ─── Build task-specific prompt ──────────────────────────────────
TASK_QUERY_INSTRUCTIONS=""
TASK_SAVE_INSTRUCTIONS=""
BACKLOG_SYNC_INSTRUCTIONS=""

# Common: streams info
STREAM_LIST=$(yq -r '.streams[] | "- " + .display_name + " (project: " + .task_project_key + ")"' "$CONFIG_FILE" 2>/dev/null || echo "- No streams configured")

case "$TASK_TYPE" in
    jira)
        TASK_PROJECTS=$(yq -r '.providers.tasks.config.projects // [] | join(", ")' "$CONFIG_FILE")
        TASK_DESIGN_LABEL=$(yq -r '.providers.tasks.config.labels.design_work // "design-work"' "$CONFIG_FILE")
        TASK_PHASE_PREFIX=$(yq -r '.providers.tasks.config.labels.phase_prefix // "design-"' "$CONFIG_FILE")

        TASK_QUERY_INSTRUCTIONS="Using the Atlassian MCP tools, perform these checks:

### 1. Tickets Assigned to User
Search JQL: assignee = currentUser() AND status != Done ORDER BY updated DESC
Report: ticket key, summary, status, last update

### 2. Recent Design-Tagged Tickets
Search JQL: project in ($TASK_PROJECTS) AND labels = $TASK_DESIGN_LABEL AND updated >= -1d ORDER BY updated DESC
Report: ticket key, summary, status, assignee

### 3. Status Changes Since Morning
Search JQL: project in ($TASK_PROJECTS) AND status changed AFTER -4h ORDER BY updated DESC
Report: ticket key, from-status, to-status, summary"

        TASK_SAVE_INSTRUCTIONS="### 4. Compare with Morning Baseline
Read $CHECKS_FILE and look at the 'task_morning' key (written by the morning briefing).
Only highlight items that are NEW or CHANGED since the morning scan.
If the file or key doesn't exist, report all items.

### 5. Save Results
Read the existing $CHECKS_FILE first (preserve all existing keys).
Then UPDATE it by adding/overwriting ONLY the 'task_midday' key:
{
  ...existing keys preserved...,
  \"task_midday\": {
    \"timestamp\": \"$TIMESTAMP\",
    \"source\": \"task-check\",
    \"assigned_to_user\": [{\"key\": \"...\", \"summary\": \"...\", \"status\": \"...\"}],
    \"design_tagged_recent\": [{\"key\": \"...\", \"summary\": \"...\", \"status\": \"...\"}],
    \"status_changes\": [{\"key\": \"...\", \"summary\": \"...\", \"from\": \"...\", \"to\": \"...\"}],
    \"delta\": [{\"type\": \"new|changed\", \"key\": \"...\", \"summary\": \"...\"}]
  }
}
IMPORTANT: Read the file first, merge your key in, then write the full file back.
Do NOT overwrite other keys (heartbeat, task_morning, briefing, full_scan)."

        BACKLOG_SYNC_INSTRUCTIONS="BACKLOG SYNC (after delta detection):
Read $BACKLOG_FILE. For each status change in the delta:
1. Find the ticket key in the task key column of the backlog.
2. If found: update the Status and Phase columns to match the new Jira state.
   - Jira status mapping: To Do -> RESEARCH, In Progress -> BUILD, In Review/Waiting for approval -> REVIEW, Done -> DONE
   - Phase label mapping: RESEARCH -> ${TASK_PHASE_PREFIX}research, BUILD -> ${TASK_PHASE_PREFIX}build, REVIEW -> ${TASK_PHASE_PREFIX}review, DONE -> (no phase label needed)
3. If status = Done: move the row from Active/Queued section to the Completed section, adding today's date.
4. Write the updated backlog file back."
        ;;

    linear)
        TASK_TEAMS=$(yq -r '.providers.tasks.config.team_ids // [] | join(", ")' "$CONFIG_FILE")
        TASK_LABEL_GROUP=$(yq -r '.providers.tasks.config.label_group // "Design"' "$CONFIG_FILE")

        TASK_QUERY_INSTRUCTIONS="Using Linear MCP tools, perform these checks:

### 1. Issues Assigned to User
Search active issues assigned to current user in teams: $TASK_TEAMS
Report: identifier, title, status, priority, last update

### 2. Recent Design-Labeled Issues
Search issues with label group $TASK_LABEL_GROUP updated in the last day in teams: $TASK_TEAMS
Report: identifier, title, status, assignee

### 3. Status Changes Since Morning
Search issues in teams: $TASK_TEAMS with status changes in the last 4 hours
Report: identifier, title, from-status, to-status"

        TASK_SAVE_INSTRUCTIONS="### 4. Compare with Morning Baseline
Read $CHECKS_FILE and look at the 'task_morning' key.
Only highlight items that are NEW or CHANGED since the morning scan.
If the file or key doesn't exist, report all items.

### 5. Save Results
Read $CHECKS_FILE first (preserve all existing keys).
UPDATE only the 'task_midday' key with: timestamp, assigned issues, design-labeled issues, status changes, and delta from morning."

        BACKLOG_SYNC_INSTRUCTIONS="BACKLOG SYNC (after delta detection):
Read $BACKLOG_FILE. For each status change in the delta:
1. Find the issue identifier in the task key column.
2. If found: update Status and Phase columns.
   - Linear status mapping: Backlog/Triage -> RESEARCH, In Progress -> BUILD, In Review -> REVIEW, Done/Canceled -> DONE
3. If status = Done: move to Completed section with today's date.
4. Write updated backlog file back."
        ;;

    github-issues)
        TASK_REPOS=$(yq -r '.providers.tasks.config.repos // [] | join(", ")' "$CONFIG_FILE")
        TASK_LABELS=$(yq -r '.providers.tasks.config.labels // [] | join(", ")' "$CONFIG_FILE")

        TASK_QUERY_INSTRUCTIONS="Using gh CLI, perform these checks:

### 1. Issues Assigned to User
For each repo in ($TASK_REPOS): gh issue list --assignee @me --state open
Report: number, title, labels, last update

### 2. Recent Design-Labeled Issues
For each repo: gh issue list --label \"$TASK_LABELS\" --state open --json number,title,assignees,updatedAt
Filter to issues updated in the last day.

### 3. Recently Closed Issues
For each repo: gh issue list --assignee @me --state closed --json number,title,closedAt
Filter to issues closed in the last 4 hours."

        TASK_SAVE_INSTRUCTIONS="### 4. Compare with Morning Baseline
Read $CHECKS_FILE and look at the 'task_morning' key.
Only highlight items that are NEW or CHANGED since the morning scan.

### 5. Save Results
Read $CHECKS_FILE first (preserve all existing keys).
UPDATE only the 'task_midday' key with: timestamp, assigned issues, design-labeled issues, recently closed, and delta."

        BACKLOG_SYNC_INSTRUCTIONS="BACKLOG SYNC (after delta detection):
Read $BACKLOG_FILE. For each change in the delta:
1. Find the issue number in the task key column.
2. If found: update Status column. If closed -> DONE, move to Completed section.
3. Write updated backlog file back."
        ;;

    notion)
        TASK_DB=$(yq -r '.providers.tasks.config.task_db // ""' "$CONFIG_FILE")

        TASK_QUERY_INSTRUCTIONS="Using Notion MCP tools, perform these checks:

### 1. Tasks Assigned to User
Query database $TASK_DB for items assigned to current user with status != Done.
Report: page ID, title, status, priority, last edited

### 2. Recently Updated Design Tasks
Query database $TASK_DB for items with a design tag/type, edited in last day.
Report: page ID, title, status, last edited

### 3. Status Changes
Query database $TASK_DB sorted by last edited, filter to last 4 hours.
Compare current status against morning baseline to detect changes."

        TASK_SAVE_INSTRUCTIONS="### 4. Compare with Morning Baseline
Read $CHECKS_FILE and look at the 'task_morning' key.
Only highlight items that are NEW or CHANGED.

### 5. Save Results
Read $CHECKS_FILE first (preserve all existing keys).
UPDATE only the 'task_midday' key with: timestamp, assigned tasks, design tasks, status changes, and delta."

        BACKLOG_SYNC_INSTRUCTIONS="BACKLOG SYNC (after delta detection):
Read $BACKLOG_FILE. For each status change in the delta:
1. Find the task ID/title in the backlog.
2. If found: update Status and Phase columns to match.
3. If status = Done: move to Completed section with today's date.
4. Write updated backlog file back."
        ;;
esac

# ─── Assemble the full prompt ────────────────────────────────────

PROMPT="You are a task intelligence agent for $USER_NAME ($USER_ROLE).

Work streams being tracked:
$STREAM_LIST

$TASK_QUERY_INSTRUCTIONS

$TASK_SAVE_INSTRUCTIONS

$NOTIFY_INSTRUCTIONS

$BACKLOG_SYNC_INSTRUCTIONS

Be concise. Minimize token usage."

echo "[$TIMESTAMP] Invoking Claude (provider: $TASK_TYPE)..." >> "$LOG_FILE"

perl -e 'alarm 300; exec @ARGV' claude --print --dangerously-skip-permissions "$PROMPT" >> "$LOG_FILE" 2>&1 || {
    echo "[$TIMESTAMP] Task check timed out or errored" >> "$LOG_FILE"
}

echo "[$TIMESTAMP] Task check complete" >> "$LOG_FILE"

# ─── Clean up old logs ───────────────────────────────────────────
find "$LOG_DIR" -name "task-check-*.log" -mtime +7 -delete 2>/dev/null || true
