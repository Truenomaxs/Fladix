{
  pkgs,
  kernel,
  initrd,
}:

let

  config = pkgs.writeText "limine.conf" ''

    timeout: 4
       serial: yes

       /amongOS
         protocol: linux
         path: boot():/boot/bzImage
         module_path: boot():/boot/initrd
         cmdline: console=ttyS0



  '';

in

pkgs.runCommand "myos-iso"
  {

    nativeBuildInputs = with pkgs; [
      limine
      xorriso
    ];

  }
  ''
        mkdir -p iso/boot/limine
         cp ${kernel}/${kernel.target} iso/boot/bzImage
         cp ${initrd}/initrd iso/boot/initrd
         cp ${config} iso/boot/limine/limine.conf
        cp ${pkgs.limine}/share/limine/limine-bios.sys iso/boot/limine/
    cp ${pkgs.limine}/share/limine/limine-bios-cd.bin iso/boot/limine/
         
        xorriso -as mkisofs -R -r -J \
           -b boot/limine/limine-bios-cd.bin \
           -no-emul-boot -boot-load-size 4 -boot-info-table \
        -hfsplus -apm-block-size 2048 --protective-msdos-label \
           iso -o "$out"




  ''
