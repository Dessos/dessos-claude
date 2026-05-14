---
name: write-a-prd
description: Create a Product Requirements Document through an interactive user interview, codebase exploration, and module design. Use when user wants to write a PRD, define product requirements, spec out a feature, or plan a new capability.
---

### Process

1. **Interview the user** -- Ask about the problem being solved, who benefits, success criteria, constraints, and non-goals. Be thorough but efficient.

2. **Explore the codebase** -- Understand existing patterns, modules, and conventions that the feature must integrate with. Check `AGENTS.md` for governance rules that apply.

3. **Design the module** -- Propose where the feature fits in the architecture, which existing modules it touches, and what new modules (if any) are needed.

4. **Draft the PRD** with these sections:
   - **Problem Statement** -- what pain exists today
   - **User Stories** -- who benefits and how (as a [role], I want [capability], so that [benefit])
   - **Scope** -- what's in, what's explicitly out
   - **Implementation Decisions** -- architectural choices, module placement, integration points
   - **Testing Decisions** -- what to test, test tier (unit/integration/contract), test approach
   - **Risk & Governance** -- risk implications, lifecycle gates, paper-vs-live considerations
   - **Success Criteria** -- how we know it's done and working
   - **Non-Goals** -- explicitly excluded scope

5. **Output** -- Save to `docs/vault/sprints/` or present inline for user review.

### Trading-Specific Considerations

- Does this touch the execution path? If so, paper-vs-live implications are mandatory.
- Does this change risk controls? AGENTS.md governance applies, risk has veto power.
- Does this add new metrics? Must follow Prometheus conventions.
- Does this add new configuration? Must work with YAML-overrides-env-vars model.
- Does this affect the event pipeline? Map the impact through all stages.
