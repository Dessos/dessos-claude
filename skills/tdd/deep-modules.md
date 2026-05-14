# Deep Modules

**Deep module** = small interface + lots of implementation (good).
Few methods, simple params, complex logic hidden.

**Shallow module** = large interface + little implementation (avoid).
Many methods, complex params, just passes through.

When designing interfaces, ask:
- Can I reduce the number of methods?
- Can I simplify the parameters?
- Can I hide more complexity inside?

## Examples in This Project

**Deep**: `RiskManager.check_order(order) -> RiskVerdict` -- simple interface hiding margin calculation, position limit checks, loss tracking, mode transitions, reduce-only logic.

**Shallow**: A hypothetical `OrderValidator` that just calls `RiskManager` and `PositionTracker` without adding logic -- it's a pass-through that increases surface area without adding depth.
