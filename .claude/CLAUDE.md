# CLAUDE.md — Session Startup

## 1. Load Skills Registry

Read `.claude/skills/SKILLS.md` now. It lists every available skill, how to invoke it, and what it does.

---

## 2. Memory Check

Check if project memory exists:
```bash
test -f .claude/MEMORY.md && echo "initialized" || echo "run: mkdir -p .claude/memory && touch .claude/MEMORY.md"
```

If initialized, the following memories are loaded:
- [.claude/memory/user_preferences.md](.claude/memory/user_preferences.md) — user workflow preferences
- [.claude/memory/project_decisions.md](.claude/memory/project_decisions.md) — architecture and design decisions
- [.claude/memory/patterns.md](.claude/memory/patterns.md) — recurring patterns and corrections

---

## 3. Wiki Root Detection

Resolve `WIKI_ROOT` for all wiki and ingest operations:
1. Check `$WIKI_ROOT` env var
2. Look for `wiki/index.md` walking up from CWD
3. If not found, ask the user

The wiki schema — directory layout, page formats, ingest/query/lint workflows — is in the root `CLAUDE.md`. Read it before any wiki operation.

---

## 4. Quick Skill Reference

| Invoke | Purpose |
|--------|---------|
| `/wiki-ingest [file]` | Ingest a file or drain the queue |
| `/wiki-query <question>` | Search wiki + synthesize answer |
| `/wiki-lint` | Full wiki health audit |
| `/excalidraw-diagram` | Generate an Excalidraw `.excalidraw` file |

Full registry with all options: `.claude/skills/SKILLS.md`

---

**Note:** This file is kept under 60 lines. All schema and workflow detail lives in root `CLAUDE.md`.
