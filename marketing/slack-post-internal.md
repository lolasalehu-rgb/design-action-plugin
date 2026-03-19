# Slack Post — #product-dev (Internal)

## Main Post

---

hey, i've been using this to turn meeting discussions into design prototypes faster. sharing in case it's useful to others.

it pulls context from Google Meet recordings + Jira tickets + Slack threads, synthesizes the evidence, and creates grounded artifacts — prototypes, journey maps, wireframes, research docs. every element cites its source, so no hallucinated design rationale.

1-min demo:

0:00 — how it works (one command: `/design-action --topic "product model navigation"`)
0:25 — what it produces (Digital Showroom + Activation prototypes)
0:49 — how to get started

GitHub: github.com/akeneo/design-action
Landing page: design-action-site.vercel.app

works with Google Meet recordings, Jira (AS8 + ADS), Slack, Figma, and Notion — the tools we already use.
no infrastructure needed. clone, install, point it at your meetings.

```
git clone git@github.com:akeneo/design-action.git
claude --plugin-dir ./design-action
/setup
```

[attached: demo video]

---

## Thread Reply (optional — prototyping strategy connection)

---

btw this also feeds into the prototyping strategy we've been exploring with pim-playground.

the flow: meeting evidence → design-action synthesis → stack-matched prototypes → pim-playground for stakeholder visibility.

Activation prototypes match AS8's stack (React 19 + Next.js + DSM) so they're directly absorbable. DS prototypes match DS's stack (Tailwind + shadcn). pim-playground acts as the central demo hub linking out to both.

so far it's helped create prototypes for error management, product model navigation, search experience, onboarding walkthrough, and PIM nav restructuring — all grounded in real meeting evidence rather than assumptions.

---

## Notes

- Post to: **#product-dev** (C031QDW61)
- Tone: Casual, peer-to-peer — "here's something useful", not a formal announcement
- Mirror: Souhail's pim-playground post style (timestamps, GitHub link, attached video)
- Video: Attach as file upload, not a link
- Timing: Afternoon (matches Souhail's post pattern)
