# herdr-sessions

Save and restore the Claude Code sessions running in Herdr workspaces, so a reboot or a Herdr update does not lose the layout.

`snapshot` records every workspace, tab and pane together with the Claude Code session running in it. `restore` recreates whatever is missing and resumes each session with `claude --resume`.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/eng1n88r/herdr-sessions/master/install.sh | bash
```

Or from a checkout:

```sh
make install
```

Either way the install is idempotent and does three things:

1. Puts the latest release in `~/.local/share/herdr-sessions` (a checkout is used in place).
2. Symlinks the script to `~/.local/bin/herdr-sessions` (override with `PREFIX=`).
3. Schedules `herdr-sessions snapshot --quiet` every 10 minutes: a LaunchAgent on macOS, a systemd user timer on Linux.

Needs `python3`, `curl`, Herdr at `~/.local/bin/herdr`, and `claude` on the PATH of the Herdr panes.

`make uninstall` removes the script and the schedule; `make check` runs the lint checks.

## Update

```sh
herdr-sessions update
```

Compares the running version against the latest GitHub release and, if newer, re-runs the installer for it (`herdr-sessions --version` to check). Re-running the install one-liner works too.

## Use

```sh
herdr-sessions snapshot            # save the live layout now
herdr-sessions show                # print the saved manifest
herdr-sessions restore --dry-run   # preview what restore would do
herdr-sessions restore             # recreate workspaces/tabs/panes and resume every session
```

After a reboot: open Herdr, then run `herdr-sessions restore`. Panes that already run Claude are skipped, so it is safe to rerun.

## Files

| Path | What |
| --- | --- |
| `~/.config/herdr/claude-sessions.json` | saved manifest (per machine) |
| `~/.config/herdr/claude-sessions.log` | stderr of the scheduled snapshot on macOS |
| `~/.claude/sessions/<pid>.json` | Claude Code's registry of live sessions, read to map panes to session ids |

On Linux, check the timer with `systemctl --user status herdr-sessions.timer` and its output with `journalctl --user -u herdr-sessions`.

## Release

Bump `VERSION` in `herdr-sessions`, commit, then tag and push:

```sh
git tag v0.1.1 && git push origin master v0.1.1
```

The `release` workflow checks that the tag matches `VERSION`, builds `herdr-sessions.tar.gz` with its sha256, and publishes the GitHub release that the installer and `herdr-sessions update` download.

## License

MIT
