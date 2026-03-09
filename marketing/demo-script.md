# Demo Video Script — design-action

**Duration**: 60–90 seconds
**Style**: Light terminal theme, warm overlays, Remotion animated text
**Music**: Lo-fi ambient (optional, low volume)
**Voiceover**: Optional (ElevenLabs) or text-only with animated captions

---

## Scene 1: Hook (0:00–0:05)

**Visual**: White background. Text types in one letter at a time:

> "Your design meetings have 47 decisions buried in them."

Beat. Then:

> "You're probably tracking 3."

**Animation**: Numbers "47" and "3" highlight in coral and accent respectively.

---

## Scene 2: The Problem (0:05–0:15)

**Visual**: Five source icons (Meeting, Jira, Slack, Figma, Video) arranged in a circle. They float apart chaotically — the "scatter" animation from the landing page.

**Text overlay**: "Design evidence lives in 5+ tools"

**Animation**: Each icon has a label that fades in:
- 🎙️ "PM sync — Monday"
- 📋 "PROJ-456 — Sprint backlog"
- 💬 "#product-feedback — Tuesday"
- 🎨 "Figma comment — Wednesday"
- 📹 "User interview — last week"

**Text overlay** (bottom): "By Friday, you've forgotten Monday."

---

## Scene 3: The Solution (0:15–0:20)

**Visual**: Terminal window (light theme) appears. Clean, warm background.

**Typed command**:
```
/design-action --topic "onboarding"
```

**Text overlay**: "One command. Five phases."

---

## Scene 4: The Pipeline (0:20–0:50)

**Visual**: Split screen — terminal output on left, visual representation on right.

### Phase 1: Gather (0:20–0:28)
- Terminal shows: "Searching Granola... 12 meetings found"
- Terminal shows: "Searching Jira... 8 tickets matched"
- Terminal shows: "Searching Slack... 3 threads found"
- Right side: The five scattered icons converge into a stack

### Phase 2: Synthesize (0:28–0:35)
- Terminal shows extraction output:
  ```
  Pain Points: 6 identified (4 cross-referenced)
  Decisions: 3 confirmed
  Open Questions: 2 flagged
  Verbatim Quotes: 8 captured
  ```
- Right side: Cards slide in showing pain point + sources

### Phase 3: Suggest (0:35–0:40)
- Terminal: "Recommended artifact: Journey Map (evidence: 4 pain points with user flow context)"
- Right side: Journey map wireframe appears

### Phase 4: Create (0:40–0:48)
- Terminal: Artifact being generated with progress
- Right side: Journey map fills in with content, each element has a small source tag
- **Key moment**: Zoom into one element showing:
  - "Pain Point: Onboarding confusion"
  - "Sources: Customer Call (Mar 7), PROJ-456, #product-feedback"
  - "4 mentions · STRONG evidence"

### Phase 5: Track (0:48–0:50)
- Terminal: "DDR created: DDR-2026-001-onboarding-simplification.md"
- Terminal: "Backlog updated: 3 new items added"

---

## Scene 5: The Payoff (0:50–1:00)

**Visual**: Side-by-side comparison with a smooth slide transition.

**Left**: The five scattered source icons, semi-transparent, chaotic
**Right**: The completed journey map, clean, with visible source tags on each element

**Text overlay**: "Every element traces back to its source."

---

## Scene 6: CTA (1:00–1:10)

**Visual**: Clean white background. Text center-aligned.

**Line 1** (large): `design-action`
**Line 2** (medium): "Evidence-grounded design synthesis"
**Line 3** (code block):
```
npx skills add lolasalehu-rgb/design-action-plugin
```

**Line 4** (small): "Free for personal use"
**Line 5** (link): GitHub URL + landing page URL

**Animation**: Gentle fade-in, each line 0.3s after the previous.

---

## Production Notes

### Remotion Setup
- Project location: `~/Desktop/coding/design-action-demo/`
- Use `new-project design-action-demo vite` + `pnpm add remotion @remotion/cli`
- Compositions: `Hook`, `Problem`, `Pipeline`, `Payoff`, `CTA`
- Duration: 30fps × 90s = 2700 frames
- Resolution: 1920×1080

### Terminal Recording
- Tool: Tella or FocuSee
- Terminal theme: Light (match landing page cream background)
- Font: Same Kiro.dev stack or SF Mono
- Record actual `/design-action` run with sample data

### Color Palette (match landing page)
- Background: #faf9f7
- Accent: #7c5cfc
- Coral: #f27059
- Teal: #2db5a3
- Text: #1a1a1a
- Muted: #7a7a7a

### Social Cuts
- **Twitter**: 0:00–0:50 (skip detailed pipeline, keep hook + payoff)
- **LinkedIn**: Full 90s version
- **GIF**: Scene 4 Phase 4 only (the "every element cites its source" moment) — 10s loop
