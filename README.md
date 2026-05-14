# dessos-claude

Generic engineering skills for [Claude Code](https://claude.com/claude-code), distilled from real cross-project use. Ships project-agnostic so domain-specific overrides can ride on top.

## What's inside

Ten skills covering the engineering workflow surface:

| Skill | When to use |
|---|---|
| [`tdd`](skills/tdd/SKILL.md) | Test-driven development with red-green-refactor loop. Vertical slices, not horizontal. |
| [`improve-codebase-architecture`](skills/improve-codebase-architecture/SKILL.md) | Find refactoring opportunities by deepening shallow modules (Ousterhout). |
| [`three-phase-derived-view-pattern`](skills/three-phase-derived-view-pattern/SKILL.md) | Apply write-sync / read-inject / staleness to keep a derived view (docs, indexes, ADR, dependency graphs) in sync with source state. |
| [`grill-me`](skills/grill-me/SKILL.md) | Interview-driven plan stress-testing. Walks every branch of the decision tree. |
| [`write-a-prd`](skills/write-a-prd/SKILL.md) | Create a PRD via interactive interview, codebase exploration, module design. |
| [`prd-to-plan`](skills/prd-to-plan/SKILL.md) | Convert a PRD into a multi-phase implementation plan using vertical tracer-bullet slices. |
| [`prd-to-tasks`](skills/prd-to-tasks/SKILL.md) | Break a PRD into independently-grabbable HITL / AFK tasks. |
| [`request-refactor-plan`](skills/request-refactor-plan/SKILL.md) | Create a detailed refactor plan with tiny commits via user interview. |
| [`ubiquitous-language`](skills/ubiquitous-language/SKILL.md) | Extract a DDD-style glossary; flag ambiguities, propose canonical terms. |
| [`design-an-interface`](skills/design-an-interface/SKILL.md) | Generate multiple radically different interface designs via parallel sub-agents. |

## Install

Inside Claude Code:

```
/plugin marketplace add Dessos/dessos-claude
/plugin install dessos-claude@dessos-claude
```

Once installed at user scope, the skills are available in every project — no per-project wiring needed. Skills surface via the `Skill` tool or `/<skill-name>`.

To update later: `/plugin marketplace update dessos-claude`.

## Project-specific overrides

The plugin ships generic versions. To layer domain awareness without forking the skill, drop a project-local override at `.claude/skills/<skill-name>/SKILL.md` in your repo — local skills take precedence over plugin skills.

Example: append a `## Project-Domain Awareness` section to `grill-me` listing what to cross-reference for your project (governance rules, architectural constraints, risk gates).

## Development

Skills follow the [Anthropic skill format](https://docs.claude.com/en/docs/claude-code/skills): a directory containing `SKILL.md` with YAML frontmatter (`name`, `description`) followed by the prompt content.

Lint a skill before committing:

```bash
# from the repo root
python -m yaml < skills/<skill-name>/SKILL.md  # validates frontmatter
```

PRs welcome for generic skills only — domain-specific stuff belongs in project-local `.claude/skills/`.

## Origin

Most skills here derive from [mattpocock/skills](https://github.com/mattpocock/skills), refined through use on real production codebases (one large quantitative trading platform, one enterprise AI-OS project) and stripped of domain-specific framing. Customizations stay in each project's local `.claude/skills/`; the generic core lives here.

## License

[MIT](LICENSE) — use freely, modify, redistribute.
