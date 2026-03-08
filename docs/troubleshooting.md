# Troubleshooting

## Common Issues

### "Config file not found"

**Cause:** `~/.design-action/config.yaml` doesn't exist.
**Fix:** Run `/setup` to create configuration interactively.

### "No meetings found"

**Possible causes:**
1. Meeting provider not configured or MCP server not running
2. Search query too specific — try broader terms
3. For manual provider: notes_dir doesn't exist or has no .md files

**Debug:**
- Check config: `cat ~/.design-action/config.yaml`
- Validate config: `./scripts/validate-config.sh`
- Try a very broad search: `/design-action --topic "meeting" --broad`

### "Task tracker not responding"

**Possible causes:**
1. MCP server not configured in `~/.claude/.mcp.json`
2. Authentication expired (API token, OAuth)
3. Wrong project key in config

**Debug:**
- Check MCP server is listed: `cat ~/.claude/.mcp.json`
- Try a direct MCP call to verify connectivity
- Check provider-specific auth requirements in `docs/providers.md`

### "Slack scanning skipped"

**Cause:** Communication provider not configured or tool not available.

**For `slack-browser`:**
- Chrome must be running with remote debugging enabled
- Slack must be open in a Chrome tab
- Chrome DevTools MCP must be configured

**For `slack-mcp`:**
- Slack MCP server must be installed and configured
- Check API token permissions

### Cache Issues

**Stale extraction cache:**
- design-action warns when cache is > 48 hours old
- Choose "refresh" or "start fresh" when prompted
- Or delete manually: `rm ~/.design-action/extractions/{stream}-{topic}*.json`

**Corrupted last-checks.json:**
- Delete and let it recreate: `rm ~/.design-action/extractions/last-checks.json`
- Or reset specific keys by editing the JSON

### Scoring Weights Don't Sum to 1.0

The config validation script checks this. Fix by adjusting weights in config:
```yaml
scoring:
  dimensions:
    - { name: "A", weight: 0.4 }
    - { name: "B", weight: 0.3 }
    - { name: "C", weight: 0.2, invert: true }
    - { name: "D", weight: 0.1 }
    # Total: 1.0 ✓
```

## Automation Issues

### Briefing Not Running

1. Check automation is enabled in config: `automation.enabled: true`
2. Check scheduler status:
   - macOS: `launchctl list | grep design-action`
   - Linux: `systemctl --user status design-action-briefing`
3. Check logs in `~/.design-action/logs/`
4. Verify work hours — automation skips weekends and outside configured hours

### Heartbeat Not Triggering

1. Verify the meeting tool creates/modifies a local file that the heartbeat watches
2. Check throttle setting — heartbeat won't fire more than once per `throttle_minutes`
3. Check scheduler is loaded and watching the right path

## Getting Help

- Run `/setup` to reconfigure from scratch
- Run `./scripts/validate-config.sh` to check config validity
- Check `docs/providers.md` for provider-specific setup
- File issues at the project repository
