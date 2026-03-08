#!/bin/bash
set -euo pipefail

# =============================================================================
# design-action heartbeat — event-driven meeting watcher
# Triggered by file changes (launchd WatchPaths) or polling (systemd/cron).
# Reads all config from ~/.design-action/config.yaml via yq.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$HOME/.design-action/config.yaml"

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "ERROR: Config not found at $CONFIG_FILE"
  echo "Run: design-action init"
  exit 1
fi

for cmd in yq claude python3; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: Required command '$cmd' not found in PATH"
    exit 1
  fi
done

# ---------------------------------------------------------------------------
# Read config
# ---------------------------------------------------------------------------
DATA_DIR="$(yq -r '.paths.data_dir // "~/.design-action"' "$CONFIG_FILE" | sed "s|^~|$HOME|")"
LOG_DIR="$DATA_DIR/logs"
STATE_FILE="$DATA_DIR/state/heartbeat-state.json"
LAST_CHECKS="$DATA_DIR/last-checks.json"
INBOX="$DATA_DIR/inbox.md"

MEETING_PROVIDER="$(yq -r '.providers.meetings // "manual"' "$CONFIG_FILE")"
NOTES_DIR="$(yq -r '.providers.notes_dir // ""' "$CONFIG_FILE" | sed "s|^~|$HOME|")"
TASK_PROVIDER="$(yq -r '.providers.tasks // "none"' "$CONFIG_FILE")"

WORK_START="$(yq -r '.schedule.work_hours.start // 7' "$CONFIG_FILE")"
WORK_END="$(yq -r '.schedule.work_hours.end // 19' "$CONFIG_FILE")"
WEEKDAYS_ONLY="$(yq -r '.schedule.weekdays_only // true' "$CONFIG_FILE")"
THROTTLE_MINUTES="$(yq -r '.schedule.throttle_minutes // 10' "$CONFIG_FILE")"

NOTIFICATION="$(yq -r '.notifications.type // "none"' "$CONFIG_FILE")"

mkdir -p "$LOG_DIR" "$DATA_DIR/state" "$DATA_DIR/briefings" "$DATA_DIR/extractions"

# ---------------------------------------------------------------------------
# CLI flags
# ---------------------------------------------------------------------------
FORCE=false
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --force)   FORCE=true ;;
    --dry-run) DRY_RUN=true ;;
  esac
done

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
LOGFILE="$LOG_DIR/heartbeat-$(date +%Y%m%d).log"
log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOGFILE"; }

log "=== Heartbeat triggered (provider=$MEETING_PROVIDER, force=$FORCE, dry_run=$DRY_RUN) ==="

# ---------------------------------------------------------------------------
# Gate 1: Time gate
# ---------------------------------------------------------------------------
if [[ "$FORCE" != "true" ]]; then
  CURRENT_HOUR=$(date +%H | sed 's/^0//')
  CURRENT_DOW=$(date +%u)  # 1=Mon, 7=Sun

  if [[ "$WEEKDAYS_ONLY" == "true" ]] && (( CURRENT_DOW > 5 )); then
    log "SKIP: Weekend (day=$CURRENT_DOW)"
    exit 0
  fi

  if (( CURRENT_HOUR < WORK_START || CURRENT_HOUR >= WORK_END )); then
    log "SKIP: Outside work hours ($WORK_START-$WORK_END, current=$CURRENT_HOUR)"
    exit 0
  fi
fi

# ---------------------------------------------------------------------------
# Gate 2: Meeting count gate (providers with local cache files only)
# ---------------------------------------------------------------------------
get_watch_path() {
  case "$MEETING_PROVIDER" in
    granola)
      echo "$HOME/Library/Application Support/Granola/cache-v4.json"
      ;;
    manual)
      echo "$NOTES_DIR"
      ;;
    *)
      echo ""
      ;;
  esac
}

WATCH_PATH="$(get_watch_path)"

