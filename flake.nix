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
    };
}
