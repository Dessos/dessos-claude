# ADR Workflow

Single source of truth for how the Architectural Decision Record (ADR) stays in sync with code + findings state. Referenced from [CLAUDE.md:104](../../CLAUDE.md).

Three independently verifiable loops: **write (Phase A)**, **read (Phase B)**, **staleness (Phase C)**. All three run via `scripts/adr/`.

The same triangle also covers **vault-context files** (`docs/vault/context/ai-session-brief.md`, `current-priorities.md`) that Claude reads at session start. All three phases now exist (Phase A shipped 2026-04-29 alongside V6-133 closure): Phase A fires on PostToolUse `git commit` via `scripts/adr/sync_vault_context.py --if-finding-closed` and rewrites stale V-ID citations as `- ✓ V-ID (closed YYYY-MM-DD; commit X) <prose>` with a three-layer false-flag safety stack (detection-side word-boundary keyword exemption / apply-side idempotence regex / `auto_close: never` honor — see `apply_closures` docstring); Phase B fires on `SessionStart` via `scripts/adr/pre_session_vault_inject.py`; Phase C is `scripts/adr/sync_vault_context.py --check` (preflight-wired). See [Phase B — vault-context](#phase-b-2-vault-context-inject-sessionstart) below.

## Shared runtime

All ADR scripts go through the codebase-memory-mcp binary's CLI mode:

```bash
codebase-memory-mcp.exe cli manage_adr '<json-args>'
```

Binary lives at `%LOCALAPPDATA%/codebase-memory-mcp/codebase-memory-mcp.exe` by default; override via `HF_CCM_BIN`. Subprocess and helpers shared in `scripts/adr/_ccm_shared.py`.

## Phase A — Write-time invalidation (TRADEOFFS)

**What**: keeps `TRADEOFFS.Known findings (open)` synchronized with `reports/findings/*.md` frontmatter.

**Who triggers**: PostToolUse `git commit` hook (fires when commit message has V-ID AND commit touches `reports/findings/*.md`).

**Script**: `scripts/adr/sync_tradeoffs.py`. Modes:
- `--if-finding-closed` — hook mode, gate on commit context, silent no-op otherwise
- `--force` — always reconcile, skip gate
- `--dry-run` — print diff, don't write
- `--check` — exit 1 if out of sync (preflight / CI integration)

**Preflight auto-recovery**: the PostToolUse hook only fires when Claude Code itself issues the `git commit`; external commits (parallel session, manual, Codex) bypass it structurally. To heal that drift, `scripts/preflight.py check_adr_drift` runs `--check` first, then auto-invokes `--force` + re-checks when drift is detected. Output line: `✓ TRADEOFFS auto-synced — N active findings` on convergence, `✗ TRADEOFFS auto-sync failed — manual investigation required` otherwise. This is a Phase A recovery invocation, not a Phase C auto-write (Phase C's read-only invariant is preserved).

**Validator**: pre-drop evidence check. Legacy entries without V-series ID → preserved in `⚠ Claimed resolved, verification gap` subsection rather than silently dropped. V-series entries without Resolution section or fix commit → same.

**Inline budget** (CCM 8000-char cap, 500-char headroom target): TRADEOFFS keeps the **4 newest** findings inline with a **100-char title cap** (ellipsis-trimmed). Older findings collapse to a single pointer line referencing `reports/findings/INDEX.md`. Constants `_MAX_INLINE_FINDINGS` and `_MAX_BULLET_TITLE` in `sync_tradeoffs.py` are tunable. `_ccm_shared.ccm_cli` emits a `budget_warning` telemetry event to `O:/Temp/hf-adr-hook.jsonl` when a `manage_adr update` would push merged content past 7500 chars — surfaces overflow approaching before CCM rejects.

## Phase B — Read-time auto-injection (PATTERNS)

**What**: injects module-filtered ADR PATTERNS into Claude's additional context on Edit/Write/MultiEdit for `src/myproject/**/*.py`.

**Who triggers**: PreToolUse hook matching `Edit|Write|MultiEdit` + path pattern `src/myproject/**/*.py`.

**Script**: `scripts/adr/pre_edit_query.py`. Always exit 0 (never blocks). Emits `hookSpecificOutput.additionalContext` with filtered PATTERNS.

**Idempotency**: marker file `O:/Temp/hf-adr-<session_id>-<module>.seen`. Each `(session_id, module)` pair injects at most once per session.

**No disk cache for PATTERNS content** — fetched fresh via CLI every first-of-module hit. Eliminates cache-poisoning vector.

**Escape hatch**: `HF_ADR_HOOK_DISABLE=1` bypasses entirely.

**Widening (opt-in)**: `HF_ADR_HOOK_INCLUDE` accepts a comma-separated list of path patterns to extend the path gate beyond the default `src/myproject/<module>/`. Pattern forms: `dir/` (prefix match — module label = first segment), `filename.ext` (exact-filename match against the path tail — module label = filename stem with dots → hyphens). Default unset → byte-identical to the prior hardcoded regex. Shared resolver lives in [`scripts/_lib/hook_path_filter.py`](../../scripts/_lib/hook_path_filter.py) and is used in lockstep by [`scripts/findings/pre_edit_inject.py`](../../scripts/findings/pre_edit_inject.py) via `HF_FINDINGS_HOOK_INCLUDE`. Example: `export HF_ADR_HOOK_INCLUDE=scripts/,configs/` makes edits to `scripts/preflight.py` trigger PATTERNS injection under module label `scripts` (or the nudge fallback if no `scripts`-scoped PATTERNS exists in CCM).

**Fallback**: if CLI unavailable, emit nudge-style reminder ("run manage_adr get ... before editing `<module>/`") instead of full PATTERNS. Marker still created so reminder doesn't repeat.

## Phase C — Staleness detection (PATTERNS)

**What**: detects stale PATTERNS entries (missing file refs, citations of closed findings, legacy F-series without fix context).

**Script**: `scripts/adr/sync_patterns.py`. Modes:
- `--check` — print report, exit 1 on any staleness
- `--report` — print JSON staleness map + annotated text, exit 0

**Design note**: Phase C does NOT auto-write. PATTERNS is operator-curated prose; auto-rewriting is risky. Phase B's filter uses Phase C's `staleness_map()` to annotate injected context with `⚠` markers inline instead.

## Phase B (3) — Prompt-time PATTERNS inject (UserPromptSubmit)

**What**: fires on every `UserPromptSubmit` event, scans the prompt text for module references (Tier 1 path / Tier 2 disambiguated keyword), and injects a deduplicated PATTERNS block as `additionalContext` BEFORE Claude processes the prompt. Complements Phase B by covering plan-mode / Q&A / brainstorming where no Edit fires.

**Who triggers**: `UserPromptSubmit` hook wired by `install_claude_hooks.py`.

**Script**: `scripts/adr/pre_prompt_inject.py`. Wrapped in `run_hook()` from `scripts/_lib/hook_emit.py`. **Fast-path early-exit** at the top of the script (minimal imports, exits before heavy work) for slash commands, sub-100-char prompts, and empty stdin — keeps cold-path under ~80ms on Windows. Topic extraction lives in `scripts/_lib/topic_extract.py` (Tier 1 path regex + Tier 2 disambiguated-keyword with stoplist `{core, data, config, utils, metrics}`).

**Composition**: ONE deduplicated block. `[all]` and `[config]` lines appear once under `### Cross-cutting`; per-module sections follow with `[module]`/`[module/...]` lines. Capped at `HF_PROMPT_INJECT_MAX_MODULES=3` modules per prompt (overflow recorded in telemetry).

**Idempotency — SEPARATE marker namespace** from Phase B. Marker filename: `MARKER_DIR / f"hf-adr-prompt-{session_id}-{module}.seen"` (Phase B uses `hf-adr-{session_id}-{module}.seen`). Double-injection across the two hooks is the lesser evil — body reflects current PATTERNS state at each fire, so an intervening `manage_adr update` is reflected on whichever hook fires next.

**Escape hatches**: `HF_PROMPT_INJECT_DISABLE=1` (this hook only); `HF_HOOKS_DISABLE=1` (all `run_hook`-wrapped hooks). Confidence-tier override: `HF_PROMPT_INJECT_MIN_CONFIDENCE=path` disables Tier 2 keyword matching.

**session_id fallback chain** (for marker keying when Claude Code's `session_id` field is missing): payload → `CLAUDE_SESSION_ID` env → SHA-1 of `transcript_path[:40]` → `pid-{getpid()}`.

**Telemetry**: appended to `O:/Temp/hf-hook.jsonl` under `hook: "adr-prompt-inject"`. Outcomes: `injected | marker_skip | no_modules_detected | fast_path_skip | disabled | ccm_unavailable | error | success | timeout`. `extra` carries `modules`, `confidence_mix={path: N, keyword: M}`, `context_chars`, `truncated`, optional `overflow`.

## Phase B (2) — Vault-context inject (SessionStart)

**What**: runs at every `SessionStart`, scans `docs/vault/context/ai-session-brief.md` + `current-priorities.md` for V-ID citations that reference resolved/closed findings, and injects a `⚠`-annotated drift summary into Claude's `additionalContext` BEFORE Claude reads the brief.

**Who triggers**: SessionStart `type: command` hook wired by `install_claude_hooks.py`.

**Script**: `scripts/adr/pre_session_vault_inject.py`. Imports `sync_vault_context.staleness_map()` directly (shares the detection definition with Phase C — one source of truth). Wrapped in `run_hook()` from `scripts/_lib/hook_emit.py` — never blocks session start.

**Silent on no-drift**: empty `staleness_map` → exit 0 with nothing emitted. Only stale sessions get extra context.

**Escape hatch**: `HF_VAULT_CONTEXT_HOOK_DISABLE=1` bypasses this hook specifically; `HF_HOOKS_DISABLE=1` kills all `run_hook`-wrapped hooks.

**Telemetry**: single line per session-start to `O:/Temp/hf-hook.jsonl` under `hook: "vault-context-pre-session"` with outcomes `{injected, fresh, no_files, disabled}`.

## Observability

All hook invocations append one JSONL line to `O:/Temp/hf-adr-hook.jsonl`:

```json
{"ts": "...", "session_id": "...", "module": "...", "outcome": "injected|marker_skip|gate_skip|fallback|error", "elapsed_ms": 20}
```

Use this to debug:
- "why didn't the hook fire?" → grep for session_id, inspect `outcome`
- "which modules get touched most?" → aggregate by `module`
- "is the hook slow?" → `elapsed_ms` distribution

## Preflight integration

`python scripts/preflight.py` surfaces TRADEOFFS + PATTERNS freshness at session start:

```
── ADR ───────────────────────────────────────────
  ✓ TRADEOFFS in sync
  ⚠ PATTERNS stale — 2 entries need review
```

Both are `--check` invocations with 5s timeout; silent skip if CCM CLI unavailable.

## Operator actions

- **Flush TRADEOFFS manually**: `python scripts/adr/sync_tradeoffs.py --force`
- **List stale PATTERNS**: `python scripts/adr/sync_patterns.py --check`
- **Fix a stale PATTERNS line**: edit ADR via `manage_adr(mode='update', sections={'PATTERNS': '...'})` or the CLI equivalent; the `--check` line on next preflight confirms freshness.
- **Force re-inject PATTERNS this session**: `rm O:/Temp/hf-adr-<session_id>-*.seen`
- **Disable Phase B hook for a session**: `export HF_ADR_HOOK_DISABLE=1`
- **Detector + auto-fix disagree on the same files** (e.g. preflight warns the auto-fix can never clear): suspect detector/auto-fix scope drift before assuming the auto-fix is broken. See [docs/vault/architecture/2026-04-29-detector-auto-fix-scope-alignment.md](../../docs/vault/architecture/2026-04-29-detector-auto-fix-scope-alignment.md) for the rubric (V6-151's distilled lesson).

## Related

- [CLAUDE.md:104](../../CLAUDE.md) — the canonical instruction
- [.claude/rules/findings-workflow.md](./findings-workflow.md) — findings lifecycle (Phase A consumes this)
- [docs/vault/architecture/three-phase-derived-view-pattern.md](../../docs/vault/architecture/three-phase-derived-view-pattern.md) — golden card for the derived-view triangle
- [docs/vault/architecture/2026-04-29-detector-auto-fix-scope-alignment.md](../../docs/vault/architecture/2026-04-29-detector-auto-fix-scope-alignment.md) — golden card for symmetry within one phase (V6-151 distillation)
- [docs/vault/learnings/adr-tradeoffs-maintenance-gap.md](../../docs/vault/learnings/adr-tradeoffs-maintenance-gap.md) — archived; the learning that motivated this whole effort
