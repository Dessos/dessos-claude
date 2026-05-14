---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

If a question can be answered by exploring the codebase, explore the codebase instead.

## How to use

This skill ships as a generic interview workflow. To add project-specific awareness (governance rules, architectural constraints, risk gates, etc.), drop a project-local override at `.claude/skills/grill-me/SKILL.md` in your repo — local skills take precedence over plugin skills, so you can keep the interview core and append a `## Project-Domain Awareness` section that lists what to cross-reference.
