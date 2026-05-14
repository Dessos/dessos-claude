---
name: ubiquitous-language
description: Extract a DDD-style ubiquitous language glossary from the current conversation and codebase, flagging ambiguities and proposing canonical terms. Saves to UBIQUITOUS_LANGUAGE.md. Use when user wants to define domain terms, build a glossary, harden terminology, or mentions "domain model" or "DDD".
---

### Process

1. **Scan the conversation and codebase** for domain-relevant nouns, verbs, and concepts. Explore the domain / core / service directories (whatever your project's layout calls them) for term usage.
2. **Identify problems**: same word for different concepts (ambiguity), different words for same concept (synonyms), vague or overloaded terms.
3. **Propose a canonical glossary** with opinionated term choices.
4. **Write to `UBIQUITOUS_LANGUAGE.md`** in the project root.
5. **Output a summary** inline in the conversation.

### Output Format

Write `UBIQUITOUS_LANGUAGE.md` with:
- Grouped tables (Term | Definition | Aliases to avoid)
- Relationships section with bold term names and cardinality
- Example dialogue (3-5 exchanges between dev and domain expert showing terms used precisely)
- Flagged ambiguities section

### Rules

- **Be opinionated.** Pick the best term, list others as aliases to avoid.
- **Flag conflicts explicitly.** Call out ambiguous usage with clear recommendation.
- **Keep definitions tight.** One sentence max. Define what it IS, not what it does.
- **Show relationships.** Bold term names, express cardinality where obvious.
- **Only domain terms.** Skip generic programming concepts unless domain-specific.
- **Group terms into multiple tables** when natural clusters emerge.
- **Write an example dialogue** (3-5 exchanges) clarifying boundaries between related concepts.

### Commonly overloaded term clusters

Watch for these patterns of ambiguity (examples drawn from common domains — your project will have its own):

- **Identity collisions** — the same word used for two different concepts (e.g., "Order" = customer-facing purchase request vs internal queueing slot)
- **Synonym sprawl** — different words for the same concept (e.g., "User", "Account", "Customer", "Member" all referring to one entity)
- **Lifecycle confusion** — process-states vs domain-states (e.g., "Active" the user-state vs "Active" the subscription-state vs "Active" the session-state)
- **Aggregation conflation** — singular vs plural meaning (e.g., "Inventory" = the warehouse vs "Inventory" = one SKU)
- **Time-mode terms** — when a concept means different things in different modes (e.g., dev vs staging vs prod; draft vs published; simulation vs production)

### Re-running

When invoked again: read existing file, incorporate new terms, update evolved definitions (mark "(updated)"), add new entries (mark "(new)"), re-flag new ambiguities, rewrite example dialogue to incorporate new terms.

### Post-output instruction

State: "I've written/updated `UBIQUITOUS_LANGUAGE.md`. From this point forward I will use these terms consistently. If I drift from this language or you notice a term that should be added, let me know."
