#!/bin/sh
# self-improving-agents installer
# Run from the cloned repo root:  sh install.sh
# Idempotent — safe to re-run after pulling updates.

set -e

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
INSTALL_DIR="$CLAUDE_DIR/self-improving"

echo "self-improving-agents installer"
echo "==============================="
echo "Source:      $REPO_ROOT"
echo "Install to:  $CLAUDE_DIR"
echo ""

# --- 0. preflight ---
echo "[0/7] Preflight check..."
MISSING=""
for cmd in jq python3 git; do
  command -v "$cmd" >/dev/null 2>&1 || MISSING="$MISSING $cmd"
done
if [ -n "$MISSING" ]; then
  echo "ERROR: missing required commands:$MISSING"
  echo "On macOS:  brew install jq python3 git"
  exit 1
fi

# Optional but recommended
WARN=""
command -v gh >/dev/null 2>&1 || WARN="$WARN gh"
command -v timeout >/dev/null 2>&1 || command -v gtimeout >/dev/null 2>&1 || WARN="$WARN coreutils(for gtimeout)"
[ -n "$WARN" ] && echo "Optional but recommended:$WARN  (some features will degrade gracefully)"

CLAUDE_BIN=$(command -v claude || true)
if [ -z "$CLAUDE_BIN" ]; then
  echo "NOTE: 'claude' CLI not found in PATH. launchd cron jobs will not work."
  echo "      Install Claude Code from https://claude.com/code first if you want the cron."
fi

# --- 1. dirs ---
echo "[1/7] Creating directories..."
mkdir -p "$CLAUDE_DIR/hooks/self-improving"
mkdir -p "$CLAUDE_DIR/agents"
mkdir -p "$CLAUDE_DIR/skills"
mkdir -p "$INSTALL_DIR/data"
mkdir -p "$INSTALL_DIR/digests"
mkdir -p "$INSTALL_DIR/config"
mkdir -p "$INSTALL_DIR/sources"
mkdir -p "$INSTALL_DIR/logs"

# --- 2. copy hooks ---
echo "[2/7] Installing hooks..."
for f in _lib.sh test.sh README.md \
         no-coauthor-without-flag.sh \
         no-no-verify.sh \
         no-self-signed-keystore.sh \
         no-fake-env-vars.sh; do
  cp "$REPO_ROOT/hooks/$f" "$CLAUDE_DIR/hooks/self-improving/$f"
done
chmod +x "$CLAUDE_DIR/hooks/self-improving/"*.sh

# --- 3. copy agents + skills (with self-improving- prefix) ---
echo "[3/7] Installing agents and skills..."
cp "$REPO_ROOT/agents/failure-extractor.md"  "$CLAUDE_DIR/agents/self-improving-failure-extractor.md"
cp "$REPO_ROOT/agents/cve-scanner.md"        "$CLAUDE_DIR/agents/self-improving-cve-scanner.md"
cp "$REPO_ROOT/skills/meta-learn.md"         "$CLAUDE_DIR/skills/self-improving-meta-learn.md"
cp "$REPO_ROOT/skills/cve-digest.md"         "$CLAUDE_DIR/skills/self-improving-cve-digest.md"

# --- 4. install template (only if missing — preserves user edits on re-run) ---
echo "[4/7] Installing data templates (only if missing)..."
[ -f "$INSTALL_DIR/data/meta-failures.md" ] || cp "$REPO_ROOT/templates/meta-failures.md" "$INSTALL_DIR/data/meta-failures.md"
[ -f "$INSTALL_DIR/config/dependencies-watchlist.json" ] || cp "$REPO_ROOT/templates/dependencies-watchlist.example.json" "$INSTALL_DIR/config/dependencies-watchlist.json"
# Email config is opt-in — install example only if user hasn't created either form yet.
if [ ! -f "$INSTALL_DIR/config/email.json" ] && [ ! -f "$INSTALL_DIR/config/email.example.json" ]; then
  cp "$REPO_ROOT/templates/email.example.json" "$INSTALL_DIR/config/email.example.json"
