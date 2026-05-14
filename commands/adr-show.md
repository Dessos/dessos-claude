Display the current ADR PATTERNS section, optionally filtered by module. Read-only — no writes, no confirmations.

Usage:
- `/adr-show` — full PATTERNS body
- `/adr-show <module>` — filtered to `[<module>]` + `[<module>/...]` + cross-cutting `[all]` + `[config]` lines

Arguments: $ARGUMENTS

## Steps

1. **Parse `$ARGUMENTS`**. Strip whitespace. If empty → display the full PATTERNS body. Otherwise the single token is the module to filter.

2. **Validate the module** (only when an argument was given). Run:

   ```bash
   PYTHONIOENCODING=utf-8 python -c "
   import sys; sys.path.insert(0, 'scripts/adr')
   from _ccm_shared import discover_modules
   print(','.join(sorted(discover_modules())))
   "
   ```

   If the user-supplied module is not in the comma-separated list, print the valid set and STOP. Do not fall back to "show all" — that hides the typo.

3. **Fetch + filter PATTERNS** in a single Python invocation:

   ```bash
   PYTHONIOENCODING=utf-8 python -c "
   import sys; sys.path.insert(0, 'scripts/adr')
   from _ccm_shared import fetch_patterns, filter_patterns
   text = fetch_patterns(timeout=10.0) or ''
   module = '<MODULE_FROM_STEP_1_OR_NONE>'  # empty string for no filter
   if module:
       print(filter_patterns(text, module))
   else:
       print(text)
   "
   ```

   Replace `<MODULE_FROM_STEP_1_OR_NONE>` with the parsed module (or leave empty for no filter). If `fetch_patterns` returns nothing, print "No PATTERNS section found (or CCM unreachable)" and STOP.

4. **Render** the output as a fenced markdown code block (```` ```text ... ``` ````) so the operator can copy lines verbatim. Above the block, print one summary line:

   ```
   ADR PATTERNS — <module or "all"> (N lines)
   ```

## Rules

- **No writes.** Never call `manage_adr update`. Never call any tool that mutates state.
- **No AskUserQuestion.** This command is informational; there is nothing to confirm.
- **No invention.** If PATTERNS is empty or filter yields zero matches, say so explicitly — do not synthesize content.
- **Truncate long lines** in the rendered output only if they exceed ~200 chars and the user is on a narrow terminal. Default to faithful rendering.

## Examples

```
/adr-show
→ ADR PATTERNS — all (28 lines)
   ```text
   [config] YAML limits profiles override env vars unconditionally...
   [config] target_long_usd must be <= 0.7 * max_position_usd...
   [risk] Three modes: NORMAL->SAFE_MODE->HALTED. ...
   ...
   ```

/adr-show engine
→ ADR PATTERNS — engine (8 lines)
   ```text
   [config] YAML limits profiles override env vars unconditionally...
   [config] target_long_usd must be <= 0.7 * max_position_usd...
   [engine] Order chunking needs headroom between target and limit. F001 fixed.
   [engine] EventBus swallows handler failures silently...
   [engine] Position recovery syncs strategy state...
   [engine] API-only mode: ensure_db_session() initializes DB session...
   [engine/credit] Credit system: mode=enforce, fail_closed=true, schema_version=2.0.0.
   [all] Dedup caches use manual set + deque sync (bounded, fragile pattern).
   ```
```

## See also

- `/adr-remember "<text>" <module>` — append a pattern with preview-then-confirm
- `python scripts/adr/sync_patterns.py --check` — surface stale entries (closed findings, missing file refs)
