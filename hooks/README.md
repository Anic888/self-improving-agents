# Hooks

PreToolUse shell hooks that block known bad patterns at the tool layer.

| Script | What it blocks | Bypass env var |
|--------|----------------|----------------|
| `no-coauthor-without-flag.sh` | `git commit` with `Co-Authored-By:` line | `ALLOW_COAUTHOR=1` |
| `no-no-verify.sh` | `--no-verify`, `--no-gpg-sign`, `commit.gpgsign=false` | `ALLOW_NO_VERIFY=1` |
| `no-self-signed-keystore.sh` | `keytool -genkey`, `openssl req -newkey` | `ALLOW_KEYGEN=1` |
| `no-fake-env-vars.sh` | `.env*` file writes declaring vars not referenced anywhere in the project | `ALLOW_FAKE_ENV=1` |

Global kill switch: `SELF_IMPROVING_AGENTS_DISABLED=1` — all hooks pass-through silently.

## Run the test suite

```sh
sh hooks/test.sh
```

Expected: `Results: 13 passed, 0 failed`.

## Add your own hook

1. Add tests to `test.sh` (positive + negative + bypass). Use `printf '%s'` (not `echo`) when piping JSON containing `\n` escapes — zsh's `echo` interprets them and breaks the JSON parser.
2. Write `<hook-name>.sh` sourcing `_lib.sh`. Read tool-call JSON from stdin; exit `2` to block (with stderr message), exit `0` to allow.
3. `chmod +x <hook-name>.sh`.
4. Add an entry to `~/.claude/settings.json` under `hooks.PreToolUse[]` with the right matcher (`Bash`, `Write`, `Edit`, etc.) — the `install.sh` shows the upsert pattern.

## Platform notes

`no-fake-env-vars.sh` uses GNU `timeout` (or `gtimeout` from `brew install coreutils`) to cap grep at 1.5s on large repos. Without either, grep runs unbounded — usually fine for a single project but can be slow on huge monorepos.