fi

# --- 5. run hook tests ---
echo "[5/7] Running hook test suite..."
if sh "$CLAUDE_DIR/hooks/self-improving/test.sh"; then
  echo "Hook tests: OK"
else
  echo "ERROR: hook tests failed. Aborting before settings.json patch."
  exit 1
fi

# --- 6. patch settings.json (idempotent upsert + backup) ---
echo "[6/7] Patching ~/.claude/settings.json..."
SETTINGS="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "$SETTINGS.pre-self-improving.bak"
else
  echo '{}' > "$SETTINGS"
fi

python3 - <<PY
import json, pathlib
p = pathlib.Path("$SETTINGS")
data = json.loads(p.read_text() or "{}")
hook_dir = "$CLAUDE_DIR/hooks/self-improving"
bash_hooks = [
    {"type": "command", "command": f"{hook_dir}/no-coauthor-without-flag.sh"},
    {"type": "command", "command": f"{hook_dir}/no-no-verify.sh"},
    {"type": "command", "command": f"{hook_dir}/no-self-signed-keystore.sh"},
]
write_hooks = [
    {"type": "command", "command": f"{hook_dir}/no-fake-env-vars.sh"},
]
data.setdefault("hooks", {}).setdefault("PreToolUse", [])
pre = data["hooks"]["PreToolUse"]
def upsert(matcher, additions):
    for entry in pre:
        if entry.get("matcher") == matcher:
            existing = {h["command"] for h in entry.get("hooks", []) if h.get("type") == "command"}
            for h in additions:
                if h["command"] not in existing:
                    entry.setdefault("hooks", []).append(h)
            return
    pre.append({"matcher": matcher, "hooks": list(additions)})
upsert("Bash", bash_hooks)
upsert("Write", write_hooks)
upsert("Edit", write_hooks)
p.write_text(json.dumps(data, indent=2) + "\n")
print("settings.json patched.")
PY

# --- 7. optional: install launchd cron ---
echo "[7/7] launchd cron (optional)..."
if [ -z "$CLAUDE_BIN" ]; then
  echo "Skipping launchd — 'claude' CLI not in PATH."
elif [ "$(uname)" != "Darwin" ]; then
  echo "Skipping launchd — not on macOS. See README for cron alternatives on Linux."
else
  read -p "Install daily CVE scan + weekly catalog refresh as launchd jobs? [y/N] " yn
  case "$yn" in
    y|Y|yes)
      PLIST_DIR="$HOME/Library/LaunchAgents"
      mkdir -p "$PLIST_DIR"
      for kind in cve-daily weekly-recatalog; do
        SRC="$REPO_ROOT/launchd/com.self-improving.${kind}.plist.template"
        DEST="$PLIST_DIR/com.self-improving.${kind}.plist"
        sed -e "s|{{ HOME }}|$HOME|g" -e "s|{{ CLAUDE_BIN }}|$CLAUDE_BIN|g" "$SRC" > "$DEST"
        launchctl bootout "gui/$(id -u)" "$DEST" 2>/dev/null || true
        launchctl bootstrap "gui/$(id -u)" "$DEST"
        echo "Bootstrapped: com.self-improving.$kind"
      done
      launchctl list | grep self-improving || true
      ;;
    *)
      echo "Skipped. Run manually later: see README §Schedule."
      ;;
  esac
fi

echo ""
echo "Install complete."
echo ""
echo "Next steps:"
echo "  1. Edit  $INSTALL_DIR/config/dependencies-watchlist.json  with your projects."
echo "  2. Drop notes into  $INSTALL_DIR/sources/  for the failure-extractor to mine."
echo "  3. (Optional) Set up email delivery — see README \xc2\xa7 Email notifications,"
echo "     or copy  $INSTALL_DIR/config/email.example.json  to  email.json  and fill in."
echo "  4. Try a manual run:  /self-improving-cve-digest   or   /self-improving-meta-learn"
echo ""
echo "Uninstall any time:  sh $REPO_ROOT/uninstall.sh"
