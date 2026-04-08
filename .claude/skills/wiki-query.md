# Wiki Query Skill

Answer a question using the LLM wiki. Arguments: the question to answer.

## Instructions

Determine WIKI_ROOT:
1. Check env var `$WIKI_ROOT` first
2. Otherwise look for a `wiki/` directory with an `index.md` in the current working directory or its parents
3. If still not found, ask the user for the path

### Query workflow

1. Read `$WIKI_ROOT/wiki/index.md` to identify relevant pages
2. Search for relevant pages:
   - Use `mcp__wiki-tools__wiki_search` if available
   - Otherwise use Grep across `$WIKI_ROOT/wiki/`
3. Read the relevant pages
4. Synthesize an answer with citations using `[[page-name]]` wikilink format
5. Offer to file the answer as `wiki/queries/<kebab-question>.md`

### If no argument given

Ask the user what they want to know.

Use wiki-tools MCP if available. Fall back to Grep + Read tools if MCP is not loaded.
