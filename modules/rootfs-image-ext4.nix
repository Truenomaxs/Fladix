{ pkgs, rootfsTree }:

pkgs.runCommand "amongOS-rootfs.ext4"
  {
    nativeBuildInputs = [ pkgs.e2fsprogs ];
  }
  ''
    truncate -s 1G $out

    mkfs.ext4 -F \
      -L AMONGOS \
      -d ${rootfsTree} \
      $out
  ''
