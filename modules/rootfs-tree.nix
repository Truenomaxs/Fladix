{ pkgs, dinitConfig }:

let

  rootfs = pkgs.buildEnv {

    name = "fladix";
    paths = with pkgs; [
      bash
      coreutils
      util-linux
      dinit

      # System inspection
      procps
      htop
      lsof

      # Files and text
      less
      file
      tree
      ncdu

      fastfetch

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
  closure = pkgs.closureInfo {
    rootPaths = [ rootfs ];
  };

in
pkgs.runCommand "fladix-rootfs-tree" { } ''
    mkdir -p $out/nix/store
    mkdir -p $out/{dev,proc,sys,run,tmp,etc,root}

    cp -a ${rootfs}/. $out/
  cp -a ${dinitConfig}/etc/. $out/etc/

          chmod u+w $out/etc
    cp ${osRelease} $out/etc/os-release
    cp ${hostname} $out/etc/hostname

    while IFS= read -r path; do
      cp -a "$path" "$out/nix/store/"
    done < ${closure}/store-paths

    chmod 1777 $out/tmp
''
