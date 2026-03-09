# Scoring Framework

Customize how design items are prioritized. Edit `~/.design-action/config.yaml` to change dimensions and weights.

## Default Dimensions

### User Impact (Weight: 0.4)
How much does this help users accomplish their goals?

| Score | Meaning |
|-------|---------|
| 5 | Critical — users are blocked without this |
| 4 | High — significant friction reduction |
| 3 | Medium — noticeable improvement |
| 2 | Low — minor convenience |
| 1 | Minimal — barely affects users |

### Business Value (Weight: 0.3)
How much does this drive business outcomes?

| Score | Meaning |
|-------|---------|
| 5 | Direct revenue impact or critical retention risk |
| 4 | High strategic value, affects key metrics |
| 3 | Moderate impact on business goals |
| 2 | Indirect or long-term value |
| 1 | Nice-to-have, no clear business case |

### Effort (Weight: 0.2, Inverted)
Engineering and design complexity. Higher effort = lower priority (inverted).

| Score | Meaning |
|-------|---------|
| 5 | Very complex — weeks of work, cross-team coordination |
| 4 | Complex — days of work, significant design + engineering |
| 3 | Moderate — a few days, well-understood scope |
| 2 | Simple — a day or less, clear implementation |
| 1 | Trivial — hours, copy/config change |

### Strategic Alignment (Weight: 0.1)
How well does this align with current product strategy?

| Score | Meaning |
|-------|---------|
| 5 | Core to current strategy — directly supports OKRs |
| 4 | Strongly aligned — supports strategic themes |
| 3 | Moderately aligned — relevant but not primary |
| 2 | Tangentially related |
| 1 | Off-strategy — may still be valuable but not aligned |

## Priority Calculation

```
priority = Σ (score[i] × weight[i] × direction[i])
```

Where `direction[i]` = 1 for normal dimensions, -1 for inverted dimensions.

**Example:**
- User Impact: 4 × 0.4 = 1.6
- Business Value: 3 × 0.3 = 0.9
- Effort: 2 × 0.2 × -1 = -0.4
- Strategic Alignment: 4 × 0.1 = 0.4
- **Priority: 2.5**

## Customization

### Adding Dimensions

Add to `scoring.dimensions[]` in config:
```yaml
scoring:
  dimensions:
    - name: "Technical Debt"
      weight: 0.15
      description: "Does this reduce technical debt?"
    - name: "User Impact"
      weight: 0.35
      # ... etc
```

Weights must sum to 1.0.

### Domain-Specific Examples

**E-commerce/Marketplace:**
- User Impact → "Buyer Experience"
- Business Value → "GMV Impact"
- Add: "Seller Experience" dimension

**SaaS/B2B:**
- User Impact → "Admin Productivity"
- Business Value → "Churn Reduction"
- Add: "Implementation Complexity" (inverted)

**Consumer App:**
- User Impact → "User Delight"
- Business Value → "Engagement/Retention"
- Add: "Virality Potential"
