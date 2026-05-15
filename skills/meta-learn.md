---
name: self-improving-meta-learn
description: Refresh the failure pattern catalog. Use when the user says "update failure catalog", "re-analyze my mistakes", or "/self-improving-meta-learn". Dispatches the failure-extractor subagent and shows a diff summary at the end.
---

# Self-Improving — Meta Learn

Manual entry point to refresh `~/.claude/self-improving/data/meta-failures.md`.

## Steps

1. Take a hash of the current catalog:
   ```sh
   shasum ~/.claude/self-improving/data/meta-failures.md > /tmp/meta-failures.before.sha
   ```

2. Dispatch the `self-improving-failure-extractor` subagent with this prompt:

   > Refresh the meta-failures catalog at `~/.claude/self-improving/data/meta-failures.md`. Read all `*.md` files in `~/.claude/self-improving/sources/`. Dedup against the current catalog. Report N added / M updated / K rejected at the end. Cite source filename + verbatim excerpt for every pattern.

3. After the subagent returns, take a fresh hash and compare:
   ```sh
   shasum ~/.claude/self-improving/data/meta-failures.md > /tmp/meta-failures.after.sha
   diff /tmp/meta-failures.before.sha /tmp/meta-failures.after.sha
   ```

4. Show the user:
   - Number of new patterns
   - Number of updated patterns
   - The diff (show the appended/changed section)

5. If 0 new + 0 updated: say so plainly. Do not invent activity.
