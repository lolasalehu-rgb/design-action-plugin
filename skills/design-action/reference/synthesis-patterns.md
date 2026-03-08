# Cross-Meeting Synthesis Patterns

Patterns for extracting and aggregating insights across multiple meetings.

---

## Core Extraction Categories

### 1. Decisions

**What to extract:**
- Confirmed choices (not just discussions)
- The rationale behind each decision
- Who made or approved the decision
- Any constraints that influenced it

**Pattern:**
```markdown
### Decisions Made

| Decision | Rationale | Meeting | Date | Owner |
|----------|-----------|---------|------|-------|
| [Decision] | [Why] | [Meeting name] | [Date] | [Person] |
```

**Keywords to look for:**
- "Let's go with..."
- "We decided to..."
- "The approach will be..."
- "We're committing to..."
- "After discussion, we'll..."

---

### 2. Pain Points

**What to extract:**
- User frustrations (from research calls)
- Internal team blockers
- Customer complaints
- Process inefficiencies

**Frequency tracking:**
Track how many times each pain point appears across meetings.

**Pattern:**
```markdown
### Pain Points by Frequency

1. **"[Pain point summary]"** - mentioned in X meetings
   - Meeting 1 ([date]): "[verbatim quote or context]"
   - Meeting 2 ([date]): "[verbatim quote or context]"
   - Meeting 3 ([date]): "[related mention]"

2. **"[Pain point summary]"** - mentioned in X meetings
   - [evidence...]
```

**Keywords to look for:**
- "Frustrating..."
- "I don't understand..."
- "Why can't I..."
- "This is confusing..."
- "I expected..."
- "It's hard to..."
- "We keep hearing..."

---

### 3. Feature Proposals

**What to extract:**
- Suggested solutions
- Their current status (confirmed, discussed, rejected)
- Source of the proposal (customer request, team idea, competitive insight)

**Pattern:**
```markdown
### Proposed Solutions

| Solution | Status | Source | Evidence |
|----------|--------|--------|----------|
| [Feature idea] | Confirmed | [Customer/Team/Competitor] | [Meeting, date] |
| [Feature idea] | Discussed | [Source] | [Meeting, date] |
| [Feature idea] | Rejected | [Source] | [Reason] - [Meeting, date] |
```

**Status definitions:**
- **Confirmed**: Team committed to building this
- **Discussed**: Mentioned but no commitment yet
- **Rejected**: Explicitly decided against (include reason)
- **Deferred**: Postponed to future consideration

---

### 4. Open Questions

**What to extract:**
- Unresolved issues
- Items marked for follow-up
- Dependencies on external information
- Technical unknowns

**Pattern:**
```markdown
### Open Questions

| Question | Context | Raised In | Owner |
|----------|---------|-----------|-------|
| [Question] | [Why it matters] | [Meeting, date] | [Who to follow up] |
```

**Keywords to look for:**
- "We need to figure out..."
- "Action item: investigate..."
- "Still unclear..."
- "Depends on..."
- "Waiting for..."
- "TBD"

---

### 5. Quotes

**What to extract:**
- Verbatim customer quotes (powerful for artifacts)
- Stakeholder quotes that capture key insights
- Team quotes that crystallize decisions

**Pattern:**
```markdown
### Notable Quotes

| Quote | Speaker | Context | Theme |
|-------|---------|---------|-------|
| "[Verbatim quote]" | [Name/Role] | [What prompted this] | [Category] |
```

**Themes to categorize:**
- User frustration
- Feature request
- Workflow insight
- Competitive observation
- Strategic direction

---

### 6. Visual References

**What to extract:**
- Screens or UI discussed
- Sketches or wireframes shown
- External examples referenced
- Video timestamps

**Pattern:**
```markdown
### Visual References

| Reference | Source | Context | Relevant Timestamps |
|-----------|--------|---------|---------------------|
| [Description] | [Video URL / Screenshot] | [What it illustrates] | [0:00 - 0:30] |
```

---

## Aggregation Patterns

### Theme Convergence Matrix

Identify themes that appear across multiple meetings:

```markdown
### Theme Convergence

| Theme | Meeting 1 | Meeting 2 | Meeting 3 | Meeting 4 | Total |
|-------|-----------|-----------|-----------|-----------|-------|
| Error handling | x | x | x | | 3 |
| Mobile preview | x | | x | x | 3 |
| Onboarding | | x | x | | 2 |
| Performance | x | | | | 1 |
```

### Stakeholder Alignment Check

Track what different stakeholders said about the same topic:

```markdown
### Stakeholder Perspectives: [Topic]

| Stakeholder | Perspective | Meeting |
|-------------|-------------|---------|
| [Customer - Acme Corp] | "[view]" | [Meeting] |
| [PM - Alex] | "[view]" | [Meeting] |
| [Eng - Sam] | "[view]" | [Meeting] |
| [Design - Jordan] | "[view]" | [Meeting] |
```

**Flag:** If perspectives diverge significantly, note it as an open question.

### Evolution Tracking

Track how understanding of a topic evolved across meetings:

```markdown
### Evolution: [Topic]

1. **[Date] - [Meeting 1]**: Initial understanding
   - "[Key point]"

2. **[Date] - [Meeting 2]**: Refined after user research
   - "[New insight]"
   - Changed: [What shifted]

3. **[Date] - [Meeting 3]**: Final decision
   - "[Decision]"
   - Reason: [Why this direction]
```

---

## Synthesis Output Format

### Summary Block (for artifact creation)

```markdown
## Cross-Meeting Analysis: "[Topic]"

**Meetings analyzed:** X total
**Date range:** [Start] - [End]
**Key participants:** [Names]

### TL;DR
[2-3 sentences capturing the most important takeaways]

### Top Pain Points (by frequency)
1. "[Pain]" - X meetings
2. "[Pain]" - X meetings
3. "[Pain]" - X meetings

### Confirmed Decisions
- [Decision 1] - [Meeting]
- [Decision 2] - [Meeting]

### Strongest Evidence
> "[Most compelling quote]"
> — [Speaker], [Meeting]

### Open Questions Requiring Resolution
1. [Question]
2. [Question]

### Recommended Artifact
Based on this synthesis, the most valuable artifact would be: **[Type]**
Rationale: [Why this artifact addresses the key findings]
```

---

## Analysis Prompts

Use these prompts when analyzing meeting transcripts:

### For User Research Calls
```
Extract:
1. Every pain point mentioned (verbatim quotes preferred)
2. Their current workflow (what they do today)
3. What they wish they could do
4. Emotional reactions (frustration, delight, confusion)
5. Feature requests (explicit and implied)
```

### For Team Discussions
```
Extract:
1. Decisions made (not just discussed)
2. Action items and owners
3. Technical constraints mentioned
4. Timeline discussions
5. Dependencies identified
```

### For Design Reviews
```
Extract:
1. Feedback on current designs
2. Suggested changes
3. Concerns raised
4. Approvals given
5. Next steps agreed
```

### For Strategy/Planning
```
Extract:
1. Goals and OKRs mentioned
2. Prioritization decisions
3. Resource constraints
4. Risk factors
5. Success metrics
```

---

## Quality Checks

Before presenting synthesis:

- [ ] All pain points have frequency counts
- [ ] All decisions have meeting sources
- [ ] No assumptions made without evidence
- [ ] Open questions are clearly marked
- [ ] Themes are validated across multiple meetings
- [ ] Quotes are verbatim (not paraphrased)
- [ ] Conflicting perspectives are flagged
