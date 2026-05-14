Prescribe ONE next action from the engineering-improvements queue (GitHub Project #9). Parallel sibling of `/focus` — `/focus` services the V-series trading-bug ledger, `/wsjf` services tooling/workflow polish. Designed to run **alongside** `/focus` in a separate session when the operator is in engineering-focus mode.

**Use when**: a separate session is already running `/focus` and you want to drain Project #9 in parallel; or you want to context-switch from trading work to engineering polish for a stretch.

## Execute

1. Run: `python -m scripts.wsjf`
2. Read the emitted JSON:
   - `primary` → top WSJF candidate. Render via the template below.
   - `flags` contains `tie-cluster: N items at WSJF~X.XX` when cluster tie-break fired — pass through to the rendered output so the operator sees that ordering was non-trivial.
3. **Sanity-check the primary.** The backend sorts by WSJF descending with tie-breaks. Before emitting: does the issue make sense to action *this* session given the current state? Common reasons to override: (a) the linked code is mid-refactor by `/focus`, (b) the issue depends on something not yet shipped. If overriding, promote `fallback` and add `judgment-override: <rationale>` to FLAGS.
4. Write the prescription (template below). The JSON's `wsjf` field powers the "Why it won" line — paraphrase, don't paste.

## Rubric

- Primary ranking: WSJF descending (operator pre-graded at filing time, e.g. `[WSJF: 6.0] /focus rubric blind to ...`)
- Tie-break: within ε=0.05 of identical WSJF, [`scripts/wsjf/scoring.py::tie_break`](../../scripts/wsjf/scoring.py) decides. Edit there, not here. Lock changes in `tests/wsjf/test_scoring.py`.
- Actionable status: only items with status ∈ {Todo, To-Do, Backlog} (closed/in-progress filter implicit)

## Output template

```
## WSJF — {date}

**Open items**: {total_open}  |  **Top WSJF**: {primary.wsjf}  |  **Project**: #9 Engineering Improvements

━━━ PRIMARY (WSJF {primary.wsjf}) ━━━
#{primary.issue_number} — {primary.title}
{primary.url}

**Why it won**: highest WSJF in queue{; or: tied at WSJF~X, won tie-break via <reason>}
**Done when**: PR merges and closes the issue (or operator marks Done in Project view)

━━━ FALLBACK (WSJF {fallback.wsjf}) ━━━
#{fallback.issue_number} — {fallback.title}

━━━ NEXT (up to 5) ━━━
- #N (WSJF X.XX) — <title>
- ...

━━━ FLAGS ━━━
{tie-cluster: N items at WSJF~X.XX}
{judgment-override: <rationale>}
```

## Notes

- `/wsjf` does NOT compete with `/focus` for primary attention. They serve different queues by the split rule (trading bugs → V-series; tooling/workflow → Project #9). If both prescribe a primary the same morning, pick by which queue you intend to service this session.
- `gh` CLI is the only external dependency. ~1–2s latency for the project fetch is acceptable for a session-start command. If gh auth fails, the script emits `flags: ["no-candidates"]` and the rendered output should say so.
- Future enhancements (NOT v1): chronic-deferral tracking, has-open-PR drop, label-weighted tie-breaks, history log. v1 sorts pre-graded WSJF and gets out of the way.
