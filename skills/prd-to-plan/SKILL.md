---
name: prd-to-plan
description: Convert a PRD into a multi-phase implementation plan using tracer-bullet vertical slices. Use when user has a PRD and wants an implementation plan, mentions "vertical slices", or wants to break a spec into phases.
---

### Philosophy

Every phase is a **tracer bullet** -- a thin, complete path through all integration layers. Not horizontal slices (all models, then all APIs, then all UI). Each phase produces working, testable code.

### Workflow

1. **Read the PRD** -- either from a file path the user provides or from the conversation.

2. **Identify integration layers** for this project:
   - Domain models / Pydantic schemas
   - Event definitions and EventBus handlers
   - Engine/strategy logic
   - Risk checks
   - Exchange/broker integration
   - API endpoints (FastAPI routers)
   - Metrics (Prometheus)
   - Tests (pytest)
   - Configuration (YAML + env vars)

3. **Identify durable architectural decisions** -- choices that must be made upfront because they affect all phases: data models, key interfaces, configuration shape, event types. List these first.

4. **Break into phases** -- each phase is a vertical slice:
   - Phase 1: Thinnest possible end-to-end path (the tracer bullet)
   - Phase 2-N: Each adds one meaningful capability, touching all relevant layers
   - Each phase must leave the codebase in a working state
   - Each phase must pass `pytest tests/`

5. **For each phase**, specify:
   - What capability it adds (user-visible behavior)
   - Which layers it touches
   - Key implementation decisions
   - What tests verify it works
   - Dependencies on prior phases

6. **Output** -- Save plan to `docs/vault/sprints/` as a markdown file. Include a summary table showing phases vs layers.

### Anti-Patterns

- Don't create a phase that's "set up all the models" -- that's a horizontal slice
- Don't defer testing to a final phase -- each phase includes its tests
- Don't plan more than 5-7 phases -- if you need more, the PRD scope is too large
- Don't create phases that can't be independently verified
