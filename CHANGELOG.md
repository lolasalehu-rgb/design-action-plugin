# Changelog

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
