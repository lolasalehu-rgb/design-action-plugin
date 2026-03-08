# DDR-001: Onboarding Wizard with Progressive Disclosure

**Status:** Accepted
**Date:** 2026-03-07
**Stream:** my-product
**Author:** Jordan (Designer)

## Context

Over a 2-week period, 4 separate customer calls surfaced the same friction: new users don't know where to start after first login. The empty dashboard provides no guidance, and setup steps aren't presented in a logical sequence.

This was discussed in Sprint Planning (Mar 7) and confirmed as a sprint priority.

## Decision

Build a step-by-step onboarding wizard that:
1. Appears on first login (dismissible after completion)
2. Uses progressive disclosure — only shows steps relevant to the user's setup type
3. Persists progress across sessions (users can return where they left off)
4. Replaces the empty dashboard state with guided next steps

## Alternatives Considered

1. **Tooltip tour**: Rejected — tooltips are easy to dismiss and don't enforce sequence. Users reported needing structured guidance, not hints.
2. **Video walkthrough in empty state**: Deferred — good supplementary content but doesn't solve the "what do I do next" problem. May add after wizard ships.
3. **Documentation link**: Rejected — customers explicitly said they shouldn't need to leave the app to figure out setup.

## Evidence

- "I spent 20 minutes just trying to find where to start" — Taylor (PM), Acme Corp Call, Mar 7
- "The dashboard is empty and there's no guidance" — User Research Session, Mar 3
- "I expected a wizard or checklist" — User Research Session, Mar 3
- "I didn't realize I needed to do that first" — Acme Corp Call, Mar 7
- 3/5 user research participants mentioned onboarding confusion unprompted

## Impact

- **User Impact**: HIGH — directly addresses #1 reported friction point
- **Technical Impact**: MEDIUM — requires new wizard component + progress persistence API
- **Business Impact**: HIGH — onboarding friction is correlated with trial-to-paid conversion drop-off

## Next Steps

- [x] Create interactive prototype for validation
- [ ] User test prototype with 3 customers
- [ ] Refine based on feedback
- [ ] Hand off to engineering with annotated specs

---
*Created by design-action. Status: Accepted (Mar 7, 2026)*
