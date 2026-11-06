# nixos-update-check

Two reminders for a flake-based NixOS:

1. **New release notification** – checks once a day whether a new NixOS release
   (e.g. 26.11) has actually been released (not just branched off: the
   `channels.nixos.org/nixos-YY.MM` channel must point to a non-beta build).
   If your flake tracks an older `nixos-YY.MM` branch you get a desktop
   notification, at most once per day. If you track `nixpkgs-unstable` you get
   a single notification per new release.
2. **Plasma system tray widget** – a Nix snowflake next to Wi-Fi/battery/etc.
   It gets an orange badge when the `nixpkgs` input in `flake.lock` is older
   than 7 days and a red badge when a new release is available. Click it for
   details. It also tells you when the lock changed but you haven't rebuilt yet.

## Usage

```nix
# flake.nix
inputs.nixos-update-check.url = "github:samularity/nixos-versioncheck";
inputs.nixos-update-check.inputs.nixpkgs.follows = "nixpkgs";

outputs = { self, nixpkgs, nixos-update-check, ... }:
# ...
modules = [
  nixos-update-check.nixosModules.default
  { services.nixos-update-check.enable = true; }
];
```

Options (`services.nixos-update-check.*`): `flakePath` (`/etc/nixos`),
`input` (`nixpkgs`), `maxAgeDays` (`7`), `plasmoid.enable` (`true`).

The lock age is the commit date of the locked nixpkgs revision, i.e. how old
the packages you build actually are.

CLI:

```
nixos-update-check status                 # JSON used by the widget
nixos-update-check release --force        # check for a new release now
nixos-update-check test-notify
systemctl --user list-timers nixos-update-check
```

If the widget doesn't show up after the rebuild: log out and in once, or
right-click the tray arrow → *Configure System Tray* → *Entries* →
"NixOS Update Status" → *Always shown*.
