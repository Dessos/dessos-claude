Run the manual cleanup workflow for doc-freshness drift end-to-end: regenerate the audit diff, walk you through review, apply the chosen portions (repo + memory), run side actions, and report the post-state. The detector + audit + Phase B inject was built in commits `e6653f2c` → `db496000`. Outputs land in `reports/cleanup/` (gitignored).

## Execute

1. **Regenerate the audit.** Run, capturing both stdout and stderr:

   ```bash
   python scripts/validate/audit_doc_freshness.py
   ```

   The script prints a short summary (auto-fix count, HITL count, output paths). Show that to the user verbatim. If the auto-fix count is `0`, STOP and report "No drift to clean — preflight should be green; if it isn't, run `python scripts/validate/check_doc_freshness.py --check` to inspect."

2. **Surface the HITL list.** The audit also writes a markdown sidecar — read it and summarize:

   ```bash
   cat reports/cleanup/$(date +%Y-%m-%d)-doc-freshness-audit.hitl.md
   ```

   Do not paste the whole file. Instead: list each `## <file>` heading with its bullet count, then point at the side-actions section as a separate item ("plus N side action(s) listed at the bottom").

3. **Get a verdict via AskUserQuestion.** Single-select:

   - `Apply both diffs` — repo + memory satellites, then side-actions prompt
   - `Apply repo only` — CLAUDE.md + vault context; skip memory satellites
   - `Apply memory only` — memory satellites only; skip repo
   - `Review without applying` — print the three artifact paths and stop here
   - `Stop` — abort, change nothing

4. **Pre-flight uncommitted-changes check.** Before applying anything, run:

   ```bash
   git status --short
   ```

   If there are unstaged or staged changes outside `reports/cleanup/`, surface them and ask via AskUserQuestion whether to proceed (changes might mix into the cleanup commit) or stash first. Recommend: `git stash --keep-index --include-untracked` then proceed.

5. **On apply repo:**

   ```bash
   patch -p1 --dry-run < reports/cleanup/$(date +%Y-%m-%d)-doc-freshness-audit.diff
   ```

   - If dry-run reports any FAILED hunks, STOP. Show the failed hunks. Ask the user whether to:
     - re-run audit (some upstream file changed since the diff was generated)
     - skip and move on to memory
     - abort
   - If dry-run is clean, apply for real:

     ```bash
     patch -p1 < reports/cleanup/$(date +%Y-%m-%d)-doc-freshness-audit.diff
     ```

   Use `patch` not `git apply` — vault context (`docs/vault/`) is gitignored, so `git apply` rejects those hunks with "does not exist in index".

6. **On apply memory:**

   First resolve the memory dir:

   ```bash
   MEM_DIR=$(python -c "import sys; sys.path.insert(0, 'scripts/validate'); from _doc_surfaces import default_memory_dir; d = default_memory_dir(); print(d if d else '')")
   ```

   - If `$MEM_DIR` is empty, STOP and tell the user — the memory dir wasn't found. A fresh checkout on a new machine may need `HF_MEMORY_DIR` set; otherwise check that `~/.claude/projects/<slug>/memory/` exists for the current project.

   With a resolved path, dry-run first:

   ```bash
   cd "$MEM_DIR" && patch -p1 --dry-run < /o/Code/trading-project/reports/cleanup/$(date +%Y-%m-%d)-doc-freshness-audit.memory.diff
   ```

   - Same dry-run-then-apply discipline as repo. If dry-run reports any FAILED hunks, surface them and ask whether to skip / re-run audit / abort.

   On clean dry-run, apply:

   ```bash
   cd "$MEM_DIR" && patch -p1 < /o/Code/trading-project/reports/cleanup/$(date +%Y-%m-%d)-doc-freshness-audit.memory.diff
   ```

7. **Side-actions prompt** (AskUserQuestion, single-select):

   - `Run side actions now` — execute champion re-seed + scaffold the Q1 trace finding
   - `Skip — I'll handle them later`
   - `Skip — already done`

