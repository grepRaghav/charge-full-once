#!/bin/bash
# Installs the helper, systemd unit, sudoers rule and Plasma widget.
# Run as your normal user (NOT with sudo). Asks for sudo once. Safe to re-run.
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
  echo "Run this as your normal user, not root." >&2
  exit 1
fi

HERE=$(cd "$(dirname "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Check hardware support first
if ! ls /sys/class/power_supply/BAT*/charge_control_end_threshold >/dev/null 2>&1; then
  echo "Warning: no /sys/class/power_supply/BAT*/charge_control_end_threshold found."
  echo "Your laptop may not support charge thresholds; the widget will not work."
  read -r -p "Continue anyway? [y/N] " ans
  [ "$ans" = "y" ] || [ "$ans" = "Y" ] || exit 1
fi

# sudoers rule allows ONLY the two helper commands, without a password
echo "$USER ALL=(root) NOPASSWD: /usr/local/bin/charge-full-once start, /usr/local/bin/charge-full-once cancel" > "$TMP/sudoers"

echo "Installing system parts (needs sudo)..."
sudo visudo -cf "$TMP/sudoers" >/dev/null
sudo install -o root -g root -m 755 "$HERE/system/charge-full-once" /usr/local/bin/charge-full-once
sudo install -o root -g root -m 644 "$HERE/system/charge-full-once.service" /etc/systemd/system/charge-full-once.service
sudo install -o root -g root -m 440 "$TMP/sudoers" /etc/sudoers.d/charge-full-once
sudo systemctl daemon-reload
sudo systemctl enable charge-full-once.service >/dev/null 2>&1

DEST="$HOME/.local/share/plasma/plasmoids/org.local.chargefullonce"
rm -rf "$DEST"
mkdir -p "$(dirname "$DEST")"
cp -r "$HERE/plasmoid" "$DEST"
kbuildsycoca6 >/dev/null 2>&1 || true

echo
echo "Done. Reload Plasma:  plasmashell --replace >/dev/null 2>&1 &"
echo "Then: right-click desktop/panel > Add Widgets > 'Charge to 100% Once'."
echo "(If you had an older version of the widget on screen, remove it and add it again.)"
