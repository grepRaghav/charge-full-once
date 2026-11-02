# Charge to 100% Once

A KDE Plasma 6 widget for laptops that use a battery charge limit (for example, charge to 80%, resume at 40%).
Press it once to charge to 100% for the current charge only. Your normal limits are restored
automatically when charging stops, so you never have to dig through Power Management settings.

> **Status:** early version. Tested on: _(add your laptop model, distro and Plasma version here)_.

## Features

- One click to lift the charge limit for a single charge
- Raises both the stop and the start threshold, so charging begins immediately even if the battery is between your limits
- Restores your original limits automatically when the battery is full or the charger is unplugged
- Survives reboots: the restore service runs at boot if a one-time charge was left active
- Desktop notifications on every toggle, including error messages if something fails
- Works as a desktop widget (button) or a panel icon (single click toggles)

## Requirements

- KDE Plasma 6
- Linux laptop whose battery exposes charge thresholds in sysfs. Check with:
  ```
  ls /sys/class/power_supply/BAT*/charge_control_*
  ```
  You need at least `charge_control_end_threshold`. If `charge_control_start_threshold` is also present, it is used too.
- systemd and sudo

## Install

```
git clone https://github.com/YOUR_USERNAME/charge-full-once.git
cd charge-full-once
bash install.sh
plasmashell --replace >/dev/null 2>&1 &
```

Then right-click the desktop or a panel, choose **Add Widgets**, and search for **Charge to 100% Once**.
If you installed an older version before, remove the old widget from the screen and add it again.

Run `install.sh` as your normal user, not with sudo. It asks for your sudo password once.

## Usage

1. Plug in the charger.
2. Click the widget (desktop: press the button).
3. Leave it. When the battery is full, or you unplug, your normal limits come back.

Clicking it again during a one-time charge cancels it and restores your limits immediately.
Pressing it with the charger unplugged shows an error and changes nothing.

## How it works

| Part | Location | Purpose |
|------|----------|---------|
| Helper script | `/usr/local/bin/charge-full-once` | Saves your current thresholds, sets end=100 and start=99, restores them later |
| systemd unit | `/etc/systemd/system/charge-full-once.service` | Runs the watcher in the background; also runs at boot if a charge was left active |
| sudoers rule | `/etc/sudoers.d/charge-full-once` | Lets your user run only `charge-full-once start` and `cancel` without a password |
| Widget | `~/.local/share/plasma/plasmoids/org.local.chargefullonce` | The button, status and notifications |

Saved limits are kept in `/var/lib/charge-full-once/state` while a one-time charge is active.
The watcher restores them after the battery reports Full (or 97%+ and "Not charging", or "Discharging") for about 15 seconds.

## Verifying it works

Plasma's Power Management settings page shows Plasma's own stored values, not the live hardware values,
so it will **not** change when you press the widget. To see the real values:

```
grep . /sys/class/power_supply/BAT*/charge_control_*
```

The widget tooltip and the desktop widget also show the live start/stop limits.

## Troubleshooting

- **Blank widget:** run `plasmawindowed org.local.chargefullonce` in a terminal to see QML errors.
- **"Charge toggle failed":** the notification includes the reason. Check that `/etc/sudoers.d/charge-full-once` exists and that `sudo -n /usr/local/bin/charge-full-once status` works.
- **"Could not write charge_control_end_threshold":** your firmware or driver may not allow writes. Confirm you can set the value manually with `echo 100 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold`.
- **Limits not restored:** run `sudo charge-full-once cancel`, then check `systemctl status charge-full-once`.

## Caveats

- Changing the charge limit in Plasma's settings while a one-time charge is active may be overwritten when the saved values are restored.
- Charge limits are approximate on many laptops; the battery may stop a couple of percent away from the set value.
- The passwordless sudo rule is limited to two exact commands, but you should still read `system/charge-full-once` before installing anything that runs as root.

## Uninstall

```
bash uninstall.sh
```

This restores your limits if a one-time charge is active, then removes all installed files.

## License

MIT, see [LICENSE](LICENSE).
