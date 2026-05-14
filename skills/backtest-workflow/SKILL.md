# Backtest Workflow

Standardized workflow for running parameter sweeps, walk-forward validation, and interpreting results.

## Trigger
- User says "run backtest", "sweep parameters", "walk-forward", or "validate strategy"

## Workflow

### Phase 1: Data Verification
1. Confirm data file exists at expected path (e.g., `data/merged_btcusd_4h.csv`)
2. Check row count, date range, and column completeness
3. Verify no gaps in timestamps (`prepare_price_target_backtest.py` handles this)

### Phase 2: Select Sweep Pass
Choose the appropriate sweep type:

| Pass | Script | Combos | Purpose |
|------|--------|--------|---------|
| Coarse | `sweep_price_target_params.py --pass coarse` | ~216 | Find profitable regions |
| Fine | `sweep_price_target_params.py --pass fine` | ~540 | Tune exit params on top-N |
| Regime | `sweep_price_target_params.py --pass regime` | ~2916 | Regime scaling on locked base |

See `references/sweep-params.md` for parameter ranges and meanings.

### Phase 3: Run Sweep
```bash
python scripts/backtest/sweep_price_target_params.py \
    --data data/merged_btcusd_4h.csv \
    --pass coarse \
    --output reports/backtest/sweep_results.csv
```

### Phase 4: Interpret Results
Key metrics to evaluate:
- **Return %**: Target > 0% (coarse), > 20% (fine)
- **Max Drawdown**: Must be < 15% for Gate 1
- **Trade Count**: Edge kicks in at 550+ trades
- **Sharpe Ratio**: Target > 0 (OOS), > 1.0 (in-sample)

See `references/evaluation.md` for detailed interpretation guide.

### Phase 5: Walk-Forward Validation
```bash
python scripts/backtest/walk_forward_price_target.py \
    --data data/merged_btcusd_4h.csv \
    --output reports/backtest/walk_forward_results.csv
```

Walk-forward config: 180d train / 30d validate / 30d test / 30d step.

### Phase 6: Archive Results
1. Save sweep CSV to `reports/backtest/`
2. Create vault note in `docs/vault/evaluation/` using the `_templates/experiment-result.md` template
   - Set `result:` field to `positive`, `negative`, or `inconclusive`
   - **ALL outcomes must be archived** — negative results are as valuable as positive ones
   - For negative results: fill "What to Avoid" section with specific configs/approaches that failed
   - Link to the raw data in `reports/backtest/` via the `source:` frontmatter field
3. Update sprint tracker

## Key Constraints
- **Locked params** (Sprint 2): BMT=0.30, decay=0.05, exit=fixed_stop_tp, SL=0.02, TP=0.06
- **Hit tolerance**: avoid 0.003 (parameter cliff — see parameter-cliff-analysis)
- **Trade count**: target 550+ for statistical edge
- **Gate 1 criteria**: Walk-forward OOS Sharpe >= 0, max DD <= 15%

## References
- `references/sweep-params.md` — parameter ranges and meanings
- `references/evaluation.md` — interpreting walk-forward results
