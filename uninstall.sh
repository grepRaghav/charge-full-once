#!/bin/bash
# Restores your normal limits (if a one-time charge is active) and removes everything.
set -u
if [ "$(id -u)" -eq 0 ]; then
  echo "Run this as your normal user, not root." >&2
  exit 1
fi

sudo -n /usr/local/bin/charge-full-once cancel 2>/dev/null || sudo /usr/local/bin/charge-full-once cancel 2>/dev/null
sudo systemctl disable --now charge-full-once.service 2>/dev/null
sudo rm -f /usr/local/bin/charge-full-once \
           /etc/systemd/system/charge-full-once.service \
           /etc/sudoers.d/charge-full-once
sudo rm -rf /var/lib/charge-full-once
sudo systemctl daemon-reload
rm -rf "$HOME/.local/share/plasma/plasmoids/org.local.chargefullonce"
echo "Removed. Remove the widget from your desktop/panel if it is still showing, or run: plasmashell --replace &"
