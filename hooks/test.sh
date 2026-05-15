#!/bin/sh
# Hook test harness. Run from anywhere:
#   sh hooks/test.sh
# Expected: "Results: 13 passed, 0 failed"

set -u
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0
FAIL=0

# === _lib.sh ===

if (. "$HOOK_DIR/_lib.sh") >/dev/null 2>&1; then
  PASS=$((PASS+1)); echo "PASS: _lib.sh sources"
else
  FAIL=$((FAIL+1)); echo "FAIL: _lib.sh sources"
fi

if SELF_IMPROVING_AGENTS_DISABLED=1 sh -c ". $HOOK_DIR/_lib.sh; disabled_check"; then
  PASS=$((PASS+1)); echo "PASS: disabled_check exits 0 when SELF_IMPROVING_AGENTS_DISABLED=1"
else
  FAIL=$((FAIL+1)); echo "FAIL: disabled_check exits 0 when SELF_IMPROVING_AGENTS_DISABLED=1"
fi

# === no-coauthor-without-flag.sh ===

POS_COAUTHOR='{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: x\n\nCo-Authored-By: Bot <b@x.com>\""}}'
NEG_COAUTHOR='{"tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: x\""}}'

if [ -x "$HOOK_DIR/no-coauthor-without-flag.sh" ]; then
  if printf '%s' "$POS_COAUTHOR" | sh "$HOOK_DIR/no-coauthor-without-flag.sh" >/dev/null 2>&1; then
    FAIL=$((FAIL+1)); echo "FAIL: no-coauthor positive (should have blocked)"
  else
    PASS=$((PASS+1)); echo "PASS: no-coauthor positive blocks"
  fi

  if printf '%s' "$NEG_COAUTHOR" | sh "$HOOK_DIR/no-coauthor-without-flag.sh" >/dev/null 2>&1; then
    PASS=$((PASS+1)); echo "PASS: no-coauthor negative allows"
  else
    FAIL=$((FAIL+1)); echo "FAIL: no-coauthor negative (should have allowed)"
  fi

  if printf '%s' "$POS_COAUTHOR" | ALLOW_COAUTHOR=1 sh "$HOOK_DIR/no-coauthor-without-flag.sh" >/dev/null 2>&1; then
    PASS=$((PASS+1)); echo "PASS: no-coauthor bypass via ALLOW_COAUTHOR=1"
  else
    FAIL=$((FAIL+1)); echo "FAIL: no-coauthor bypass (should have allowed)"
  fi
fi

# === no-no-verify.sh ===

POS_NV1='{"tool_name":"Bash","tool_input":{"command":"git commit --no-verify -m x"}}'
POS_NV2='{"tool_name":"Bash","tool_input":{"command":"git push --no-gpg-sign"}}'
NEG_NV='{"tool_name":"Bash","tool_input":{"command":"git commit -m x"}}'

if [ -x "$HOOK_DIR/no-no-verify.sh" ]; then
  for inp in "$POS_NV1" "$POS_NV2"; do
    if printf '%s' "$inp" | sh "$HOOK_DIR/no-no-verify.sh" >/dev/null 2>&1; then
      FAIL=$((FAIL+1)); echo "FAIL: no-no-verify positive (should have blocked: $inp)"
    else
      PASS=$((PASS+1)); echo "PASS: no-no-verify positive blocks"
    fi
  done

  if printf '%s' "$NEG_NV" | sh "$HOOK_DIR/no-no-verify.sh" >/dev/null 2>&1; then
    PASS=$((PASS+1)); echo "PASS: no-no-verify negative allows"
  else
    FAIL=$((FAIL+1)); echo "FAIL: no-no-verify negative (should have allowed)"
  fi
fi

# === no-self-signed-keystore.sh ===

POS_KS1='{"tool_name":"Bash","tool_input":{"command":"keytool -genkey -alias debug -keystore ./debug.keystore"}}'
POS_KS2='{"tool_name":"Bash","tool_input":{"command":"openssl req -newkey rsa:4096 -keyout key.pem -x509 -out cert.pem"}}'
NEG_KS='{"tool_name":"Bash","tool_input":{"command":"keytool -list -keystore ./debug.keystore"}}'

if [ -x "$HOOK_DIR/no-self-signed-keystore.sh" ]; then
  for inp in "$POS_KS1" "$POS_KS2"; do
    if printf '%s' "$inp" | sh "$HOOK_DIR/no-self-signed-keystore.sh" >/dev/null 2>&1; then
      FAIL=$((FAIL+1)); echo "FAIL: no-keygen positive (should have blocked: $inp)"
    else
      PASS=$((PASS+1)); echo "PASS: no-keygen positive blocks"
    fi
  done

  if printf '%s' "$NEG_KS" | sh "$HOOK_DIR/no-self-signed-keystore.sh" >/dev/null 2>&1; then
    PASS=$((PASS+1)); echo "PASS: no-keygen negative (keytool -list) allows"
  else
    FAIL=$((FAIL+1)); echo "FAIL: no-keygen negative (should have allowed)"
  fi
fi

# === no-fake-env-vars.sh ===

if [ -x "$HOOK_DIR/no-fake-env-vars.sh" ]; then
  SCRATCH=$(mktemp -d)
  cat >"$SCRATCH/code.py" <<'PY'
import os
key = os.getenv("REAL_KEY")
PY

  POS_ENV=$(jq -n --arg p "$SCRATCH/.env.example" --arg c 'REAL_KEY=...
FAKE_KEY=...' '{tool_name:"Write",tool_input:{file_path:$p,content:$c}}')
  NEG_ENV=$(jq -n --arg p "$SCRATCH/.env.example" --arg c 'REAL_KEY=...' '{tool_name:"Write",tool_input:{file_path:$p,content:$c}}')

  cd "$SCRATCH"
  if printf '%s' "$POS_ENV" | sh "$HOOK_DIR/no-fake-env-vars.sh" >/dev/null 2>&1; then
    FAIL=$((FAIL+1)); echo "FAIL: no-fake-env positive (should have blocked FAKE_KEY)"
  else
    PASS=$((PASS+1)); echo "PASS: no-fake-env positive blocks"
  fi
  if printf '%s' "$NEG_ENV" | sh "$HOOK_DIR/no-fake-env-vars.sh" >/dev/null 2>&1; then
    PASS=$((PASS+1)); echo "PASS: no-fake-env negative allows"
  else
    FAIL=$((FAIL+1)); echo "FAIL: no-fake-env negative (should have allowed)"
  fi
  cd - >/dev/null
  rm -rf "$SCRATCH"
fi

echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
