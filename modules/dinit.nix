{ pkgs }:

let
  bootService = pkgs.writeText "fladix-dinit-boot" ''
    type = internal
    waits-for: shell
    waits-for.d: boot.d
  '';

  shellService = pkgs.writeText "fladix-dinit-shell" ''
    type = process
    command = ${pkgs.util-linux}/bin/agetty --noclear --noissue -n -l /bin/bash ttyS0 115200 vt100
    term-signal = HUP
  '';

  syslogService = pkgs.writeText "fladix-dinit-syslog" ''
    type = process
    command = ${pkgs.busybox}/bin/busybox syslogd -n -C
  '';

  klogService = pkgs.writeText "fladix-dinit-klog" ''
    type = process
    command = ${pkgs.busybox}/bin/busybox klogd -n
    depends-on = syslog
  '';

in

pkgs.runCommand "fladix-dinit-config" { } ''
    set -eu

    mkdir -p "$out/etc/dinit.d"
    cp ${bootService} "$out/etc/dinit.d/boot"
    cp ${shellService} "$out/etc/dinit.d/shell"
    cp ${syslogService} "$out/etc/dinit.d/syslog"
    cp ${klogService} "$out/etc/dinit.d/klog"
   
    mkdir -p "$out/etc/dinit.d/boot.d"
  ln -s ../syslog "$out/etc/dinit.d/boot.d/syslog"
  ln -s ../klog "$out/etc/dinit.d/boot.d/klog"
    
    test -x ${pkgs.util-linux}/bin/agetty

    ${pkgs.dinit}/bin/dinit-check \
      --services-dir "$out/etc/dinit.d" boot
''
