# Code Review

Quality gate checklist for reviewing code changes before commit or PR.

## Trigger
- User says "review this", "code review", or "check before merge"
- Before any PR creation

## Checklist

### 1. Risk Guardrails
- [ ] No risk limits relaxed without explicit user sign-off
- [ ] `max_position_notional_frac_equity` stays <= 0.25
- [ ] `target_long_usd` <= 0.7 x `max_position_usd`
- [ ] YAML config precedence respected (YAML overrides env vars)
- See `references/risk-guardrails.md`

### 2. Known Issues
- [ ] Changes don't reintroduce any of the 22 known findings
- [ ] Changes near known-issue locations are extra careful
- See `references/known-issues.md`

### 3. Test Coverage
- [ ] Every behavior change has accompanying tests
- [ ] Run `scripts/check-coverage.sh` for changed files
- [ ] All existing tests still pass (`pytest tests/`)

### 4. Security
- [ ] No secrets committed (env var names only, keys via secrets management)
- [ ] No injection, XSS, or OWASP top-10 vulnerabilities introduced
- [ ] Research code does NOT call live exchange APIs

### 5. Observability
- [ ] Trading, execution, risk, and data ops emit logs and metrics on critical paths
- [ ] Prometheus gauges updated on every market tick (not just signal/fill events)
- [ ] Process isolation respected (API vs paper-trader are separate registries)

### 6. Code Quality
- [ ] Minimal diffs — no formatting churn or broad rewrites
- [ ] Epsilon consistency: 1e-8 (portfolio), 1e-9 (risk/reduce_only), 1e-12 (sizing)
- [ ] Timestamps use `replace(tzinfo=timezone.utc)` for naive datetimes
- [ ] `ruff check` passes on changed files
- [ ] Symbol is `BTC/USDC` (not BTC/USDT)

### 7. Architecture
- [ ] Event pipeline preserved: Market -> Strategy -> Risk -> Order -> Execution -> Fill -> Portfolio -> Metrics
- [ ] No existing logic removed (additive only unless explicitly requested)
- [ ] Prefer editing existing files over creating new ones

## Scripts
- `scripts/check-coverage.sh` — pytest coverage scoped to changed files

## References
- `references/risk-guardrails.md` — risk defaults and modes
- `references/known-issues.md` — 22 findings from logic analysis
