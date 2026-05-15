#!/bin/sh
# self-improving-agents uninstaller. Reversible.
# Restores ~/.claude/settings.json from .pre-self-improving.bak if present.

set -e

CLAUDE_DIR="$HOME/.claude"
echo "self-improving-agents uninstaller"
echo "================================="
echo ""

# 1. unload launchd jobs
if [ "$(uname)" = "Darwin" ]; then
  for kind in cve-daily weekly-recatalog; do
    PLIST="$HOME/Library/LaunchAgents/com.self-improving.${kind}.plist"
    if [ -f "$PLIST" ]; then
      launchctl bootout "gui/$(id -u)" "$PLIST" 2>/dev/null || true
      rm -f "$PLIST"
      echo "Removed launchd job: com.self-improving.$kind"
    fi
  done
fi

# 2. restore settings.json from backup (preferred) or strip our entries
SETTINGS="$CLAUDE_DIR/settings.json"
BACKUP="$SETTINGS.pre-self-improving.bak"
if [ -f "$BACKUP" ]; then
  echo "Restoring settings.json from backup..."
  cp "$BACKUP" "$SETTINGS"
elif [ -f "$SETTINGS" ]; then
  echo "No backup found — stripping self-improving entries from settings.json..."
  python3 - <<'PY'
import json, pathlib, os
p = pathlib.Path(os.environ["HOME"]) / ".claude" / "settings.json"
data = json.loads(p.read_text() or "{}")
pre = data.get("hooks", {}).get("PreToolUse", [])
for entry in pre:
    entry["hooks"] = [
        h for h in entry.get("hooks", [])
        if "self-improving" not in (h.get("command") or "")
    ]
data["hooks"]["PreToolUse"] = [e for e in pre if e.get("hooks")]
p.write_text(json.dumps(data, indent=2) + "\n")
print("Stripped.")
PY
fi

# 3. remove files
echo "Removing installed files..."
rm -rf "$CLAUDE_DIR/self-improving"
rm -rf "$CLAUDE_DIR/hooks/self-improving"
rm -f  "$CLAUDE_DIR/agents/self-improving-failure-extractor.md"
rm -f  "$CLAUDE_DIR/agents/self-improving-cve-scanner.md"
rm -f  "$CLAUDE_DIR/skills/self-improving-meta-learn.md"
rm -f  "$CLAUDE_DIR/skills/self-improving-cve-digest.md"

echo ""
echo "Uninstalled. Backup of settings.json (if any) left at: $BACKUP"
