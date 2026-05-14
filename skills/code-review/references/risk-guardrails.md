# Risk Guardrails Reference

Source: `CLAUDE.md`, `src/myproject/risk/engine.py`

## Default Limits
```yaml
max_leverage: 10.0
max_margin_utilization: 0.60
min_liquidation_buffer_pct: 0.15
max_position_notional_frac_equity: 0.25   # reverted from 0.90 — unsafe
max_net_exposure_frac_equity: 0.80
max_gross_exposure_frac_equity: 1.50
max_daily_loss_frac_equity: 0.03
max_weekly_loss_frac_equity: 0.06
max_peak_to_trough_drawdown_frac: 0.15
max_open_orders: 20
max_order_notional_frac_equity: 0.10
safe_mode_position_scale: 0.25
```

## Risk Modes
`NORMAL -> SAFE_MODE -> HALTED` (kill switch)
- Paper mode: fail-open (`except Exception: noqa: BLE001`)
- Live mode: fail-closed (`ErrorHandlingPolicy.fail_fast_unknown`)

## Config Precedence (CRITICAL)
YAML limits profiles **override** env vars. Always edit:
- `configs/limits.default.yaml`
- `configs/limits.paper.yaml`
- `configs/limits.live.yaml`

Env vars for risk fields (e.g., `HF_MAX_POSITION_FRAC_EQUITY`) only take effect
if the YAML profile does NOT contain that field.

## Strategy vs Risk Separation
- `HF_TARGET_LONG_USD` = strategy's desired position size
- `HF_MAX_POSITION_USD` = risk limit ceiling
- Rule: `target_long_usd <= 0.7 x max_position_usd` (chunking needs headroom)

## Costs (BybitEU)
- Maker: 0.02%, Taker: 0.055%
- Funding: every 8h (0000, 0800, 1600 UTC)
- API rate limits: 600 req/5s per IP; 10/s per UID for order endpoints
