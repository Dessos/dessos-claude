# Known Issues (22 Findings)

Source: `LOGIC_ANALYSIS_REPORT.md`

## Critical (2)
| ID | Description | Status |
|----|-------------|--------|
| F001 | Batch order risk gap: multi-intent loop doesn't accumulate positions | **FIXED** March 2026 |
| F002 | ML strategy crashes on non-numeric feature data | **OPEN** (flagged off with 0 credits) |

## High (6)
| ID | Description | Status |
|----|-------------|--------|
| F003 | Peak equity ratchet never resets after anomalous ticks | **FIXED** |
| F004 | Fill reconciliation fallback matches first active order by symbol+side | **FIXED** |
| F005 | Daily loss check bypassed before first market event | **FIXED** |
| F006 | Credit sync_usage_from_exposure can lock out strategies | **OPEN** |
| F007 | Funding loop unbounded after long disconnect | **FIXED** (1000 iter cap) |
| F008 | Non-retryable errors silently swallowed in live mode | **PARTIAL** (SAFE_MODE, not HALTED) |

## Medium (10)
| ID | Description | Status |
|----|-------------|--------|
| F009 | Fill dedup hash collision without fill_identity_key | OPEN |
| F010 | VaR/ES excludes zero-equity returns | OPEN |
| F011 | Epsilon inconsistency between portfolio/risk/sizing | OPEN (known) |
| F012 | Projected risk context double-counts pending + target | OPEN (conservative) |
| F013 | Fill zeroing window creates temporary exposure overcount | OPEN (conservative) |
| F014-F018 | Various edge cases in state ordering, timezone, dedup | OPEN |

## Low (4)
| ID | Description | Status |
|----|-------------|--------|
| F019-F022 | Documentation fragility, operator surprise, metric gaps | OPEN |

## Watch Zones
When reviewing changes near these files, extra caution:
- `engine/engine.py` — F001, F008, F010, F013 (widest blast radius)
- `risk/engine.py` — F003, F005, F012
- `engine/credit_allocator.py` — F006
- `strategy/ml_mean_reversion.py` — F002
- `domain/portfolio.py` — F005, F011
