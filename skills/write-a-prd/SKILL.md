---
name: write-a-prd
description: Create a Product Requirements Document through an interactive user interview, codebase exploration, and module design. Use when user wants to write a PRD, define product requirements, spec out a feature, or plan a new capability.
---

### Process

1. **Interview the user** -- Ask about the problem being solved, who benefits, success criteria, constraints, and non-goals. Be thorough but efficient.

2. **Explore the codebase** -- Understand existing patterns, modules, and conventions that the feature must integrate with. Check the project's governance docs (`CLAUDE.md`, `AGENTS.md`, or equivalent) for rules that apply.

3. **Design the module** -- Propose where the feature fits in the architecture, which existing modules it touches, and what new modules (if any) are needed.

4. **Draft the PRD** with these sections:
   - **Problem Statement** -- what pain exists today
   - **User Stories** -- who benefits and how (as a [role], I want [capability], so that [benefit])
   - **Scope** -- what's in, what's explicitly out
   - **Implementation Decisions** -- architectural choices, module placement, integration points
   - **Testing Decisions** -- what to test, test tier (unit/integration/contract), test approach
   - **Risk & Governance** -- risk implications, lifecycle gates, environment-specific (dev/staging/prod) considerations
   - **Success Criteria** -- how we know it's done and working
   - **Non-Goals** -- explicitly excluded scope

5. **Output** -- Save to a project-appropriate location (e.g., `docs/sprints/`, `docs/vault/sprints/`, `docs/prds/`) or present inline for user review.

### Project-domain extension

To add project-specific PRD checks (governance rules, critical-path implications, lifecycle gates), drop a project-local override at `.claude/skills/write-a-prd/SKILL.md` and append a `### Project-Specific Considerations` section. Local skills take precedence over plugin skills, so the override layers on top.
