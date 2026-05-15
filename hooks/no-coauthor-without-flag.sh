#!/bin/sh
# Blocks `git commit` whose message contains `Co-Authored-By:` unless ALLOW_COAUTHOR=1.
# Rationale: many users prefer commit authorship to reflect humans only, or have org
# policy against auto-added agent co-author lines. Hook is a guardrail, not a prison —
# set ALLOW_COAUTHOR=1 for the one commit that should keep the line.

. "$(dirname "$0")/_lib.sh"
disabled_check

if [ "${ALLOW_COAUTHOR:-}" = "1" ]; then
  exit 0
fi

payload=$(read_tool_input)
cmd=$(extract_bash_command "$payload")

case "$cmd" in
  *"git commit"*|*"git -c"*"commit"*) ;;
  *) exit 0 ;;
esac

case "$cmd" in
  *"Co-Authored-By:"*|*"co-authored-by:"*)
    log_block "git commit contains 'Co-Authored-By'. Default policy: do not add co-author lines unless explicitly requested. Re-run with ALLOW_COAUTHOR=1 if intentional."
    exit 2
    ;;
esac
exit 0
