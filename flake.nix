{
  description = "my little os prototype";

  inputs = {

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  };

  outputs =
    { nixpkgs, ... }:

    let

      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      vmConfig = import ./hosts/vm.nix;
      boot = import ./modules/boot.nix { inherit pkgs; };
      iso = import ./modules/bootloader.nix {
        inherit pkgs;
        inherit (boot) kernel initrd;
      };
      dinitConfig = import ./modules/dinit.nix {
        inherit pkgs;
      };

      rootfsTree = import ./modules/rootfs-tree.nix {
        inherit pkgs dinitConfig;
      };

      rootfsExt4 = import ./modules/rootfs-image-ext4.nix {
        inherit pkgs;
        inherit rootfsTree;
      };

      vmArgs = [
        "-m"
        (toString vmConfig.memoryMiB)
        "-smp"
        "cpus=${
          toString (vmConfig.cores * vmConfig.threads)
        },sockets=1,cores=${toString vmConfig.cores},threads=${toString vmConfig.threads}"
        "-display"
        "none"
        "-serial"
        "stdio"
        "-monitor"
        "none"
        "-cdrom"
        "${iso}"
        "-boot"
        "d"
        "-drive"
        "file=${rootfsExt4},format=raw,if=virtio,snapshot=on"
      ];
      vm = pkgs.writeShellScriptBin "vm" ''
        exec ${pkgs.qemu}/bin/qemu-system-x86_64 \
        ${builtins.concatStringsSep " " vmArgs} "$@"
      '';

    in
    {

      devShells.${system}.default =
        with pkgs;

        mkShell {

          packages = [
            bash
            qemu
          ];
        };

      packages.${system} = {

        inherit iso;
        inherit vm;
        inherit rootfsTree;
        inherit rootfsExt4;
        inherit dinitConfig;
        default = vm;

      };

    };

}
