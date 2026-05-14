---
description: How to file findings when discovering bugs or issues during any task
paths:
  - "**"
---

# Findings Workflow

**Never drop findings.** If you discover a bug, error, logic issue, or code smell during any task — even if "pre-existing" — you MUST either:

1. **Fix it** if in the current task's scope (add tests)
2. **File a finding** at `reports/findings/YYYY-MM-DD-<slug>.md` using the project template

## Finding Template Fields

- Severity (P0–P3)
- Evidence (code reference, reproduction steps)
- Failure scenario (what breaks if unfixed)
- Proposed fix
- Required tests

## V-Series Numbering

Finding IDs continue the V-series from `LOGIC_ANALYSIS_REPORT_v4.md`. Check `reports/findings/INDEX.md` for the authoritative latest ID, or run:

```bash
python -c "import sys; sys.path.insert(0, 'scripts/_lib'); from findings_common import next_free_finding_id; from pathlib import Path; print(next_free_finding_id(Path('.')))"
```

Hard-coded numbers in this doc rot — the helper above scans every finding file's body markers and frontmatter and returns the next free ID.

## On-Disk-Verified Trailer (V6-055 Option C)

Commits that reference a V-series ID AND touch `src/myproject/{strategy,backtest,ml,evaluation}/` MUST carry one of the following trailers — the `tests/{strategy,backtest,ml,evaluation,regression,market}/` subdirs are gitignored (`.gitignore:94-99`) so CI cannot see regression tests that land there, and the trailer is the operator's visible-in-`git log` claim that local verification happened:

```
On-disk-verified: pytest tests/strategy/test_dca_ladder.py::TestX (6 passing)
```

or, when genuinely no regression test applies (mechanical rename, comment-only, etc.):

```
No-tests: <rationale>
```

Enforced by `scripts/validate/commit_msg_on_disk_verified.py` — wired as a PreToolUse Bash[git commit] hook via `install_claude_hooks.py`, and available as a local git `commit-msg` hook at `.githooks/commit-msg` (opt in with `git config core.hooksPath .githooks`). Emergency bypass: `HF_ON_DISK_VERIFIED_DISABLE=1` or `git commit --no-verify`.

## Pre-commit `related_modules:` validator (V6-060)

`reports/findings/*.md` `related_modules:` paths feed `pre_edit_inject.py` — stale entries silently break edit-time finding injection. Three observed drift subclasses:

- **A. Filesystem rename lag** — finding cites a path the rename moved (`_setup/` → `setup/`).
- **B. Missing `src/myproject/` prefix** — bare `api/foo.py` instead of `src/myproject/api/foo.py`. The recurring write-time bite — two within 24h triggered the hook (V6-218, V6-222).
- **C. Reverted artifact still listed** — module briefly existed and was removed.

[`scripts/findings/audit_related_modules.py`](../../scripts/findings/audit_related_modules.py) detects all three (`--check` / `--list` / `--all` / `--json`). [`scripts/validate/commit_related_modules_validate.py`](../../scripts/validate/commit_related_modules_validate.py) wraps it as a write-time gate.

**Trigger**: PreToolUse `Bash[git commit]` hook fires iff at least one staged file is under `reports/findings/*.md` (excluding `_TEMPLATE.md` / `README.md` / `INDEX.md`). Purely-code or purely-other-docs commits don't trigger.

**Behaviour**: block (exit 2) when any staged finding has a `related_modules:` entry that looks like a path (`/` or `.py`/`.json`/`.yaml`/`.yml`/`.sh`/`.md` suffix) and doesn't resolve. Module-prefix entries ending in `/` are checked as directory existence. The sentinel `cross-cutting` is skipped (it's a flag for the edit-time hook, not a path).

**Modes**:

- Claude Code hook (default, stdin JSON) — wired by `install_claude_hooks.py`
- Git commit-msg hook (`--git-msg-file PATH`) — opt-in via `git config core.hooksPath .githooks`
- Standalone `--check` — exits 1 on stale against the current staged index

**Emergency bypass**: `HF_RELATED_MODULES_VALIDATE_DISABLE=1` (this hook only) or `HF_HOOKS_DISABLE=1` (global). Fail-open on any internal error so a hook crash never wedges commits.

**Telemetry**: one JSONL line per fire at `O:/Temp/hf-hook.jsonl` under `hook: "commit-related-modules-validate"`. Outcomes: `pass | blocked | disabled | no_trigger | parse_error | error`.

## Phase A — Auto-flip status on fix-commit landing (V6-065)

`scripts/findings/sync_finding_status.py` keeps `reports/findings/*.md` `status:` lines synchronized with source state. Mirrors the [ADR Phase A pattern](./adr-workflow.md) for findings:

- **Trigger**: PostToolUse `Bash[git commit]` hook fires when HEAD message contains a V-series ID. Runs between `findings_signal.py` (signal must land first) and `sync_tradeoffs.py` (so TRADEOFFS sees flipped state on the same commit).
- **Strong-match input**: consumes `reconcile_findings.reconcile()`'s `auto_closed` bucket (V-ID + fix-language gate, ~95% confidence). No new detection logic.
- **Narrow gate**: only `open` → `resolved`. Never touches `in-progress` (operator-managed multi-slice work signal), terminal states (`fixed | closed | resolved | wont-fix | accepted | superseded | confirmed | duplicate | deferred`), or findings carrying `auto_close: never`. Append-only on status — never moves `resolved` → `open`.
- **Side effects**: appends `## Resolution` section citing the fix commit (idempotent — no double-append) and regenerates `reports/findings/INDEX.md`.

Modes (mirror `sync_tradeoffs.py`):

```
--if-finding-closed   # hook mode: silent no-op unless HEAD msg has V-ID
--force               # always reconcile
--dry-run             # print plan, no writes
--check               # exit 1 if any flippable finding remains open (preflight)
```

**Opt-out**: add `auto_close: never` to a finding's frontmatter when the work spans multiple commits or operator wants HITL closure (e.g., post-canary validation). The script + reconcile both honor this.

**Preflight integration**: `check_findings()` in `scripts/preflight.py` runs `sync_finding_status.py --force` on detected drift, then re-checks with `reconcile_findings.py --check`. Three observable outcomes:
- `Finding statuses auto-synced (was N stale)` — full recovery
- `Phase A flipped K finding(s); N remain (in-progress / no fix commit / opt-out)` — partial recovery
- dim `Phase A: 0 flippable — remaining need manual triage` — nothing was auto-flippable

Telemetry: `O:/Temp/hf-hook.jsonl` under `hook: "sync-finding-status"`. Outcomes: `gate_skip | no_candidates | drift_detected | no_drift | flipped | dry_run | no_op | no_findings_dir`.

**Out of scope**: this is *future-drift prevention*, not *current-cleanup*. Findings already in `in-progress` / lacking strong-match commits / carrying `auto_close: never` need manual operator triage — flip the frontmatter directly in an editor, then re-run `python scripts/validate/build_findings_index.py` (or just rely on the next `--force` invocation to regenerate INDEX).

## At Session End

Summarize any findings filed during the session.
