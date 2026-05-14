---
name: improve-codebase-architecture
description: Explore the codebase to find architectural improvement opportunities, focusing on deepening shallow modules and improving testability. Use when user wants to improve architecture, find refactoring opportunities, consolidate tightly-coupled modules, or make the codebase more maintainable.
---

Explore the codebase organically, surface architectural friction, discover opportunities for improving testability, and propose module-deepening refactors as vault RFCs.

A **deep module** (John Ousterhout) has a small interface hiding a large implementation. Deep modules are more testable, more navigable, and let you test at the boundary instead of inside.

### Process

1. **Explore the codebase** -- Use the Agent tool with subagent_type=Explore. Also use codebase-memory-mcp tools (`search_graph`, `query_graph`, `trace_call_path`) for quantitative backing. Do NOT follow rigid heuristics -- explore organically and note friction:
   - Where does understanding one concept require bouncing between many small files?
   - Where are modules so shallow the interface is nearly as complex as the implementation?
   - Where have pure functions been extracted just for testability, but real bugs hide in how they're called?
   - Where do tightly-coupled modules create integration risk in the seams?
   - Which parts are untested or hard to test?
   - The friction you encounter IS the signal.

2. **Present candidates** -- Numbered list of deepening opportunities. For each: cluster (which modules/concepts), why they're coupled, dependency category (see [REFERENCE.md](REFERENCE.md)), test impact (what tests would be replaced by boundary tests). Do NOT propose interfaces yet. Ask user which to explore.

3. **User picks a candidate**.

4. **Frame the problem space** -- Write user-facing explanation: constraints any new interface must satisfy, dependencies it would rely on, rough illustrative code sketch (not a proposal, just grounding). Show to user, then immediately proceed to Step 5.

5. **Design multiple interfaces** -- Spawn 3+ sub-agents in parallel using the Agent tool. Each gets separate technical brief with different design constraint: minimize interface (1-3 entry points), maximize flexibility, optimize for common caller, ports & adapters pattern. Each outputs: interface signature, usage example, what it hides, dependency strategy, trade-offs. Present sequentially, then compare in prose. **Give your own recommendation** -- be opinionated.

6. **User picks an interface** (or accepts recommendation).

7. **Create vault RFC** -- Write to `docs/vault/sprints/` or `reports/` with the problem, proposed interface, dependency strategy, testing strategy, and implementation recommendations. Do NOT include specific file paths in the implementation section (they become outdated).
