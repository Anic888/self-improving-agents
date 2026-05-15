#!/bin/sh
# Blocks Write/Edit to .env* files declaring variables that aren't referenced
# anywhere in the cwd as os.getenv(), process.env.NAME, or Deno.env.get().
# Rationale: phantom env vars create "safety rails" that don't exist — the code
# never reads them. Tells the user they're protected when they aren't. This hook
# enforces grep-before-write. Bypass: ALLOW_FAKE_ENV=1.
#
# Note: uses GNU `timeout` (or `gtimeout`) to cap grep at 1.5s on large repos.
# On systems without either, runs grep unbounded — typically still fast.

. "$(dirname "$0")/_lib.sh"
disabled_check

if [ "${ALLOW_FAKE_ENV:-}" = "1" ]; then
  exit 0
fi

payload=$(read_tool_input)
path=$(extract_write_path "$payload")
content=$(extract_write_content "$payload")

case "$path" in
  *.env|*.env.*|*/.env|*/.env.*) ;;
  *) exit 0 ;;
esac

vars=$(printf '%s\n' "$content" \
  | grep -E '^[A-Z_][A-Z0-9_]*=' \
  | sed 's/=.*//' \
  | sort -u)

[ -z "$vars" ] && exit 0

if command -v timeout >/dev/null 2>&1; then
  TIMEOUT="timeout 1.5"
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT="gtimeout 1.5"
else
  TIMEOUT=""
fi

fake=""
for v in $vars; do
  if ! $TIMEOUT grep -RIl --exclude-dir=node_modules --exclude-dir=.git \
        --exclude='*.env*' \
        -E "(os\\.getenv\\(['\"]${v}['\"]|process\\.env\\.${v}\\b|Deno\\.env\\.get\\(['\"]${v}['\"])" \
        . >/dev/null 2>&1; then
    fake="$fake $v"
  fi
done

if [ -n "$fake" ]; then
  log_block "These env vars are not referenced anywhere in $(pwd):$fake. Default policy: grep os.getenv / process.env BEFORE writing .env / .env.example. Bypass: ALLOW_FAKE_ENV=1."
  exit 2
fi
exit 0
