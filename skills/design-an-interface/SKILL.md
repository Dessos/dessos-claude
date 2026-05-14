---
name: design-an-interface
description: Generate multiple radically different interface designs for a module using parallel sub-agents. Use when user wants to design an API, explore interface options, compare module shapes, or mentions "design it twice".
---

Based on "Design It Twice" from "A Philosophy of Software Design": your first idea is unlikely to be the best. Generate multiple radically different designs, then compare.

### Workflow

1. **Gather Requirements** -- What problem does this module solve? Who are the callers? Key operations? Constraints? What should be hidden vs exposed?

2. **Generate Designs (Parallel Sub-Agents)** -- Spawn 3+ sub-agents simultaneously using the Agent tool. Each must produce a **radically different** approach. Assign different constraints:
   - Agent 1: "minimize method count (1-3 max)"
   - Agent 2: "maximize flexibility and composability"
   - Agent 3: "optimize for the most common caller pattern"
   - Agent 4 (optional): "take inspiration from [specific paradigm/library]"

   Each outputs: interface signature (Python classes/protocols with type hints), usage example, what it hides internally, trade-offs.

3. **Present Designs** -- Show each with interface signature, usage examples, what it hides. Present sequentially so user can absorb each.

4. **Compare Designs** on:
   - Interface simplicity (fewer methods = better)
   - General-purpose vs specialized
   - Implementation efficiency
   - Depth (small interface hiding significant complexity = good)
   - Ease of correct use vs ease of misuse
   - Pydantic model compatibility
   - EventBus integration patterns

   Discuss in prose, not tables. Highlight where designs diverge most.

5. **Synthesize** -- Often best design combines insights. Ask: "Which design best fits your primary use case?" and "Any elements from other designs worth incorporating?"

### Anti-Patterns

- Don't let sub-agents produce similar designs -- enforce radical difference via constraints
- Don't skip comparison -- the value is in contrast
- Don't implement -- purely about interface shape
- Don't evaluate based on implementation effort

### Python Conventions

- Use `typing.Protocol` for interface definitions
- Use Pydantic `BaseModel` for data structures
- Use `@dataclass` for pure value objects
- Type all parameters and return values
- Consider async vs sync based on I/O requirements
