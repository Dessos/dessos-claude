# Sweep Parameter Reference

Source: `scripts/backtest/sweep_price_target_params.py`

## Coarse Grid (~216 combos)
| Parameter | Values | Meaning |
|-----------|--------|---------|
| `hit_tolerance_frac` | 0.001, 0.003, 0.005, 0.008 | How close price must be to a level to trigger. **Avoid 0.003** (parameter cliff) |
| `breakout_momentum_threshold` | 0.30, 0.60, 0.90 | Momentum needed to switch from mean-reversion to breakout. **Lock 0.30** |
| `outer_level_decay` | 0.05, 0.15, 0.30 | How much outer levels (r6/s6) are discounted vs inner (r1/s1). **Lock 0.05** |
| `min_signal_strength` | 0.05, 0.10 | Minimum signal to generate a trade. Lower = more trades |
| `max_position_usd` | 5000.0 | Position cap |
| `exit_mode` | none, fixed_stop_tp, trailing | Exit strategy |

## Fine Exit Grid (~540 combos, applied to top-10 coarse winners)
| Parameter | Values | Meaning |
|-----------|--------|---------|
| `stop_loss_frac` | 0.01, 0.02, 0.03 | Stop loss as fraction of entry price. Sweet spot: **0.02** |
| `take_profit_frac` | 0.02, 0.04, 0.06 | Take profit fraction. Sweet spot: **0.06** (3:1 R:R) |
| `trailing_stop_frac` | 0.01, 0.015, 0.025 | Trailing stop distance. Sweet spot: **0.015-0.025** |

## Regime Grid (~2916 combos, applied on locked Sprint 2 base)
| Parameter | Values | Meaning |
|-----------|--------|---------|
| `regime_scale_trending_up` | 0.5, 0.7, 0.9 | Position scale in uptrend |
| `regime_scale_trending_down` | 0.3, 0.5, 0.7 | Position scale in downtrend (key weakness target) |
| `regime_scale_high_vol` | 0.4, 0.6, 0.8 | Position scale in high volatility |
| `magnitude_boost` | 0.0, 0.5, 1.5, 3.0 | How much momentum amplifies sizing |
| `vol_high_threshold` | 0.60, 0.80, 1.00 | Annualized vol threshold for HIGH_VOL regime |
| `trending_momentum_threshold` | 0.02, 0.03, 0.05 | Momentum threshold for trending regime |
| `min_signal_strength` | 0.03, 0.05, 0.10 | Minimum signal (overrides coarse value) |

## Parameter Cliffs (from Sprint 2 analysis)
1. **BMT 0.30 vs 0.60**: -19pp return. Lock at 0.30.
2. **Decay 0.05 vs 0.15**: -12pp return. Lock at 0.05.
3. **HTF 0.003**: -21pp vs 0.001 or 0.005. Avoid 0.003.
4. **Trade count**: Edge kicks in at 550+ trades. Target high trade count.
5. **SL=0.02, TP=0.06**: 3:1 R:R = 90% win rate across fine sweep.
