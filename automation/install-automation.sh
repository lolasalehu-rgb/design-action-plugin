#!/bin/bash
set -euo pipefail

# =============================================================================
# design-action automation installer
# Reads config from ~/.design-action/config.yaml, generates and installs
# platform-specific scheduled tasks (launchd / systemd / cron).
# =============================================================================

CONFIG="$HOME/.design-action/config.yaml"
PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
AUTOMATION_DIR="$PLUGIN_DIR/automation"

LAUNCHD_TEMPLATE_DIR="$AUTOMATION_DIR/launchd"
SYSTEMD_TEMPLATE_DIR="$AUTOMATION_DIR/systemd"
CRON_TEMPLATE_DIR="$AUTOMATION_DIR/cron"

PLIST_DEST="$HOME/Library/LaunchAgents"
SYSTEMD_DEST="$HOME/.config/systemd/user"

ACTION=""
for arg in "$@"; do
  case "$arg" in
    --uninstall) ACTION="uninstall" ;;
    --help|-h)
      echo "Usage: install-automation.sh [--uninstall]"
      echo "  Reads ~/.design-action/config.yaml and installs scheduled tasks."
      echo "  --uninstall  Remove all installed automation"
      exit 0
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------------------------
check_deps() {
  local missing=()
  for cmd in yq python3 claude; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done
  if (( ${#missing[@]} > 0 )); then
    echo "ERROR: Missing required commands: ${missing[*]}"
    echo "Install them before running this script."
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Read config
# ---------------------------------------------------------------------------
read_config() {
  if [[ ! -f "$CONFIG" ]]; then
    echo "ERROR: Config not found at $CONFIG"
    echo "Run: design-action init"
    exit 1
  fi

  DATA_DIR="$(yq -r '.paths.data_dir // "~/.design-action"' "$CONFIG" | sed "s|^~|$HOME|")"
  LOG_DIR="$DATA_DIR/logs"

  MEETING_PROVIDER="$(yq -r '.providers.meetings // "manual"' "$CONFIG")"
  NOTES_DIR="$(yq -r '.providers.notes_dir // ""' "$CONFIG" | sed "s|^~|$HOME|")"
  TASK_PROVIDER="$(yq -r '.providers.tasks // "none"' "$CONFIG")"

  BRIEFING_TIME="$(yq -r '.schedule.briefing_time // "08:00"' "$CONFIG")"
  TASK_CHECK_TIME="$(yq -r '.schedule.task_check_time // "12:00"' "$CONFIG")"
  THROTTLE_MINUTES="$(yq -r '.schedule.throttle_minutes // 10' "$CONFIG")"
  POLLING_INTERVAL="$(yq -r '.schedule.polling_interval_minutes // 15' "$CONFIG")"

  BRIEFING_HOUR="${BRIEFING_TIME%%:*}"
  BRIEFING_MINUTE="${BRIEFING_TIME##*:}"
  # Strip leading zeros for plist integer fields
  BRIEFING_HOUR=$((10#$BRIEFING_HOUR))
  BRIEFING_MINUTE=$((10#$BRIEFING_MINUTE))

  TASK_CHECK_HOUR="${TASK_CHECK_TIME%%:*}"
  TASK_CHECK_MINUTE="${TASK_CHECK_TIME##*:}"
  TASK_CHECK_HOUR=$((10#$TASK_CHECK_HOUR))
  TASK_CHECK_MINUTE=$((10#$TASK_CHECK_MINUTE))

  THROTTLE_SECONDS=$((THROTTLE_MINUTES * 60))

  # Build PATH that includes common tool locations
  TOOL_PATH="/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin:$HOME/.local/bin:$HOME/.cargo/bin"

  # Determine watch path based on provider
  case "$MEETING_PROVIDER" in
    granola)
      WATCH_PATH="$HOME/Library/Application Support/Granola/cache-v4.json"
      ;;
    manual)
      WATCH_PATH="$NOTES_DIR"
      ;;
    *)
      WATCH_PATH=""
      ;;
  esac

  mkdir -p "$LOG_DIR"
}

# ---------------------------------------------------------------------------
# Template expansion helper
# ---------------------------------------------------------------------------
expand_template() {
  local template="$1"
  local output="$2"

  sed \
    -e "s|{{SCRIPT_PATH_HEARTBEAT}}|$AUTOMATION_DIR/heartbeat.sh|g" \
    -e "s|{{SCRIPT_PATH_BRIEFING}}|$PLUGIN_DIR/scripts/daily-briefing.sh|g" \
    -e "s|{{SCRIPT_PATH_TASK_CHECK}}|$PLUGIN_DIR/scripts/task-check.sh|g" \
    -e "s|{{BRIEFING_HOUR}}|$BRIEFING_HOUR|g" \
    -e "s|{{BRIEFING_MINUTE}}|$BRIEFING_MINUTE|g" \
    -e "s|{{TASK_CHECK_HOUR}}|$TASK_CHECK_HOUR|g" \
    -e "s|{{TASK_CHECK_MINUTE}}|$TASK_CHECK_MINUTE|g" \
    -e "s|{{THROTTLE_SECONDS}}|$THROTTLE_SECONDS|g" \
    -e "s|{{POLLING_SECONDS}}|$((POLLING_INTERVAL * 60))|g" \
    -e "s|{{LOG_DIR}}|$LOG_DIR|g" \
    -e "s|{{DATA_DIR}}|$DATA_DIR|g" \
    -e "s|{{PATH}}|$TOOL_PATH|g" \
    -e "s|{{WATCH_PATH}}|$WATCH_PATH|g" \
    -e "s|{{PLUGIN_DIR}}|$PLUGIN_DIR|g" \
    "$template" > "$output"
}

# ---------------------------------------------------------------------------
# macOS (launchd)
# ---------------------------------------------------------------------------
install_macos() {
  echo "Installing macOS launchd agents..."
  mkdir -p "$PLIST_DEST"

  local templates=(
    "com.design-action.daily-briefing.plist.template"
    "com.design-action.heartbeat.plist.template"
    "com.design-action.task-check.plist.template"
  )

  for tmpl in "${templates[@]}"; do
    local src="$LAUNCHD_TEMPLATE_DIR/$tmpl"
    local name="${tmpl%.template}"
    local dest="$PLIST_DEST/$name"

    if [[ ! -f "$src" ]]; then
      echo "  WARN: Template not found: $src"
      continue
    fi

    # Unload if already loaded
    if launchctl list | grep -q "${name%.plist}" 2>/dev/null; then
      launchctl bootout "gui/$(id -u)/$name" 2>/dev/null || true
    fi

    expand_template "$src" "$dest"
    echo "  Generated: $dest"

    # If heartbeat has no watch path, skip loading (polling not supported via WatchPaths)
    if [[ "$name" == *"heartbeat"* ]] && [[ -z "$WATCH_PATH" ]]; then
      echo "  NOTE: No local watch path for provider '$MEETING_PROVIDER'."
      echo "        Heartbeat will use polling. Consider adding a cron fallback."
      # Still load it — it will fire on the StartInterval instead
    fi

    launchctl bootstrap "gui/$(id -u)" "$dest" 2>/dev/null || {
      echo "  WARN: Could not bootstrap $name (may already be loaded)"
      # Try load as fallback
      launchctl load "$dest" 2>/dev/null || true
    }
    echo "  Loaded: $name"
  done

  echo ""
  echo "macOS launchd agents installed."
}

# ---------------------------------------------------------------------------
# Linux (systemd)
# ---------------------------------------------------------------------------
install_linux() {
  echo "Installing systemd user units..."
  mkdir -p "$SYSTEMD_DEST"

  local templates=(
    "design-action-briefing.service.template"
    "design-action-briefing.timer.template"
    "design-action-heartbeat.service.template"
    "design-action-heartbeat.timer.template"
    "design-action-task-check.service.template"
    "design-action-task-check.timer.template"
  )

  for tmpl in "${templates[@]}"; do
    local src="$SYSTEMD_TEMPLATE_DIR/$tmpl"
    local name="${tmpl%.template}"
    local dest="$SYSTEMD_DEST/$name"

    if [[ ! -f "$src" ]]; then
      echo "  WARN: Template not found: $src"
      continue
    fi

    expand_template "$src" "$dest"
    echo "  Generated: $dest"
  done

  systemctl --user daemon-reload

  for timer in design-action-briefing design-action-heartbeat design-action-task-check; do
    systemctl --user enable --now "${timer}.timer" 2>/dev/null || {
      echo "  WARN: Could not enable ${timer}.timer"
    }
    echo "  Enabled: ${timer}.timer"
  done

  echo ""
  echo "systemd user units installed."
}

# ---------------------------------------------------------------------------
# Cron (fallback)
# ---------------------------------------------------------------------------
install_cron() {
  echo "Installing cron entries..."

  local tmpl="$CRON_TEMPLATE_DIR/crontab.template"
  if [[ ! -f "$tmpl" ]]; then
    echo "  ERROR: Template not found: $tmpl"
    exit 1
  fi

  local generated="$DATA_DIR/crontab.generated"
  expand_template "$tmpl" "$generated"

  # Merge with existing crontab (removing old design-action entries)
  local current
  current=$(crontab -l 2>/dev/null || true)
  local filtered
  filtered=$(echo "$current" | grep -v 'design-action' || true)

  {
    echo "$filtered"
    echo ""
    echo "# --- design-action automation (managed) ---"
    cat "$generated"
    echo "# --- end design-action ---"
  } | crontab -

  echo "  Cron entries installed."
  echo "  NOTE: Heartbeat requires fswatch/inotifywait for event-driven behavior."

  # Check for fswatch / inotifywait
  if [[ -n "$WATCH_PATH" ]]; then
    if command -v fswatch &>/dev/null; then
      echo "  TIP: fswatch is available. You can run this in a terminal for event-driven heartbeat:"
      echo "    fswatch -1 \"$WATCH_PATH\" && $AUTOMATION_DIR/heartbeat.sh"
    elif command -v inotifywait &>/dev/null; then
      echo "  TIP: inotifywait is available. You can run this in a terminal for event-driven heartbeat:"
      echo "    inotifywait -m -e modify \"$WATCH_PATH\" | while read; do $AUTOMATION_DIR/heartbeat.sh; done"
    else
      echo "  WARN: Neither fswatch nor inotifywait found. Heartbeat will only run via cron polling."
    fi
  fi

  echo ""
  echo "Cron entries installed."
}

# ---------------------------------------------------------------------------
# Uninstall
# ---------------------------------------------------------------------------
uninstall() {
  echo "Uninstalling design-action automation..."

  # macOS
  if [[ "$(uname)" == "Darwin" ]]; then
    for label in com.design-action.daily-briefing com.design-action.heartbeat com.design-action.task-check; do
      local plist="$PLIST_DEST/${label}.plist"
      if [[ -f "$plist" ]]; then
        launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || \
          launchctl unload "$plist" 2>/dev/null || true
        rm -f "$plist"
        echo "  Removed: $plist"
      fi
    done
  fi

  # Linux
  if command -v systemctl &>/dev/null && [[ -d "$SYSTEMD_DEST" ]]; then
    for unit in design-action-briefing design-action-heartbeat design-action-task-check; do
      systemctl --user disable --now "${unit}.timer" 2>/dev/null || true
      rm -f "$SYSTEMD_DEST/${unit}.service" "$SYSTEMD_DEST/${unit}.timer"
      echo "  Removed: ${unit}.service + ${unit}.timer"
    done
    systemctl --user daemon-reload 2>/dev/null || true
  fi

  # Cron
  if crontab -l 2>/dev/null | grep -q 'design-action'; then
    local filtered
    filtered=$(crontab -l 2>/dev/null | sed '/# --- design-action/,/# --- end design-action/d')
    echo "$filtered" | crontab -
    echo "  Removed cron entries"
  fi

  echo ""
  echo "Uninstall complete."
}

# ==========================================================================
# Main
# ==========================================================================
check_deps
read_config

if [[ "$ACTION" == "uninstall" ]]; then
  uninstall
  exit 0
fi

echo "============================================"
echo " design-action automation installer"
echo "============================================"
echo ""
echo "Config:           $CONFIG"
echo "Data directory:   $DATA_DIR"
echo "Meeting provider: $MEETING_PROVIDER"
echo "Task provider:    $TASK_PROVIDER"
echo "Briefing time:    $BRIEFING_HOUR:$(printf '%02d' $BRIEFING_MINUTE)"
echo "Task check time:  $TASK_CHECK_HOUR:$(printf '%02d' $TASK_CHECK_MINUTE)"
echo "Throttle:         ${THROTTLE_MINUTES}m"
echo "Watch path:       ${WATCH_PATH:-'(none — polling mode)'}"
echo ""

PLATFORM="$(uname)"
case "$PLATFORM" in
  Darwin)
    install_macos
    # Also generate cron as documented fallback
    echo ""
    echo "Generating cron template as fallback..."
    if [[ -f "$CRON_TEMPLATE_DIR/crontab.template" ]]; then
      expand_template "$CRON_TEMPLATE_DIR/crontab.template" "$DATA_DIR/crontab.generated"
      echo "  Saved: $DATA_DIR/crontab.generated (install manually with: crontab $DATA_DIR/crontab.generated)"
    fi
    ;;
  Linux)
    install_linux
    ;;
  *)
    echo "Unknown platform: $PLATFORM — falling back to cron"
    install_cron
    ;;
esac

echo ""
echo "============================================"
echo " Installation summary"
echo "============================================"
echo ""
if [[ "$PLATFORM" == "Darwin" ]]; then
  echo "Installed launchd agents:"
  ls -1 "$PLIST_DEST"/com.design-action.* 2>/dev/null | sed 's/^/  /' || echo "  (none)"
elif [[ "$PLATFORM" == "Linux" ]]; then
  echo "Installed systemd units:"
  ls -1 "$SYSTEMD_DEST"/design-action-* 2>/dev/null | sed 's/^/  /' || echo "  (none)"
  echo ""
  echo "Timer status:"
  systemctl --user list-timers 'design-action-*' 2>/dev/null || true
fi
echo ""
echo "Logs:  $LOG_DIR/"
echo "State: $DATA_DIR/state/"
echo ""
echo "Verify with:"
if [[ "$PLATFORM" == "Darwin" ]]; then
  echo "  launchctl list | grep design-action"
elif [[ "$PLATFORM" == "Linux" ]]; then
  echo "  systemctl --user list-timers 'design-action-*'"
fi
echo ""
echo "To uninstall: $0 --uninstall"
