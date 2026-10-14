{ pkgs, rootfsTree }:

pkgs.runCommand "fladix-rootfs.ext4"
  {
    nativeBuildInputs = [ pkgs.e2fsprogs ];
  }
  ''
    set -eu

    truncate -s 1G "$out"

    mkfs.ext4 -F \
      -L FLADIX \
      -d ${rootfsTree} \
      "$out"

    # Set numeric ownership and permissions inside the ext4 image.
    debugfs -w -R 'set_inode_field /root uid 0' "$out"
    debugfs -w -R 'set_inode_field /root gid 0' "$out"
    debugfs -w -R 'set_inode_field /root mode 040700' "$out"

    debugfs -w -R 'set_inode_field /home uid 0' "$out"
    debugfs -w -R 'set_inode_field /home gid 0' "$out"
    debugfs -w -R 'set_inode_field /home mode 040755' "$out"

    debugfs -w -R 'set_inode_field /home/fladix uid 1000' "$out"
    debugfs -w -R 'set_inode_field /home/fladix gid 1000' "$out"
    debugfs -w -R 'set_inode_field /home/fladix mode 040755' "$out"

    debugfs -w -R 'set_inode_field /var uid 0' "$out"
    debugfs -w -R 'set_inode_field /var gid 0' "$out"
    debugfs -w -R 'set_inode_field /var mode 040755' "$out"

    debugfs -w -R 'set_inode_field /var/log uid 0' "$out"
    debugfs -w -R 'set_inode_field /var/log gid 0' "$out"
    debugfs -w -R 'set_inode_field /var/log mode 040755' "$out"

    # Validate the completed filesystem without modifying it.
    e2fsck -fn "$out"
  ''
