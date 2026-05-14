Walk through pending finding candidates in `reports/findings/_pending/` and promote, edit, or reject each one. The candidates are auto-scaffolded by `scripts/findings/digest_routine_outputs.py` from V-IDs cited in routine outputs that aren't yet filed.

## Execute

1. **List pending candidates.** Run:

   ```bash
   ls reports/findings/_pending/*.md 2>/dev/null
   ```

   If empty, STOP — say "No pending candidates" and suggest running `python scripts/findings/digest_routine_outputs.py` first if the user expected some.

2. **For each candidate** (newest filename first, since filenames lead with `YYYY-MM-DD`):

   a. **Read the file.** Display:
      - The V-ID (extracted from the filename)
      - The `Found in:` block (which routines cited it, with line refs)
      - The `Routine context (verbatim from primary citation):` block
      - Any TODO markers visible in the body

   b. **Get a verdict via AskUserQuestion.** Options (single-select):
      - `Accept (file as-is)` — promote to `reports/findings/`, leave TODO markers for the operator to fix later
      - `Accept after edit` — open the candidate file, fill in evidence/severity/etc., then promote
      - `Reject (delete)` — V-ID was a false positive (just mentioned in passing, no real bug); delete the file
      - `Skip for now` — leave in `_pending/`, move to next candidate
      - `Stop triage` — leave remaining candidates, end the command

   c. **On Accept (with or without edit):**
      - If "Accept after edit", open the file and prompt the user for the missing fields. Do NOT fabricate evidence — match the rules in `/file-finding`.
      - Flip frontmatter: `status: pending-triage` → `status: open`. Use the Edit tool with exact-string match.
      - Move the file: `git mv reports/findings/_pending/<file> reports/findings/<file>` (preserves history if the candidate happened to get tracked accidentally).
        - If `git mv` fails because the file is gitignored, just use `mv` — that's the normal path.
      - Run `python scripts/validate/findings-lint.py reports/findings/<file>` to verify schema.
        - If lint fails on a TODO marker, ask the user whether to address it now or accept the lint warning.
      - Run `python scripts/validate/build_findings_index.py` to regenerate `INDEX.md`.
      - Print: `Promoted <V-ID> → reports/findings/<file>`.

   d. **On Reject:**
      - Delete the file: `rm reports/findings/_pending/<file>`.
      - Print: `Rejected <V-ID> (deleted)`.

   e. **On Skip:** print `Skipped <V-ID>` and continue.

   f. **On Stop:** break out of the loop, print a summary of what was triaged this session.

3. **End-of-session summary.** Print counts: accepted N, rejected M, skipped K, remaining in `_pending/` L. If L > 0, remind the user they can re-run `/triage-routine-findings` next session.

## Rules

- **Never fabricate evidence.** If a candidate's TODO markers ask for severity/evidence and the operator can't recall, leave them as `<TODO — operator triage>` and accept anyway — `findings-lint` will surface them.
- **Don't auto-rename.** The candidate's filename was chosen by the digester from the title hint; don't second-guess it during promotion. The operator can rename later if needed.
- **One commit, one finding.** When the user is ready to commit promoted findings, encourage one commit per finding — keeps `git log` clean and lets `sync_finding_status.py` track them individually.
- **`_DIGEST_REPORT.md` is informational** — if the scheduled task wrote one to `_pending/_DIGEST_REPORT.md`, treat it as context for the operator (a session-start summary). Do NOT promote it as a finding. Skip files starting with `_`.
- **Don't commit during triage.** This command moves files but never commits. Let the user decide when to commit promoted findings.

## Notes

- Idempotent — running this command twice with no operator input between runs is fine.
- The `_pending/` directory is gitignored except for `.gitkeep`, so candidates never leak into commits even if the user forgets to run this command.
- Mirrors the shape of [`/file-finding`](file-finding.md) — same template, same `findings-lint` + `build_findings_index` post-hooks. The key difference: `/file-finding` scaffolds from session context, this command scaffolds from routine output.
