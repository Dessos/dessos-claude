---
name: three-phase-derived-view-pattern
description: Apply the three-phase write-sync / read-inject / staleness pattern to keep a derived view (TODO list, docs index, dependency graph, architectural-decision record, etc.) consistent with its source state. Use when you have data that's computed FROM something else and risks drifting AWAY from it. Distilled from production use; covers what each phase guarantees, what each one fails to catch, and which Claude Code hook anchors implement each phase.
---

A **derived view** is data computed from source state and shown to an agent (or persisted on disk). Examples: a tradeoffs document derived from open issues, an API surface doc derived from source code, an architectural-decision record derived from commit history. Without active maintenance, derived views **drift** — the source changes, the view doesn't, the agent reads stale info, downstream decisions are wrong.

The three-phase pattern keeps the view consistent via three independent loops, each catching what the others miss.

## The three phases

### Phase A — Write-time sync

When the source changes, propagate the change to the derived view immediately.

**Trigger**: a write event on source — `git commit`, file save, DB row insert, etc.

**Mechanism**: a hook fires on the write event, runs a sync script that re-derives the view (or applies a targeted delta) and writes it.

**What it guarantees**: the common-case write keeps the view in sync.

**What it misses**: writes that bypass the trigger. External agents, manual edits without the hook, automated jobs from other sessions, etc.

### Phase B — Read-time injection

When the agent is about to read the view (or about to do work that depends on the view), inject the freshest derivation into its context.

**Trigger**: a read or work event — `Edit`, `Write`, `MultiEdit`, `UserPromptSubmit`, `SessionStart` (Claude Code hook anchors map directly to these).

**Mechanism**: a hook fires on the read event, queries the source state, emits an `additionalContext` block with the current view.

**What it guarantees**: even if Phase A missed a write, the agent sees the truth at decision time.

**What it misses**: state changes that don't trigger an injection point. E.g., if the agent is just chatting (no Edit, no prompt-with-keyword-match), it operates on whatever it had cached.

### Phase C — Staleness detection

A separate read-only check that compares source state against the derived view, reports drift.

**Trigger**: a recurring check — preflight at session start, CI on PR, scheduled cron.

**Mechanism**: a script with a `--check` mode that exits non-zero on drift. Often the same script as Phase A but with `--check` instead of `--fix`.

**What it guarantees**: any drift Phase A and Phase B both missed becomes visible — the operator (or the next session) sees the warning.

**What it misses**: drift that exists during the window between checks. Mitigated by running Phase C cheaply and often.

## Why three (and not one or two)

Each phase covers a different failure mode:

| Failure mode | A | B | C |
|---|---|---|---|
| Common write — sync immediately | ✓ | — | — |
| External agent commits outside trigger | ✗ | ✓ | ✓ |
| Phase A script crashes silently | ✗ | ✓ | ✓ |
| Manual edit bypassing hooks | ✗ | ✓ | ✓ |
| Agent caches stale view across turns | — | ✓ | — |
| All hooks disabled / broken / not wired | ✗ | ✗ | ✓ |

A alone fails on external writes. B alone is expensive (every read re-derives) and misses non-read-triggered drift. C alone is reactive — drift exists during the window. Together they form a defense in depth.

## When the pattern applies

- The view is **derived** (computed from source), not authored independently.
- The source **changes over time** at non-trivial frequency.
- **Staleness has cost** — the agent makes decisions based on the view, or a human reads the view as ground truth.
- The view is **expensive to re-derive on every read** (or the read frequency is high enough that on-demand derivation is wasteful).

If any of these fails, simpler patterns work: one-shot generation, lazy on-read derivation, manual refresh, etc.

## Claude Code hook anchors

If you implement this in a Claude Code project, the standard mapping:

| Phase | Hook event | When it fires |
|---|---|---|
| A | `PostToolUse` matched on `Bash[git commit]` | After a commit lands |
| A | `PostToolUse` matched on `Write\|Edit\|MultiEdit` with a path pattern | After an edit to specific files |
| B | `PreToolUse` matched on `Edit\|Write\|MultiEdit` with a path pattern | Before agent edits a file |
| B | `UserPromptSubmit` | Before the agent processes each user message |
| B | `SessionStart` | At the start of every session |
| C | Standalone script run by `preflight.py`, CI, or a scheduled task | Periodically |

Wire all three; each script must be **idempotent** and **fail-open** (errors swallowed, no exit-1 from B hooks that would block the agent).

## Implementation checklist

When applying this pattern to a new derived view:

1. **Name the view explicitly** and define its schema (what fields, what types, where stored).
2. **Identify the source** — what files / DB tables / external state does the view derive from.
3. **Write the derivation function** once — used by all three phases.
4. **Phase A**: wire a `PostToolUse[git commit]` (or appropriate write event) hook that calls the derivation, writes the view. Add a gate inside the hook so it only fires when the commit/edit actually touched the source.
5. **Phase B**: wire a read-time hook (`PreToolUse[Edit|Write|MultiEdit]`, `UserPromptSubmit`, or `SessionStart` depending on where the agent reads the view) that calls the derivation, emits `additionalContext`. Add a marker file for idempotency (one inject per session per module).
6. **Phase C**: expose a `--check` flag on the derivation script that compares stored view vs. fresh derivation. Wire into preflight or CI.
7. **Add telemetry** — every hook invocation emits one JSONL line to a known log so you can debug "why didn't the hook fire?" or "which derivation was slowest?"
8. **Add an escape hatch** env var per hook (e.g. `MYPROJECT_FOO_HOOK_DISABLE=1`) for the cases where a hook is misbehaving and you need to keep working.

## Anti-patterns

- **Phase A only, no Phase C**: drift accumulates silently when external writes bypass the trigger. Always pair A with C.
- **Phase B on every read**: re-deriving on every prompt is slow and expensive. Use idempotency markers (one inject per session per scope).
- **No telemetry**: when a hook silently doesn't fire, you'll waste hours debugging. Always emit JSONL.
- **Phase B raises on error**: a Phase B failure blocking the agent is worse than the staleness it was preventing. Always fail-open.
- **Same script for derivation and check, no `--check` flag**: makes Phase C tempting to skip, makes auto-fix tempting to run unconditionally. Always expose both modes.
- **Hook fires on every event without a gate**: e.g. PostToolUse on every git commit, even when the commit doesn't touch the source. Add a fast-path no-op check at the top of every hook script.

## Related patterns

- **Detector / auto-fix scope alignment** — when Phase A (auto-fix) and Phase C (detector) operate on different scopes, they fight each other indefinitely. Source both from one helper.
- **Episode-scoped emission gate** — for derived views with per-episode lifetime, the gate belongs on the episode lifecycle owner, not on the per-tick dispatcher.
