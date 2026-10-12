{ pkgs, rootfsTree }:

pkgs.runCommand "fladix-rootfs.ext4"
  {
    nativeBuildInputs = [ pkgs.e2fsprogs ];
  }
  ''
    truncate -s 1G "$out"

    mkfs.ext4 -F \
      -L FLADIX \
      -d ${rootfsTree} \
      "$out"

    # Validate the completed filesystem without modifying it.
    e2fsck -fn "$out"
  ''
