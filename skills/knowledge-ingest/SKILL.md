# Knowledge Ingestion

Ingest external content (articles, tweets, papers) into the AI Knowledge Vault.

## Trigger
- User pastes article text or URL
- User says "ingest this", "add to vault", or "save this knowledge"

## Workflow

1. **Extract** key insights from the pasted content
2. **Categorize** into one of the 27 vault categories (see `references/categories.md`)
3. **Generate** a vault note with valid YAML frontmatter (see `references/conventions.md`)
4. **Place** the note in `docs/vault/knowledge/` with `status: draft`
5. **Cross-link** with `[[wikilinks]]` to related existing vault notes
6. **Report** the file path and suggest related notes for the user to review

## Rules

- All ingested notes enter as `status: draft` — only the digestion pipeline promotes to `active`
- Filenames must be kebab-case and descriptive
- Tags must be kebab-case using the vault taxonomy
- Include `source:` field pointing to the original URL or "user-provided"
- Include `source_type:` (twitter, article, blog, paper, discord, youtube, raw_text)
- Set `confidence:` based on source quality (high/medium/low)
- Use the note template in `assets/note-template.md` as the structural guide
- Cross-link aggressively — check existing vault notes for related content

## Quality Checks

Before saving, verify:
- [ ] Valid YAML frontmatter with all required fields
- [ ] Category is one of the 27 valid categories
- [ ] At least 2 key insights extracted
- [ ] Filename is kebab-case
- [ ] No duplicate note exists (check by title similarity)

## References
- `references/categories.md` — 27 categories organized by domain
- `references/conventions.md` — vault frontmatter schema and rules
- `assets/note-template.md` — example well-formed note
- `src/myproject/knowledge/models.py` — canonical category definitions
