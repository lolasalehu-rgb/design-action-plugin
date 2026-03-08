# Production Pattern Extraction & Team Execution

## Phase 3.5: Production Pattern Extraction (Prototypes Only)

**Trigger:** Runs when selected artifact is an interactive prototype. Skip for non-code artifacts.

**Purpose:** Extract visual foundation from the production codebase so the prototype matches production look-and-feel while innovating on UX patterns.

### What to Extract

| Category | What to Find | Where to Look |
|----------|-------------|---------------|
| **Density/spacing system** | Grid columns, card padding, spacing scale | Layout components, CSS variables, design tokens |
| **Card/tile interactions** | Hover states, transitions, shadows | Card/tile components in main UI routes |
| **Loading states** | Skeleton count, structure, animation | `*Skeleton*` or `*Loading*` components |
| **Color tokens** | Semantic tokens (never raw hex) | `globals.css`, `tokens.css`, theme files |
| **Grid/responsive breakpoints** | All responsive breakpoints | Grid layout components, media queries |
| **Typography hierarchy** | Font sizes, weights, line-clamp, colors | Text/heading components, content areas |

### How to Extract

1. Launch an Explore agent targeting the production feature area closest to the prototype's domain
2. Create a `designConstants.ts` (or equivalent) in the prototype's shared folder with extracted values
3. Import constants into prototype components instead of hardcoding

### Match vs Diverge

| MUST match production | FREE to diverge |
|-----------------------|-----------------|
| Spacing/density system | Navigation structures |
| Hover/interaction patterns | Information architecture |
| Loading state patterns | New component compositions |
| Semantic color tokens | Layout of novel UX patterns |
| Responsive breakpoints | Interaction flows |
| Typography hierarchy | Filter/sort approaches |

### Design System Extension Proposals

When a prototype introduces new visual elements not in the production design system:
1. Document the extension with a comment explaining intent
2. Allowlist the extension in design token compliance tests
3. Track as a "DS Extension Proposal" for team review

---

## Phase 3.6: Team Execution (Parallel Mode)

### When to Spawn a Team

- Triage output has 2+ items with `independent: true`
- `--scan` finds multiple new items
- User explicitly requests: "work these", "parallel", "team"

**Stay single-threaded** when: only 1 item, items are dependent, or user wants sequential focus.

### Pre-Triaged Items (`--execute` mode)

Present ready items from `{paths.extractions}/triage-{date}.json`:

```
## Morning Triage Results
| # | Item | Stream | Type | Priority |
|---|------|--------|------|----------|
Work all N in parallel? Or select specific items?
```

### Team Roles

| Role | Responsibility |
|------|---------------|
| **Lead** (you) | Coordinate, synthesize, present |
| **Scout** | Research: meetings, tasks, caches |
| **Builder** | Artifact creation via appropriate skill |
| **Reviewer** | DDR drafting, backlog updates |

Spawn only needed roles. A 2-item run might just need 2 scouts.

### Multi-Tool Dispatch

| Artifact Type | Skill/Tool |
|---------------|-----------|
| Interactive prototype | `frontend-design` / `impeccable:frontend-design` |
| Journey map | Figma/Penpot MCP (if configured) or Mermaid |
| UI images | `image-gen` skill |
| Demo video | `remotion` skill |
| Wireframes | `frontend-design` |
| Research synthesis | Direct markdown write |

### Execution Flow

1. Lead reads triage output (or runs Phase 1-3 if no triage)
2. Lead creates task list: one task per independent item
3. Teammates work tasks in parallel
4. Each writes results to `{paths.extractions}/{stream}-{item}-result.json`
5. Builders work in a prototype directory (user-configured or auto-detected)
6. Lead synthesizes → updates backlog → presents to user
7. Lead shuts down team
