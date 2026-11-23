#!/usr/bin/env bash
# herdr-sessions installer:
#   curl -fsSL https://raw.githubusercontent.com/eng1n88r/herdr-sessions/master/install.sh | bash
#
# Downloads the latest GitHub release (falls back to the master branch if there is
# none), links the script into ~/.local/bin and schedules a snapshot every 10
# minutes. Idempotent. Run from a checkout it installs that checkout instead.
set -euo pipefail

REPO=eng1n88r/herdr-sessions
PREFIX=${PREFIX:-$HOME/.local}
BINDIR=$PREFIX/bin
SHARE=$PREFIX/share/herdr-sessions

src=${BASH_SOURCE[0]:-}
if [ -n "$src" ] && [ -f "$(dirname "$src")/herdr-sessions" ]; then
    repo=$(cd "$(dirname "$src")" && pwd)
else
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    url="https://github.com/$REPO/releases/latest/download/herdr-sessions.tar.gz"
    echo "downloading $url"
    if ! curl -fsSL "$url" -o "$tmp/pkg.tar.gz"; then
        echo "no release found; falling back to the master branch"
        curl -fsSL "https://github.com/$REPO/archive/refs/heads/master.tar.gz" -o "$tmp/pkg.tar.gz"
    fi
    mkdir "$tmp/pkg"
    tar -xzf "$tmp/pkg.tar.gz" -C "$tmp/pkg" --strip-components 1
    [ -f "$tmp/pkg/herdr-sessions" ] || { echo "error: unexpected archive layout" >&2; exit 1; }
    mkdir -p "$PREFIX/share"
    rm -rf "$SHARE"
    mv "$tmp/pkg" "$SHARE"
    repo=$SHARE
fi

chmod +x "$repo/herdr-sessions"
mkdir -p "$BINDIR" "$HOME/.config/herdr"
ln -sf "$repo/herdr-sessions" "$BINDIR/herdr-sessions"

case "$(uname -s)" in
Darwin)
    label=dev.herdr.claude-sessions
    plist="$HOME/Library/LaunchAgents/$label.plist"
    mkdir -p "$HOME/Library/LaunchAgents"
    sed -e "s|__HOME__|$HOME|g" -e "s|__BIN__|$BINDIR/herdr-sessions|g" "$repo/launchd/$label.plist" > "$plist"
    launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$plist"
    echo "scheduled: LaunchAgent $label"
    ;;
Linux)
    units="$HOME/.config/systemd/user"
    mkdir -p "$units"
    sed "s|__BIN__|$BINDIR/herdr-sessions|g" "$repo/systemd/herdr-sessions.service" > "$units/herdr-sessions.service"
    cp "$repo/systemd/herdr-sessions.timer" "$units/"
    systemctl --user daemon-reload
    systemctl --user enable --now herdr-sessions.timer
    echo "scheduled: systemd user timer herdr-sessions.timer"
    ;;
*)
    echo "no scheduler set up for $(uname -s); run 'herdr-sessions snapshot' yourself" >&2
    ;;
esac

echo "$("$repo/herdr-sessions" --version) installed to $BINDIR/herdr-sessions"
