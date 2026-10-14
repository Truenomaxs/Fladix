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

    # Keep early-boot diagnostics available in the emergency shell.
    exec >/dev/console 2>&1
    BOOT_LOG=/run/boot.log
    touch "$BOOT_LOG"

    log() {
      echo "[Fladix boot] $*"
      echo "[Fladix boot] $*" >> "$BOOT_LOG"
    }

    fail() {
      log "ERROR: $*"
      log "Entering emergency shell. Log: $BOOT_LOG"
      exec setsid cttyhack sh
    }

    log "Mounting proc"
    mount -t proc proc /proc || fail "Could not mount /proc"

    log "Mounting sysfs"
    mount -t sysfs sysfs /sys || fail "Could not mount /sys"

    log "Mounting devtmpfs"
    mount -t devtmpfs devtmpfs /dev || fail "Could not mount /dev"

    log "Mounting temporary /run"
    mount -t tmpfs tmpfs /run || fail "Could not mount /run"

    log "Loading virtio_pci"
    ${pkgs.kmod}/bin/modprobe virtio_pci || fail "Could not load virtio_pci"

    log "Loading virtio_blk"
    ${pkgs.kmod}/bin/modprobe virtio_blk || fail "Could not load virtio_blk"

    log "Loading ext4"
    ${pkgs.kmod}/bin/modprobe ext4 || fail "Could not load ext4"

    log "Mounting root filesystem"
    mount -t ext4 /dev/vda /root || fail "Could not mount /dev/vda as ext4"

    if [ -r /root/etc/hostname ]; then
      hostname "$(cat /root/etc/hostname)"
    fi

    mkdir -p /root/dev /root/proc /root/sys /root/run

    log "Moving system mounts"
    mount --move /dev /root/dev || fail "Could not move /dev"
    mount --move /proc /root/proc || fail "Could not move /proc"
    mount --move /sys /root/sys || fail "Could not move /sys"
    mount --move /run /root/run || fail "Could not move /run"

    log "Switching to Fladix root and starting Dinit"
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
