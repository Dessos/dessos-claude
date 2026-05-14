# Refactor Candidates

After TDD cycle, look for:

- **Duplication** -- extract function/class
- **Long methods** -- break into private helpers, keep tests on public interface
- **Shallow modules** -- combine or deepen
- **Feature envy** -- move logic to where data lives
- **Primitive obsession** -- introduce value objects (e.g., `Money`, `Quantity`, `Symbol`)
- **Existing code the new code reveals as problematic** -- file a finding if out of scope

## Project-Specific Patterns

- Dedup caches use manual `set` + `deque` sync -- known fragile pattern, candidate for deepening
- Epsilon values are intentionally per-domain (1e-8 portfolio, 1e-9 risk, 1e-12 sizing) -- don't "fix" this
- Error handling uses `except Exception: noqa: BLE001` for fail-open paths -- intentional
