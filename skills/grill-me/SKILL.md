---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

If a question can be answered by exploring the codebase, explore the codebase instead.

## Trading-Domain Awareness

When grilling plans that touch trading infrastructure:
- Cross-reference against `AGENTS.md` governance rules and lifecycle gates
- Check risk guardrails in `docs/governance/` — risk has veto power
- Verify paper-vs-live implications — research code must never call live exchange APIs
- Consider the event pipeline impact: Market -> Strategy -> Risk -> Order -> Execution -> Fill -> Portfolio -> Metrics
- Check if the plan respects the YAML-overrides-env-vars configuration model
