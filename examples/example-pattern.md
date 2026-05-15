# Example: How a Pattern Entry Looks

This is what one well-formed entry in `meta-failures.md` looks like.
Use this as a reference when adding patterns manually.

```yaml
---pattern---
id: SHORTCUTS_OVER_CANONICAL
title: Self-signed credentials instead of canonical credential pipeline
category: security
severity: high
trigger: |
  When a build step needs a signing key, generating a fresh keystore /
  service-account / certificate locally instead of using the project's
  canonical credential pipeline (EAS managed credentials, GitHub OIDC,
  cloud secret manager, etc.). This produces credentials with the wrong
  fingerprint, breaking signature-verified integrations downstream.
why: |
  Signature-verified integrations (Google Sign-In, Play Integrity, Apple
  notarization, etc.) tie auth to a specific signing key. A self-signed
  keystore has a different SHA fingerprint than the one registered in the
  OAuth client / Play Console, so the integration silently fails after
  build. The "fix" feels like progress but ships broken auth.
evidence:
  - source: notes-build-pipeline.md
    excerpt: "Generated a fresh debug keystore to unblock the local build; deployed and Google Sign-In stopped working."
defense_type: hook
defense_status: implemented
defense_ref: |
  hooks/no-self-signed-keystore.sh
---/pattern---
```

## Field guide

| Field | What goes in it |
|-------|-----------------|
| `id` | SCREAMING_SNAKE_CASE. Stable across versions. Used as primary key by hooks. |
| `title` | One short line. No period. |
| `category` | One of: `process`, `code`, `env`, `security`, `i18n`, `naming`, `testing`. |
| `severity` | `critical` (data loss / broken auth / irreversible), `high` (explicitly flagged), `medium` (observed in 2+ projects), `low` (single occurrence). |
| `trigger` | Concrete behavior. Observable. Not "be careful with X" — say *what* happens. |
| `why` | The reason this fails. Cite incident date if you have one. |
| `evidence` | At least one `source` + verbatim `excerpt`. No citation = no pattern. |
| `defense_type` | How it's defended: `hook`, `memory` (a documented policy you read at session start), `scheduled-check`, or `none-yet`. |
| `defense_status` | `planned` (no defense yet), `implemented` (defense exists), `n/a`. |
| `defense_ref` | Path to the hook script, memory file, or cron entry. |
