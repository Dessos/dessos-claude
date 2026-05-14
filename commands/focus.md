Prescribe ONE next action for this session using a weighted rubric over all candidates. `/briefing` shows signals; `/focus` computes the plan. Runs in ~5s.

**Use when**: session start, mid-session context loss, or any time you catch yourself hopping between tasks without a clear "why this now".

## Execute

1. Run: `python3 -m scripts.focus`
2. Read the emitted JSON:
   - `ship_bootstrap: true` → output the bootstrap line + `ship_subjects`, stop. Recommend `git push`; don't compute the rest.
   - Otherwise, `primary_id` + `fallback_id` + `candidates[].contributions` are your inputs.
3. **Sanity-check the primary.** The backend computes which candidate *should* win by the rubric. Before you emit it, ask: does this candidate's description match what would actually move *this* session forward given the current conversation? If it does, emit as-is. If it doesn't — e.g., the primary is a Gate 2 review row but the operator is mid-implementation on something — promote the fallback and record why in FLAGS as `judgment-override: <rationale>`. This is the one place you add value the backend can't: the backend doesn't know what the operator just said.
4. Write the prescription (template below). The JSON's `contributions` dict powers the "Why it won" line — paraphrase, don't paste raw. **If `recommended_model` is null, omit the `**Model**:` line entirely.** When populated, render it verbatim using `recommended_model` and `model_recommendation_reason`.
5. Pipe `log_payload` to the log subcommand so next session can detect chronic deferral:

   ```bash
   echo '<log_payload-as-json>' | python3 -m scripts.focus log
   ```

## Rubric

Weights live in [`scripts/focus/weights.py`](../../scripts/focus/weights.py) — edit there, not here. Tune only from evidence ("I picked X over Y and Y would have been better → bump Y's tag weight"). Locked via `tests/focus/test_scoring.py` so tuning surfaces in a diff.

Rubric shape (for reference — do not re-implement; the backend computes this):

- `gate2_blocker` 100 | `ship_ready` 30 | `stale_finding` 20 | `P0` 40 | `P1` 15 | `P2` 5 | `P3` 0
- WIP age: +10 per day beyond 2-day grace
- Gate 2 proximity (≤7 days): ×2 on `gate2_blocker` scores
- Blocker-reentry: zeroes score if handoff-guarded V-ID (guard-word-gated)
- Ship-bootstrap: ≤5 unpushed + no hook failures → short-circuit
- Verify-before-output: drops primary if finding is closed, a `fix(V-ID)` commit landed *and* finding wasn't edited since, or the candidate is a Gate 2 row that's evidence-linked / verified-date-prefixed (sign-off-pending — work shipped, awaiting CRO initial). Walks full ranked list; flags `verification-exhausted` past 3 drops
- Chronic deferral: ID appears in top-3 of ≥3 of last 5 sessions, never primary → annotation
- Model recommendation: post-scoring rubric in [`scripts/focus/model_recommendation.py`](../../scripts/focus/model_recommendation.py) emits `recommended_model` + `reason`. Triggers: verification-exhausted, chronic-deferral on primary, ≥3 tied scores, Gate-2 proximity + blocker, long-effort gate2_blocker, P0 primary, P1 stuck (wip_age≥2). Ship-bootstrap → `haiku`. Default → null (Sonnet)

## Output template

```
## Focus — {date}

**Days to Gate 2**: {N}  |  **Ship queue**: {unpushed}  |  **WIP**: {mod} modified, {new} untracked  |  **Findings open**: {count}  |  **Model**: {recommended_model} ← omit this segment if `recommended_model` is null

━━━ PRIMARY ({effort_min} min) ━━━
{description}

**Why it won**: {top 2-3 contributions, e.g. "gate2_blocker×2 (proximity) + P1 = 230"}
**Done when**: {one-line concrete verification — a file changes / test passes / commit lands / metric moves}
━━━ FALLBACK (if primary blocks) ━━━
{description}  ({effort_min} min)

━━━ REJECTED (up to 5) ━━━
- {candidate} — {reason: lower score N / verification: status=fixed / blocker-reentry / chronically deferred N sessions}
- {candidate} — {reason}

━━━ FLAGS ━━━
{ship-bootstrap applied: run `git push` first, re-run /focus}
{gate2-proximity-multiplier-active}
{verification-exhausted (3 primary candidates dropped)}
{chronic-deferral: <id> (N sessions) — change approach or escalate}
{judgment-override: <rationale>}
```

## Mid-session escalation (soft halt)

The deterministic rubric is session-start. Within-session, when a task started Sonnet-appropriate evolves into deep work, follow this discipline:

- **Trigger**: prescribed `effort_min` exceeded **2×** AND the **Done when** condition is still unmet.
- **Action**: halt before the next mutating tool call (`Edit | Write | NotebookEdit | mutating Bash`). Read-only operations (`Read | Grep | Glob | read-only Bash`) may continue — extra diagnostic context helps the operator on return.
- **Emit verbatim**:

  > `⚠ Pausing before next write — prescribed effort exceeded 2× and Done-when unmet. /model upshift recommended. Reply with how to proceed (upshift, explicit "continue", or pivot).`

- **Why halt, not advisory continue**: the cost of false-continue (Sonnet writes wrong code on a hard problem, Opus has to re-read context AND undo edits) is asymmetrically higher than the cost of false-halt (operator types `continue`, Sonnet was actually fine). Bias toward halting.
- **Operator response paths**: `/model` upshift (recommended), explicit `continue`, or pivot to a different task.
- Do NOT auto-`/model` switch — the slash command is user-typed only, and silent context shifts erase agency.

## Notes for future-me editing this file

- The weights are in Python now. Editing this markdown does not change behavior.
- If the rubric misfires, first check `O:/Temp/hf-focus-history.jsonl` — the evidence for a weight tune should live there, not in memory.
- Do not add a "novelty" or "interestingness" weight. Boredom is not a signal.
- Keep the output tight. Point is to reduce decisions, not produce another doc to read.
- Gate 2 moves. When it does, update the date source (`docs/governance/gate2-signoff-checklist.md` → `target_signoff_date:` or `paper_period_ends:`).
- **`HF_CURRENT_MODEL`** env var: `export HF_CURRENT_MODEL=opus` (or `haiku`/`sonnet`) suppresses recommendations matching the current model, silencing no-op nags. Set it once per shell.
- `/focus` runs once per session — if a Sonnet-appropriate session evolves into deep bug work mid-flow, the operator switches via `/model` (see Mid-session escalation above). The deterministic rubric won't re-fire within-session.
