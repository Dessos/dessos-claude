# Vault Conventions (Condensed)

Source: `docs/vault/context/vault-conventions.md`

## Required Frontmatter (ALL notes)
```yaml
---
type: knowledge           # for ingested content
status: draft             # ALL ingested notes start as draft
created: YYYY-MM-DDTHH:mm:ssZ
updated: YYYY-MM-DDTHH:mm:ssZ
tags: []                  # kebab-case
related: []               # [[wikilinks]]
confidence: high|medium|low
source: ""                # URL or "user-provided"
---
```

## Naming
- Filenames: **kebab-case**, descriptive (e.g., `kelly-criterion-half-sizing.md`)
- Place in: `docs/vault/knowledge/`

## Tags Taxonomy
| Prefix | Examples |
|--------|----------|
| _(none)_ | `risk`, `engine`, `strategy`, `ml` |
| `finding/` | `finding/F001` |
| `sprint/` | `sprint/2026-w12` |
| `topic/` | `topic/epsilon` |

## Digestion Gate
- All raw ingested notes: `status: draft`
- Only promoted to `active` after cross-reference analysis (3+ independent sources)
- Only `active` notes may be referenced from CLAUDE.md, skills, or system decisions
- Unverifiable claims must be flagged explicitly

## Lifecycle
- Supersede, don't delete (set `status: superseded`)
- Always update `updated` field
- Cross-link aggressively with `[[wikilinks]]`
