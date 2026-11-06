{
  lib,
  stdenvNoCC,
  nixos-update-check,
}:

stdenvNoCC.mkDerivation {
  pname = "plasma-applet-nixos-update";
  version = "1.0";
  src = ../plasmoid;

  installPhase = ''
    dir=$out/share/plasma/plasmoids/org.samularity.nixosupdate
    mkdir -p $dir
    cp -r . $dir
    substituteInPlace $dir/contents/ui/main.qml \
      --replace-fail @checker@ ${lib.getExe nixos-update-check}
  '';

  meta = {
    description = "Plasma system tray applet showing NixOS update status";
    platforms = lib.platforms.linux;
  };
}
