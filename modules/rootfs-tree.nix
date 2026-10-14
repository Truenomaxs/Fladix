{ pkgs, dinitConfig }:

let
  rootfs = pkgs.buildEnv {
    name = "fladix";

    paths = with pkgs; [
      # Shell and everyday commands
      bash
      coreutils
      findutils
      gnugrep
      gnused
      gawk
      diffutils
      which

      # System and process management
      util-linux
      procps
      dinit
      busybox
      linux-pam
      # Inspection and troubleshooting
      htop
      btop
      lsof
      less
      file
      tree
      ncdu
      fastfetch
      strace

      # Archives and compression
      gzip
      xz
      zstd

      # Filesystem administration
      e2fsprogs
    ];

  };

  osRelease = pkgs.writeText "fladix-os-release" ''
    NAME="Fladix"
    PRETTY_NAME="Fladix Linux"
    ID=fladix
    VERSION="0.1"
    VERSION_ID="0.1"
  '';

  hostname = pkgs.writeText "Fladix-hostname" "Fladix\n";

  passwd = pkgs.writeText "fladix-passwd" ''
    root:x:0:0:root:/root:/bin/bash
    fladix:x:1000:1000:Fladix User:/home/fladix:/bin/bash
  '';

  group = pkgs.writeText "fladix-group" ''
    root:x:0:
    fladix:x:1000:
  '';

  shadow = pkgs.writeText "fladix-shadow" ''
    root:!:1::::::
    fladix:!:1::::::
  '';

  gshadow = pkgs.writeText "fladix-gshadow" ''
    root:!::
    fladix:!::
  '';

  closure = pkgs.closureInfo {
    rootPaths = [ rootfs ];
  };

in

pkgs.runCommand "fladix-rootfs-tree" { } ''
  set -eu

  # Create the basic filesystem layout.
  mkdir -p "$out/nix/store"
  mkdir -p "$out"/{dev,proc,sys,run,tmp,etc,root,home/fladix,var/log}

  # Copy the selected runtime utilities into the root filesystem.
  cp -a ${rootfs}/. "$out/"

  # Make /etc writable before installing Dinit configuration.
  chmod u+w "$out/etc"

  cp -a ${dinitConfig}/etc/. "$out/etc/"

  # Ensure /etc is writable after preserving source permissions.
  chmod u+w "$out/etc"

  # Remove existing destination entries, including possible symlinks.
  rm -f \
    "$out/etc/os-release" \
    "$out/etc/hostname" \
    "$out/etc/passwd" \
    "$out/etc/group" \
    "$out/etc/shadow" \
    "$out/etc/gshadow"

  # Install Fladix-specific configuration.
  cp ${osRelease} "$out/etc/os-release"
  cp ${hostname} "$out/etc/hostname"
  cp ${passwd} "$out/etc/passwd"
  cp ${group} "$out/etc/group"
  cp ${shadow} "$out/etc/shadow"
  cp ${gshadow} "$out/etc/gshadow"

  # Set account database permissions.
  chmod 0644 "$out/etc/passwd" "$out/etc/group"
  chmod 0600 "$out/etc/shadow" "$out/etc/gshadow"

  # Set directory permissions.
  chmod 0700 "$out/root"
  chmod 0755 "$out/home" "$out/home/fladix" "$out/var" "$out/var/log"
  chmod 1777 "$out/tmp"

  # Include the complete Nix store closure of the runtime environment.
  while IFS= read -r path; do
    cp -a "$path" "$out/nix/store/"
  done < ${closure}/store-paths
''
