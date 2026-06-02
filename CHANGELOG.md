# Changelog

## [1.1.0] - 2026-06-02

### Fixed
- **Granola heartbeat never fired on current Granola versions.** The watch path was hardcoded to `cache-v4.json`; Granola has since moved to v6/v7 and, as of **v7.277 (May 2026), encrypts the cache** (`cache-v*.json.enc`, leaving the plaintext file an empty stub). The heartbeat now auto-detects the newest cache artifact (encrypted or not) in both `heartbeat.sh` and `install-automation.sh`.
- **Heartbeat count-gate could skip forever on an unparseable watch source.** Added graceful degradation: when the watched file can't be counted (encrypted cache, or any unparseable format), the count gate is treated as *inconclusive* and falls through to the timestamp/throttle gate instead of silently exiting. Benefits any provider, not just Granola. The stored meeting count is no longer overwritten with a spurious `0`.

### Added
- **Official Granola Cloud MCP** (`granola-cloud`, `https://mcp.granola.ai/mcp`) documented in `docs/providers.md` as the recommended Granola server — it talks to Granola's API and is unaffected by local-cache encryption. The community local-cache MCP is retained as a legacy option for pre-v7.277 builds.
- Troubleshooting guidance: distinguish a *quiet window* (zero new meetings is normal) from a *broken source* using a data-first freshness check, rather than assuming an expired subscription. Provider-general, with the Granola encryption change documented as one specific cause.

### Notes
- These changes are scoped to the **Granola** provider path and provider-general robustness; Otter, Fireflies, Google Meet, Notion, and manual providers are unaffected by the Granola cache change (they read cloud APIs or local files).

## [1.0.0] - 2026-03-08

### Added
- Core skill: `/design-action` with 5-phase methodology (gather evidence → synthesize → suggest → create → automate)
- Provider-agnostic architecture with dispatch tables for meetings, videos, tasks, communication, and design tools
- Meeting providers: Granola, Otter.ai, Fireflies.ai, Google Meet, Notion, manual markdown
- Task providers: Jira, Linear, GitHub Issues, Notion
- Communication providers: Slack (MCP + browser), Discord, Microsoft Teams
- Design tool providers: Figma, Penpot
- Interactive setup wizard (`/setup`) with MCP auto-detection
- Scan command (`/scan`) for proactive source discovery
- Briefing command (`/briefing`) for daily design briefings
- Configurable scoring framework with weighted dimensions
- Design Decision Record (DDR) templates
- Tiered loading system for efficient token management
- Cross-meeting synthesis patterns
- Evidence grounding standards with citation formats
- 9 artifact templates (journey maps, prototypes, wireframes, research synthesis, demo videos, FigJam boards, prioritization matrices, flow diagrams)
- Production pattern extraction for prototype fidelity
- Agent Team dispatch for parallel execution
- Config validation script
- Comprehensive provider setup documentation
- Automation scripts: daily-briefing.sh, heartbeat.sh, task-check.sh (all config-driven)
- Cross-platform installer: install-automation.sh (macOS launchd, Linux systemd, cron fallback)
- Scheduler templates: 3 launchd plists, 6 systemd units, 1 crontab template
- Heartbeat with 3-gate system (time, count, timestamp) before invoking Claude
- Decision-log auto-generation from DDR files via embedded Python
