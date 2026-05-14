Append a manual pivot-levels row to `data/pivot_levels.csv`. Use when the user pastes a target set directly into chat (bypassing the Telegram ingestor). Usage: `/pivot-add <levels_raw>` where `<levels_raw>` is the `86830<84381<...<76136 - 74409>...>64499` format.

Arguments: $ARGUMENTS

## Steps

1. **Validate arguments**. `$ARGUMENTS` should be the full `levels_raw` string. It contains digits, `<`, `>`, ` - ` (separator), and spaces. If empty, STOP and ask the user for the string. Do NOT guess levels from chat history or charts.

2. **Detect explicit timestamp**. If the user said something like "timestamp HH:MM" or "@HH:MM UTC" in the same turn (e.g. to mirror a Telegram post time), plan to pass `--ts YYYY-MM-DDTHH:MM:00+00:00`. Otherwise let the script default to `now(UTC)` truncated to the minute.

3. **Run the helper script**:

   ```
   python scripts/data/add_pivot_levels.py "$ARGUMENTS"
   ```

   or, with explicit timestamp:

   ```
   python scripts/data/add_pivot_levels.py "$ARGUMENTS" --ts 2026-04-19T18:43:00+00:00
   ```

   The script wraps `myproject.ingestion.telegram_price_level`:
   - Validates format via the same regex as the Telegram ingestor
   - Computes `pivot = (r1 + s1) / 2` (banker's-rounded to int in CSV)
   - Atomic temp-file + `os.replace()` write (enricher hot-reloads on mtime change)
   - Dedups if the last row has the same `datetime`

4. **Report**. Echo the script's output verbatim, then add:
   - Final row count: `wc -l data/pivot_levels.csv`
   - One-line note: "enricher auto-reloads on mtime change, no restart needed"

5. **On dedup skip** (script prints `Wrote: False`): ask the user if they want to force a different minute (re-run with `--ts` one minute later). Don't loop silently.

## Rules

- **Don't fabricate targets.** If the string looks malformed (not 6 levels per side, decimals, wrong separator), the script returns exit 2 — surface that error instead of "fixing" the string.
- **No commits.** `data/pivot_levels.csv` is gitignored alpha data. This command mutates the file; never stage or commit it.
- **No chart-derived targets.** If the user only pasted a chart screenshot with no `levels_raw` string, STOP and ask for the string. The methodology's anchor is the numerical set, not OCR from charts.
- **Pivot ≠ spot price.** The CSV pivot is derived from `(r1 + s1) / 2`, not live BTC price. If the user asks "why is pivot 75272 when BTC is 74900" — that's normal, not a bug.
