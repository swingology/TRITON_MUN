# Wiki Lint Skill

Scan the LLM wiki for structural issues and output a report.

## Instructions

Determine WIKI_ROOT:
1. Check env var `$WIKI_ROOT` first
2. Otherwise look for a `wiki/` directory with an `index.md` in the current working directory or its parents
3. If still not found, ask the user for the path

Read `$WIKI_ROOT/CLAUDE.md` for the lint workflow definition, then run it:

### Lint checks

1. **Orphan pages** — pages with no inbound `[[wikilinks]]` from other pages
2. **Missing pages** — `[[wikilinks]]` that reference pages that don't exist
3. **Untagged pages** — pages missing `tags:` in their YAML frontmatter
4. **Index drift** — pages that exist on disk but aren't listed in `wiki/index.md`
5. **Stale claims** — pages whose `updated:` date is older than 90 days and that reference entities/models that may have changed
6. **Domain gaps** — domains with only one page on a sub-topic (suggest expansion)

### Output

Write the report to `$WIKI_ROOT/wiki/queries/lint-YYYY-MM-DD.md` (use today's date).

Print a summary of findings to the user.

Use wiki-tools MCP if available. Fall back to Grep + Glob + Read tools if MCP is not loaded.
