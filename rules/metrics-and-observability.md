---
description: Prometheus metrics emission rules, tick-level gauges, and process isolation
paths:
  - src/myproject/engine/**
  - src/myproject/metrics*
  - src/myproject/monitoring/**
---

# Metrics & Observability

## Tick-Level Gauges (MUST update on every market tick)

All Prometheus gauges on the trading hot path must be updated in `engine.py:_on_market()`, not only on signal/fill events. Gauges set only in `_record_exposure_and_pnl_metrics()` go stale between signals.

Current tick-level gauges: `market_price`, `portfolio_equity`, `position_qty`, `gross_exposure_usd`, `net_exposure_usd`, `daily_pnl_usd`.

## Process Isolation

- API container: port **8080**
- Paper-trader container: port **9105**
- Separate Python processes → independent `prometheus_client.REGISTRY` instances
- Trading engine metrics emit from paper-trader process
- Grafana dashboards: use `job=~"myproject-paper-trader|myproject-api"`, don't assume a single job label
