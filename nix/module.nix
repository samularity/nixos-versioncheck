{ config, lib, pkgs, ... }:

let
  cfg = config.services.nixos-update-check;

  checker = pkgs.callPackage ./package.nix {
    inherit (cfg) flakePath input maxAgeDays;
  };

  plasmoid = pkgs.callPackage ./plasmoid.nix {
    nixos-update-check = checker;
  };
in
{
  options.services.nixos-update-check = {
    enable = lib.mkEnableOption "notifications about new NixOS releases and stale flake.lock files";

    flakePath = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nixos";
      description = "Directory containing the system flake.nix / flake.lock.";
    };

    input = lib.mkOption {
      type = lib.types.str;
      default = "nixpkgs";
      description = "Name of the root flake input whose age and branch is checked.";
    };

    maxAgeDays = lib.mkOption {
      type = lib.types.ints.positive;
      default = 7;
      description = "The lock is reported as stale once the input is this many days old.";
    };

    plasmoid.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install the Plasma system tray applet.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ checker ] ++ lib.optional cfg.plasmoid.enable plasmoid;

    # Runs hourly and on login; the script itself only hits the network every 12h
    # and notifies at most once per day.
    systemd.user.services.nixos-update-check = {
      description = "Check for a new NixOS release";
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe checker} release --notify";
        # usually: no network yet after boot/resume
        Restart = "on-failure";
        RestartSec = "10min";
      };
    };

    systemd.user.timers.nixos-update-check = {
      description = "Check for a new NixOS release";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnStartupSec = "3min";
        OnCalendar = "hourly";
        Persistent = true;
        RandomizedDelaySec = "5min";
      };
    };
  };
}
