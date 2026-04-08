"""
LLM Wiki MCP Server
Exposes wiki tools: search, read, write, index, ingest_queue, log_append
"""
import os
import shutil
import subprocess
from pathlib import Path
from fastmcp import FastMCP

WIKI_ROOT = Path(os.environ.get("WIKI_ROOT", Path(__file__).parent.parent.parent))
WIKI_DIR = WIKI_ROOT / "wiki"
QUEUE_FILE = WIKI_ROOT / "raw" / ".queue" / "pending.txt"

# Prefer ripgrep if available, fall back to grep
_RG = shutil.which("rg") or os.environ.get("RG_PATH", "rg")

mcp = FastMCP("llm-wiki")


def _grep_files(pattern: str, path: str, glob: bool = True) -> str:
    """Run ripgrep if available, else fall back to grep -rl."""
    if shutil.which(_RG):
        cmd = [_RG, pattern, path, "-l"]
        if glob:
            cmd += ["--glob", "*.md"]
        result = subprocess.run(cmd, capture_output=True, text=True)
    else:
        # grep -rl: recursive, files-with-matches only
        cmd = ["grep", "-rl", "--include=*.md", pattern, path]
        result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout.strip()


def wiki_search_impl(query: str, tag: str = "", domain: str = "") -> str:
    """Search wiki pages. Returns matching file paths."""
    search_path = str(WIKI_DIR / domain) if domain else str(WIKI_DIR)

    if tag:
        tag_files = _grep_files(f"tags:.*{tag}", search_path)
        if not tag_files:
            return f"No pages tagged: {tag}"
        if query:
            results = []
            for f in tag_files.splitlines():
                r = _grep_files(query, f, glob=False)
                if r:
                    results.append(r)
            return "\n".join(results) if results else "No matches."
        return tag_files

    if query:
        matched = _grep_files(query, search_path)
        return matched or "No matches."

    result = subprocess.run(
        ["find", search_path, "-name", "*.md"],
        capture_output=True, text=True
    )
    return result.stdout.strip()


def wiki_read_impl(path: str) -> str:
    """Read a wiki page by relative path."""
    full_path = WIKI_ROOT / path
    if not full_path.exists():
        return f"Page not found: {path}"
    return full_path.read_text()


def wiki_write_impl(path: str, content: str) -> str:
    """Write a wiki page."""
    full_path = WIKI_ROOT / path
    full_path.parent.mkdir(parents=True, exist_ok=True)
    full_path.write_text(content)
    return f"Written: {path}"


def wiki_index_impl() -> str:
    """Return current index.md content."""
    return (WIKI_DIR / "index.md").read_text()


def log_append_impl(entry: str) -> str:
    """Append an entry to log.md."""
    log_path = WIKI_DIR / "log.md"
    with open(log_path, "a") as f:
        f.write(f"\n{entry}\n")
    return "Logged."


def ingest_queue_impl() -> str:
    """Return pending ingest queue contents."""
    if not QUEUE_FILE.exists():
        return "Queue file not found."
    content = QUEUE_FILE.read_text().strip()
    return content if content else "Queue is empty."


@mcp.tool()
def wiki_search(query: str = "", tag: str = "", domain: str = "") -> str:
    """Search the wiki by text query, tag, and/or domain."""
    return wiki_search_impl(query, tag, domain)

@mcp.tool()
def wiki_read(path: str) -> str:
    """Read a wiki page by path (relative to wiki root)."""
    return wiki_read_impl(path)

@mcp.tool()
def wiki_write(path: str, content: str) -> str:
    """Write or update a wiki page."""
    return wiki_write_impl(path, content)

@mcp.tool()
def wiki_index() -> str:
    """Get the current wiki index."""
    return wiki_index_impl()

@mcp.tool()
def log_append(entry: str) -> str:
    """Append an entry to the wiki log."""
    return log_append_impl(entry)

@mcp.tool()
def ingest_queue() -> str:
    """Check the ingest queue for pending files."""
    return ingest_queue_impl()


if __name__ == "__main__":
    mcp.run()
