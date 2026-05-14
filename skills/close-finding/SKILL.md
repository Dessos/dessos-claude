---
name: close-finding
description: Walk through a verified closure of a V-series finding — re-run evidence, check every trigger branch, verify offending values, then flip status, append Resolution, regenerate INDEX. Use when user wants to close a finding manually (not via fix-commit auto-flip), says "close V6-XXX", or is resolving a finding with multiple trigger reasons / brittleness claim / side-channel verification / watch-window observation.
---

Manual finding closure for the cases Phase A auto-flip (`scripts/findings/sync_finding_status.py`) can't reach: multi-slice closures, evidence-based closures, brittleness verifications, watch-window null observations, and operator-side hygiene drops.

If closure is a single fix commit referencing the V-ID + standard fix-language, the PostToolUse hook handles it on commit — **stop and let auto-flip run** instead of using this skill.

## Preflight gates — STOP if any fails

Read the finding file end-to-end first. Then check each gate. Do NOT proceed to verification or editing until every gate is cleared or the user explicitly overrides.

### Gate 1: Trigger-reason count

Count distinct **Trigger conditions** / **Found during** sources in the finding body. If more than one independent reason is listed:

- Each trigger reason is a separate branch. Closing one upstream cause ≠ closing the finding.
- Verify EVERY branch is now non-firing before flipping. The V6-222 / V6-236 lesson: one cause fixed + another silently masked = false closure.
- If a branch is genuinely out-of-scope for this closure, the finding stays `open` (or becomes `in-progress`) — split into a child finding via `/file-finding`.

### Gate 2: Brittleness claim

If the finding title or body contains "brittle to X=Y" / "fails when N>K" / "breaks under <condition>":

- Verification MUST set X=Y / push N>K / induce <condition>. Default-environment green is NOT sufficient.
- Re-run the offending scenario explicitly. Quote the exact command + output in the Resolution section.

### Gate 3: Side-channel null window

If the finding is "X was observed firing N times in 24h" or relies on a metric/log frequency:

- A null observation window is not the same as fixed. The V6-222 lesson: zero-observation in one regime ≠ structurally fixed.
- Require either (a) same-regime retest (replay the conditions that produced the original count), or (b) a multi-day zero spanning ≥ 2 regime transitions.
- Upstream-fix-mid-watch: if the fix landed during the watch window, run an early intra-day sample. Don't wait for scheduled Day-N — the watch period was contaminated.

### Gate 4: Image timestamp (containerized services)

If `related_modules` touches code that runs in a container (paper-trader, ingestion workers, API):

- Run `bash scripts/deploy/check_image_freshness.sh`. If the image timestamp predates the fix commit, the deployed service is still running stale code. The fix is in source, not in production.
- Either rebuild before closing (`docker compose build <svc> && docker compose up -d <svc>`) or downgrade to `in-progress` with a deploy-pending marker.

### Gate 5: Evidence currency

The finding's Evidence section is a SAMPLE, not a total. Before claiming closure:

- Re-run any cited script with the post-fix code. Re-grep any cited pattern across the current tree.
- The "Finding Evidence is a sample" memory: original Evidence listed 3 call sites, but 12 existed; fix patched 3, finding looked closed, 9 remained broken.
- If the re-run surfaces sites the fix missed, downgrade to `in-progress` and either expand the fix or split.

### Gate 6: Code-location drift

The finding's `Smallest-safe-fix` may name a file the refactor moved. Before editing the named file:

- Grep for the actual symbol/function across `src/myproject/` — the fix often lives in a renamed module.
- The `feedback_finding_playbook_code_location_drift` memory.

### Gate 7: Test scope

The finding's `Tests to add` lists one test file. Other tests may also exercise the same code path.

- Grep for every test touching the affected lines/functions. A fix that breaks adjacent tests is a regression, not a closure.

## Verification phase

After gates pass, run actual verification:

