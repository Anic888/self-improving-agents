#!/bin/sh
# Blocks --no-verify / --no-gpg-sign / commit.gpgsign=false unless ALLOW_NO_VERIFY=1.
# Rationale: skipping pre-commit hooks or GPG signing usually indicates a workaround
# rather than a fix. If a hook is failing, fix the underlying issue. Set
# ALLOW_NO_VERIFY=1 only when the user has explicitly authorized the bypass.

. "$(dirname "$0")/_lib.sh"
disabled_check

if [ "${ALLOW_NO_VERIFY:-}" = "1" ]; then
  exit 0
fi

payload=$(read_tool_input)
cmd=$(extract_bash_command "$payload")

case "$cmd" in
  *"--no-verify"*|*"--no-gpg-sign"*|*"commit.gpgsign=false"*)
    log_block "Command uses --no-verify / --no-gpg-sign / commit.gpgsign=false. Default policy: never skip hooks or signing without explicit user instruction. Set ALLOW_NO_VERIFY=1 to bypass."
    exit 2
    ;;
esac
exit 0
