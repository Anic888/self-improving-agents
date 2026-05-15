# Meta-Failures Catalog

Living document. Updated by the `self-improving-failure-extractor` subagent.
Each pattern is a YAML block between `---pattern---` and `---/pattern---` fences.

## Schema

```yaml
id: SCREAMING_SNAKE       # stable identifier, used by hooks
title: short human-readable name
category: process | code | env | security | i18n | naming | testing
severity: low | medium | high | critical
trigger: |
  Concrete behavior that constitutes the failure.
  One paragraph. Imperative, observable.
why: |
  Why this is a failure. Cite source file + date if applicable.
evidence:
  - source: <filename>
    excerpt: "..."   # short verbatim quote
defense_type: hook | memory | scheduled-check | none-yet
defense_status: planned | implemented | n/a
defense_ref: |
  If hook: path to hook script.
  If memory: path to memory file.
  If scheduled-check: name of cron entry.
```

## Patterns

<!-- Subagent appends entries below this line. -->
