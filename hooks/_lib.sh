#!/bin/sh
# Shared helpers for self-improving hooks. Source this file from each hook.

disabled_check() {
  if [ "${SELF_IMPROVING_AGENTS_DISABLED:-}" = "1" ]; then
    exit 0
  fi
}

log_block() {
  reason="$1"
  printf 'BLOCKED by self-improving-hooks: %s\n' "$reason" >&2
  printf 'To bypass once: set the documented per-hook env var (see hooks/README.md).\n' >&2
  printf 'To disable all self-improving hooks: export SELF_IMPROVING_AGENTS_DISABLED=1\n' >&2
}

read_tool_input() {
  cat
}

extract_bash_command() {
  printf '%s' "$1" | jq -r '.tool_input.command // empty'
}

extract_write_content() {
  printf '%s' "$1" | jq -r '.tool_input.content // empty'
}

extract_write_path() {
  printf '%s' "$1" | jq -r '.tool_input.file_path // empty'
}
