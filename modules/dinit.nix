{ pkgs }:

pkgs.runCommand "fladix-dinit-config" { } ''
    mkdir -p $out/etc/dinit.d

    cat > $out/etc/dinit.d/boot <<'EOF'
  type = internal
  waits-for: shell
  EOF

    cat > $out/etc/dinit.d/shell <<EOF
  type = process
  command = ${pkgs.util-linux}/bin/agetty --noclear --noissue -n -l /bin/bash ttyS0 115200 vt100
  EOF
''
