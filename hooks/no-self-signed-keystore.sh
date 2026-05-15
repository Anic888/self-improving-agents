#!/bin/sh
# Blocks keytool/openssl keypair generation unless ALLOW_KEYGEN=1.
# Rationale: hand-generating a keystore for an app with signature-verified
# integrations (Google Sign-In, Play Integrity, Apple notarization, etc.) will
# usually break those integrations because the new fingerprint isn't registered
# in the OAuth/signing-config. For mobile, prefer EAS managed credentials.

. "$(dirname "$0")/_lib.sh"
disabled_check

if [ "${ALLOW_KEYGEN:-}" = "1" ]; then
  exit 0
fi

payload=$(read_tool_input)
cmd=$(extract_bash_command "$payload")

case "$cmd" in
  *"keytool -genkey"*|*"keytool -genkeypair"*)
    log_block "keytool -genkey detected. Default policy: never hand-generate keystores for apps with signature-verified integrations (Google Sign-In, Play Integrity). Prefer managed credentials (e.g., 'eas build --profile preview'). Bypass: ALLOW_KEYGEN=1."
    exit 2
    ;;
  *"openssl req"*"-newkey"*"-keyout"*)
    log_block "openssl is generating a new keypair + writing private key. Confirm this is not an app-signing or service-account key. Bypass: ALLOW_KEYGEN=1."
    exit 2
    ;;
esac
exit 0