1. **Re-run the finding's evidence** — exact commands from the Evidence section, against current HEAD.
2. **Check the cited fix commit** — `git log --oneline -- <related_module>` to confirm the commit landed, mentions the V-ID, and matches fix-language.
3. **Run the test pinned in Tests to add** — quote pass/fail in Resolution.
4. **If finding touches `src/myproject/{strategy,backtest,ml,evaluation}/`**: tests are gitignored. The fix commit's `On-disk-verified:` trailer is the audit trail — verify it exists in `git log`.

## Edit phase

Only after verification:

1. Read the finding file once more (state may have changed during verification).
2. Edit frontmatter:
   ```yaml
   ---
   status: resolved        # was: open
   ---
   ```
3. Replace the body checkbox `- [ ]` with `- [x]` (governance gate for INDEX rendering).
4. Append a `## Resolution` section at the end:
   ```markdown
   ## Resolution

   Resolved YYYY-MM-DD by `<short-sha>` (commit subject).

   **Verification:**
   - Re-ran <evidence command>: <result>
   - <pinned test command>: <pass/fail with count>
   - <any gate-specific verification>: <quote>

   **Scope honesty:** <which trigger branches were verified; which were out-of-scope and split>
   ```

   If the auto-flip Resolution section already exists (placeholder skeleton from `sync_finding_status.py`), REPLACE its body — don't append a duplicate. The `feedback_auto_flip_resolution_section_idempotence` memory: idempotence is header-presence based, so placeholder Resolution survives and needs manual fill.

## Mechanical phase

Order matters — INDEX must regenerate after status flip, TRADEOFFS after INDEX:

```bash
# 1. Validate the edited finding
python scripts/validate/findings-lint.py

# 2. Regenerate INDEX
python scripts/validate/build_findings_index.py

# 3. Sync TRADEOFFS (only if commit touches reports/findings/ — usually yes)
python scripts/adr/sync_tradeoffs.py --force

# 4. Sync vault-context (only if vault-context cites this V-ID)
python scripts/adr/sync_vault_context.py --force

# 5. Reconcile to verify nothing else drifted
python scripts/reconcile_findings.py --check
```

If `reconcile_findings.py --check` exits non-zero, surface the report before committing — closure may have unmasked another open finding's drift.

## Commit

```
chore(findings): close V6-XXX — <one-line reason> [V6-XXX]
```

If the closure touches `src/myproject/{strategy,backtest,ml,evaluation}/`, add the trailer:

```
On-disk-verified: <pytest command> (<N passing>)
```

or `No-tests: <rationale>` for genuinely test-less closures (operator-side hygiene, doc-only). Enforced by `scripts/validate/commit_msg_on_disk_verified.py`.

## Anti-patterns — surface to the user, don't silently do

- **Bundling triggering-workflow into verification**: the workflow that surfaced the bug ≠ the verification that proves it's fixed. The `feedback_finding_trigger_vs_finding_verification` memory.
- **Closing on default-env green when title says "brittle to X=Y"**: see Gate 2.
- **"Verification exhausted" + chronic-deferral + score-0**: suspect the verify parser or detector first, not operator avoidance. The `feedback_chronic_deferral_as_parser_signal` memory — V6-165's inline-comment leak was a parser bug masquerading as deferral.
- **Auto-flip didn't fire on commit**: check the extractor first. Bold-wrapped `Finding ID: **V6-XXX**` is invisible to `extract_finding_id` (V6-243 root cause). Un-bold before assuming the flip logic is broken.
- **Closing a finding that opens a downstream**: the unmask-cascade pattern. Closing one bug often unmasks 5–10 latent ones. File the unmasks as new findings — don't bundle into this closure.
- **Stamp without audit chain**: when closing under operator delegation, the Resolution section is the audit chain — include the 4 elements (signature: who/when, quote: what was verified, anchor: file:line, SHA: fix commit).
