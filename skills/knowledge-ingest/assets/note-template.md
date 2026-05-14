---
type: knowledge
status: draft
created: 2026-03-18T12:00:00Z
updated: 2026-03-18T12:00:00Z
tags: [quantitative-methods, topic/kelly-criterion]
related:
  - "[[verified-trading-quantitative-principles]]"
confidence: medium
source: "https://example.com/article-about-kelly"
source_type: article
---

# Kelly Criterion for Fractional Sizing

## Key Insights
- Half-Kelly (f*/2) reduces variance by 75% while only losing 25% of growth rate
- Full Kelly is optimal for log-wealth but has extreme drawdowns in practice
- Estimation error in win probability makes quarter-Kelly safer for live trading

## Actionable Items
- Consider implementing quarter-Kelly as default fractional sizing
- Add win-probability estimation to backtest evaluation pipeline

## Context
Article discusses practical applications of Kelly criterion in systematic trading,
with emphasis on the estimation error problem and why conservative fractions are
preferred in production systems.

## Related Work
- [[strategy/adaptive-price-level]] — could use Kelly for position sizing
- [[risk/canonical-guardrails]] — Kelly must respect risk limits
