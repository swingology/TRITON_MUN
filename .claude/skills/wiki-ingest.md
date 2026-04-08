# Wiki Ingest Skill

Ingest a source file into the LLM wiki. Arguments: optional file path. If no path given, process the ingest queue.

## Instructions

Determine WIKI_ROOT:
1. Check env var `$WIKI_ROOT` first
2. Otherwise look for a `wiki/` directory with an `index.md` in the current working directory or its parents
3. If still not found, ask the user for the path

### If a file path was given as argument (`$ARGUMENTS`):

1. Read the file at `$ARGUMENTS`
2. Read `$WIKI_ROOT/CLAUDE.md` for the schema and ingest workflow
3. Read `$WIKI_ROOT/wiki/index.md` for current state
4. Follow the **Ingest Workflow** in CLAUDE.md exactly:
   - Discuss key takeaways (2-3 sentences)
   - Write `wiki/sources/<kebab-title>.md`
   - Update or create domain pages (typically 3-8 pages)
   - Update `wiki/index.md`
   - Append to `wiki/log.md`

### If no argument given:

1. Read `$WIKI_ROOT/raw/.queue/pending.txt`
2. If empty, report "Queue is empty"
3. Otherwise process each file in the queue:
   - Run ingest for each file (following CLAUDE.md workflow)
   - After success, remove from pending.txt and append to `raw/.queue/done.txt`
4. Report: files processed, files failed, pages created/updated

Use wiki-tools MCP if available (`mcp__wiki-tools__wiki_write`, `mcp__wiki-tools__wiki_index`, `mcp__wiki-tools__log_append`). Fall back to direct Read/Write/Edit tools if MCP is not loaded.
