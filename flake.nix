{
  description = "NixOS update reminder: release notifications + Plasma tray widget for flake.lock age";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
    in
    {
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        rec {
          nixos-update-check = pkgs.callPackage ./nix/package.nix { };
          plasmoid = pkgs.callPackage ./nix/plasmoid.nix { inherit nixos-update-check; };
          default = nixos-update-check;
        });

      nixosModules.default = ./nix/module.nix;

      checks = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          # minimal system using the module; only the parts we touch get built
          eval = nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              self.nixosModules.default
              {
                services.nixos-update-check.enable = true;
                boot.loader.grub.enable = false;
                fileSystems."/" = { device = "none"; fsType = "tmpfs"; };
                system.stateVersion = "26.05";
              }
            ];
          };
          units = eval.config.systemd.user.units;
        in
        {
          inherit (self.packages.${system}) nixos-update-check plasmoid;

          shellcheck = pkgs.runCommand "shellcheck" { nativeBuildInputs = [ pkgs.shellcheck ]; } ''
            shellcheck ${./bin/nixos-update-check}
            touch $out
          '';

          module = pkgs.runCommand "module-eval" { } ''
            svc=${units."nixos-update-check.service".unit}/nixos-update-check.service
            timer=${units."nixos-update-check.timer".unit}/nixos-update-check.timer
            grep -q 'ExecStart=.*/bin/nixos-update-check release --notify' $svc
            grep -q 'OnCalendar=hourly' $timer
            ${pkgs.lib.optionalString
              (!builtins.any (p: pkgs.lib.hasPrefix "plasma-applet-nixos-update" (p.name or ""))
                eval.config.environment.systemPackages)
              "echo 'plasmoid missing from systemPackages'; exit 1"}
            touch $out
          '';
        });
    };
}