if [[ "$FORCE" != "true" ]] && [[ -n "$WATCH_PATH" ]] && [[ -f "$WATCH_PATH" || -d "$WATCH_PATH" ]]; then
  # Count current items
  CURRENT_COUNT=0
  case "$MEETING_PROVIDER" in
    granola)
      if [[ -f "$WATCH_PATH" ]]; then
        CURRENT_COUNT=$(python3 -c "
import json, sys
try:
    with open('$WATCH_PATH') as f:
        data = json.load(f)
    if isinstance(data, dict):
        print(len(data.get('documents', data.get('meetings', []))))
    elif isinstance(data, list):
        print(len(data))
    else:
        print(0)
except Exception:
    print(0)
" 2>/dev/null || echo "0")
      fi
      ;;
    manual)
      if [[ -d "$WATCH_PATH" ]]; then
        CURRENT_COUNT=$(find "$WATCH_PATH" -type f -name '*.md' -o -name '*.txt' | wc -l | tr -d ' ')
      fi
      ;;
  esac

  # Compare with stored count
  PREV_COUNT=0
  if [[ -f "$STATE_FILE" ]]; then
    PREV_COUNT=$(python3 -c "
import json
try:
    with open('$STATE_FILE') as f:
        print(json.load(f).get('meeting_count', 0))
except Exception:
    print(0)
" 2>/dev/null || echo "0")
  fi

  if (( CURRENT_COUNT <= PREV_COUNT )); then
    log "SKIP: No new items (current=$CURRENT_COUNT, previous=$PREV_COUNT)"
    exit 0
  fi

  log "New items detected: $PREV_COUNT → $CURRENT_COUNT"
fi

# ---------------------------------------------------------------------------
# Gate 3: Timestamp / throttle gate
# ---------------------------------------------------------------------------
if [[ "$FORCE" != "true" ]]; then
  THROTTLE_SECONDS=$((THROTTLE_MINUTES * 60))
  LAST_RUN=0
  if [[ -f "$LAST_CHECKS" ]]; then
    LAST_RUN=$(python3 -c "
import json, datetime
try:
    with open('$LAST_CHECKS') as f:
        ts = json.load(f).get('heartbeat', '')
    if ts:
        dt = datetime.datetime.fromisoformat(ts.replace('Z', '+00:00'))
        print(int(dt.timestamp()))
    else:
        print(0)
except Exception:
    print(0)
" 2>/dev/null || echo "0")
  fi

  NOW_EPOCH=$(date +%s)
  ELAPSED=$((NOW_EPOCH - LAST_RUN))

  if (( ELAPSED < THROTTLE_SECONDS )); then
    log "SKIP: Throttled (${ELAPSED}s < ${THROTTLE_SECONDS}s)"
    exit 0
  fi
fi

# ---------------------------------------------------------------------------
# Build Claude prompt
# ---------------------------------------------------------------------------
SINCE="$(date -v-2H '+%Y-%m-%d %H:%M' 2>/dev/null || date -d '2 hours ago' '+%Y-%m-%d %H:%M' 2>/dev/null || date '+%Y-%m-%d')"

case "$MEETING_PROVIDER" in
  granola)
    MEETING_INSTRUCTION="Check Granola for new meetings since $SINCE. Use the Granola MCP tools to retrieve recent meeting data."
    ;;
  otter)
    MEETING_INSTRUCTION="Check Otter for new transcripts since $SINCE."
    ;;
  fireflies)
    MEETING_INSTRUCTION="Check Fireflies for new meetings since $SINCE."
    ;;
  manual)
    MEETING_INSTRUCTION="Check $NOTES_DIR for new or modified files since $SINCE. Look for meeting notes, action items, and design decisions."
    ;;
  google-meet)
    MEETING_INSTRUCTION="Check for new Google Meet meetings since $SINCE."
    ;;
  notion)
    MEETING_INSTRUCTION="Check Notion for new meeting notes since $SINCE."
    ;;
  *)
    MEETING_INSTRUCTION="Check for new meetings since $SINCE."
    ;;
esac

TASK_INSTRUCTION=""
if [[ "$TASK_PROVIDER" != "none" ]]; then
  TASK_INSTRUCTION="
Also tag any extracted items for the task provider ($TASK_PROVIDER):
- If you find action items, format them for $TASK_PROVIDER integration.
- Use labels/tags consistent with the user's workflow."
fi

PROMPT="You are the design-action heartbeat agent. Your job is to check for new meeting content and extract actionable items.

$MEETING_INSTRUCTION
$TASK_INSTRUCTION

For each new meeting found:
1. Extract key decisions, action items, and design-relevant notes
2. Append findings to $INBOX using this format:
   ## [Meeting Title] — [Date]
   **Source:** $MEETING_PROVIDER
   - Decision: ...
   - Action: ...
   - Note: ...
3. If no new meetings are found, report that and exit.

Be concise. Focus on design decisions, feedback, and actionable items."

# ---------------------------------------------------------------------------
# Execute (or dry-run)
# ---------------------------------------------------------------------------
if [[ "$DRY_RUN" == "true" ]]; then
  log "DRY RUN — would send to Claude:"
  log "---"
  echo "$PROMPT" | tee -a "$LOGFILE"
  log "---"
  log "DRY RUN complete"
  exit 0
fi

log "Sending to Claude..."
RESULT=$(timeout 300 claude --print "$PROMPT" 2>&1) || {
  log "ERROR: Claude invocation failed (exit=$?)"
  exit 1
}

log "Claude response received (${#RESULT} chars)"
echo "$RESULT" >> "$LOGFILE"

# ---------------------------------------------------------------------------
# Post-run: update state
# ---------------------------------------------------------------------------

# Update last-checks.json
NOW_ISO="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
python3 -c "
import json, os
path = '$LAST_CHECKS'
data = {}
if os.path.exists(path):
    try:
        with open(path) as f:
            data = json.load(f)
    except Exception:
        pass
data['heartbeat'] = '$NOW_ISO'
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
"

# Update state file with meeting count
if [[ -n "${CURRENT_COUNT:-}" ]]; then
  python3 -c "
import json, os
path = '$STATE_FILE'
data = {}
if os.path.exists(path):
    try:
        with open(path) as f:
            data = json.load(f)
    except Exception:
        pass
data['meeting_count'] = $CURRENT_COUNT
data['last_run'] = '$NOW_ISO'
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
"
fi

# ---------------------------------------------------------------------------
# Notification
# ---------------------------------------------------------------------------
notify() {
  local msg="$1"
  case "$NOTIFICATION" in
    macos)
      osascript -e "display notification \"$msg\" with title \"Design Action\"" 2>/dev/null || true
      ;;
    notify-send)
      notify-send "Design Action" "$msg" 2>/dev/null || true
      ;;
    none)
      ;;
  esac
}

# Notify if new items were processed
if echo "$RESULT" | grep -qi "decision\|action\|meeting"; then
  notify "Heartbeat: new meeting content processed"
fi

# ---------------------------------------------------------------------------
# Log cleanup (keep 2 days)
# ---------------------------------------------------------------------------
find "$LOG_DIR" -name 'heartbeat-*.log' -mtime +2 -delete 2>/dev/null || true

log "=== Heartbeat complete ==="
