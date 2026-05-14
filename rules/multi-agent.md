---
description: Multi-agent coordination protocol — agent roster, shared context, conflict zones
paths:
  - docs/agents/**
---

# Multi-Agent Coordination

This project uses multiple AI agents. Coordination layer: `docs/agents/`.

## At Every Session Start, Read:

1. [`docs/agents/SHARED_CONTEXT.md`](../../docs/agents/SHARED_CONTEXT.md) — preferences, roster, protocol
2. [`docs/agents/active-tasks.md`](../../docs/agents/active-tasks.md) — what others are working on
3. [`docs/agents/conflict-zones.md`](../../docs/agents/conflict-zones.md) — files needing coordination

**Update your status** in `active-tasks.md` before starting and when finishing.

## Agent Roster

| Agent | Tool | Domain |
|-------|------|--------|
| Claude (main) | Claude Code | Source code, config, CI/CD |
| Claude (vault) | Claude Code | Knowledge vault (`docs/vault/`) |
| Codex | OpenAI Codex | Source code, architecture, research |

## Cross-Session Zone Advisory (PreToolUse)

[`scripts/agents/cross_session_zone_check.py`](../../scripts/agents/cross_session_zone_check.py) fires on
`Edit|Write|MultiEdit` against `src/myproject/**/*.py` and warns when another
agent has uncommitted work in the same directory. Closes the gap where
`docs/agents/active-tasks.md` and the activity log were only consulted manually
at `/handoff`.

**Decision tree**:

1. `git status --porcelain <target_dir>` — modified files in the edit zone
2. Filter out files this session has already touched (per-session edit log at
   `O:/Temp/hf-zone-session-<session_id>.txt`)
3. Concurrency signal — at least one of:
   - Another agent committed in the last 60 min (per `docs/agents/activity/`)
   - Another agent's `Current task:` in `active-tasks.md` is non-idle
     (idle sentinels: `—`, `-`, `(idle)`, empty)
4. If both #2 (not mine) and #3 (someone else active) — emit `additionalContext`
   warning naming the files + active agents

**Never blocks** (always exit 0 via `run_hook()` harness). The warning is
advisory — Claude can still proceed but is now informed of the collision risk.

**Escape hatches**:

- `HF_ZONE_CHECK_DISABLE=1` — skip this hook only
- `HF_HOOKS_DISABLE=1` — skip every `run_hook()`-wrapped hook (global)

**Telemetry** — `O:/Temp/hf-hook.jsonl` under `hook: "cross-session-zone-check"`.
Outcomes: `silent_clean | silent_self | silent_stale | warn_emitted | gate_skip
| disabled | parse_error | missing_fields`.

**Debugging**:

```bash
# Manual fire with happy-path payload
echo '{"session_id":"dbg","tool_input":{"file_path":"src/myproject/engine/engine.py"}}' \
  | python scripts/agents/cross_session_zone_check.py

# Clear this session's edit log to re-evaluate "mine vs theirs"
rm O:/Temp/hf-zone-session-<session_id>.txt

# Inspect recent telemetry
tail -n 10 O:/Temp/hf-hook.jsonl | grep cross-session-zone-check
```
