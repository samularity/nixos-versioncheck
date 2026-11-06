{
  lib,
  stdenvNoCC,
  makeWrapper,
  bash,
  coreutils,
  curl,
  git,
  gnused,
  jq,
  libnotify,
  flakePath ? "/etc/nixos",
  input ? "nixpkgs",
  maxAgeDays ? 7,
}:

stdenvNoCC.mkDerivation {
  pname = "nixos-update-check";
  version = "1.0";
  src = ../bin;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ bash ];

  installPhase = ''
    install -Dm755 nixos-update-check $out/bin/nixos-update-check
    patchShebangs $out/bin
    wrapProgram $out/bin/nixos-update-check \
      --prefix PATH : ${lib.makeBinPath [ coreutils curl git gnused jq libnotify ]} \
      --set-default NIXOS_UPDATE_FLAKE ${lib.escapeShellArg flakePath} \
      --set-default NIXOS_UPDATE_INPUT ${lib.escapeShellArg input} \
      --set-default NIXOS_UPDATE_MAX_AGE_DAYS ${toString maxAgeDays}
  '';

  meta = {
    description = "Notify about new NixOS releases and stale flake.lock files";
    mainProgram = "nixos-update-check";
    platforms = lib.platforms.linux;
  };
}
