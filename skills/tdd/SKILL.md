---
name: tdd
description: Test-driven development with red-green-refactor loop. Use when user wants to build features or fix bugs using TDD, mentions "red-green-refactor", wants integration tests, or asks for test-first development.
---

### Philosophy

**Core principle**: Tests should verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't.

**Good tests** are integration-style: they exercise real code paths through public APIs. They describe _what_ the system does, not _how_ it does it. A good test reads like a specification. These tests survive refactors because they don't care about internal structure.

**Bad tests** are coupled to implementation. They mock internal collaborators, test private methods, or verify through external means. Warning sign: your test breaks when you refactor, but behavior hasn't changed.

### Anti-Pattern: Horizontal Slices

**DO NOT write all tests first, then all implementation.** This is "horizontal slicing" -- treating RED as "write all tests" and GREEN as "write all code."

This produces crap tests: tests written in bulk test _imagined_ behavior, not _actual_ behavior. You end up testing the _shape_ of things rather than user-facing behavior.

**Correct approach**: Vertical slices via tracer bullets. One test -> one implementation -> repeat.

```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED->GREEN: test1->impl1
  RED->GREEN: test2->impl2
  RED->GREEN: test3->impl3
```

### Workflow

1. **Planning** -- Read the reference files for this step:
   - Read `.claude/skills/tdd/deep-modules.md` — understand deep vs shallow module design
   - Read `.claude/skills/tdd/interface-design.md` — interface design principles for testability

   Then: confirm interface changes, which behaviors to test, identify deep module opportunities, design for testability, list behaviors, get user approval. Ask: "What should the public interface look like? Which behaviors are most important to test?" You can't test everything -- confirm with the user which behaviors matter most.

2. **Tracer Bullet** -- Read the reference files for this step:
   - Read `.claude/skills/tdd/tests.md` — good vs bad test examples with Python/pytest patterns
   - Read `.claude/skills/tdd/mocking.md` — when to mock (system boundaries only) and how

   Then: write ONE test confirming ONE thing about the system. RED: test fails. GREEN: minimal code to pass.

3. **Incremental Loop** -- For each remaining behavior: RED (write next test, fails) -> GREEN (minimal code to pass). One test at a time. Only enough code to pass current test. Don't anticipate future tests.

4. **Refactor** -- Read the reference file for this step:
   - Read `.claude/skills/tdd/refactoring.md` — refactor candidates and project-specific patterns

   Then: extract duplication, deepen modules, apply SOLID where natural, consider what new code reveals about existing code, run tests after each step. **Never refactor while RED.**

### Checklist Per Cycle

- Test describes behavior, not implementation
- Test uses public interface only
- Test would survive internal refactor
- Code is minimal for this test
- No speculative features added

### Python/pytest Specifics

- Tests mirror source structure: `tests/unit/`, `tests/integration/`, etc.
- Use `pytest.fixture` for setup, `pytest.mark.parametrize` for data-driven cases
- Shared helpers in `tests/support/` (e.g., `metrics_test_utils.py`)
- Use `conftest.py` for fixtures shared across a test directory
- Run with `pytest tests/` or target specific tiers
- Use `tmp_path` fixture for file I/O, not hardcoded paths
- basetemp: `O:/Code/trading-project/.pytest_tmp`
