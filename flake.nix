{
  description = "A best script!";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        my-name = "nixos-versioncheck";
        my-buildInputs = with pkgs; [ libnotify ];
        my-script = (pkgs.writeScriptBin my-name (builtins.readFile ./notify.sh)).overrideAttrs(old: {
          buildCommand = "${old.buildCommand}\n patchShebangs $out";
        });
      in rec {
        defaultPackage = packages.my-script;
        packages.my-script = pkgs.symlinkJoin {
          name = my-name;
          version = "0.01";
          paths = [ my-script ] ++ my-buildInputs;
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = "wrapProgram $out/bin/${my-name} --prefix PATH : $out/bin";
        };

        nixosModules.default =
      # For illustration, probably want to break this definition out to a separate file
      { config, pkgs, lib, ... }: {
        options = {
          services.${my-name}.enable = lib.mkEnableOption "${my-name}";
        };

        config = lib.mkIf config.services.${my-name}.enable {
          systemd.services.myApp = {
            description = "check for NixOs version updates";
            startAt = ["hourly"] ;
            serviceConfig.ExecStart = "${self.packages.${pkgs.system}.default}/bin/${my-name}";
          };
        };
      };

      }
    );
}

