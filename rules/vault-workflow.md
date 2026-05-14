---
description: Knowledge vault conventions, MUST READ/WRITE rules, and vault linter
paths:
  - docs/vault/**
---

# Vault Workflow

See also: [`docs/vault/CLAUDE.md`](../../docs/vault/CLAUDE.md) for vault-agent-specific instructions.

## Every Session: Read First

[`docs/vault/context/ai-session-brief.md`](../../docs/vault/context/ai-session-brief.md) — current stage, sprint focus, P0 blockers, active constraints.

## MUST READ Before These Tasks

| Task | Check first |
|------|-------------|
| Architecture decisions | `decisions/`, `architecture/` |
| Risk/engine work | `risk/`, `learnings/` |
| Order/execution debugging | `execution/`, `risk/`, `operations/` |
| Strategy work | `strategy/`, `evaluation/` |
| Sprint planning | `sprints/`, `context/project-overview.md` |
| Deploying/promoting | `governance/release-gates.md`, `evaluation/walk-forward-gates.md` |
| Role-based tasks | `roles/_role-index.md`, `context/role-task-routing.md` |

## MUST WRITE After These Events

| Event | Action |
|-------|--------|
| Design decision made | Create in `decisions/` with ADR template |
| Non-obvious behavior discovered | Create in `learnings/` |
| Tricky bug fixed | Update/create in relevant domain folder |
| Sprint completed | Create/update retro in `sprints/` |
| Risk limits or config changed | Update `risk/canonical-guardrails.md` + ADR via `manage_adr(mode='update')` |
| Unsure where it goes | Put in `inbox/` |

## Conventions

- Every note MUST have YAML frontmatter (see `docs/vault/_templates/`)
- Use `[[wikilinks]]` to connect related notes
- Filenames: kebab-case (e.g., `credit-sync-lockout.md`)
- Update `updated` field when modifying notes; set `status: superseded` (don't delete) when replaced
- Run `python scripts/validate/vault-lint.py` before committing vault changes
- After refactoring that deletes/moves modules, run `python scripts/validate/vault-code-drift.py --root .` or `/vault-hygiene` to detect stale notes

## Pillars

Vault notes have an optional `pillar:` frontmatter field for domain-level navigation. See [`docs/vault/pillars/_pillar-index.md`](../../docs/vault/pillars/_pillar-index.md) for the 10 pillars and their manifests.

When creating vault notes, assign `pillar:` per the routing table in [`docs/vault/CLAUDE.md`](../../docs/vault/CLAUDE.md).

**Pillar tools:**
- `python scripts/validate/pillar-autotag.py --apply` — auto-assign pillar to all notes
- `python scripts/validate/pillar-refresh.py` — refresh manifest Highlights/Recent
- `python scripts/validate/pillar-query.py --since 7d` — query across pillars

## Knowledge Notes

Consult [`docs/vault/knowledge/_manifest.md`](../../docs/vault/knowledge/_manifest.md) before architectural, risk, or strategy decisions. Only reference notes with `status: active`.
