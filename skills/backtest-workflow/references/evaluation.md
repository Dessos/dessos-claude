# Walk-Forward Evaluation Guide

Source: `scripts/backtest/walk_forward_price_target.py`

## Walk-Forward Configuration
- **Train**: 180 days — mini-sweep to select best params
- **Validate**: 30 days — confirm params (reject if Sharpe < -1)
- **Test**: 30 days — out-of-sample evaluation (recorded)
- **Step**: 30 days — rolling window advance
- **Periods**: ~80 over 7 years of BTC 4h data

## Gate 1 Criteria (BACKTEST -> PAPER)
| Metric | Threshold | Notes |
|--------|-----------|-------|
| OOS Sharpe (avg) | > 0 | Average across all test periods |
| OOS Sharpe (median) | > 0 | Median more robust to outliers |
| Max drawdown | < 15% | Per-period and cumulative |
| Leakage audit | Clean | No look-ahead bias detected |
| Results exist | Files present | CSV + aggregate JSON |

## Interpreting Results

### Good Signs
- Median Sharpe > mean Sharpe (right-skewed = occasional big wins)
- Win rate > 50% across periods
- Low variation in per-period returns
- Bull AND bear regime periods show positive Sharpe

### Warning Signs
- Mean Sharpe >> median (left-skewed = occasional catastrophic periods)
- Win rate below 40% in any regime
- Sharpe < -1 in validation (params not stable)
- In-sample to OOS degradation > 5x (overfitting)

### Regime Breakdown
Always check per-regime results:
| Regime | Healthy Win Rate | Current Weakness |
|--------|-----------------|------------------|
| Bull | > 60% | - |
| Low Vol | > 55% | - |
| Ranging | > 45% | Marginal |
| Bear | > 40% | **38% (Sprint 3 target)** |

## Trade Count Dependency
```
< 100 trades:    avg return -9.6%   (insufficient samples)
100-400 trades:  avg return -10.2%  (still insufficient)
400-550 trades:  avg return +7.8%   (edge emerging)
550+ trades:     avg return +15.7%  (edge compounds)
```

## Sprint 2 Best Results (reference)
- Best in-sample: **+107.6%**, 7.3% DD, trailing exit
- Best OOS avg Sharpe: **0.121**, 53.8% win rate
- Annualized OOS: ~2.9%/year (20% cumulative over 80 months)