8. **On run side actions:**

   a. **Re-seed champion.json:**

      ```bash
      python scripts/backtest/seed_champion.py
      ```

      Confirm the file now exists:

      ```bash
      ls -la reports/backtest/champion.json
      ```

   b. **Scaffold the Q1 trace finding.** Use the existing `/file-finding` template logic, but inline (don't recurse into the slash command). Compute the V-ID via `python scripts/validate/findings-lint.py --next-id`. Then write `reports/findings/$(date +%Y-%m-%d)-champion-json-regenerated-from-detector-baseline.md` with:

      ```markdown
      ---
      status: resolved
      severity: P3
      ---

      # Finding: champion.json was missing as of 2026-04-27 detector baseline; re-seeded by manual workflow

      - [x] **Strategy Champion section in root CLAUDE.md cited `reports/backtest/champion.json` as authoritative, but the file was absent at audit time.** — Severity: P3 — Confidence: High — Basis: Observed via `python scripts/validate/check_doc_freshness.py --check`.
        - Finding ID: <V-ID from --next-id>
        - Found during: Doc-freshness audit baseline (commit `e6653f2c`).
        - Resolution: re-seeded via `python scripts/backtest/seed_champion.py` on YYYY-MM-DD. Confirm walk-forward auto-update cadence is producing fresh seeds — last `1h_*_sweep` directory should be within 14d.
      ```

      Run findings-lint to verify schema:

      ```bash
      python scripts/validate/findings-lint.py reports/findings/<that-file>.md
      ```

      Then regenerate the index:

      ```bash
      python scripts/validate/build_findings_index.py
      ```

9. **Final state report.** Run preflight:

   ```bash
   python scripts/preflight.py --section docs
   ```

   Compare the new count to the pre-cleanup count. Expected drop: most warn-class V-ID findings cleared (vault context + memory annotations applied), plus a couple of error-class clearings (`champion.json` paths if Q1 ran). Print:

   - Pre-cleanup: <count from step 1's audit>
   - Post-cleanup: <new count from preflight>
   - Delta: <difference>

   If the count went UP or didn't drop meaningfully, surface that — something didn't apply or there's new drift.

10. **Recommend a commit.** Do NOT commit. Tell the user the suggested commit shape:

    ```
    docs: apply doc-freshness audit cleanup (V-ID annotations + Q5 etc.)

    Generated by /clean-doc-drift on YYYY-MM-DD. Auto-fixes from
    scripts/validate/audit_doc_freshness.py against detector commit
    e6653f2c. Side actions: <list which were run>.
    ```

    If the user ran side actions, recommend a separate commit for the champion re-seed + trace finding (different concern — keeps `git log` clean):

    ```
    chore(backtest): re-seed champion.json + file V<N>-NNN trace
    ```

## Rules

- **Never auto-commit.** This command modifies files but never `git add` / `git commit`. The operator decides when and how to commit. Surface the suggested commit shapes verbatim.
- **Always dry-run before applying.** `patch -p1 --dry-run` first, real apply second. If the working tree drifted from the diff's source state, dry-run catches it.
- **HITL items are listed, not fixed.** This command does NOT attempt to write missing files (`scripts/demo-up.sh`, `configs/vault-maintenance.yaml`, etc.) — those are in the `.hitl.md` sidecar for the operator to handle separately.
- **Memory dir is C:**, repo dir is O:. The `MEM_DIR` lookup uses `default_memory_dir()` to handle this — don't hardcode the path.
- **Idempotent.** Re-running this command after a clean apply produces "0 auto-fixes" from step 1 and stops at the early-return. Safe.
- **One sweep per session.** Don't loop. If the post-cleanup count is still high, that's HITL or new drift — both deserve a fresh session, not a re-run.

## Notes

- Mirrors `/triage-routine-findings` shape (regenerate → walk-through → state report). Key difference: this command edits files in-place via `patch`; that one moves files between dirs via `git mv`.
- Re-runnable anytime — the audit script is read-only on the codebase, only the `reports/cleanup/*` artifacts are regenerated.
- The repo diff covers CLAUDE.md edits + vault-context V-ID annotations. Vault context is gitignored, so the post-cleanup `git status` will only show `CLAUDE.md` modified — that's expected.
- If the user wants to disable the SessionStart drift inject after cleanup, `export HF_DOC_FRESHNESS_HOOK_DISABLE=1`. The detector still runs in preflight either way.
- See [`scripts/validate/check_doc_freshness.py`](../scripts/validate/check_doc_freshness.py) and [`scripts/validate/audit_doc_freshness.py`](../scripts/validate/audit_doc_freshness.py) for implementation; see memory `reference_doc_freshness_detector.md` for the pointer.
