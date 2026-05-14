Dispatch top-N `/focus` candidates to N parallel subagent workers, each in its own git worktree. Single picker (this session), N executors (subagents). Eliminates same-task overlap by construction — only the parent picks.

**Use when**: you have a ranked `/focus` queue and want to burn down multiple candidates in parallel rather than serializing on one primary.

**Use `/focus` (not this)** when: you want one prescribed action with the model-recommendation + flags + chronic-deferral surfacing. `/focus-burndown` is for *executing* the top of the queue in parallel, not for picking.

## Execute

1. Run: `python -m scripts.focus burndown {{args:-3}}` (default N=3, cap 5).

2. Parse the emitted JSON. Handle preflight blocks first:
   - `preflight_block == "ship_bootstrap"` → emit `🚢 Ship-bootstrap active: run \`git push\` first, then re-run /focus-burndown`. Stop.
   - `preflight_block == "verification_exhausted"` → emit `⚠ Verification exhausted: run /focus and inspect rejected[] for manual triage`. Stop.
   - `preflight_block == "no_candidates"` → emit `⚠ No dispatchable candidates: {skipped[].vid} all filtered ({reasons})`. Stop.

3. If `actual_n < requested_n`, emit one advisory line: `ℹ Only {actual_n}/{requested_n} candidates pass filter — dispatching {actual_n}`. Continue.

4. **Update `docs/agents/active-tasks.md`** — set the Claude (main) `Current task:` to:
   ```
   /focus-burndown: dispatching N workers — {vid1}, {vid2}, ...
   ```
   This is the coordination claim other agents see.

5. **Dispatch** — ONE message with N `Agent` tool calls in parallel. Each call:
   - `subagent_type`: `"general-purpose"`
   - `isolation`: `"worktree"` (parent stays on its branch; subagent gets a fresh worktree)
   - `description`: `"Burndown <vid>"`
   - `prompt`: the `briefs[i].prompt` field verbatim (already formatted by `burndown.py`)

   Do NOT modify the prompt. Do NOT pre-fetch context for the subagent — the brief is self-contained and the subagent will explore its worktree fresh.

6. **Await all N**. Each subagent returns a result message with `worktree_path`, `branch`, `commit_sha`, `status`, `notes`. Extract these.

7. **Roll up** — print a structured summary to the operator:
   ```
   ## /focus-burndown rollup ({date})

   Dispatched: N workers
   Shipped: M  |  Blocked: K  |  Deferred: J

   ✓ V6-X  → claude/burndown-V6-X-2026-MM-DD-HHMMSS  ({sha})  shipped
            notes: <subagent notes>
   ⚠ V6-Y  → claude/burndown-V6-Y-2026-MM-DD-HHMMSS  blocked
            notes: <subagent notes>

   Skipped (pre-flight filter):
   - V6-Z: chronic-deferral (3 sessions)

   ### Next steps
   Review and merge worker branches:
       git branch -a --list 'claude/burndown-*'
       git diff claude...claude/burndown-V6-X-...
       git merge --ff-only claude/burndown-V6-X-...
       git worktree remove .claude/worktrees/...
       git branch -d claude/burndown-V6-X-...
   ```

8. **Log the rollup** — take `rollup_log_payload` from step 1, set its `burndown_meta.shipped` and `burndown_meta.blocked` from step 6 counts, then pipe to `/focus log`:
   ```bash
   echo '<rollup_log_payload-with-counts-as-json>' | python -m scripts.focus log
   ```
   This writes ONE line to `O:/Temp/hf-focus-history.jsonl` so the next `/focus` sees this session in its drift-lookback window with the chosen primary now in `was_primary` (chronic-deferral signal stays meaningful).

9. **Update `docs/agents/active-tasks.md`** — set Claude (main) `Current task:` back to `—` and add a one-line entry to `### Recently Completed` referencing the burndown date and shipped V-IDs.

## Operator merge workflow (post-rollup)

Workers stay on their own branches. The parent does NOT auto-merge. Per-branch:

```bash
git branch -a --list 'claude/burndown-*'

# Inspect:
git log --oneline claude..claude/burndown-V6-X-2026-MM-DD-HHMMSS
git diff claude...claude/burndown-V6-X-2026-MM-DD-HHMMSS

# Merge (ff-only is intentional — refuses if branch diverged from claude):
git merge --ff-only claude/burndown-V6-X-2026-MM-DD-HHMMSS

# Cleanup:
git worktree remove .claude/worktrees/burndown-V6-X-2026-MM-DD-HHMMSS
git branch -d claude/burndown-V6-X-2026-MM-DD-HHMMSS
```

If two workers both edited a shared coordination file (e.g. `reports/findings/INDEX.md`), the second `--ff-only` fails — resolve by hand with `git merge` and conflict resolution. Workers are *instructed* to avoid coordination-file writes (see brief prompt), so this should be rare.

## Notes

- **Hard cap N=5.** Parent context fills with N subagent results (~10-20K tokens each at verbose). N≥6 risks parent context exhaustion. Override in `scripts/focus/burndown.py:HARD_CAP_N` if needed.
- **No `/loop /focus-burndown N` under 30 min.** Each burndown logs one history line, but rapid-fire still pollutes the 5-session drift lookback. See [scripts/focus/drift.py](../../scripts/focus/drift.py) `DRIFT_LOOKBACK_SESSIONS=5`.
- **Worktree cleanup is operator-driven.** If a worker hits a fatal error mid-task, its worktree persists. Clean with `git worktree prune` + `git worktree remove`.
- **For independent `/focus` from N tabs** (not this skill), use Phase 2's claim files: `python -m scripts.focus --claim-on-pick`. See [`scripts/focus/claim.py`](../../scripts/focus/claim.py).
