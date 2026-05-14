---
name: request-refactor-plan
description: Create a detailed refactor plan with tiny commits via user interview, then output as a vault sprint doc or report. Use when user wants to plan a refactor, create a refactoring RFC, or break a refactor into safe incremental steps.
---

### Steps

1. Ask user for long, detailed description of the problem and potential solution ideas.
2. Explore the repo to verify assertions and understand current state.
3. Ask whether they've considered other options; present alternatives.
4. Interview the user about implementation -- extremely detailed and thorough.
5. Hammer out exact scope -- what to change, what NOT to change.
6. Check test coverage of the area. If insufficient, ask about testing plans.
7. Break implementation into **tiny commits**. Martin Fowler's advice: "make each refactoring step as small as possible, so that you can always see the program working."
8. Output the refactor plan to `docs/vault/sprints/` or `reports/` depending on scope.

### Output Template

- **Problem Statement** -- from the developer's perspective
- **Solution** -- from the developer's perspective
- **Commits** -- LONG, detailed implementation plan in plain English. Tiniest commits possible. Each leaves codebase in working state. Each commit must pass `pytest tests/`.
- **Decision Document** -- modules built/modified, interface changes, technical clarifications, architectural decisions. Do NOT include specific file paths or code snippets (may become outdated).
- **Testing Decisions** -- what makes a good test (only test external behavior), which modules will be tested, prior art in `tests/`.
- **Out of Scope** -- what is explicitly excluded.
- **Governance Gates** -- any risk guardrails, lifecycle gates, or AGENTS.md rules that apply.

### Project-Specific Rules

- Cross-reference `AGENTS.md` governance for risk/lifecycle changes
- Check `reports/findings/` for known issues in the affected area
- Respect the event pipeline ordering when planning changes
- Never plan changes that would mix research and production code paths
- Consider paper-vs-live implications of any execution path changes
