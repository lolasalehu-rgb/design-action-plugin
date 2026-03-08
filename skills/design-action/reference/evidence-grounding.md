# Evidence Grounding Standards

Every design element in artifacts must cite its source. This ensures traceability, builds stakeholder confidence, and prevents "design by assumption."

---

## Citation Formats

### Meeting Citations

**Full format:**
```
[Meeting Name], [Date], [Timestamp if available]
```

**Examples:**
```
Acme Corp Customer Call, Jan 15 2026, 12:34
Error Handling Workshop, Jan 20 2026
Design Review, Jan 22 2026, 45:00-47:30
```

**In-context usage:**
```markdown
Pain Point: "Error messages don't explain what to fix"
Source: Acme Corp Customer Call, Jan 15 2026, 12:34
```

### Quote Citations

**Format:**
```
"[Verbatim quote]"
— [Speaker Name/Role], [Meeting Name], [Date]
```

**Examples:**
```
"I have to publish just to see what it looks like on my phone"
— Taylor (PM), Customer Call, Jan 15 2026

"We need a way to retry without losing context"
— Sam, Error Handling Workshop, Jan 20 2026
```

### Video Citations

**Format:**
```
[Video Source], [Timestamp], [Description]
```

**Examples:**
```
Awesome Screenshot (Jan 22), 0:42-0:58, Shows error state UI
Google Meet Recording, 15:30, Customer demonstrates workflow
Loom, 2:15, Designer walkthrough of proposed solution
```

### Aggregated Citations

When multiple meetings support the same point:

**Format:**
```
[Point] - mentioned in X meetings
- [Meeting 1, Date]: "[context]"
- [Meeting 2, Date]: "[context]"
```

**Example:**
```
"No mobile preview" - mentioned in 4 meetings
- Acme Corp Call, Jan 15: "I can't see what it looks like on my phone"
- Design Review, Jan 18: Team discussed as top priority
- User Research, Jan 20: 3/5 participants mentioned this
- Workshop, Jan 22: Confirmed for Q1 roadmap
```

---

## Evidence Levels

### Strong Evidence
- Direct verbatim quote from customer
- Observation from user research session
- Confirmed team decision in meeting
- Data from analytics/metrics

**Mark as:** `[STRONG]` or use bold

### Moderate Evidence
- Paraphrased customer feedback
- Team discussion (not decision)
- Competitive observation
- Expert opinion

**Mark as:** `[MODERATE]`

### Weak Evidence
- Assumption (explicitly state)
- Inferred from related discussion
- Single mention, no corroboration
- Anecdotal

**Mark as:** `[ASSUMPTION]` or `[INFERRED]`

---

## Artifact-Specific Grounding

### Journey Maps

**For each phase:**
```
┌────────────────────────────────────────────┐
│ Phase: [Name]                              │
├────────────────────────────────────────────┤
│ User Goal: [Goal]                          │
│ Source: [Meeting, Date]                    │
│                                            │
│ Pain Point: "[Pain]"                       │
│ Source: [Meeting, Date] [STRONG]           │
│ Frequency: X meetings                      │
│                                            │
│ Opportunity: [Idea]                        │
│ Source: [Meeting, Date] [MODERATE]         │
└────────────────────────────────────────────┘
```

**In FigJam sticky notes:**
```
[PAIN POINT]
"Can't preview on mobile"

Source: Acme Corp, Jan 15
Freq: 4x across meetings
Level: STRONG
```

### Wireframes/Prototypes

**For each design decision:**
```markdown
## Decision: [What was designed]

### Evidence
- **Requirement source**: [Meeting, Date] - "[Quote or context]"
- **Pattern choice**: [Why this pattern] - [Meeting, Date]
- **Edge case handling**: [How it was identified] - [Meeting, Date]

### Assumptions (to validate)
- [Assumption 1] [ASSUMPTION]
- [Assumption 2] [INFERRED from Meeting, Date]
```

### Research Synthesis Docs

**Every insight must have:**
```markdown
### Insight: [Title]

**Evidence:**
- "[Verbatim quote 1]" — [Speaker], [Meeting]
- "[Verbatim quote 2]" — [Speaker], [Meeting]
- [Observation from Meeting]

**Confidence:** HIGH/MEDIUM/LOW
**Action:** [Recommended next step]
```

---

## Citation Shorthand

For efficiency in artifacts, use these abbreviations:

| Full | Shorthand |
|------|-----------|
| Customer Call | CC |
| Design Review | DR |
| User Research | UR |
| Workshop | WS |
| Team Sync | TS |
| Stakeholder Meeting | SM |

**Example:**
```
Source: CC-Jan15, UR-Jan20, WS-Jan22
```

---

## No Evidence? Flag It

If a design element lacks evidence:

**Option 1: Mark as assumption**
```
Feature: Quick retry button
Source: [ASSUMPTION - to validate with users]
```

**Option 2: Create validation task**
```
Feature: Quick retry button
Source: Team intuition (DR-Jan22)
TODO: Validate in next user research session
```

**Option 3: Request more context**
```
"I don't have evidence for [element]. Should I:
1. Mark it as an assumption and proceed
2. Search for more meeting context
3. Remove it from the artifact"
```

---

## Video Evidence Integration

### Capturing Video Context

When processing video recordings:

1. **Auto-capture frames** at key intervals
2. **Let user confirm** which are relevant
3. **Tag each frame** with:
   - Timestamp
   - Description
   - What it demonstrates

**Format:**
```markdown
### Video Evidence: [Source]

| Timestamp | Frame | Description | Supports |
|-----------|-------|-------------|----------|
| 0:42 | [img] | Error state shown | Pain point #1 |
| 1:15 | [img] | User attempts retry | Workflow insight |
| 2:30 | [img] | Confusion visible | UX issue |
```

### Embedding in Artifacts

**FigJam:**
- Place screenshot in context
- Add sticky note with timestamp + source
- Connect to related pain points

**Prototypes:**
- Reference in code comments
- Link in design documentation

---

## Quality Checklist

Before finalizing any artifact:

- [ ] Every pain point has a source meeting
- [ ] Every quote is verbatim with speaker attribution
- [ ] Frequency counts are accurate
- [ ] Assumptions are clearly marked
- [ ] Video timestamps are included where relevant
- [ ] Evidence levels (STRONG/MODERATE/WEAK) are noted for key items
- [ ] No design decisions are "floating" without justification

---

## Example: Fully Grounded Pain Point

```markdown
### Pain Point: Mobile Preview Missing

**Summary:** Users cannot preview how their product content will appear on mobile devices before publishing.

**Evidence [STRONG]:**
1. "I have to publish just to see what it looks like on my phone, and then fix it, and publish again"
   — Taylor (PM), Acme Corp Customer Call, Jan 15 2026, 12:34

2. "Mobile preview is the number one request we hear"
   — Morgan (PMM), GTM Sync, Jan 18 2026

3. Observed in user research: 3/5 participants mentioned this unprompted
   — User Research Session, Jan 20 2026

4. Video evidence: User demonstrates publish-check-fix cycle
   — Awesome Screenshot, Jan 22 2026, 0:42-1:15

**Frequency:** Mentioned in 6 separate meetings across 2 weeks

**Decision:** Confirmed for Q1 roadmap
   — Error Handling Workshop, Jan 22 2026

**Implication for Design:**
- Add mobile preview toggle in editor
- Show side-by-side desktop/mobile view
- [ASSUMPTION] Tablet preview also needed - to validate
```
