PREFIX ?= $(HOME)/.local
BINDIR := $(PREFIX)/bin
VERSION := $(shell python3 herdr-sessions --version | awk '{print $$2}')
DIST := herdr-sessions-$(VERSION)

.PHONY: install uninstall check dist clean

# Idempotent: links this checkout into $(BINDIR) and schedules the snapshot.
install:
	PREFIX=$(PREFIX) ./install.sh

uninstall:
	rm -f $(BINDIR)/herdr-sessions
	rm -rf $(PREFIX)/share/herdr-sessions
	@if [ "$$(uname -s)" = Darwin ]; then \
		launchctl bootout gui/$$(id -u)/dev.herdr.claude-sessions 2>/dev/null || true; \
		rm -f $(HOME)/Library/LaunchAgents/dev.herdr.claude-sessions.plist; \
	else \
		systemctl --user disable --now herdr-sessions.timer 2>/dev/null || true; \
		rm -f $(HOME)/.config/systemd/user/herdr-sessions.service $(HOME)/.config/systemd/user/herdr-sessions.timer; \
	fi

check:
	python3 -c 'import ast, sys; ast.parse(open("herdr-sessions").read(), "herdr-sessions")'
	python3 herdr-sessions --version
	bash -n install.sh
	@if command -v shellcheck >/dev/null 2>&1; then shellcheck install.sh; else echo "shellcheck not found, skipped"; fi

# The archive the release workflow uploads and install.sh downloads.
dist:
	rm -rf $(DIST) && mkdir $(DIST)
	cp -R herdr-sessions install.sh launchd systemd README.md LICENSE $(DIST)/
	tar -czf herdr-sessions.tar.gz $(DIST)
	rm -rf $(DIST)

clean:
	rm -rf herdr-sessions.tar.gz herdr-sessions-*/ __pycache__
