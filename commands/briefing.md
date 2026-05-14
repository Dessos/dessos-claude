Generate a concise project briefing to orient this session. Run these steps in parallel where possible, then present a structured summary.

The vault (`docs/vault/`) is the project's long-term memory. It is the PRIMARY source of context for this briefing.

## Gather (run in parallel)

1. **Git state**: Run `git log --oneline -10` and `git status -s` and `git branch -a --list` to see recent commits, uncommitted changes, and active branches.

2. **Vault — Sprint**: Read the most recent file(s) in `docs/vault/sprints/` to understand current sprint focus, open items, and retro learnings.

3. **Vault — Recent decisions**: List and skim files in `docs/vault/decisions/` — summarize any active (non-superseded) decisions that shape current work.

4. **Vault — Learnings**: List and skim files in `docs/vault/learnings/` — flag any recent learnings that affect how we should approach today's work.

5. **Vault — Inbox**: List files in `docs/vault/inbox/` — these are pending items that need triage or action.

6. **Vault — Risk state**: Read `docs/vault/risk/` for current risk context (mode transitions, guardrail changes, telemetry notes).

7. **Vault — Changelog**: Read the most recent `docs/vault/context/changelog-*.md` file for a summary of recent changes.

8. **Memory check**: Read the memory index (`MEMORY.md`) and any `handoff_latest.md` for session continuity. Also scan `project_*.md` files.

9. **Active config**: Read `configs/limits.paper.yaml` to confirm current risk limits profile.

10. **Vault — Verified knowledge**: Read `docs/vault/knowledge/_manifest.md` to see knowledge categories and note counts. Then find `status: active` knowledge notes whose tags match the current sprint focus or recent decisions (e.g., if sprint involves risk work → read risk-management tagged notes; if strategy work → read trading-strategies tagged notes). Summarize the top 3-5 verified principles most relevant to today's work.

## Present

Output a briefing in this exact format (keep it tight — no fluff):

```
## Session Briefing — {date}

**Branch**: {branch} | **Uncommitted**: {count} files
**Last 5 commits**: (one-line each)

**Sprint focus**: {1-2 sentence summary from vault sprints}

**Recent decisions**: {1-line each for active decisions, or "none"}

**Key learnings**: {any learnings relevant to active work, or "none new"}

**Vault inbox**: {pending items needing triage, or "empty"}

**Risk context**: {current mode, any recent guardrail changes from vault}

**Active decisions/blockers**: {from memory handoff + vault, or "none"}

**Risk profile**: {limits profile name} | key limits: max_position={val}, max_daily_loss={val}

**Last session handoff**: {summary from handoff_latest.md, or "no handoff found"}

**Verified knowledge**: {top 3-5 active principles from vault knowledge notes relevant to current work, with note filenames for reference — or "no matching knowledge"}

**Recommended first action**: {what to pick up based on all of the above}
```

Do NOT read CLAUDE.md or skills.md — those are already loaded. Focus only on dynamic state that changes between sessions. Prioritize vault content over git history for understanding project context.
