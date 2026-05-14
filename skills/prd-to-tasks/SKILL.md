---
name: prd-to-tasks
description: Break a PRD into independently-grabbable tasks using tracer-bullet vertical slices, tagged as HITL (human-in-the-loop) or AFK (fully autonomous). Use when user wants to convert a PRD to tasks, create implementation work items, or break down a spec into sprint tasks.
---

### Process

1. **Locate the PRD** -- Ask the user for the PRD file path or content. Check `docs/vault/sprints/` for existing PRDs. If the PRD was created with `/write-a-prd`, it should already be there.

2. **Explore the codebase (optional)** -- If not already explored, do so to understand current state and identify integration points.

3. **Draft vertical slices** -- Break the PRD into tracer bullet tasks. Each task is a thin vertical slice cutting through ALL integration layers end-to-end (not horizontal).

   **Slice types:**
   - **HITL** (Human-In-The-Loop) -- requires your input: architectural decisions, design review, trade-off choices, risk policy decisions
   - **AFK** (Away-From-Keyboard) -- can be implemented and merged by Claude without your interaction

   **AFK is preferred.** Only mark HITL when the task genuinely requires a human decision.

   **Rules:**
   - Each slice delivers a narrow but COMPLETE path through every relevant layer (domain models, engine logic, risk checks, API endpoints, tests, config)
   - A completed slice is verifiable on its own
   - Prefer many thin slices over few thick ones
   - Each slice must leave the codebase in a working state (`pytest tests/` passes)

4. **Quiz the user** -- Present proposed breakdown as a numbered list showing:
   - Title
   - Type (HITL / AFK)
   - Blocked by (dependencies on other slices)
   - User stories covered

   Then ask about: granularity, dependency correctness, whether slices should be merged/split, HITL/AFK correctness. Iterate until approved.

5. **Create task list** -- For each approved slice, write to `docs/vault/sprints/` as a task breakdown file. Use the template below. Order by dependencies (blockers first).

### Task Template

For each slice in the output file:

```markdown
### Task N: [Title] [HITL|AFK]

**Blocked by:** Task M / None
**User stories:** [which PRD user stories this covers]

**What to build:**
[Concise end-to-end behavior description. Reference PRD sections, don't duplicate them.]

**Acceptance criteria:**
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Tests pass]

**Layers touched:**
[Which parts of the event pipeline: Domain / Strategy / Risk / Engine / Exchange / API / Metrics / Config / Tests]
```

### Trading-Specific Considerations

- Tasks touching execution paths must specify paper-vs-live implications
- Tasks changing risk controls are always HITL (risk has veto power per AGENTS.md)
- Tasks adding new configuration must work with the YAML-overrides-env-vars model
- Reference the event pipeline layers: Market -> Strategy -> Risk -> Order -> Execution -> Fill -> Portfolio -> Metrics
- Cross-reference `AGENTS.md` governance for lifecycle gate requirements
