{ pkgs }:

let
  kernel = pkgs.linuxPackages_latest.kernel;
  busybox = pkgs.busybox;

  modules = [
    "virtio_pci"
    "virtio_blk"
    "ext4"
  ];

  modulesClosure = pkgs.makeModulesClosure {
    kernel = pkgs.lib.getOutput "modules" kernel;
    rootModules = modules;
    firmware = pkgs.runCommand "no-firmware" { } "mkdir -p $out";
  };

  init = pkgs.writeScript "init" ''
    #!/bin/sh
    export PATH=/bin

    mkdir -p /proc /sys /dev /run /root
    mount -t proc proc /proc
    mount -t sysfs sysfs /sys
    mount -t devtmpfs devtmpfs /dev
    mount -t tmpfs tmpfs /run

    exec </dev/console >/dev/console 2>&1

    ${pkgs.kmod}/bin/modprobe virtio_pci
    ${pkgs.kmod}/bin/modprobe virtio_blk
    ${pkgs.kmod}/bin/modprobe ext4

    mount -t ext4 /dev/vda /root ||
      exec setsid cttyhack sh

    mkdir -p /root/dev /root/proc /root/sys /root/run

    mount --move /dev /root/dev
    mount --move /proc /root/proc
    mount --move /sys /root/sys
    mount --move /run /root/run

    exec switch_root /root ${pkgs.dinit}/bin/dinit
  '';

  initrd = pkgs.makeInitrd {
    contents = [
      {
        object = init;
        symlink = "/init";
      }
      {
        object = "${busybox}/bin";
        symlink = "/bin";
      }
      {
        object = "${modulesClosure}/lib";
        symlink = "/lib";
      }
    ];
  };
in
{
  inherit kernel initrd;
}
