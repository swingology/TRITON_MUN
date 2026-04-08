# SKILLS.md — Master Skills Registry

All skills available in this project. Each entry shows the invocation, its file location, and what it does.

Skills in `.claude/skills/` are project-local. To make a skill globally available across all projects, copy its file to `~/.claude/skills/`.

---

## Wiki Skills

Require `WIKI_ROOT` to be set or detectable. Use wiki-tools MCP when available; fall back to direct file tools.

| Invoke | File | Purpose |
|--------|------|---------|
| `/wiki-ingest [file]` | `skills/wiki-ingest.md` | Ingest a source file or drain `raw/.queue/pending.txt` |
| `/wiki-query <question>` | `skills/wiki-query.md` | Search wiki, synthesize answer with citations, offer to file result |
| `/wiki-lint` | `skills/wiki-lint.md` | Full structural audit → `wiki/queries/lint-YYYY-MM-DD.md` |

---

## Ingest Queue Skills

| Invoke | Purpose |
|--------|---------|
| `/queue-add <path>` | Add a file to `raw/.queue/pending.txt` |
| `/queue-status` | Show pending file count and last ingest run |

**`/queue-add`** — validate the file exists, then append to `raw/.queue/pending.txt`. Deduplicate against `done.txt`.

**`/queue-status`** — read `raw/.queue/pending.txt` and `raw/.queue/done.txt`, show counts and most recent entry from `wiki/log.md`.

---

## Diagram Skills

| Invoke | File | Purpose |
|--------|------|---------|
| `/excalidraw-diagram` | `skills/excalidraw-diagram/SKILL.md` | Generate `.excalidraw` JSON files that argue visually |

The excalidraw skill is self-contained — it includes its own color palette, element templates, JSON schema reference, and a render/validate loop. Read `skills/excalidraw-diagram/SKILL.md` for the full workflow.

Renderer setup (first time only):
```bash
cd .claude/skills/excalidraw-diagram/references
uv sync && uv run playwright install chromium
```

---

## Memory Skills

| Invoke | Purpose |
|--------|---------|
| `/memory-check` | Verify `.claude/MEMORY.md` exists, list loaded memory files |
| `/memory-add <text>` | Add a new memory entry to `.claude/memory/` |
| `/memory-search <query>` | Search `.claude/memory/*.md` files |
| `/memory-list` | List all memory files and their descriptions |

---

## MCP Tools Reference

### wiki-tools (Docker or local Python)

| Tool | Purpose |
|------|---------|
| `mcp__wiki-tools__wiki_search` | Search by text query, tag, domain |
| `mcp__wiki-tools__wiki_read` | Read any wiki page by path |
| `mcp__wiki-tools__wiki_write` | Write or update a wiki page |
| `mcp__wiki-tools__wiki_index` | Get current `wiki/index.md` |
| `mcp__wiki-tools__log_append` | Append to `wiki/log.md` |
| `mcp__wiki-tools__ingest_queue` | Check `raw/.queue/pending.txt` |

Register the MCP server (Docker):
```bash
claude mcp add wiki-tools --transport docker -- \
  docker run --rm -i \
  -v "$WIKI_ROOT:/wiki:rw" \
  -e WIKI_ROOT=/wiki \
  wiki-tools-mcp
```

---

## Deploying This Package to a New Project

1. Copy `.claude/` into the target project root
2. Clear `memory/project_decisions.md` and `memory/patterns.md` — they will be repopulated by Claude
3. Set `WIKI_ROOT` to the project path, or ensure `wiki/index.md` exists so Claude can detect it
4. Build and register the MCP server (see above)
5. Install macOS automation if desired (see `tools/launchd/README.md`)
