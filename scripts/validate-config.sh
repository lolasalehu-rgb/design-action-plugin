#!/bin/bash
# validate-config.sh — Validate design-action configuration
# Usage: ./validate-config.sh [config-path]

set -euo pipefail

CONFIG_PATH="${1:-$HOME/.design-action/config.yaml}"
ERRORS=0
WARNINGS=0

echo "Validating design-action config: $CONFIG_PATH"
echo "================================================"

# Check config exists
if [ ! -f "$CONFIG_PATH" ]; then
    echo "ERROR: Config file not found at $CONFIG_PATH"
    echo "Run /setup to create configuration."
    exit 1
fi

# Check required tools
check_tool() {
    if command -v "$1" &>/dev/null; then
        echo "  ✓ $1 found"
    else
        echo "  ✗ $1 not found — $2"
        ((WARNINGS++))
    fi
}

echo ""
echo "Checking tools..."
check_tool "yq" "needed for YAML parsing (brew install yq)"
check_tool "claude" "Claude Code CLI"

# If yq is available, validate config structure
if command -v yq &>/dev/null; then
    echo ""
    echo "Checking config structure..."

    # Check version
    VERSION=$(yq '.version' "$CONFIG_PATH" 2>/dev/null)
    if [ "$VERSION" != "1" ]; then
        echo "  ✗ Missing or invalid version (expected: 1, got: $VERSION)"
        ((ERRORS++))
    else
        echo "  ✓ Version: $VERSION"
    fi

    # Check user
    USER_NAME=$(yq '.user.name' "$CONFIG_PATH" 2>/dev/null)
    if [ "$USER_NAME" = "null" ] || [ -z "$USER_NAME" ]; then
        echo "  ✗ Missing user.name"
        ((ERRORS++))
    else
        echo "  ✓ User: $USER_NAME"
    fi

    # Check streams
    STREAM_COUNT=$(yq '.streams | length' "$CONFIG_PATH" 2>/dev/null)
    if [ "$STREAM_COUNT" = "0" ] || [ "$STREAM_COUNT" = "null" ]; then
        echo "  ✗ No streams defined"
        ((ERRORS++))
    else
        echo "  ✓ Streams: $STREAM_COUNT defined"
    fi

    # Check meeting provider
    MEETING_TYPE=$(yq '.providers.meetings.type' "$CONFIG_PATH" 2>/dev/null)
    VALID_MEETING_TYPES="granola otter fireflies google-meet notion manual"
    if [ "$MEETING_TYPE" = "null" ] || [ -z "$MEETING_TYPE" ]; then
        echo "  ✗ Missing providers.meetings.type"
        ((ERRORS++))
    elif echo "$VALID_MEETING_TYPES" | grep -qw "$MEETING_TYPE"; then
        echo "  ✓ Meeting provider: $MEETING_TYPE"
    else
        echo "  ✗ Invalid meeting provider: $MEETING_TYPE (valid: $VALID_MEETING_TYPES)"
        ((ERRORS++))
    fi

    # Check task provider
    TASK_TYPE=$(yq '.providers.tasks.type' "$CONFIG_PATH" 2>/dev/null)
    VALID_TASK_TYPES="jira linear github-issues notion none"
    if [ "$TASK_TYPE" = "null" ] || [ -z "$TASK_TYPE" ]; then
        echo "  ⚠ Missing providers.tasks.type (defaulting to 'none')"
        ((WARNINGS++))
    elif echo "$VALID_TASK_TYPES" | grep -qw "$TASK_TYPE"; then
        echo "  ✓ Task provider: $TASK_TYPE"
    else
        echo "  ✗ Invalid task provider: $TASK_TYPE (valid: $VALID_TASK_TYPES)"
        ((ERRORS++))
    fi

    # Check scoring weights sum to ~1.0
    WEIGHT_SUM=$(yq '[.scoring.dimensions[].weight] | add' "$CONFIG_PATH" 2>/dev/null)
    if [ "$WEIGHT_SUM" = "null" ]; then
        echo "  ⚠ No scoring dimensions defined (will use defaults)"
        ((WARNINGS++))
    else
        # Check if close to 1.0 (allow 0.95-1.05 for floating point)
        IN_RANGE=$(echo "$WEIGHT_SUM" | awk '{if ($1 >= 0.95 && $1 <= 1.05) print "yes"; else print "no"}')
        if [ "$IN_RANGE" = "yes" ]; then
            echo "  ✓ Scoring weights sum: $WEIGHT_SUM"
        else
            echo "  ✗ Scoring weights sum to $WEIGHT_SUM (should be ~1.0)"
            ((ERRORS++))
        fi
    fi

    # Check paths
    DATA_DIR=$(yq '.paths.data_dir' "$CONFIG_PATH" 2>/dev/null)
    if [ "$DATA_DIR" != "null" ] && [ -n "$DATA_DIR" ]; then
        EXPANDED_DIR="${DATA_DIR/#\~/$HOME}"
        if [ -d "$EXPANDED_DIR" ]; then
            echo "  ✓ Data directory exists: $DATA_DIR"
        else
            echo "  ⚠ Data directory doesn't exist: $DATA_DIR (will be created on first run)"
            ((WARNINGS++))
        fi
    fi

    # Check for manual provider notes_dir
    if [ "$MEETING_TYPE" = "manual" ]; then
        NOTES_DIR=$(yq '.providers.meetings.config.notes_dir' "$CONFIG_PATH" 2>/dev/null)
        if [ "$NOTES_DIR" = "null" ] || [ -z "$NOTES_DIR" ]; then
            echo "  ✗ Manual meeting provider requires config.notes_dir"
            ((ERRORS++))
        else
            EXPANDED_NOTES="${NOTES_DIR/#\~/$HOME}"
            if [ -d "$EXPANDED_NOTES" ]; then
                FILE_COUNT=$(find "$EXPANDED_NOTES" -name "*.md" | wc -l | tr -d ' ')
                echo "  ✓ Notes directory: $NOTES_DIR ($FILE_COUNT .md files)"
            else
                echo "  ✗ Notes directory doesn't exist: $NOTES_DIR"
                ((ERRORS++))
            fi
        fi
    fi

else
    echo ""
    echo "⚠ yq not installed — skipping detailed validation"
    echo "  Install with: brew install yq"
    ((WARNINGS++))
fi

# Summary
echo ""
echo "================================================"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✓ Config is valid — no issues found"
elif [ $ERRORS -eq 0 ]; then
    echo "⚠ Config is valid with $WARNINGS warning(s)"
else
    echo "✗ Config has $ERRORS error(s) and $WARNINGS warning(s)"
    exit 1
fi
