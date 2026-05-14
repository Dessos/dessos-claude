# dessos-claude — `domain-coupled` branch

> **This is the `domain-coupled` branch.** It contains the full personal kit (14 skills + 11 commands + 6 rules), not the public-installable plugin. For the installable plugin see [`main`](https://github.com/Dessos/dessos-claude/tree/main).

## Purpose

A centralized reference of the operator's complete Claude Code workflow across two projects (a trading platform + an AI-OS enterprise project). Skills, commands, and rules here are **coupled to the operator's domain conventions** — V-series finding IDs, governance gates, vault structure, focus rubric, WSJF queue, etc.

Project-identifying strings have been sanitized (`aihedgefund` → `myproject`, `ai-hedgefund-2026` → `trading-project`); workflow conventions (HF_* env vars, hf_* metrics, V6-XXX finding IDs) are preserved as-is so the docs match the operator's actual environment.

## Not installable as a plugin

The `main` branch is the canonical installable Claude Code plugin (9 generic engineering skills). This `domain-coupled` branch is intentionally project-coupled and **should not be installed via `/plugin install`** — its skills assume specific repo structure (a `src/myproject/` layout, vault at `docs/vault/`, finding ledger at `reports/findings/`, etc.) that won't exist in arbitrary projects.

Use this branch as a **reference** — clone the repo, `git checkout domain-coupled`, then hand-pick skills/commands/rules into your project's `.claude/` directory.

## What's in the kit

### Skills (14)

| Skill | Purpose |
|---|---|
| `tdd` | Test-driven red-green-refactor loop |
| `code-review` | Project-conventions code review checklist |
| `improve-codebase-architecture` | Deepen shallow modules (Ousterhout) |
| `grill-me` | Interview-driven plan stress-testing with domain awareness |
| `write-a-prd` | Interactive PRD authoring |
| `prd-to-plan` | PRD → multi-phase vertical-slice plan |
| `prd-to-tasks` | PRD → HITL/AFK tasks |
| `request-refactor-plan` | Refactor plan with tiny commits |
| `ubiquitous-language` | DDD glossary extraction |
| `design-an-interface` | Parallel interface design via sub-agents |
| `backtest-workflow` | Backtest run + analysis workflow |
| `knowledge-ingest` | Vault knowledge ingestion |
| `vault-code-bridge` | Cross-reference vault notes ↔ source code |
| `close-finding` | 7-gate manual finding closure flow |

### Commands (11)

`adr-remember`, `adr-show`, `briefing`, `clean-doc-drift`, `file-finding`, `focus`, `focus-burndown`, `handoff`, `pivot-add`, `triage-routine-findings`, `wsjf`

### Rules (6)

`adr-workflow`, `findings-workflow`, `metrics-and-observability`, `multi-agent`, `risk-guardrails`, `vault-workflow`

## License

[MIT](LICENSE) — same as `main`.
