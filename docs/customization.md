# Customization Guide

## Scoring Framework

### Changing Dimensions

Edit `~/.design-action/config.yaml` → `scoring.dimensions`:

```yaml
scoring:
  dimensions:
    - name: "Customer Impact"
      weight: 0.35
      description: "How much does this impact customers?"
    - name: "Revenue Potential"
      weight: 0.25
      description: "Direct or indirect revenue impact"
    - name: "Technical Complexity"
      weight: 0.25
      invert: true
      description: "How complex to implement?"
    - name: "Team Capacity"
      weight: 0.15
      invert: true
      description: "Does the team have bandwidth?"
```

**Rules:**
- Weights must sum to 1.0
- Set `invert: true` for dimensions where higher = lower priority
- Each dimension is scored 1-5 during triage

### Domain-Specific Presets

See `templates/scoring-framework.md` for examples tailored to e-commerce, SaaS, and consumer apps.

## Work Streams

### Single Stream (Simple)

```yaml
streams:
  - name: "product"
    display_name: "Product Design"
    task_project_key: "PROD"
    channels: ["#design"]
```

### Multiple Streams

```yaml
streams:
  - name: "web-app"
    display_name: "Web Application"
    task_project_key: "WEB"
    channels: ["#web-team", "#web-design"]
  - name: "mobile"
    display_name: "Mobile App"
    task_project_key: "MOB"
    channels: ["#mobile-team"]
```

Streams are used for:
- Categorizing scan results
- Filtering task tracker queries
- Organizing extraction caches
- Backlog segmentation

## Templates

### DDR Template

Copy and modify `templates/ddr-template.md` to match your team's decision record format. The template is used when design-action creates DDRs in Phase 5.

### Backlog Format

The backlog (`~/.design-action/backlog.md`) uses a simple markdown table format. Customize columns by editing the template. design-action will respect whatever columns you define.

### Inbox Format

Same as backlog — customize `~/.design-action/inbox.md` to match your preferred format.

## Artifact Templates

### Adding Custom Artifact Types

Edit `skills/design-action/reference/artifact-templates.md` to add templates for artifact types specific to your workflow:

```markdown
## [Your Artifact Type]

### Structure
[Describe the structure]

### Components
[List components and their purpose]

### Example
[Provide an example]
```

The skill will include your custom types in Phase 3 artifact suggestions.

## Automation

### Work Hours

```yaml
automation:
  work_hours:
    start: 9      # 9 AM
    end: 17       # 5 PM
    weekdays_only: true
```

Automation scripts skip execution outside these hours.

### Briefing Schedule

```yaml
automation:
  briefing_time: "09:00"    # When daily briefing runs
  task_check_time: "14:00"  # When mid-day task check runs
```

### Heartbeat

```yaml
automation:
  heartbeat:
    enabled: true
    throttle_minutes: 10    # Minimum interval between runs
```

The heartbeat watches for changes in your meeting tool's local data and triggers a lightweight scan.

## Provider-Specific Config

### Jira Labels

```yaml
providers:
  tasks:
    type: "jira"
    config:
      projects: ["PROJ"]
      labels:
        design_work: "design-work"      # Main filter label
        phase_prefix: "design-"         # Phase labels: design-research, design-build
        stream_prefix: "design-stream-" # Stream labels: design-stream-web
```

design-action uses these labels to:
- Filter design-relevant tickets during scans
- Set phase labels when creating/updating tickets
- Set stream labels for multi-stream setups

### Manual Meeting Notes

```yaml
providers:
  meetings:
    type: "manual"
    config:
      notes_dir: "~/meeting-notes"
```

**Recommended file naming:** `YYYY-MM-DD-meeting-title.md`

The skill uses Glob patterns and Grep to search across your notes. Include participant names, dates, and clear headings for best results.
