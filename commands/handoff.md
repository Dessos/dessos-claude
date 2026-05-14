Create a session handoff note to preserve context for the next conversation. This runs at the END of a session.

The vault (`docs/vault/`) is the project's long-term memory. Significant learnings and decisions should be persisted there, not just in Claude memory.

## Gather

1. Review the conversation history to identify:
   - What was accomplished this session (completed tasks, code written, decisions made)
   - Any decisions that were deferred or need follow-up
   - What the logical next step would be
   - Any surprises, blockers, or learnings worth remembering

2. Check `git log --oneline -5` to see what was committed this session.

3. Check `git status -s` for any uncommitted work.

4. Check for session trail at `O:/Temp/hf-session-trail.log`. If it exists, read it and include a **Debugging Trail** section in the handoff showing key commands that were run (test results, backtest runs, validations). Delete the trail file after reading.

## Write handoff (Claude memory)

Save a memory file at the user's memory directory as `handoff_latest.md` with this structure:

```markdown
---
name: Session Handoff — {date}
description: What was done and what to pick up next — {1-line summary}
type: project
---

**Completed**: {bulleted list of what got done}

**Decisions made**: {any choices or trade-offs decided, or "none"}

**Deferred/blocked**: {anything postponed and why, or "none"}

**Uncommitted work**: {any staged/unstaged changes not yet committed, or "all committed"}

**Next session should**: {concrete recommended first action}
```

Important:
- OVERWRITE the previous `handoff_latest.md` — only keep the most recent handoff
- After overwriting `handoff_latest.md` (or any other satellite file edited during the session), also update its one-liner in `MEMORY.md` so the index reflects the new `description:` field. The doc-freshness detector currently does NOT catch this drift — operator discipline is the fix until the detector verifier lands (V6-131).
- Update the MEMORY.md index if this is the first handoff (add a pointer under ## Project)
- Keep it concise — this is a breadcrumb trail, not a journal
- Convert any relative dates to absolute dates (e.g., "tomorrow" -> "2026-03-18")

## Write to vault (if warranted)

After writing the handoff, evaluate whether this session produced knowledge worth persisting in the vault:

- **Made a design decision?** → Create/update note in `docs/vault/decisions/` using ADR template
- **Discovered non-obvious behavior?** → Create/update note in `docs/vault/learnings/`
- **Fixed a tricky bug?** → Update relevant domain folder in vault
- **Changed risk limits or config?** → Update `docs/vault/risk/canonical-guardrails.md`
- **Completed sprint work?** → Update sprint tracker in `docs/vault/sprints/`
- **None of the above?** → Skip vault write, handoff memory is sufficient

Follow vault conventions: YAML frontmatter required, kebab-case filenames, `[[wikilinks]]` for cross-references, update `updated` timestamps. See `docs/vault/context/vault-conventions.md` for the full schema.

## Update session brief

After vault writes, patch `docs/vault/context/ai-session-brief.md` to reflect this session's changes:

1. Update **Recent Decisions** (last 5) if any decisions were made
2. Update **Active Sprint Focus** if sprint items were completed or added
3. Update **Blockers** if any were resolved or new ones discovered
4. Update the date at the top of the brief
5. Update `updated` timestamp in frontmatter

This keeps the session brief current for the next session without manual intervention.

## Final output

Present a brief summary of what was written and where.
