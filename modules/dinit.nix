{ pkgs }:

let
  bootService = pkgs.writeText "fladix-dinit-boot" ''
    type = internal
    waits-for: shell
  '';

  shellService = pkgs.writeText "fladix-dinit-shell" ''
    type = process
    command = ${pkgs.util-linux}/bin/agetty --noclear --noissue -n -l /bin/bash ttyS0 115200 vt100
    term-signal = HUP
  '';
in
pkgs.runCommand "fladix-dinit-config" { } ''
  set -eu

  mkdir -p "$out/etc/dinit.d"
  cp ${bootService} "$out/etc/dinit.d/boot"
  cp ${shellService} "$out/etc/dinit.d/shell"

  test -x ${pkgs.util-linux}/bin/agetty

  ${pkgs.dinit}/bin/dinit-check \
    --services-dir "$out/etc/dinit.d" boot
''
