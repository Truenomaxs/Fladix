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

  closure = pkgs.closureInfo {
    rootPaths = [ rootfs ];
  };

in
pkgs.runCommand "fladix-rootfs-tree" { } ''
    mkdir -p $out/nix/store
    mkdir -p $out/{dev,proc,sys,run,tmp,etc,root}

    cp -a ${rootfs}/. $out/
  cp -a ${dinitConfig}/etc/. $out/etc/
    while IFS= read -r path; do
      cp -a "$path" "$out/nix/store/"
    done < ${closure}/store-paths

    chmod 1777 $out/tmp
''
