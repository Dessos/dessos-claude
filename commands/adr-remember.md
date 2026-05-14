Append a single-line pattern to the ADR PATTERNS section with preview-then-confirm safety. Writes through `scripts/_lib/adr_remember_dispatch.py` which performs **client-side projection + pre-write disk backup** — never sends `dry_run` (the flag is silently ignored by the CCM binary, see V6-156).

Usage: `/adr-remember "<text>" <module>` (text quoted, module is one of the `src/myproject/<module>/` directory names)

Arguments: $ARGUMENTS

## Steps

### Step 1 — Prepare the action

Run the prepare command and capture stdout as JSON:

```bash
PYTHONIOENCODING=utf-8 python scripts/_lib/adr_remember_dispatch.py prepare $ARGUMENTS
```

The dispatch helper does steps 1-7 in a single hermetic call: parse args, validate (5 rules), fetch current PATTERNS via `mode=get`, dedupe-check, project the new body in Python, run the budget check. **No write happens here** — only `manage_adr get` (read-only) is touched.

The stdout is a JSON envelope. Inspect `status`:

- **`"aborted"`** → print the `error` field as-is to the operator and STOP. The `rule` field tags which validation tripped (`parse | module_whitelist | text_length | no_newline | no_bracket_prefix | duplicate_line | budget_abort`). Exit code is non-zero. Do NOT proceed to AskUserQuestion.
- **`"ok"`** → continue to step 2. The envelope contains:
  - `preview` — the rendered diff block (display this verbatim)
  - `state_path` — temp file path holding the prepared state for step 3
  - `module`, `text`, `candidate_line` — for context

### Step 2 — Show preview and confirm

Print the `preview` field exactly as-is (it is already formatted as a markdown block with the budget bar and git-diff-style 3-line context).

Then call `AskUserQuestion` with these options:

- `Approve` — apply the update
- `Cancel` — silent exit; ctrl+c-and-retry to revise

Do NOT offer an "Edit before approving" option. The preview itself is the editing surface — if the operator wants to revise, they cancel and re-invoke with new text.

### Step 3 — On Approve, commit

Run the commit command with the `state_path` from step 1:

```bash
PYTHONIOENCODING=utf-8 python scripts/_lib/adr_remember_dispatch.py commit "<state_path>"
```

The commit command:
1. Writes a pre-write disk backup to `O:/Temp/hf-adr-backup-<ISO8601>.json` (JSON envelope with `pre_write_patterns` and `candidate_line` — the rollback hatch)
2. Sends a single `manage_adr update` call (no `dry_run` flag — the V6-156 guard would raise if it were passed)
3. Re-fetches PATTERNS and asserts the body matches the projection byte-for-byte
4. Emits telemetry to `O:/Temp/hf-hook.jsonl` under `hook: "adr-remember"`

Inspect the JSON output:

- **`"status": "ok"`** → print a one-line success summary including `module`, `candidate_line`, `char_delta`, and `backup_path`. Done.
- **`"status": "error"`** → print the `error` field and the `backup_path`. Exit non-zero. The operator can use the backup to roll back if needed:
  ```
  python -c "
  import json, sys; sys.path.insert(0, 'scripts/adr')
  from _ccm_shared import ccm_cli
  state = json.loads(open('<backup_path>', encoding='utf-8').read())
  ccm_cli('manage_adr', {'mode': 'update', 'sections': {'PATTERNS': state['pre_write_patterns']}})
  "
  ```

### Step 4 — On Cancel, exit silently

If the operator chose `Cancel` in step 2, print one line: `Cancelled — no changes written.` Do NOT run the commit command. Do NOT delete the prepared state file (it stays in `O:/Temp/` and is harmless; next session's cleanup can remove it).

## Rules

- **Single-line discipline.** Text must be ≤ 200 chars and contain no newlines. Multi-line patterns are out of scope for v1; split into multiple invocations.
- **No `[<tag>]` prefix in the text.** The module argument auto-prepends `[<module>]`. The dispatch helper rejects manual prefixes to avoid silent inconsistency.
- **Budget hard-abort at 7500 chars.** If the projected ADR total would reach or exceed 7500 of the 8000-char cap, the prepare step aborts with a pointer to `python scripts/adr/sync_patterns.py --check` for consolidation. There is no `--force` escape hatch in v1.
- **Never pass `dry_run`.** The CCM binary silently ignores it and writes destructively. The dispatch helper never sends it; the V6-156 guard in `ccm_cli` would raise `ValueError` if it ever did.
- **Backup always lands before the write.** If `commit` fails, the backup file in `O:/Temp/` holds the pre-write state for rollback.
- **Telemetry trail.** Every successful write logs `outcome="adr_pattern_added"` with `module`, `text_len`, `char_delta`, `post_total`, `backup_path` to `O:/Temp/hf-hook.jsonl`. Mismatches log `outcome="adr_pattern_write_mismatch"`.

## Examples

```
/adr-remember "always wrap CCXT calls via resolve_ccxt_market_symbol" exchange
```

After step 1, you'd see something like:

```
## Proposed ADR PATTERNS update

Module: [exchange]
Budget: 7438 → 7522 / 8000 chars (warn threshold 7500)

--- current
+++ proposed
 [exchange] BybitEU has NO BTC perpetual. Symbol is BTC/USDC. Maker 0.02%, Taker 0.055%...
 [exchange] Fill reconciliation fallback scorer is multi-factor (qty+price+strategy_id...
+[exchange] always wrap CCXT calls via resolve_ccxt_market_symbol
```

Then AskUserQuestion fires with `Approve` / `Cancel`. Approve writes; Cancel exits silently.

## See also

- `/adr-show [module]` — read-only PATTERNS display
- `python scripts/adr/sync_patterns.py --check` — Phase C staleness detection
- `reports/findings/2026-04-30-v6-156-manage-adr-dry-run-flag-silently-ignored.md` — why we never send `dry_run`
- `.claude/rules/adr-workflow.md` — full ADR sync model (Phase A/B/C)
