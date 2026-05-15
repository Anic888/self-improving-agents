# Contributing

Thanks for considering a contribution.

## Dev loop

1. Fork + clone.
2. Run `sh install.sh` once on your own machine to set up the system.
3. Make changes in the repo. **Re-run `sh install.sh`** to copy the new versions over (it's idempotent).
4. Run the hook test suite: `sh hooks/test.sh` — must report `13 passed, 0 failed`.
5. Open a PR.

## What's likely to get merged

- **New hooks** following the existing pattern: shell script + tests in `test.sh` + entry in the install.sh `python3` upsert + row in the hooks table in `README.md`.
- **New ecosystems for the CVE scanner**: extend `agents/cve-scanner.md` with the manifest-parsing rules.
- **Bug fixes** with a regression test.

## What probably won't get merged (without discussion)

- Hooks that block things some users legitimately want to do without an obvious bypass.
- Anything that requires non-POSIX shell features (we target macOS default `/bin/sh`).
- Anything that adds runtime dependencies beyond `jq`, `python3`, `gh`.

## Open an issue first if

- You want to change the catalog schema (`templates/meta-failures.md`) — downstream tooling assumes it.
- You want to add a non-shell runtime (Node, Go, etc.) to the install path.
- You're adding telemetry of any kind.

## Style

- Shell: POSIX `sh`, no bashisms. Tested against macOS `/bin/sh`.
- Markdown: one sentence per line in long-form docs is fine but not required.
- No emojis in code or comments. Emojis in `README.md` are OK in section headers, sparingly.
- Commit messages: short imperative subject ("add no-rm-rf hook"), one body paragraph max.

## Reporting a hook miss

If a hook should have blocked something but didn't, open an issue with:

1. The exact command Claude Code tried to run.
2. The hook that should have caught it.
3. The expected error message.

Reproductions in the form of a `test.sh` test case are gold.
