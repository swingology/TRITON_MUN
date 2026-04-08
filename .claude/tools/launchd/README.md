# launchd — Wiki Automation

Two agents run as macOS launchd services:

| Plist | Purpose | Trigger |
|-------|---------|---------|
| `com.wiki.watcher` | Watches `raw/` and `Clippings/` for new files, queues them | On file creation/update |
| `com.wiki.ingest` | Processes the ingest queue via `ingest-queue.sh` | Every 30 minutes |

## Prerequisites

```bash
brew install fswatch
```

## Install

```bash
# Copy plists to LaunchAgents
cp tools/launchd/com.wiki.watcher.plist ~/Library/LaunchAgents/
cp tools/launchd/com.wiki.ingest.plist  ~/Library/LaunchAgents/

# Load them (starts immediately + persists across reboots)
launchctl load ~/Library/LaunchAgents/com.wiki.watcher.plist
launchctl load ~/Library/LaunchAgents/com.wiki.ingest.plist
```

## Check status

```bash
launchctl list | grep wiki
tail -f /tmp/wiki-watcher.log
tail -f /tmp/wiki-ingest.log
```

## Stop / unload

```bash
launchctl unload ~/Library/LaunchAgents/com.wiki.watcher.plist
launchctl unload ~/Library/LaunchAgents/com.wiki.ingest.plist
```

## Notes

- `com.wiki.ingest` calls `ingest-queue.sh` which calls `ingest.sh` which runs `claude --print`.
  Make sure `ANTHROPIC_API_KEY` is set — either in your shell profile or uncommented in the plist.
- The watcher uses `KeepAlive true` so launchd auto-restarts it if it crashes.
- Ingest runs every 30 minutes (`StartInterval 1800`). Change to taste.
