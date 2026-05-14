Scaffold a new finding file under `reports/findings/` following the project template. Usage: `/file-finding <slug>` where `<slug>` is kebab-case (e.g. `db-poller-null-cursor`).

Arguments: $ARGUMENTS

## Steps

1. **Parse arguments**. The slug is everything in `$ARGUMENTS` (strip surrounding whitespace, lowercase, replace spaces with hyphens). If empty, STOP and ask the user for a slug.

2. **Compute filename**. Use today's date (format `YYYY-MM-DD`) and the slug:
   - Path: `reports/findings/YYYY-MM-DD-<slug>.md`
   - If the file already exists, STOP and tell the user — ask whether to append or pick a different slug.

3. **Get the next V-series ID**. Run the project's tool, not a manual grep:
   ```
   python scripts/validate/findings-lint.py --next-id
   ```
   Output is a single line like `V6-019`. Use that exactly. This tool exists specifically to prevent ID collisions (two commits in this sprint hit the pattern V6-012×2 and V6-013×2 before it was added).

4. **Write the file** using the project template at [`reports/findings/_TEMPLATE.md`](reports/findings/_TEMPLATE.md). Match the style of recent findings in `reports/findings/2026-04-*.md` — specifically, browse 2-3 to calibrate tone/detail before writing.

   Exact structure:

   ```markdown
   ---
   status: open
   related_modules:
     - src/myproject/<module>/<file>.py
     - src/myproject/<module>/
   ---

   # Finding: <one-sentence title describing the bug>

   - [ ] **<one-line summary of what is wrong>** — Severity: P{0-3} — Confidence: {High|Medium|Low} — Basis: {Observed|Inferred}
     - Finding ID: V<next-from-step-3>
     - Found during: <current session context — what task we were doing when this surfaced>
     - Evidence:
       - `<file:line>` — <what the code does that is wrong>
     - Why it is incorrect or risky: <mechanism of failure>
     - Concrete failure scenario: <what breaks, under what conditions>
     - Worst-case impact: <fund-at-risk / data loss / silent degradation>
     - Trigger conditions: <when this fires — config, state, inputs>
     - Smallest safe fix: <approach; prefer behavior-preserving options>
     - Tests to add: <what to verify — file paths and assertions>
     - Related: <links to vault notes, prior findings, LOGIC_ANALYSIS_REPORT entries, or "none">
     - Status: open
   ```

5. **Fill in sections from the current conversation context**. Do NOT leave placeholder text. Extract:
   - **Title** + **one-line summary**: from whatever bug was identified in this session
   - **Severity**: P0 (fund-at-risk, live trading broken), P1 (correctness bug affecting results), P2 (latent correctness), P3 (code smell / minor risk). Default P2 if unsure.
   - **Confidence**: High if code was read and bug was traced; Medium if symptom observed; Low if inferred
   - **Basis**: Observed (tested or seen in logs) vs Inferred (reasoned from code)
   - **Evidence**: exact `src/myproject/.../file.py:line` references
   - **Found during**: 1-2 sentence summary of the session task
   - **Related**: cross-reference any vault notes, prior V-series findings, or decisions mentioned in the session
   - **`related_modules:` (REQUIRED frontmatter)**: list every file and/or module directory whose code is implicated by the finding. Used by the PreToolUse findings-injection hook (`scripts/findings/pre_edit_inject.py`) to surface this finding when an agent edits one of those paths. Matching rule: entries are exact file paths (e.g. `src/myproject/risk/engine.py`) OR module prefixes ending with `/` (e.g. `src/myproject/risk/`). For findings that span too many modules to enumerate (e.g. cross-cutting lint/type-check ledgers), use the sentinel `related_modules: [cross-cutting]` — it matches nothing and suppresses edit-time injection while keeping the finding visible via preflight/`/focus`. The governance test `tests/operations/test_findings_frontmatter.py` fails if this field is missing or empty on an open finding.

6. **Report back**. Print:
   - The filename created
   - The V-series ID assigned
   - A 1-line summary of what was filed
   - A reminder to review/tighten the content before committing

## Rules

- **Never invent evidence**. If you don't have a specific `file:line` reference, write `Evidence: (to be added — see session transcript)` rather than fabricating. Ask the user for the reference if unclear.
- **Match existing style**. Findings are technical and specific, not speculative. Browse recent examples (e.g. `2026-04-15-db-poller-null-cursor-latent.md`) to calibrate.
- **Don't commit**. This command files the finding file only. Let the user decide when to commit.
- **Honesty over ceremony**. If the session hasn't actually identified a bug, STOP and tell the user — don't fabricate a finding to satisfy the hookify drift-guard. The drift-guard can be dismissed with "no finding needed" when the dismissal language was benign.
- **Run `findings-lint` after writing** to verify structure:
  ```
  python scripts/validate/findings-lint.py
  ```
  Should report the new file as valid (open status, parseable).
