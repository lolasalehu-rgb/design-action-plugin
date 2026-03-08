---
name: briefing
description: Generate a daily design briefing from meetings, tasks, and communications
---

# Briefing Command

Generate a comprehensive daily design briefing from all configured sources. Normally triggered by automation, but can be run manually.

## Execution

1. Load config from `~/.design-action/config.yaml`
2. Gather context from all configured providers
3. Synthesize into a daily briefing document
4. Save to `{paths.briefings}/YYYY-MM-DD.md`

## Arguments

```
/briefing                    # Generate today's briefing
/briefing --date "2026-03-07"  # Generate for specific date
/briefing --dry-run           # Preview without saving
```

## Briefing Structure

The generated briefing includes:

### 1. Meeting Summary
Recent meetings from the configured meeting provider, classified by stream and relevance.

### 2. Task Status
Current sprint/iteration status from the configured task tracker:
- Items assigned to you
- Recent status changes
- Blocked items

### 3. Communication Highlights
Design-relevant messages from configured channels (if communication provider is set up).

### 4. Inbox Status
Current items in `{paths.inbox}` awaiting triage.

### 5. Backlog Priorities
Top items from `{paths.backlog}` sorted by priority score.

### 6. Triage (Optional)
If new items were found, score them and produce a triage file at `{paths.extractions}/triage-{date}.json`.

## Output

Saves to: `{paths.briefings}/YYYY-MM-DD.md`

Also updates `{paths.extractions}/last-checks.json` with briefing timestamp.
