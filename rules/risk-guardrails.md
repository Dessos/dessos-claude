---
description: Risk guardrails, modes, and fail-open/closed policy for trading engine and risk module
paths:
  - src/myproject/risk/**
  - src/myproject/engine/**
  - configs/limits.*
---

# Risk Guardrails

**Canonical source**: [`docs/governance/RISK_GUARDRAILS.md`](../../docs/governance/RISK_GUARDRAILS.md) — always check there for current values.

## Risk Modes

`NORMAL → SAFE_MODE → HALTED` (kill switch). Order matters — no skipping levels.

- **Paper mode**: fail-open (`except Exception: noqa: BLE001`)
- **Live mode**: fail-closed (`ErrorHandlingPolicy.fail_fast_unknown`)

## Key Defaults (verify against YAML before changing)

```yaml
max_leverage: 10.0
max_margin_utilization: 0.60
min_liquidation_buffer_pct: 0.15
max_position_notional_frac_equity: 0.25  # reverted March 2026 — 0.90 was unsafe
max_net_exposure_frac_equity: 0.80
max_gross_exposure_frac_equity: 1.50
max_daily_loss_frac_equity: 0.03
max_weekly_loss_frac_equity: 0.06
max_peak_to_trough_drawdown_frac: 0.15
max_open_orders: 20
max_order_notional_frac_equity: 0.10
safe_mode_position_scale: 0.25
```

Do NOT relax any guardrail without explicit user instruction.

## Epsilon Values (per-module)

- Portfolio: `1e-8` — `domain/portfolio.py`
- Risk (reduce_only): `1e-9` — `core/constants.py`
- Sizing: `1e-12` — `engine/sizing.py`

Do NOT "fix" epsilon inconsistency without explicit discussion — each was chosen for its domain.
